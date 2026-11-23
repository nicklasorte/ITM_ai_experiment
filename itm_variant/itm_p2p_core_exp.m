function [A_db, info, wbits, elev_deg, mode_code] = itm_p2p_core_exp(h_tx_m, h_rx_m, pfl, f_mhz, reliability, confidence, ...
    location, climate, N_0, polarization, epsilon, sigma, mdvar, want_info, z, cfg)
%ITM_P2P_CORE_EXP Experimental copy of the ITM v1.4 point-to-point core. THE AGENT EDITS THIS FILE.
%   Copied unchanged from nicklasorte/matlab_itm private/itm_p2p_core.m
%   (commit 9bd6a4e), plus the cfg argument. With cfg = params_exp() at its
%   defaults, the output is bit-identical to the baseline. Submodel swaps
%   read their switches and constants from cfg; thread cfg into the
%   subfunction you change. Name each change by its physics and public
%   source, and record it in experiments/LOG.md.
%
%   Original header follows.
%
%ITM_P2P_CORE ITM v1.4 point-to-point computation without argument parsing.
%   Called by itm_p2p_rev1 (after its arguments block) and, once per link,
%   by itm_pathloss_rev1, which validates its own inputs once per call.
%   The arguments block costs about 0.4 ms, a fifth of a core call, so
%   skipping it per link matters for many-link runs. Inputs are positional;
%   see itm_p2p_rev1 for their meaning. want_info builds the info struct.
%   The NTIA input checks (ValidateInputs.cpp) still run here on every
%   call. z, optional, holds the percentages already validated and
%   converted to normal deviates by itm_percentiles; itm_pathloss_rev1
%   passes it so a reliability array is converted once, not once per link.
%   wbits (uint32) is the union of the NTIA warning flags over all output
%   elements; itm_validity turns it into errors or MATLAB warnings.
%   elev_deg ([TX, RX], degrees) is the elevation angle of the path at
%   each terminal: toward the other antenna on a line-of-sight path, or
%   toward the terrain horizon, on ITM's effective earth (radius 1/gamma_e).
%   mode_code is the propagation mode in the ITM 1.2.2 encoding (ITMDLL.cpp
%   point_to_pointMDH, also used by SEADLib ITMp2pAryRels): 0 line of
%   sight, 4 single horizon, 8 double horizon, plus 1 when diffraction
%   dominates and 2 when troposcatter dominates (5, 6, 9, 10).
%
%   Area mode (ITM_AREA_TLS_Ex, itm_area.cpp): pass a struct in place of
%   pfl, with fields d_km (path distance), delta_h_m (terrain irregularity
%   parameter), and siting ([TX RX], 0 random, 1 careful, 2 very careful).
%   InitializeArea then replaces the terrain-profile analysis, N_s = N_0,
%   and DiffractionLoss leaves out its point-to-point constant. Called by
%   itm_area_rev1.

if nargin < 16 || isempty(cfg)
    cfg = params_exp();
end
if ~isstruct(cfg) || ~isfield(cfg, 'version')
    error('itmexp:cfg', 'cfg must be the struct returned by params_exp.');
end
check_placeholder_switches(cfg);

info = [];
area = isstruct(pfl);
if ~area
    pfl = pfl(:);
    validate_profile(pfl);
end

% CR mode maps reliability to time and confidence to situation
% (ITM_P2P_CR calls ITM_P2P_TLS with time = reliability, location = 50,
% situation = confidence).
warnings = validate_inputs(h_tx_m, h_rx_m, climate, N_0, f_mhz, polarization, ...
    epsilon, sigma, mdvar);
if nargin < 15 || isempty(z)
    z = itm_percentiles(reliability, confidence, location);
end
out_size = z.size;

if area
    % itm_area.cpp: checked after ValidateInputs; system elevation 0
    [d_m, delta_h_m, siting] = validate_area(pfl);
    h_sys_m = 0.0;
else
    % Terrain-averaged system height over the middle 80 percent of the path
    np = fix(pfl(1));
    p10 = fix(0.1 * np);
    h_acc = cumsum(pfl((p10:np - p10) + 3));     % sequential, like the C++ loop
    h_sys_m = h_acc(end) / (np - 2 * p10 + 1);
end

[Z_g, gamma_e, N_s] = initialize_point_to_point(f_mhz, h_sys_m, N_0, ...
    polarization, epsilon, sigma);

h_m = [h_tx_m, h_rx_m];
% Terminal clutter at a concealed Phase 2 mobile terminal (B07, B08). The
% mobile end and the actual height are fixed here, before any height is
% used, because cfg.terminal_clutter_base = "clutter_height" computes the
% whole path with that antenna at max(h, R): ITU-R P.2108-1 section 3.1
% adds A_h to "basic transmission loss ... calculated to/from the height
% of the representative clutter height used" (also Table 1). B07 used the
% actual height and so counted the gain from h up to R twice (B07
% reviewer pass).
[mobile_end, h_mobile_m, ctype] = clutter_terminal(cfg, area, h_m);
if mobile_end > 0 && cfg.terminal_clutter_base == "clutter_height"
    [~, R_clut_m] = p2108_height_gain_rev1(f_mhz, h_mobile_m, ctype, ...
        cfg.terminal_clutter_frange);
    h_m(mobile_end) = max(h_mobile_m, R_clut_m);
end
if area
    [theta_hzn, d_hzn_m, h_e_m] = initialize_area(siting, gamma_e, delta_h_m, h_m);
    theta_geo = theta_hzn;                       % no profile: the estimated horizon angles
else
    [theta_hzn, d_hzn_m, h_e_m, delta_h_m, d_m, theta_geo] = quick_pfl(pfl, gamma_e, h_m);
end
elev_deg = rad2deg(theta_geo);

% Profile context for the profile-based submodels (batch B01). Built only
% when a switch leaves its ITM value, so the default path is unchanged.
delta = startsWith(cfg.diffraction, "delta_");
if ~area && ((cfg.diffraction ~= "itm" && ~delta) || cfg.line_of_sight ~= "itm")
    cfg.ctx = profile_context(pfl, h_m, 1 / gamma_e, f_mhz, cfg);
end

cfg.N_0_sea = N_0;                  % sea-level refractivity, for cfg.troposcatter = "p452_45"
[A_ref_db, warnings, propmode, lines] = longley_rice(theta_hzn, f_mhz, Z_g, d_hzn_m, h_e_m, ...
    gamma_e, N_s, delta_h_m, h_m, d_m, warnings, area, cfg);
if delta
    if area
        error('itmexp:cfg', 'Delta-Bullington needs a terrain profile; area mode has none.');
    end
    A_itm_db = A_ref_db;
    A_ref_db = delta_bullington_reference(pfl, h_m, gamma_e, f_mhz, Z_g, N_s, cfg, delta_h_m, h_e_m);
    if isfield(cfg, 'diffraction_bound') && cfg.diffraction_bound ~= "none"
        % Batch B06. Beyond the horizon the troposcatter field is present
        % whatever the terrain does to the diffracted field, so the scatter
        % loss bounds a profile-based diffraction loss. This bounds the
        % multi-edge sums on paths of hundreds of km. No new constant.
        %   "itm_troposcatter"       applies where ITM v1.4 itself puts the
        %       actual path in its troposcatter region (d beyond d_x):
        %       the loss can't exceed ITM's reference attenuation. Steps
        %       where ITM changes region (planner battery check, B06).
        %   "itm_troposcatter_line"  applies on every transhorizon path:
        %       the loss can't exceed ITM's troposcatter line through
        %       (d_5, A_5) and (d_6, A_6) evaluated at d. ITM uses that
        %       line only beyond d_x; using it at shorter transhorizon
        %       distances as an upper bound is a design choice.
        switch cfg.diffraction_bound
            case "itm_troposcatter"
                if propmode == 3
                    A_ref_db = min(A_ref_db, A_itm_db);
                end
            case "itm_troposcatter_line"
                if propmode ~= 1 && lines.A_5_db < 1000.0
                    A_ref_db = min(A_ref_db, max(lines.A_5_db + lines.M_s * (d_m - lines.d_5_m), 0.0));
                end
            otherwise
                error('itmexp:cfg', 'Unknown cfg.diffraction_bound "%s".', cfg.diffraction_bound);
        end
    end
end

% Terminal clutter at the Phase 2 mobile terminal (batch B07). An end
% loss added to the reference attenuation, after any bound on the
% diffraction loss, so it also enters the variability soft limit as the
% reference attenuation does. Only Phase 2 rows with siting "C"
% (concealed: "immediately behind a grove of trees or a building",
% data/raw/its_phase2.zip phase_2.txt) get it; open ("O"), undocumented
% ("A"), long-term, and synthetic rows get 0.
% The row's set and siting come from the evaluator in cfg.row (fields set,
% siting, reversed; evaluator change merged as PR #3), because open and
% concealed twins share one terrain profile and can't be told apart from
% the call arguments. The mobile terminal is the transmitter (end 1) in
% sets R1, R2, R3 (fixed receiver site in r1path.txt-r3path.txt) and the
% receiver (end 2) in VA (seven fixed transmitter sites in vapath.txt);
% reversed = true (terminals swapped, as in the reciprocity check) swaps it.
% The end is chosen in clutter_terminal, near the top of this function.
%   "p2108_height_gain"  ITU-R P.2108-1 section 3.1, clutter type
%       cfg.terminal_clutter_type at the mobile terminal's height
%   "constant"           cfg.terminal_clutter_db on the same rows, with no
%       frequency or height dependence (control; B06 reviewers' ablation)
if mobile_end > 0
    switch cfg.terminal_clutter
        case "p2108_height_gain"
            A_ref_db = A_ref_db + p2108_height_gain_rev1(f_mhz, h_mobile_m, ...
                ctype, cfg.terminal_clutter_frange);
        case "constant"
            A_ref_db = A_ref_db + cfg.terminal_clutter_db;
        otherwise
            error('itmexp:cfg', 'Unknown cfg.terminal_clutter "%s".', cfg.terminal_clutter);
    end
end

A_fs_db = free_space_loss(d_m, f_mhz);

% ITM 1.2.2 mode code: horizons from int(d - d_L), C truncation toward zero
q = fix(d_m - d_hzn_m(1) - d_hzn_m(2));
if q < 0
    mode_code = 0;
else
    mode_code = 4 + 4 * (q > 0) + 1 + (propmode == 3);
end

if isfield(cfg, 'time_variability') && cfg.time_variability == "two_leg" && ~area
    cfg.leg = two_leg_geometry(pfl, h_m, 1 / gamma_e, f_mhz);   % research package H03 (B12)
elseif isfield(cfg, 'time_variability') && ~any(cfg.time_variability == ["itm", "two_leg"])
    error('itmexp:cfg', 'Unknown cfg.time_variability "%s".', cfg.time_variability);
end
[V_db, extreme] = variability(z, h_e_m, delta_h_m, f_mhz, d_m, A_ref_db, climate, mdvar, cfg);
wbits = bitor(uint32(warnings), uint32(any(extreme(:))) * uint32(8192));
if lines.A_ref_undefined
    wbits = bitor(wbits, uint32(65536));   % MATLAB-only flag; not in info.warnings
end
if numel(V_db) ~= prod(out_size)
    % Scalar deviates (for example single-message mode, which ignores
    % time) give one value for every requested percentage
    V_db = V_db + zeros(out_size);
end
A_db = reshape(V_db + A_fs_db, out_size);
if ~all(isfinite(A_db), 'all')
    error('itm:NonFiniteLoss', 'ITM returned a non-finite loss (%g dB). Check the inputs and profile.', ...
        A_db(find(~isfinite(A_db), 1)));
end

if want_info
    extreme = extreme | false(out_size);
    w = uint32(warnings) + zeros(out_size, 'uint32');
    w(extreme) = bitor(w(extreme), uint32(8192));
    mode_names = ["Line of Sight", "Diffraction", "Troposcatter"];
    info = struct( ...
        'A_fs_db', A_fs_db, ...
        'A_ref_db', A_ref_db, ...
        'd_km', d_m / 1000, ...
        'delta_h_m', delta_h_m, ...
        'd_hzn_m', d_hzn_m, ...
        'h_e_m', h_e_m, ...
        'theta_hzn_rad', theta_hzn, ...
        'elevation_deg', elev_deg, ...
        'N_s', N_s, ...
        'mode', propmode, ...
        'mode_name', mode_names(propmode), ...
        'mode_code', mode_code, ...
        'warnings', reshape(w, out_size), ...
        'warning_messages', {itm_warning_text(wbits)}, ...
        'A_ref_undefined', lines.A_ref_undefined, ...
        'lines', lines);
end
end


%% ------------------------------------------------------------------------
%  Input validation (ValidateInputs.cpp)
%  ------------------------------------------------------------------------
function validate_profile(pfl)
if ~all(isfinite(pfl))
    error('itm:InvalidProfile', 'pfl must contain only finite values.');
end
if numel(pfl) < 4
    error('itm:InvalidProfile', 'pfl must be [np, xi, z_0, ..., z_np] with np >= 1.');
end
np = pfl(1);
if np < 1 || np ~= fix(np)
    error('itm:InvalidProfile', 'pfl(1) (number of intervals) must be a positive integer.');
end
if pfl(2) <= 0
    error('itm:InvalidProfile', 'pfl(2) (point spacing) must be positive.');
end
if numel(pfl) ~= np + 3
    error('itm:InvalidProfile', ...
        'numel(pfl) is %d but pfl(1) = %d intervals requires %d elements.', numel(pfl), np, np + 3);
end
end

function warnings = validate_inputs(h_tx, h_rx, climate, N_0, f, pol, epsilon, sigma, mdvar)
% Percentages (time, location, situation) are checked in itm_percentiles
warnings = 0;
if h_tx < 1.0 || h_tx > 1000.0
    warnings = bitor(warnings, 1);
end
if h_tx < 0.5 || h_tx > 3000.0
    itm_error(1000);
end
if h_rx < 1.0 || h_rx > 1000.0
    warnings = bitor(warnings, 2);
end
if h_rx < 0.5 || h_rx > 3000.0
    itm_error(1001);
end
if climate < 1 || climate > 7 || climate ~= fix(climate)
    itm_error(1002);
end
if N_0 < 250 || N_0 > 400
    itm_error(1008);
end
if f < 40.0 || f > 10000.0
    warnings = bitor(warnings, 4);
end
if f < 20 || f > 20000
    itm_error(1009);
end
if pol ~= 0 && pol ~= 1
    itm_error(1010);
end
if epsilon < 1
    itm_error(1011);
end
if sigma <= 0
    itm_error(1012);
end
if mdvar < 0 || mdvar > 33 || mdvar ~= fix(mdvar) || mod(mdvar, 10) > 3
    itm_error(1014);
end
end

function itm_error(code)
switch code
    case 1000, id = 'InvalidTxHeight';       msg = 'TX terminal height must be 0.5 to 3000 m.';
    case 1001, id = 'InvalidRxHeight';       msg = 'RX terminal height must be 0.5 to 3000 m.';
    case 1002, id = 'InvalidClimate';        msg = 'Radio climate must be an integer 1 to 7.';
    case 1004, id = 'InvalidLocation';       msg = 'Location percentage must be in (0, 100).';
    case 1006, id = 'InvalidConfidence';     msg = 'Confidence percentage must be in (0, 100).';
    case 1007, id = 'InvalidReliability';    msg = 'Reliability percentage must be in (0, 100).';
    case 1008, id = 'InvalidRefractivity';   msg = 'Refractivity N_0 must be 250 to 400 N-units.';
    case 1009, id = 'InvalidFrequency';      msg = 'Frequency must be 20 to 20000 MHz.';
    case 1010, id = 'InvalidPolarization';   msg = 'Polarization must be 0 (horizontal) or 1 (vertical).';
    case 1011, id = 'InvalidEpsilon';        msg = 'Relative permittivity epsilon must be >= 1.';
    case 1012, id = 'InvalidSigma';          msg = 'Conductivity sigma must be > 0.';
    case 1013, id = 'GroundImpedance';       msg = 'Imaginary part of the ground impedance exceeds the real part.';
    case 1014, id = 'InvalidMdvar';          msg = 'Mode of variability must be 0-3, 10-13, 20-23, or 30-33.';
    case 1016, id = 'EffectiveEarth';        msg = 'Internally computed effective earth radius is out of range.';
    case 1017, id = 'InvalidDistance';       msg = 'Path distance d_km must be > 0.';
    case 1018, id = 'InvalidDeltaH';         msg = 'Terrain irregularity delta_h_m must be >= 0.';
    case 1019, id = 'InvalidTxSiting';       msg = 'TX siting criteria must be 0 (random), 1 (careful), or 2 (very careful).';
    case 1020, id = 'InvalidRxSiting';       msg = 'RX siting criteria must be 0 (random), 1 (careful), or 2 (very careful).';
    case 1021, id = 'SurfaceRefractivitySmall'; msg = 'Internally computed surface refractivity is below 150 N-units.';
    case 1022, id = 'SurfaceRefractivityLarge'; msg = 'Internally computed surface refractivity is above 400 N-units.';
    otherwise, id = 'Unknown';               msg = 'Unknown ITM error.';
end
error(['itm:' id], 'ITM error %d: %s', code, msg);
end

function [d_m, delta_h_m, siting] = validate_area(a)
% Area-mode checks in ITM_AREA_TLS_Ex, in the same order
if ~(a.d_km > 0)
    itm_error(1017);
end
if ~(a.delta_h_m >= 0)
    itm_error(1018);
end
siting = a.siting;
if ~any(siting(1) == [0 1 2])
    itm_error(1019);
end
if ~any(siting(2) == [0 1 2])
    itm_error(1020);
end
d_m = a.d_km * 1000;
delta_h_m = a.delta_h_m;
end

%% ------------------------------------------------------------------------
%  Initialization (InitializePointToPoint.cpp, InitializeArea.cpp)
%  ------------------------------------------------------------------------
function [Z_g, gamma_e, N_s] = initialize_point_to_point(f_mhz, h_sys_m, N_0, pol, epsilon, sigma)
gamma_a = 157e-9;
if h_sys_m == 0.0
    N_s = N_0;
else
    N_s = N_0 * exp(-h_sys_m / 9460.0);
end
gamma_e = gamma_a * (1.0 - 0.04665 * exp(N_s / 179.3));
ep_r = complex(epsilon, 18000 * sigma / f_mhz);
Z_g = sqrt(ep_r - 1.0);
if pol == 1
    Z_g = Z_g / ep_r;
end
end

function [theta_hzn, d_hzn_m, h_e_m] = initialize_area(siting, gamma_e, delta_h_m, h_m)
% InitializeArea.cpp: effective heights, horizon distances, and horizon
% angles estimated from delta_h and the siting criteria [Algorithm, Eqns 3.2-3.4]
h_e_m = zeros(1, 2); d_hzn_m = zeros(1, 2); theta_hzn = zeros(1, 2);
for i = 1:2
    if siting(i) == 0
        h_e_m(i) = h_m(i);
    else
        if siting(i) == 1
            B = 4.0;
        else
            B = 9.0;
        end
        if h_m(i) < 5.0
            B = B * sin(0.1 * pi * h_m(i));
        end
        h_e_m(i) = h_m(i) + (1.0 + B) * exp(-c_min(20.0, 2.0 * h_m(i) / c_max(1e-3, delta_h_m)));
    end
    d_Ls = sqrt(2.0 * h_e_m(i) / gamma_e);
    d_hzn_m(i) = d_Ls * exp(-0.07 * sqrt(delta_h_m / c_max(h_e_m(i), 5)));
    theta_hzn(i) = (0.65 * delta_h_m * (d_Ls / d_hzn_m(i) - 1.0) - 2.0 * h_e_m(i)) / d_Ls;
end
end

%% ------------------------------------------------------------------------
%  Terrain processing (QuickPfl.cpp, FindHorizons.cpp, ComputeDeltaH.cpp,
%  LinearLeastSquaresFit.cpp). pfl is 1-based here: C++ pfl[j] is pfl(j+1).
%  ------------------------------------------------------------------------
function [theta_hzn, d_hzn_m, h_e_m, delta_h_m, d_m, theta_geo] = quick_pfl(pfl, gamma_e, h_m)
% theta_geo: the horizon angles from the profile, before the smooth-earth
% replacement used for paths well within line of sight
d_m = pfl(1) * pfl(2);
np = fix(pfl(1));
a_e = 1 / gamma_e;
[theta_hzn, d_hzn_m] = find_horizons(pfl, a_e, h_m);
theta_geo = theta_hzn;

d_start_m = min(15.0 * h_m(1), 0.1 * d_hzn_m(1));
d_end_m = d_m - min(15.0 * h_m(2), 0.1 * d_hzn_m(2));
delta_h_m = compute_delta_h(pfl, d_start_m, d_end_m);

h_e_m = zeros(1, 2);
if d_hzn_m(1) + d_hzn_m(2) > 1.5 * d_m
    % Well within line of sight: horizons from the smooth-earth fit
    [fit_tx, fit_rx] = linear_least_squares_fit(pfl, d_start_m, d_end_m);
    h_e_m(1) = h_m(1) + fdim(pfl(3), fit_tx);
    h_e_m(2) = h_m(2) + fdim(pfl(np + 3), fit_rx);
    d_hzn_m = sqrt(2.0 * h_e_m * a_e) .* exp(-0.07 * sqrt(delta_h_m ./ max(h_e_m, 5.0)));
    combined = d_hzn_m(1) + d_hzn_m(2);
    if combined <= d_m
        h_e_m = h_e_m * (d_m / combined)^2;
        d_hzn_m = sqrt(2.0 * h_e_m * a_e) .* exp(-0.07 * sqrt(delta_h_m ./ max(h_e_m, 5.0)));
    end
    q = sqrt(2.0 * h_e_m * a_e);
    theta_hzn = (0.65 * delta_h_m * (q ./ d_hzn_m - 1.0) - 2.0 * h_e_m) ./ q;
else
    [fit_tx, ~] = linear_least_squares_fit(pfl, d_start_m, 0.9 * d_hzn_m(1));
    h_e_m(1) = h_m(1) + fdim(pfl(3), fit_tx);
    [~, fit_rx] = linear_least_squares_fit(pfl, d_m - 0.9 * d_hzn_m(2), d_end_m);
    h_e_m(2) = h_m(2) + fdim(pfl(np + 3), fit_rx);
end
end

function [theta_hzn, d_hzn_m] = find_horizons(pfl, a_e, h_m)
% Vectorized horizon search. Distances use cumsum, which adds in sequence
% exactly like the C++ loop (d += xi); k*xi rounds differently, and
% downstream integer truncation (for example 0.9*d_hzn/xi) is sensitive
% to that last bit. max() returns the first maximum, matching the C++
% strict > comparison.
np = fix(pfl(1));
xi = pfl(2);
d_m = pfl(1) * pfl(2);
z_tx = pfl(3) + h_m(1);
z_rx = pfl(np + 3) + h_m(2);
theta_hzn = [(z_rx - z_tx) / d_m - d_m / (2 * a_e), -(z_rx - z_tx) / d_m - d_m / (2 * a_e)];
d_hzn_m = [d_m, d_m];
if np < 2
    return
end
d_tx = cumsum(repmat(xi, np - 1, 1));
d_rx = cumsum([d_m; repmat(-xi, np - 1, 1)]);
d_rx = d_rx(2:end);
z = pfl((1:np - 1)' + 3);
[theta_tx, i_tx] = max((z - z_tx) ./ d_tx - d_tx / (2 * a_e));
[theta_rx, i_rx] = max(-(z_rx - z) ./ d_rx - d_rx / (2 * a_e));
if theta_tx > theta_hzn(1)
    theta_hzn(1) = theta_tx;
    d_hzn_m(1) = d_tx(i_tx);
end
if theta_rx > theta_hzn(2)
    theta_hzn(2) = theta_rx;
    d_hzn_m(2) = d_rx(i_rx);
end
end

function delta_h_m = compute_delta_h(pfl, d_start_m, d_end_m)
% Terrain irregularity: interdecile range of the profile about a linear
% fit, over n evenly spaced resampled points.
np = fix(pfl(1));
x_start = d_start_m / pfl(2);
x_end = d_end_m / pfl(2);
if x_end - x_start < 2.0
    delta_h_m = 0;
    return
end
p10 = fix(0.1 * (x_end - x_start + 8.0));
p10 = min(max(4, p10), 25);
n = 10 * p10 - 5;
p90 = n - p10;
np_s = n - 1;
% Resample the profile at n evenly spaced points. The C++ steps a
% fractional position x_start by `step` and, after each step, decrements
% it by 1 (advancing the profile index i) while it is positive. All but
% the last decrement are exact, and IEEE subtraction rounds the same exact
% result, so one subtraction of m = ceil(x_start) reproduces the inner
% loop bit for bit. The outer recurrence (at most 245 steps) stays a loop
% because each step's rounding depends on the previous position.
s = zeros(n + 2, 1);
s(1) = np_s;
s(2) = 1.0;
step = (x_end - x_start) / np_s;
i = fix(x_start);
x_start = x_start - double(single(i + 1.0));   % C++ casts (i + 1.0) to float
idx = zeros(n, 1);
pos = zeros(n, 1);
for j = 1:n
    if x_start > 0.0
        m = min(ceil(x_start), np - 1 - i);
        if m > 0
            x_start = x_start - m;
            i = i + m;
        end
    end
    idx(j) = i;
    pos(j) = x_start;
    x_start = x_start + step;
end
z_hi = pfl(idx + 4);
s(3:n + 2) = z_hi + (z_hi - pfl(idx + 3)) .* pos;
[fit_y1, fit_y2] = linear_least_squares_fit(s, 0.0, np_s);
fit_y2 = (fit_y2 - fit_y1) / np_s;
fit_line = cumsum([fit_y1; repmat(fit_y2, n - 1, 1)]);   % C++: y += fit_y2
diffs = s(3:n + 2) - fit_line;
sorted = sort(diffs, 'descend');      % nth_element with std::greater
q10 = sorted(p10);
q90 = sorted(p90 + 1);
delta_h_d_m = q10 - q90;
delta_h_m = delta_h_d_m / (1.0 - 0.8 * exp(-(d_end_m - d_start_m) / 50e3));
end

function [fit_y1, fit_y2] = linear_least_squares_fit(pfl, d_start, d_end)
% Least-squares line through pfl elevations between d_start and d_end,
% evaluated at the two profile ends (trapezoidal end weights, as in C++).
np = fix(pfl(1));
i_start = fix(fdim(d_start / pfl(2), 0.0));
i_end = np - fix(fdim(np, d_end / pfl(2)));
if i_end <= i_start
    i_start = fix(fdim(i_start, 1.0));
    i_end = np - fix(fdim(np, i_end + 1.0));
end
x_length = i_end - i_start;
mid_shifted_end = i_end - 0.5 * x_length;
y_s = pfl(i_start + 3);
y_e = pfl(i_end + 3);
inner = pfl((i_start + 1:i_end - 1) + 3);
m = -0.5 * x_length + (1:x_length - 1)';
% cumsum(...)(end) adds in the same order as the C++ loop; sum() may not.
acc_y = cumsum([0.5 * (y_s + y_e); inner]);
acc_s = cumsum([0.5 * (y_s - y_e) * (-0.5 * x_length); inner .* m]);
sum_y = acc_y(end);
scaled_sum_y = acc_s(end);
sum_y = sum_y / x_length;
scaled_sum_y = scaled_sum_y * 12.0 / ((x_length * x_length + 2.0) * x_length);
fit_y1 = sum_y - scaled_sum_y * mid_shifted_end;
fit_y2 = sum_y + scaled_sum_y * (np - mid_shifted_end);
end

function v = fdim(x, y)
% Positive difference. Gives 0 for NaN, like the C++ DIM macro; the
% std::fdim calls in QuickPfl and LinearLeastSquaresFit only see finite values.
v = max(x - y, 0);
end

%% ------------------------------------------------------------------------
%  Reference attenuation (LongleyRice.cpp)
%  ------------------------------------------------------------------------
function [A_ref_db, warnings, propmode, lines] = longley_rice(theta_hzn, f_mhz, Z_g, d_hzn_m, h_e_m, ...
    gamma_e, N_s, delta_h_m, h_m, d_m, warnings, area, cfg)
% area: true in area mode (DiffractionLoss leaves out its q + 10).
% lines: the reference-attenuation construction, for diagnostics (info.lines):
% the diffraction line through (d_3, A_3) and (d_4, A_4), the line-of-sight
% fit through (d_0, A_0), (d_1, A_1), and (d_sML, A_sML), and the scatter
% line through (d_5, A_5) and (d_6, A_6), all in metres and dB. Fields that a
% path's region doesn't compute are NaN.
a_e = 1 / gamma_e;
d_hzn_s = sqrt(2.0 * h_e_m * a_e);
d_sML = d_hzn_s(1) + d_hzn_s(2);
d_ML = d_hzn_m(1) + d_hzn_m(2);
theta_los = -c_max(theta_hzn(1) + theta_hzn(2), -d_ML / a_e);

if abs(theta_hzn(1)) > 200e-3, warnings = bitor(warnings, 128); end
if abs(theta_hzn(2)) > 200e-3, warnings = bitor(warnings, 256); end
if d_hzn_m(1) < 0.1 * d_hzn_s(1), warnings = bitor(warnings, 512); end
if d_hzn_m(2) < 0.1 * d_hzn_s(2), warnings = bitor(warnings, 1024); end
if d_hzn_m(1) > 3.0 * d_hzn_s(1), warnings = bitor(warnings, 2048); end
if d_hzn_m(2) > 3.0 * d_hzn_s(2), warnings = bitor(warnings, 4096); end

if N_s < 150, itm_error(1021); end
if N_s > 400, itm_error(1022); end
if N_s < 250, warnings = bitor(warnings, 16384); end
if a_e < 4000000 || a_e > 13333333, itm_error(1016); end
if real(Z_g) <= abs(imag(Z_g)), itm_error(1013); end

d_3 = c_max(d_sML, d_ML + 5.0 * (a_e^2 / f_mhz)^(1.0 / 3.0));
d_4 = d_3 + 10.0 * (a_e^2 / f_mhz)^(1.0 / 3.0);
A_3 = diffraction_loss(d_3, d_hzn_m, h_e_m, Z_g, a_e, delta_h_m, h_m, theta_los, d_sML, f_mhz, area, cfg);
A_4 = diffraction_loss(d_4, d_hzn_m, h_e_m, Z_g, a_e, delta_h_m, h_m, theta_los, d_sML, f_mhz, area, cfg);
M_d = (A_4 - A_3) / (d_4 - d_3);
A_d0 = A_3 - M_d * d_3;
nan_ = NaN;
lines = struct('a_e_m', a_e, 'd_sML_m', d_sML, 'd_ML_m', d_ML, 'theta_los_rad', theta_los, ...
    'd_3_m', d_3, 'd_4_m', d_4, 'A_3_db', A_3, 'A_4_db', A_4, 'M_d', M_d, 'A_d0_db', A_d0, ...
    'd_0_m', nan_, 'd_1_m', nan_, 'A_0_db', nan_, 'A_1_db', nan_, 'A_sML_db', nan_, ...
    'kHat_1', nan_, 'kHat_2', nan_, 'A_o_db', nan_, ...
    'd_5_m', nan_, 'd_6_m', nan_, 'A_5_db', nan_, 'A_6_db', nan_, 'M_s', nan_, 'A_s0_db', nan_, 'd_x_m', nan_, ...
    'A_ref_undefined', false);

d_min = abs(h_e_m(1) - h_e_m(2)) / 200e-3;
if d_m < d_min,   warnings = bitor(warnings, 32); end
if d_m < 1e3,     warnings = bitor(warnings, 64); end
if d_m > 1000e3,  warnings = bitor(warnings, 8); end
if d_m > 2000e3,  warnings = bitor(warnings, 16); end

% Region and, for the profile-based diffraction switches, the diffraction
% line. Without cfg.ctx (every switch at "itm") this is ITM's own test.
los_region = d_m < d_sML;
if isfield(cfg, 'ctx')
    if cfg.line_of_sight == "profile_horizons" && cfg.ctx.obstructed
        % The profile blocks the ray between the antennas, so the path is
        % treated as transhorizon even where the smooth-earth horizons of
        % the effective heights say line of sight.
        los_region = false;
    end
    blocked_los = los_region && cfg.ctx.obstructed && isfield(cfg, 'diffraction_region') ...
        && cfg.diffraction_region == "blocked_paths";
    if cfg.diffraction ~= "itm" && (~los_region || blocked_los)
        % ITM: A_d = w A_se + (1 - w) A_k + A_fo, extrapolated along the line
        % through d_3 and d_4. Here the smooth-earth and clutter part keeps
        % that line, and the knife-edge part is replaced by the
        % profile-based loss at the path's own distance. The slope M_d is
        % kept, and the line is re-anchored to pass through the new value
        % at d, so the line-of-sight fit and the scatter crossover use it.
        % With cfg.diffraction_region = "blocked_paths" the same is done for
        % line-of-sight-region paths whose profile blocks the direct ray.
        % ITM's line-of-sight fit passes through the diffraction line at
        % d_sML, so the loss is continuous where such a path crosses d_sML.
        [~, B_3] = diffraction_loss(d_3, d_hzn_m, h_e_m, Z_g, a_e, delta_h_m, h_m, theta_los, d_sML, f_mhz, area, cfg);
        [~, B_4] = diffraction_loss(d_4, d_hzn_m, h_e_m, Z_g, a_e, delta_h_m, h_m, theta_los, d_sML, f_mhz, area, cfg);
        w_d = knife_weight(d_m, d_hzn_m, h_e_m, a_e, delta_h_m, h_m, theta_los, f_mhz, area, cfg);
        A_var = B_3 + (B_4 - B_3) / (d_4 - d_3) * (d_m - d_3) ...
            + (1.0 - w_d) * cfg.cal.knife_scale * cfg.ctx.A_knife_db;
        if ~los_region && isfield(cfg, 'diffraction_region') && cfg.diffraction_region == "transhorizon_phased"
            % Phase the profile-based value in across ITM's own anchor
            % distances: ITM's line at d_sML (where its line-of-sight fit
            % joins, so the loss stays continuous), the full profile-based
            % value from d_3 (where ITM itself evaluates diffraction).
            % Linear in distance; no new constant (batch B03).
            A_itm = M_d * d_m + A_d0;
            if d_3 > d_sML
                t = min(max((d_m - d_sML) / (d_3 - d_sML), 0.0), 1.0);
            else
                t = 1.0;
            end
            A_var = A_itm + t * (A_var - A_itm);
        end
        A_d0 = A_var - M_d * d_m;
        lines.A_d0_db = A_d0;
    end
end

if los_region
    % Line-of-sight region
    A_sML = d_sML * M_d + A_d0;
    d_0 = 0.04 * f_mhz * h_e_m(1) * h_e_m(2);
    if A_d0 >= 0.0
        d_0 = c_min(d_0, 0.5 * d_ML);
        d_1 = d_0 + 0.25 * (d_ML - d_0);
    else
        d_1 = c_max(-A_d0 / M_d, 0.25 * d_ML);
    end
    A_1 = line_of_sight_loss(d_1, h_e_m, Z_g, delta_h_m, M_d, A_d0, d_sML, f_mhz, cfg, a_e);
    flag = false;
    kHat_1 = 0;
    kHat_2 = 0;
    if d_0 < d_1
        A_0 = line_of_sight_loss(d_0, h_e_m, Z_g, delta_h_m, M_d, A_d0, d_sML, f_mhz, cfg, a_e);
        q = log(d_sML / d_0);
        kHat_2 = c_max(0.0, ((d_sML - d_0) * (A_1 - A_0) - (d_1 - d_0) * (A_sML - A_0)) / ...
            ((d_sML - d_0) * log(d_1 / d_0) - (d_1 - d_0) * q));
        flag = A_d0 > 0.0 || kHat_2 > 0.0;
        if flag
            kHat_1 = (A_sML - A_0 - kHat_2 * q) / (d_sML - d_0);
            if kHat_1 < 0.0
                kHat_1 = 0.0;
                kHat_2 = fdim(A_sML, A_0) / q;
                if kHat_2 == 0.0
                    kHat_1 = M_d;
                end
            end
        end
    end
    if ~flag
        kHat_1 = fdim(A_sML, A_1) / (d_sML - d_1);
        kHat_2 = 0.0;
        if kHat_1 == 0.0
            kHat_1 = M_d;
        end
    end
    A_o = A_sML - kHat_1 * d_sML - kHat_2 * log(d_sML);
    A_ref_db = A_o + kHat_1 * d_m + kHat_2 * log(d_m);
    propmode = 1;
    lines.d_0_m = d_0; lines.d_1_m = d_1; lines.A_1_db = A_1; lines.A_sML_db = A_sML;
    if d_0 < d_1, lines.A_0_db = A_0; end
    lines.kHat_1 = kHat_1; lines.kHat_2 = kHat_2; lines.A_o_db = A_o;
else
    % Transhorizon: diffraction or troposcatter
    d_5 = d_ML + 200e3;
    d_6 = d_ML + 400e3;
    h0 = -1;
    [A_6, h0] = troposcatter_loss(d_6, theta_hzn, d_hzn_m, h_e_m, a_e, N_s, f_mhz, theta_los, h0, cfg);
    A_5 = troposcatter_loss(d_5, theta_hzn, d_hzn_m, h_e_m, a_e, N_s, f_mhz, theta_los, h0, cfg);
    if A_5 < 1000.0
        M_s = (A_6 - A_5) / 200e3;
        d_x = c_max(c_max(d_sML, d_ML + 1.088 * (a_e^2 / f_mhz)^(1.0 / 3.0) * log(f_mhz)), ...
            (A_5 - A_d0 - M_s * d_5) / (M_d - M_s));
        A_s0 = (M_d - M_s) * d_x + A_d0;
    else
        M_s = M_d;
        A_s0 = A_d0;
        d_x = 10e6;
    end
    lines.d_5_m = d_5; lines.d_6_m = d_6; lines.A_5_db = A_5; lines.A_6_db = A_6;
    lines.M_s = M_s; lines.A_s0_db = A_s0; lines.d_x_m = d_x;
    if d_m > d_x
        A_ref_db = M_s * d_m + A_s0;
        propmode = 3;
    else
        A_ref_db = M_d * d_m + A_d0;
        propmode = 2;
    end
end
% A NaN here (an out-of-domain smooth-earth term) becomes 0 in the C++
% MAX macro, as it does in c_max; the flag lets the caller say so
lines.A_ref_undefined = isnan(A_ref_db);
A_ref_db = c_max(A_ref_db, 0.0);
end

function [A_d, A_base] = diffraction_loss(d_m, d_hzn_m, h_e_m, Z_g, a_e, delta_h_m, h_m, theta_los, d_sML, f_mhz, area, cfg)
% A_base (optional): the smooth-earth and clutter part, w A_se + A_fo,
% without the knife-edge part (1 - w) A_k.
A_k = knife_edge_diffraction(d_m, f_mhz, a_e, theta_los, d_hzn_m);
A_se = smooth_earth_diffraction(d_m, f_mhz, a_e, theta_los, d_hzn_m, h_e_m, Z_g);
delta_h_dsML = terrain_roughness(d_sML, delta_h_m);
sigma_h_d = sigma_h_function(delta_h_dsML);
A_fo = c_min(15.0, 5 * log10(1.0 + 1e-5 * h_m(1) * h_m(2) * f_mhz * sigma_h_d));
delta_h_d = terrain_roughness(d_m, delta_h_m);
q = h_m(1) * h_m(2);
qk = h_e_m(1) * h_e_m(2) - q;
if ~area
    q = q + 10.0;                               % point-to-point mode only
end
term1 = sqrt(1.0 + qk / q);
d_ML = d_hzn_m(1) + d_hzn_m(2);
q = (term1 + (-theta_los * a_e + d_ML) / d_m) * c_min(delta_h_d * f_mhz / 47.7, 6283.2);
w = cfg.cal.w_const / (cfg.cal.w_const + c_sqrt(q));      % ITM: 25.1
A_d = w * A_se + (1.0 - w) * (cfg.cal.knife_scale * A_k) + cfg.cal.afo_scale * A_fo;   % ITM: scales 1
if nargout > 1
    A_base = w * A_se + cfg.cal.afo_scale * A_fo;
end
end

function w = knife_weight(d_m, d_hzn_m, h_e_m, a_e, delta_h_m, h_m, theta_los, f_mhz, area, cfg)
% ITM's smooth-earth weight w from diffraction_loss, at distance d_m. The
% knife-edge part carries 1 - w. Same arithmetic as diffraction_loss.
delta_h_d = terrain_roughness(d_m, delta_h_m);
q = h_m(1) * h_m(2);
qk = h_e_m(1) * h_e_m(2) - q;
if ~area
    q = q + 10.0;
end
term1 = sqrt(1.0 + qk / q);
d_ML = d_hzn_m(1) + d_hzn_m(2);
q = (term1 + (-theta_los * a_e + d_ML) / d_m) * c_min(delta_h_d * f_mhz / 47.7, 6283.2);
w = cfg.cal.w_const / (cfg.cal.w_const + c_sqrt(q));
end

function A_ref = delta_bullington_reference(pfl, h_m, gamma_e, f_mhz, Z_g, N_s, cfg, delta_h_m, h_e_m)
% Reference attenuation by the delta-Bullington construction (batch B04).
%   L_ba  Bullington loss of the actual profile with the actual antennas
%   L_bs  Bullington loss of a zero-height profile with the antennas at
%         their heights above the smooth-earth surface
%   A_s   ITM's own reference attenuation for the smooth-earth equivalent
%         path (straight terrain from h_st to h_sr, same antennas), standing
%         in for the spherical-earth loss L_sph
% Smooth-earth surface: least-squares fit with the obstruction adjustment
% and the terminal-ground limits, ITU-R P.452-18 Attachment 2 section 5,
% eq. (161)-(167); the same construction as ITU-R P.526-16 section 4.5.2,
% eq. (58)-(64). Bullington: ITU-R P.526-16 section 4.5.1, eq. (49)-(57).
% Forms:
%   "delta_bullington"       L_ba + max(A_s - L_bs, 0)   P.452-18 eq. (38)-(40)
%   "delta_bullington_p526"  max(L_ba + A_s - L_bs, 0)   P.526-16 eq. (66)
% On a straight-line terrain L_ba = L_bs and the smooth path is the actual
% path, so the P.526 form returns ITM's own A_ref exactly (tested).
% Batch B05 forms, all L_a + max(A_s - L_s, 0) with the same obstruction
% method on the actual and the zero-height profile:
%   "delta_string_ep"      obstructions from the stretched string
%   "delta_p526_cascaded"  ITU-R P.526-11 section 4.4.2
%   "delta_deygout"        Deygout three-edge
%   "delta_ep_isolated"    Epstein-Peterson over isolated horizon obstacles
%   "delta_bullington_afo" "delta_bullington" plus ITM's own clutter term
%       A_fo of the actual path (DiffractionLoss, ITM v1.4), which the
%       smooth-path ITM call drops because its terrain irregularity is zero
%       (control named by the B04 reviewers)
% Batch B06 forms:
%   "delta_cascaded_isolated"      ITU-R P.526-11 section 4.4.2 with secondary
%       edges weighted by isolation ("p526_cascaded_isolated")
%   "delta_cascaded_isolated_afo"  the same plus ITM's A_fo
% Batch B07 forms (no A_fo; B06 reviewer pass):
%   "delta_deygout_isolated"  Deygout over the isolation-weighted edges,
%       without P.526-11's empirical correction C
%   "delta_bullington_uc"     Bullington without the eq. (57) correction
% Batch B09 form:
%   "delta_p526_cylinders_knife"  ITU-R P.526-16 section 4.4 (multiple
%       isolated cylinders) with zero-radius cylinders, no empirical correction
np = fix(pfl(1));
xi = pfl(2);
x = (0:np)' * xi;
g = pfl(3:np + 3);
d = x(end);
hts = g(1) + h_m(1);
hrs = g(end) + h_m(2);
dd = x(2:end) - x(1:end - 1);
v1 = sum(dd .* (g(2:end) + g(1:end - 1)));                                            % eq. (161)
v2 = sum(dd .* (g(2:end) .* (2 * x(2:end) + x(1:end - 1)) + g(1:end - 1) .* (x(2:end) + 2 * x(1:end - 1))));  % eq. (162)
hst = (2 * v1 * d - v2) / d^2;                                                        % eq. (163)
hsr = (v2 - v1 * d) / d^2;                                                            % eq. (164)
if np >= 2
    ii = 2:np;
    HH = g - (hts * (d - x) + hrs * x) / d;                                           % eq. (165d)
    hobs = max(HH(ii));                                                               % eq. (165a)
    if hobs > 0
        a_t = max(HH(ii) ./ x(ii));                                                   % eq. (165b)
        a_r = max(HH(ii) ./ (d - x(ii)));                                             % eq. (165c)
        hst = hst - hobs * a_t / (a_t + a_r);                                         % eq. (166c), (166e)
        hsr = hsr - hobs * a_r / (a_t + a_r);                                         % eq. (166d), (166f)
    end
end
hst = min(hst, g(1));                                                                 % eq. (167a), (167b)
hsr = min(hsr, g(end));                                                               % eq. (167c), (167d)
hp = [hts - hst, hrs - hsr];                                                          % heights above the smooth surface
a_e = 1 / gamma_e;
z = g; z(1) = hts; z(end) = hrs;
switch cfg.diffraction
    case {"delta_bullington", "delta_bullington_p526", "delta_bullington_afo"}
        method = "bullington";
    case "delta_string_ep"
        method = "string_ep";
    case "delta_p526_cascaded"
        method = "p526_cascaded";
    case "delta_deygout"
        method = "deygout";
    case "delta_ep_isolated"
        method = "ep_isolated";
    case {"delta_cascaded_isolated", "delta_cascaded_isolated_afo"}
        method = "p526_cascaded_isolated";
    case "delta_deygout_isolated"
        method = "deygout_isolated";
    case "delta_bullington_uc"
        method = "bullington_uc";
    case "delta_p526_cylinders_knife"
        method = "p526_cylinders_knife";
    otherwise
        error('itmexp:cfg', 'Unknown delta form "%s".', cfg.diffraction);
end
L_ba = multi_edge_diffraction_rev1(method, x, z, f_mhz, a_e);
z0 = zeros(size(g)); z0(1) = hp(1); z0(end) = hp(2);
L_bs = multi_edge_diffraction_rev1(method, x, z0, f_mhz, a_e);
% ITM on the smooth-earth equivalent path, every switch at "itm"
pfl_s = [pfl(1); pfl(2); hst + (hsr - hst) * x / d];
c0 = cfg;
c0.diffraction = "itm"; c0.line_of_sight = "itm";
if isfield(c0, 'ctx'), c0 = rmfield(c0, 'ctx'); end
[th_s, dh_s, he_s, delta_h_s, d_s] = quick_pfl(pfl_s, gamma_e, hp);
A_s = longley_rice(th_s, f_mhz, Z_g, dh_s, he_s, gamma_e, N_s, delta_h_s, hp, d_s, uint32(0), false, c0);
if cfg.diffraction == "delta_bullington_p526"
    A_ref = max(L_ba + A_s - L_bs, 0);
else
    A_ref = L_ba + max(A_s - L_bs, 0);
end
if endsWith(cfg.diffraction, "_afo")
    % ITM's A_fo for the actual path, exactly as in diffraction_loss
    d_sML = sqrt(2.0 * h_e_m(1) * a_e) + sqrt(2.0 * h_e_m(2) * a_e);
    sigma_h_d = sigma_h_function(terrain_roughness(d_sML, delta_h_m));
    A_ref = A_ref + cfg.cal.afo_scale * c_min(15.0, 5 * log10(1.0 + 1e-5 * h_m(1) * h_m(2) * f_mhz * sigma_h_d));
end
if ~isfinite(A_ref) || ~isreal(A_ref)
    error('itmexp:delta', 'Non-finite delta-Bullington reference attenuation.');
end
end

function ctx = profile_context(pfl, h_m, a_e, f_mhz, cfg)
% What the profile-based submodels need from the terrain profile:
%   obstructed   terrain rises above the direct ray between the antennas
%                (FindHorizons found a terrain horizon)
%   A_knife_db   profile-based knife-edge loss at the path's own geometry
%                (multi_edge_diffraction_rev1), or NaN when cfg.diffraction
%                is "itm"
if isfield(cfg, 'diffraction_region') && ~ismember(cfg.diffraction_region, ["transhorizon" "blocked_paths" "transhorizon_phased"])
    error('itmexp:cfg', 'Unknown cfg.diffraction_region "%s".', cfg.diffraction_region);
end
if ~ismember(cfg.line_of_sight, ["itm" "profile_horizons"])
    error('itmexp:cfg', 'Unknown cfg.line_of_sight "%s".', cfg.line_of_sight);
end
np = fix(pfl(1));
d_m = pfl(1) * pfl(2);
[~, d_hzn_geo] = find_horizons(pfl, a_e, h_m);
ctx = struct('obstructed', d_hzn_geo(1) < d_m || d_hzn_geo(2) < d_m, 'A_knife_db', NaN);
if cfg.diffraction ~= "itm"
    x = (0:np)' * pfl(2);
    z = pfl(3:np + 3);
    z(1) = z(1) + h_m(1);
    z(np + 1) = z(np + 1) + h_m(2);
    ctx.A_knife_db = multi_edge_diffraction_rev1(cfg.diffraction, x, z, f_mhz, a_e);
end
end

function A_k = knife_edge_diffraction(d_m, f_mhz, a_e, theta_los, d_hzn_m)
d_ML = d_hzn_m(1) + d_hzn_m(2);
theta_nlos = d_m / a_e - theta_los;
d_nlos = d_m - d_ML;
v_1 = 0.0795775 * (f_mhz / 47.7) * theta_nlos^2 * d_hzn_m(1) * d_nlos / (d_nlos + d_hzn_m(1));
v_2 = 0.0795775 * (f_mhz / 47.7) * theta_nlos^2 * d_hzn_m(2) * d_nlos / (d_nlos + d_hzn_m(2));
A_k = fresnel_integral(v_1) + fresnel_integral(v_2);
end

function A = fresnel_integral(v2)
if v2 < 5.76
    A = 6.02 + 9.11 * c_sqrt(v2) - 1.27 * v2;
else
    A = 12.953 + 10 * log10(v2);
end
end

function A_se = smooth_earth_diffraction(d_m, f_mhz, a_e, theta_los, d_hzn_m, h_e_m, Z_g)
a_0 = 6370e3;
THIRD = 1.0 / 3.0;
theta_nlos = d_m / a_e - theta_los;
d_ML = d_hzn_m(1) + d_hzn_m(2);
a_m = [(d_m - d_ML) / (d_m / a_e - theta_los), ...
    0.5 * d_hzn_m(1)^2 / h_e_m(1), ...
    0.5 * d_hzn_m(2)^2 / h_e_m(2)];
d_km = [(a_m(1) * theta_nlos) / 1000.0, d_hzn_m(1) / 1000.0, d_hzn_m(2) / 1000.0];
C_0 = c_pow((4.0 / 3.0) * a_0 ./ a_m, THIRD);
K = 0.017778 * C_0 * f_mhz^(-THIRD) / abs(Z_g);
B_0 = 1.607 - K;
x_km = zeros(1, 3);
x_km(2) = B_0(2) * C_0(2)^2 * f_mhz^THIRD * d_km(2);
x_km(3) = B_0(3) * C_0(3)^2 * f_mhz^THIRD * d_km(3);
x_km(1) = B_0(1) * C_0(1)^2 * f_mhz^THIRD * d_km(1) + x_km(2) + x_km(3);
F_x_1 = height_function(x_km(2), K(2));
F_x_2 = height_function(x_km(3), K(3));
G_x = 0.05751 * x_km(1) - 10.0 * c_log10(x_km(1));
A_se = G_x - F_x_1 - F_x_2 - 20;
end

function result = height_function(x_km, K)
if x_km < 200.0
    w = -log(K);
    if K < 1e-5 || x_km * w^3 > 5495.0
        result = -117.0;
        if x_km > 1.0
            result = 17.372 * log(x_km) + result;
        end
    else
        result = 2.5e-5 * x_km^2 / K - 8.686 * w - 15.0;
    end
else
    result = 0.05751 * x_km - 4.343 * log(x_km);
    if x_km < 2000
        w = 0.0134 * x_km * exp(-0.005 * x_km);
        result = (1.0 - w) * result + w * (17.372 * log(x_km) - 117.0);
    end
end
end

function A_los = line_of_sight_loss(d_m, h_e_m, Z_g, delta_h_m, M_d, A_d0, d_sML, f_mhz, cfg, a_e)
delta_h_d = terrain_roughness(d_m, delta_h_m);
sigma_h_d = sigma_h_function(delta_h_d);
wn = f_mhz / 47.7;
sin_psi = (h_e_m(1) + h_e_m(2)) / sqrt(d_m^2 + (h_e_m(1) + h_e_m(2))^2);
R_e = (sin_psi - Z_g) / (sin_psi + Z_g) * exp(-c_min(10.0, wn * sigma_h_d * sin_psi));
q = real(R_e)^2 + imag(R_e)^2;
if q < 0.25 || q < sin_psi
    R_e = R_e * sqrt(sin_psi / q);
end
if isfield(cfg, 'los_phase') && cfg.los_phase == "curved_specular"
    % Research package H02 (batch B12): heights above the plane tangent at
    % the curved-Earth specular point, ITU-R P.530-19 eq. (121)-(126)
    delta_phi = los_phase_curved_rev1(h_e_m(1), h_e_m(2), d_m, a_e, wn);
elseif ~isfield(cfg, 'los_phase') || cfg.los_phase == "itm"
    delta_phi = wn * 2.0 * h_e_m(1) * h_e_m(2) / d_m;
else
    error('itmexp:cfg', 'Unknown cfg.los_phase "%s".', cfg.los_phase);
end
if delta_phi > pi / 2.0
    delta_phi = pi - (pi / 2.0)^2 / delta_phi;
end
rr = complex(cos(delta_phi), -sin(delta_phi)) + R_e;
A_t = -10 * log10(real(rr)^2 + imag(rr)^2);
A_d = M_d * d_m + A_d0;
w = 1 / (1 + cfg.cal.los_w_scale * f_mhz * delta_h_m / c_max(10e3, d_sML));   % ITM: scale 1
A_los = w * A_t + (1 - w) * A_d;
end

function [A_scat, h0] = troposcatter_loss(d_m, theta_hzn, d_hzn_m, h_e_m, a_e, N_s, f_mhz, theta_los, h0, cfg)
% cfg.troposcatter (B13):
%   "itm"      ITM v1.4 troposcatter attenuation (below).
%   "p452_45"  ITU-R P.452-18 section 4.3 eq. (45) at 50 % time, minus free-space
%              loss, wherever ITM itself computes a scatter loss (it returns
%              1001 where it doesn't, and that is kept) and f >= 100 MHz, the
%              lower end of P.452-18's scope; ITM's value below 100 MHz.
%              Path angular distance theta = theta_t + theta_r + d / a_e
%              (P.452-18 Table 4 definition; ITM's horizon angles and
%              effective radius). N_0 is the sea-level refractivity input.
%              Antenna gains aren't in the records: G_t + G_r = 0 dBi.
if nargin < 10
    cfg = struct('troposcatter', "itm");
end
[A_scat, h0] = troposcatter_loss_itm(d_m, theta_hzn, d_hzn_m, h_e_m, a_e, N_s, f_mhz, theta_los, h0);
switch cfg.troposcatter
    case "itm"
    case "p452_45"
        if A_scat < 1000.0 && f_mhz >= 100.0
            theta_mrad = 1e3 * (theta_hzn(1) + theta_hzn(2) + d_m / a_e);
            L_bs = p452_troposcatter_rev1(d_m / 1e3, theta_mrad, f_mhz / 1e3, cfg.N_0_sea, 50, 0);
            A_scat = L_bs - free_space_loss(d_m, f_mhz);
        end
    otherwise
        error('itmexp:cfg', 'Unknown cfg.troposcatter "%s".', cfg.troposcatter);
end
end

function [A_scat, h0] = troposcatter_loss_itm(d_m, theta_hzn, d_hzn_m, h_e_m, a_e, N_s, f_mhz, theta_los, h0)
wn = f_mhz / 47.7;
if h0 > 15.0
    H_0 = h0;
else
    ad = d_hzn_m(1) - d_hzn_m(2);
    rr = h_e_m(2) / h_e_m(1);
    if ad < 0.0
        ad = -ad;
        rr = 1.0 / rr;
    end
    theta = theta_hzn(1) + theta_hzn(2) + d_m / a_e;
    r_1 = 2.0 * wn * theta * h_e_m(1);
    r_2 = 2.0 * wn * theta * h_e_m(2);
    if r_1 < 0.2 && r_2 < 0.2
        A_scat = 1001;     % C++ returns without updating h0
        return
    end
    s = (d_m - ad) / (d_m + ad);
    q = c_min(c_max(0.1, rr / s), 10.0);
    s = c_max(0.1, s);
    h_0_m = (d_m - ad) * (d_m + ad) * theta * 0.25 / d_m;
    Z_0 = 1.7556e3;
    Z_1 = 8.0e3;
    eta_s = (h_0_m / Z_0) * (1.0 + (0.031 - N_s * 2.32e-3 + N_s^2 * 5.67e-6) * ...
        exp(-(c_min(1.7, h_0_m / Z_1))^6));
    H_00 = (h0_function(r_1, eta_s) + h0_function(r_2, eta_s)) / 2;
    Delta_H_0 = c_min(H_00, 6.0 * (0.6 - c_log10(c_max(eta_s, 1.0))) * c_log10(s) * c_log10(q));
    H_0 = H_00 + Delta_H_0;
    H_0 = c_max(H_0, 0.0);
    if eta_s < 1.0
        H_0 = eta_s * H_0 + (1.0 - eta_s) * 10 * c_log10(((1.0 + sqrt(2) / r_1) * (1.0 + sqrt(2) / r_2))^2 * ...
            (r_1 + r_2) / (r_1 + r_2 + 2 * sqrt(2)));
    end
    if H_0 > 15.0 && h0 >= 0.0
        H_0 = h0;
    end
end
h0 = H_0;
th = d_m / a_e - theta_los;
D_0 = 40e3;
H = 47.7;
A_scat = f_function(th * d_m) + 10 * c_log10(wn * H * th^4) - 0.1 * (N_s - 301.0) * exp(-th * d_m / D_0) + H_0;
end

function F_0 = f_function(td)
a = [133.4, 104.6, 71.8];
b = [0.332e-3, 0.212e-3, 0.157e-3];
c = [-10, -2.5, 5];
if td <= 10e3
    i = 1;
elseif td <= 70e3
    i = 2;
else
    i = 3;
end
F_0 = a(i) + b(i) * td + c(i) * c_log10(td);
end

function result = h0_function(r, eta_s)
eta_s = c_min(c_max(eta_s, 1), 5);
i = fix(eta_s);
q = eta_s - i;
result = h0_curve(i, r);
if q ~= 0.0
    result = (1.0 - q) * result + q * h0_curve(i + 1, r);
end
end

function h = h0_curve(j, r)
% j is 1-based (C++ index j - 1)
a = [25.0, 80.0, 177.0, 395.0, 705.0];
b = [24.0, 45.0, 68.0, 80.0, 105.0];
h = 10 * log10(1 + a(j) * (1 / r)^4 + b(j) * (1.0 / r)^2);
end

function v = terrain_roughness(d_m, delta_h_m)
v = delta_h_m * (1.0 - 0.8 * exp(-d_m / 50e3));
end

function v = sigma_h_function(delta_h_m)
v = 0.78 * delta_h_m * exp(-0.5 * delta_h_m^0.25);
end

function A = free_space_loss(d_m, f_mhz)
A = 32.45 + 20.0 * log10(f_mhz) + 20.0 * log10(d_m / 1000.0);
end

%% ------------------------------------------------------------------------
%  Variability (Variability.cpp), vectorized over time and situation
%  ------------------------------------------------------------------------
function [result, extreme] = variability(z, h_e_m, delta_h_m, f_mhz, d_m, A_ref_db, climate, mdvar, cfg)
% Vectorized over the deviates in z (see itm_percentiles). Scalars stay
% scalars and implicit expansion forms the output, which gives the same
% values as expanding every array to the output size first.
all_year = [ ...
    -9.67,   -0.62,    1.26,   -9.21,   -0.62,   -0.39,      3.15; ...
    12.7,     9.19,   15.5,     9.05,    9.19,    2.86,   857.9; ...
    144.9e3, 228.9e3, 262.6e3,  84.1e3, 228.9e3, 141.7e3, 2222.e3; ...
    190.3e3, 205.2e3, 185.2e3, 101.1e3, 205.2e3, 315.9e3,  164.8e3; ...
    133.8e3, 143.6e3,  99.8e3,  98.6e3, 143.6e3, 167.4e3,  116.3e3];
bsm1 = [2.13, 2.66, 6.11, 1.98, 2.68, 6.86, 8.51];
bsm2 = [159.5, 7.67, 6.65, 13.11, 7.16, 10.38, 169.8];
xsm1 = [762.2e3, 100.4e3, 138.2e3, 139.1e3, 93.7e3, 187.8e3, 609.8e3];
xsm2 = [123.6e3, 172.5e3, 242.2e3, 132.7e3, 186.8e3, 169.6e3, 119.9e3];
xsm3 = [94.5e3, 136.4e3, 178.6e3, 193.5e3, 133.5e3, 108.9e3, 106.6e3];
bsp1 = [2.11, 6.87, 10.08, 3.68, 4.75, 8.58, 8.43];
bsp2 = [102.3, 15.53, 9.60, 159.3, 8.12, 13.97, 8.19];
xsp1 = [636.9e3, 138.7e3, 165.3e3, 464.4e3, 93.2e3, 216.0e3, 136.2e3];
xsp2 = [134.8e3, 143.7e3, 225.7e3, 93.1e3, 135.9e3, 152.0e3, 188.5e3];
xsp3 = [95.6e3, 98.6e3, 129.7e3, 94.2e3, 113.4e3, 122.7e3, 122.9e3];
C_D = [1.224, 0.801, 1.380, 1.000, 1.224, 1.518, 1.518];
z_D = [1.282, 2.161, 1.282, 20.0, 1.282, 1.282, 1.282];
bfm1 = [1.0, 1.0, 1.0, 1.0, 0.92, 1.0, 1.0];
bfm2 = [0.0, 0.0, 0.0, 0.0, 0.25, 0.0, 0.0];
bfm3 = [0.0, 0.0, 0.0, 0.0, 1.77, 0.0, 0.0];
bfp1 = [1.0, 0.93, 1.0, 0.93, 0.93, 1.0, 1.0];
bfp2 = [0.0, 0.31, 0.0, 0.19, 0.31, 0.0, 0.0];
bfp3 = [0.0, 2.00, 0.0, 1.79, 2.00, 0.0, 0.0];
a_9000 = 9000e3;
THIRD = 1.0 / 3.0;

z_T = z.T;
z_S = z.S;
z_L = z.L;

c = climate;
wn = f_mhz / 47.7;
d_ex = sqrt(2 * a_9000 * h_e_m(1)) + sqrt(2 * a_9000 * h_e_m(2)) + (575.7e12 / wn)^THIRD;
if d_m < d_ex
    d_e = 130e3 * d_m / d_ex;
else
    d_e = 130e3 + d_m - d_ex;
end

mdvar_internal = mdvar;
plus20 = mdvar_internal >= 20;
if plus20
    mdvar_internal = mdvar_internal - 20;
    sigma_S = 0.0;
else
    sigma_S = 5.0 + 3.0 * exp(-d_e / 100e3);
end
plus10 = mdvar_internal >= 10;
if plus10
    mdvar_internal = mdvar_internal - 10;
end

V_med = curve(all_year(1, c), all_year(2, c), all_year(3, c), all_year(4, c), all_year(5, c), d_e);

switch mdvar_internal
    case 0                       % single message
        z_T = z_S;
        z_L = z_S;
    case 1                       % accidental
        z_L = z_S;
    case 2                       % mobile
        z_L = z_T;
end
if nargout > 1
    extreme = abs(z_T) > 3.10 | abs(z_L) > 3.10 | abs(z_S) > 3.10;
end

if plus10
    sigma_L = 0.0;
else
    delta_h_d = terrain_roughness(d_m, delta_h_m);
    sigma_L = 10.0 * wn * delta_h_d / (wn * delta_h_d + 13.0);
end
Y_L = sigma_L * z_L;

q = log(0.133 * wn);
g_minus = bfm1(c) + bfm2(c) / ((bfm3(c) * q)^2 + 1.0);
g_plus = bfp1(c) + bfp2(c) / ((bfp3(c) * q)^2 + 1.0);
sigma_T_minus = curve(bsm1(c), bsm2(c), xsm1(c), xsm2(c), xsm3(c), d_e) * g_minus * cfg.cal.time_minus_scale;  % ITM: 1
sigma_T_plus = curve(bsp1(c), bsp2(c), xsp1(c), xsp2(c), xsp3(c), d_e) * g_plus * cfg.cal.time_plus_scale;     % ITM: 1
sigma_TD = C_D(c) * sigma_T_plus;
tgtd = (sigma_T_plus - sigma_TD) * z_D(c);

% Three-way selection without logical-index assignment (single-threaded
% and slow on large arrays). The masks are 0 or 1 and disjoint, x*1 and
% x*0 are exact, and adding exact zeros changes nothing, so each element
% equals the C++ branch it falls in, bit for bit. The upper branch divides
% by max(z_T, z_D), which equals z_T where that branch is selected and
% avoids Inf*0 = NaN at z_T = 0 (reliability 50) elsewhere.
lower = z_T < 0.0;
upper = z_T > z_D(c);
middle = ~(lower | upper);
sigma_T = sigma_T_minus .* lower + sigma_T_plus .* middle + ...
    (sigma_TD + tgtd ./ max(z_T, z_D(c))) .* upper;
Y_T = sigma_T .* z_T;
if isfield(cfg, 'leg') && cfg.leg.w > 0 && any(z_T(:) ~= 0)
    % Research package H03 (batch B12): two legs over a common crest, each
    % with ITM's own time curve at its effective distance (NBS TN 101
    % section 10.8, independent legs), convolved and centred at its own
    % median, blended with the stock deviate by the clearance taper w.
    % Y_T(0) = 0, so every 50 % value is unchanged.
    Ydev = @(Z, d_e_j) (curve(bsm1(c), bsm2(c), xsm1(c), xsm2(c), xsm3(c), d_e_j) * g_minus * cfg.cal.time_minus_scale .* (Z < 0) + ...
        curve(bsp1(c), bsp2(c), xsp1(c), xsp2(c), xsp3(c), d_e_j) * g_plus * cfg.cal.time_plus_scale .* (Z >= 0 & Z <= z_D(c)) + ...
        (C_D(c) * curve(bsp1(c), bsp2(c), xsp1(c), xsp2(c), xsp3(c), d_e_j) * g_plus * cfg.cal.time_plus_scale + ...
        (1 - C_D(c)) * curve(bsp1(c), bsp2(c), xsp1(c), xsp2(c), xsp3(c), d_e_j) * g_plus * cfg.cal.time_plus_scale * z_D(c) ./ max(Z, z_D(c))) .* (Z > z_D(c))) .* Z;
    de = zeros(1, 2);
    for j = 1:2
        dexj = sqrt(2 * a_9000 * cfg.leg.he(j, 1)) + sqrt(2 * a_9000 * cfg.leg.he(j, 2)) + (575.7e12 / wn)^THIRD;
        if cfg.leg.len(j) < dexj
            de(j) = 130e3 * cfg.leg.len(j) / dexj;
        else
            de(j) = 130e3 + cfg.leg.len(j) - dexj;
        end
    end
    Yc = two_leg_quantiles_rev1([z_T(:); 0], @(Z) Ydev(Z, de(1)), @(Z) Ydev(Z, de(2)));
    Yc = reshape(Yc(1:end - 1), size(z_T)) - Yc(end);
    Y_T = (1 - cfg.leg.w) * Y_T + cfg.leg.w * Yc;
end

Y_S_temp = sigma_S^2 + Y_T.^2 ./ (7.8 + z_S.^2) + Y_L.^2 ./ (24.0 + z_S.^2);
switch mdvar_internal
    case 0
        Y_R = zeros(size(z_T));
        Y_S = sqrt(sigma_T.^2 + sigma_L^2 + Y_S_temp) .* z_S;
    case 1
        Y_R = Y_T;
        Y_S = sqrt(sigma_L^2 + Y_S_temp) .* z_S;
    case 2
        Y_R = sqrt(sigma_T.^2 + sigma_L^2) .* z_T;
        Y_S = sqrt(Y_S_temp) .* z_S;
    otherwise                    % broadcast
        Y_R = Y_T + Y_L;
        Y_S = sqrt(Y_S_temp) .* z_S;
end

result = A_ref_db - V_med - Y_R - Y_S;
neg = result < 0.0;
result(neg) = result(neg) .* (29.0 - result(neg)) ./ (29.0 - 10.0 * result(neg));
end

function v = curve(c1, c2, x1, x2, x3, d_e)
v = (c1 + c2 / (1.0 + ((d_e - x2) / x3)^2)) * ((d_e / x1)^2) / (1.0 + ((d_e / x1)^2));
end

%% ------------------------------------------------------------------------
%  C arithmetic. The NTIA C++ gives NaN where MATLAB would give a complex
%  number (sqrt, log10, or a fractional power of a negative number), and
%  its MAX and MIN macros keep a NaN in the second argument. These helpers
%  reproduce both, so out-of-domain inputs give the same answer as the C++.
%  ------------------------------------------------------------------------
function y = c_max(a, b)
% C macro MAX(a, b): a > b ? a : b
if a > b, y = a; else, y = b; end
end

function y = c_min(a, b)
% C macro MIN(a, b): a < b ? a : b
if a < b, y = a; else, y = b; end
end

function y = c_sqrt(x)
y = sqrt(abs(x));
y(x < 0) = NaN;
end

function y = c_log10(x)
y = log10(abs(x));
y(x < 0) = NaN;
end

function y = c_pow(x, p)
% C pow(x, p) for non-integer p
y = abs(x) .^ p;
y(x < 0) = NaN;
end


function [mobile_end, h_mobile_m, ctype] = clutter_terminal(cfg, area, h_m)
%CLUTTER_TERMINAL Which end is a Phase 2 mobile terminal in clutter (0 = none), and its P.2108 category.
%   The mobile terminal is the transmitter (end 1) in sets R1, R2, R3 and
%   the receiver (end 2) in VA; cfg.row.reversed swaps it. Siting "C" gets
%   cfg.terminal_clutter_type (B07). With cfg.terminal_clutter_open =
%   "nlcd" (B11), sitings "O" and "A" get the category of the NLCD 2001
%   class at the mobile terminal (landcover_lookup_rev1), or none;
%   "nlcd_forest" uses forest classes only (B11, 712). Fails
%   loud when the row metadata is missing.
mobile_end = 0;
h_mobile_m = NaN;
ctype = "";
if ~isfield(cfg, 'terminal_clutter') || cfg.terminal_clutter == "none"
    return
end
if area
    error('itmexp:cfg', 'Terminal clutter needs a terrain profile; area mode has none.');
end
if ~isfield(cfg, 'row')
    error('itmexp:cfg', ['Terminal clutter needs the row metadata cfg.row from the evaluator. ' ...
        'Without it every row would silently get 0.']);
end
if ~any(cfg.terminal_clutter_base == ["actual", "clutter_height"])
    error('itmexp:cfg', 'Unknown cfg.terminal_clutter_base "%s".', cfg.terminal_clutter_base);
end
if ~any(cfg.terminal_clutter_open == ["none", "nlcd", "nlcd_forest"])
    error('itmexp:cfg', 'Unknown cfg.terminal_clutter_open "%s".', cfg.terminal_clutter_open);
end
if cfg.row.set == ""
    return                                   % long-term rows and synthetic sweeps: no mobile terminal
end
if cfg.row.set == "VA", orig_end = 2; else, orig_end = 1; end
if cfg.row.siting == "C"
    ctype = cfg.terminal_clutter_type;
elseif startsWith(cfg.terminal_clutter_open, "nlcd") && any(cfg.row.siting == ["O", "A"])
    if ~isfield(cfg.row, 'path_id') || strlength(cfg.row.path_id) == 0
        error('itmexp:cfg', 'cfg.terminal_clutter_open = "nlcd" needs cfg.row.path_id from the evaluator.');
    end
    names = ["tx", "rx"];
    if cfg.terminal_clutter_open == "nlcd_forest", mp = "forest"; else, mp = "all"; end
    [~, ctype] = landcover_lookup_rev1(cfg.row.path_id, names(orig_end), mp);
    if cfg.terminal_clutter ~= "p2108_height_gain"
        error('itmexp:cfg', 'cfg.terminal_clutter_open = "nlcd" works only with cfg.terminal_clutter = "p2108_height_gain".');
    end
end
if strlength(ctype) > 0
    mobile_end = orig_end;
    if cfg.row.reversed, mobile_end = 3 - mobile_end; end
    h_mobile_m = h_m(mobile_end);
end
end


function leg = two_leg_geometry(pfl, h_m, a_e, f_mhz)
%TWO_LEG_GEOMETRY Common-crest legs for the two-leg time variability (research package H03; B12).
%   leg.w is 0 unless both terminals' raw radio horizons (highest
%   elevation angle on the effective Earth, as ITM's FindHorizons, before
%   any smooth-earth replacement) are the same interior profile sample.
%   Then: taper w = u+^2 / (1 + u+^2), u the smallest clearance, in
%   first-Fresnel radii of each leg, of any leg sample below the ray from
%   the terminal to the crest (Earth bulge in the chord frame), and of the
%   bare crest above the terminal chord over the full-link radius at the
%   crest; leg lengths; and leg effective heights h_s + max(0, z_end -
%   z_fit) from a least-squares line on each leg's bare terrain, with the
%   physical antenna height at the outer terminal and 0 at the crest.
%   All as specified in the research package's H03 proposal.
leg = struct('w', 0, 'he', zeros(2, 2), 'len', zeros(1, 2));
np = fix(pfl(1)); xi = pfl(2);
if np < 3, return, end
g = pfl(3:np + 3); x = (0:np)' * xi; D = x(end);
zt = g(1) + h_m(1); zr = g(end) + h_m(2);
k = (2:np)';
[~, it] = max((g(k) - zt) ./ x(k) - x(k) / (2 * a_e));
[~, ir] = max((g(k) - zr) ./ (D - x(k)) - (D - x(k)) / (2 * a_e));
it = k(it); ir = k(ir);
if it ~= ir, return, end
ic = it; xc = x(ic);
% the crest must obstruct both terminals' straight ray (it is a horizon)
th_los = (zr - zt) / D - D / (2 * a_e);
if (g(ic) - zt) / xc - xc / (2 * a_e) <= th_los, return, end
lambda = 299.792458 / f_mhz;
zs = g + x .* (D - x) / (2 * a_e);                       % chord frame, Earth bulge added
u = Inf;
legs = {1:ic, ic:np + 1};
ends = [zt, zs(ic); zs(ic), zr];
for j = 1:2
    ii = legs{j}; xa = x(ii(1)); xb = x(ii(end)); L = xb - xa;
    in = ii(2:end - 1);
    if isempty(in), continue, end
    t = x(in) - xa;
    ray = ends(j, 1) + (ends(j, 2) - ends(j, 1)) * t / L;
    r1 = sqrt(lambda * t .* (L - t) / L);
    u = min(u, min((ray - zs(in)) ./ r1));
end
hc = g(ic) - (zt * (D - xc) + zr * xc) / D;
u = min(u, hc / sqrt(lambda * xc * (D - xc) / D));
up = max(0, u);
leg.w = up^2 / (1 + up^2);
leg.len = [xc, D - xc];
hs = [h_m(1), 0; 0, h_m(2)];
for j = 1:2
    ii = legs{j};
    pfit = polyfit(x(ii), g(ii), 1);
    z0 = polyval(pfit, x(ii(1))); z1 = polyval(pfit, x(ii(end)));
    leg.he(j, :) = hs(j, :) + [max(0, g(ii(1)) - z0), max(0, g(ii(end)) - z1)];
end
end

function check_placeholder_switches(cfg)
% Switches listed in params_exp.m that the core doesn't implement yet. A value
% other than the stock one would be a silent no-op, so fail loud instead
% (found by the Claude Science headroom pass, 2026-11-23).
stock = struct('effective_height', "itm", 'effective_height_alpha', 1, 'variability', "itm");
for f = string(fieldnames(stock))'
    if isfield(cfg, f) && ~isequal(cfg.(f), stock.(f))
        error('itmexp:cfg', ['cfg.%s isn''t implemented in itm_p2p_core_exp; only its ' ...
            'stock value is allowed.'], f);
    end
end
end
