function out = pe2d_rev1(f_mhz, h_tx_m, pfl, gamma_e, h_rx_m, opts)
%PE2D_REV1 2D split-step Fourier parabolic-equation reference for one terrain profile (diagnostic, not a model candidate).
%   out = PE2D_REV1(f_mhz, h_tx_m, pfl, gamma_e, h_rx_m) marches the
%   narrow-angle parabolic wave equation from the transmitter (start of
%   the ITM profile pfl = [np; xi; z_0 ... z_np]) to the receiver and
%   returns the attenuation relative to free space at the receiver heights
%   h_rx_m (m above the terrain at the end of the profile).
%
%   Formulation (public source: F. J. Ryan, "Analysis of electromagnetic
%   propagation over variable terrain using the parabolic wave equation",
%   NOSC Technical Report 1453, October 1991, approved for public release):
%     - reduced field u(x, z); split-step marching (Ryan eq. (98)) with the
%       free-space propagator applied in the vertical-wavenumber domain,
%       exp(-i p^2 dx / (2k)) (Ryan eq. (110), narrow-angle operator);
%     - refraction and earth curvature through the modified refractive
%       index (Ryan eq. (32)), here m - 1 = gamma_e z with ITM's effective
%       curvature gamma_e, so the PE sees the same earth as ITM;
%     - a perfectly conducting ground for horizontal polarization: the
%       field is odd about the ground (Ryan section 3.4, sine transform),
%       done here with an FFT over the odd extension;
%     - terrain (default "shift"): terrain-following coordinates
%       z' = z - t(x) (Ryan's surface-locked coordinates, eq. (71)-(77);
%       the linear shift map used in TPEM). With u = v exp(i k t' z' +
%       i k/2 int t'^2 dx), v obeys the flat-ground PE plus a term
%       -2 t'' z' in n^2 - 1 (derived from the narrow-angle PE; it matches
%       the t'' term in Ryan's eq. (77)). On the piecewise-linear profile
%       t'' is a sum of delta functions, so v is multiplied by
%       exp(-i k (s_new - s_old) z') at each profile sample, where the
%       slope changes from s_old to s_new, and the ground is exactly at
%       z' = 0. Valid for small slopes (narrow-angle PE); B36 uses it only
%       on profiles whose steepest interval is 10 degrees or less.
%       Terrain="staircase" instead zeroes the field below the terrain at
%       every step (the knife-edge-per-range method, Dockery et al., JHU
%       APL Tech. Dig. 19(3), 1998). In this code the staircase reflects
%       only where the terrain is at the grid bottom; elsewhere it absorbs,
%       and its loss grows as the range step shrinks (B36 section 6), so it
%       is kept for comparison only;
%     - an absorbing layer at the top of the domain (Ryan section 3.5 adds
%       an absorbing potential to the split-step operator; this code uses
%       an attenuation rate per meter of range that rises as the square of
%       depth into the layer, so its effect doesn't depend on the range
%       step; the rate and the layer size are planner choices checked by
%       pe2d_tests_rev1);
%     - propagation factor F = E / E_free (Ryan eq. (42)), so basic
%       transmission loss is L = L_fs - 20 log10 |F| (Ryan eq. (43)-(44)).
%       Here F is the field divided by a free-space run of the same source
%       on the same grid, evaluated along the direct ray, so the source
%       normalization and its pattern cancel.
%
%   Inputs:
%     f_mhz    frequency (MHz)
%     h_tx_m   transmitter height above the terrain at the profile start (m)
%     pfl      ITM profile [np; xi_m; z_0; ...; z_np] (m)
%     gamma_e  effective earth curvature (1/m), as ITM computes it
%     h_rx_m   receiver heights above the terrain at the profile end (m)
%   Options (name-value):
%     Ground       "pec" (default); the free-space reference is computed internally
%     DzLambda     vertical step in wavelengths (0.25)
%     DxMax        largest range step (m) (min(xi, 30))
%     ThetaBeam    elevation angle (deg) at which the source pattern is
%                  3 dB down (20)
%     Margin       free height above the highest terrain or antenna (m)
%                  (max(1000, 3 sqrt(lambda d), 0.25 gamma_e d^2))
%     AbsorbFrac   absorber thickness as a fraction of the domain (0.5)
%     AbsorbRate   attenuation rate at the top of the grid (nepers per m of
%                  range) (2e-2)
%     WindowLambda range window for power averaging at the receiver, in
%                  wavelengths (20); 0 gives the point value
%     Knife        [x_m, top_m] for a single knife edge (tests only)
%     FlatZ        true: ignore pfl elevations (flat ground; tests)
%     Terrain      "shift" (default) or "staircase"
%     Propagator   "narrow" (default; Ryan eq. (110)) or "wide": the exact
%                  one-way free-space propagator exp(i dx (sqrt(k^2 - p^2) -
%                  k)), evanescent above p = k (the wide-angle operator Ryan
%                  gives after eq. (110))
%   Output struct: A_db (attenuation relative to free space at each
%   h_rx_m), A_point_db (point value at the end), F (complex, end), grid
%   and step sizes.
%
%   Fails loud on bad inputs or a non-finite field.
arguments
    f_mhz (1,1) double {mustBePositive}
    h_tx_m (1,1) double {mustBePositive}
    pfl (:,1) double
    gamma_e (1,1) double {mustBeNonnegative}
    h_rx_m (1,:) double {mustBePositive}
    opts.Ground (1,1) string {mustBeMember(opts.Ground, "pec")} = "pec"
    opts.DzLambda (1,1) double {mustBePositive} = 0.25
    opts.DxMax (1,1) double = NaN
    opts.ThetaBeam (1,1) double {mustBePositive} = 20
    opts.Margin (1,1) double = NaN
    opts.AbsorbFrac (1,1) double = 0.5
    opts.AbsorbRate (1,1) double {mustBePositive} = 2e-2
    opts.WindowLambda (1,1) double {mustBeNonnegative} = 20
    opts.Knife (1,:) double = []
    opts.FlatZ (1,1) logical = false
    opts.Terrain (1,1) string {mustBeMember(opts.Terrain, ["shift" "staircase"])} = "shift"
    opts.Propagator (1,1) string {mustBeMember(opts.Propagator, ["narrow" "wide"])} = "narrow"
end
np = pfl(1); xi = pfl(2);
if np < 2 || np ~= fix(np) || numel(pfl) ~= np + 3 || xi <= 0
    error('itmexp:pe2d', 'Malformed profile.');
end
lambda = 299.792458 / f_mhz;
k = 2 * pi / lambda;
d = np * xi;
xg = (0:np)' * xi;
zt = pfl(3:end);
if opts.FlatZ, zt = zeros(size(zt)); end
zb = min(zt);                                   % ground datum: lowest terrain point
zt = zt - zb;
shift = opts.Terrain == "shift";
slope = diff(zt) / xi;                          % slope of each profile interval
dslope = max(abs(diff(slope)));
if shift && ~isempty(dslope) && dslope > 1 / (4 * opts.DzLambda)
    % the slope-change phase shifts the vertical spectrum by k*dslope; keep
    % it within half the grid's Nyquist wavenumber k/(2*DzLambda)
    error('itmexp:pe2d', 'Slope change %.2f too large for DzLambda %.3g (aliasing); use a finer grid.', dslope, opts.DzLambda);
end
z_s = zt(1) + h_tx_m;                           % source height above the datum
z_r = zt(end) + h_rx_m;
margin = opts.Margin;
if isnan(margin), margin = max([1000, 3 * sqrt(lambda * d), 0.25 * gamma_e * d^2]); end
ztop = max([zt; z_s; z_r(:)]) + margin;         % top of the physical region
H = ztop / (1 - opts.AbsorbFrac);               % domain height including the absorber
dz = opts.DzLambda * lambda;
N = ceil(H / dz);
dxmax = opts.DxMax;
if isnan(dxmax), dxmax = min(xi, 30); end
nsub = ceil(xi / dxmax);                        % steps per profile interval, so knots fall on steps
nstep = np * nsub;
dx = xi / nsub;

z = (1:N)' * dz;                                % interior points; u(0) = 0 at the ground
M = 2 * (N + 1);                                % odd extension length
p = 2 * pi / (M * dz) * [0:M/2, -M/2+1:-1]';
prop = propagator(p, k, dx, opts.Propagator);
% Absorber: rate rising with the square of depth over the top AbsorbFrac of the domain
w = absorber(z, ztop, opts.AbsorbRate, dx);
% Source: Gaussian aperture with its pattern 3 dB down at ThetaBeam
% (angular spectrum exp(-p^2 W^2 / 4); 3 dB in power at p = k sin(theta)).
W = 2 * sqrt(log(2) / 2) / (k * sind(opts.ThetaBeam));
% The staircase ground at a range is the highest grid point below the
% terrain (the field is zero there); antenna heights are measured from it.
if shift
    zg0 = 0;                                    % terrain-following: the ground is z' = 0
else
    zg0 = ground_level(z, zt(1));
end
z_s = zg0 + h_tx_m;
u = exp(-((z - z_s) / W).^2) - exp(-((z - (2 * zg0 - z_s)) / W).^2);   % source and its image in the local ground
u(z <= zg0) = 0;
if shift
    u = u .* exp(-1i * k * slope(1) * z);       % u = v exp(i k t'(0) z') at the start
end
refr = exp(1i * k * dx * gamma_e * z);          % modified refractive index m - 1 = gamma_e z (Ryan eq. (32))
nwin = max(1, round(opts.WindowLambda * lambda / dx));
nwin = min(nwin, nstep);
u_rx = zeros(nwin, numel(h_rx_m));
x_rx = zeros(nwin, 1);
for s = 1:nstep
    x = s * dx;
    v = [0; u; 0; -flipud(u)];
    v = ifft(prop .* fft(v));
    u = v(2:N+1) .* refr .* w;
    if shift
        if mod(s, nsub) == 0 && s < nstep       % profile sample: slope changes
            j = s / nsub;
            u = u .* exp(-1i * k * (slope(j + 1) - slope(j)) * z);
        end
    elseif ~opts.FlatZ
        tz = interp1(xg, zt, x, 'linear');      % staircase terrain (perfect conductor)
        u(z < tz) = 0;
    end
    if ~isempty(opts.Knife) && abs(x - opts.Knife(1)) < dx / 2
        u(z < opts.Knife(2) - zb) = 0;
    end
    if s > nstep - nwin
        j = s - (nstep - nwin);
        if shift
            zr = h_rx_m;                        % heights above the terrain are z' directly
        else
            zr = ground_level(z, interp1(xg, zt, x, 'linear')) + h_rx_m;   % above the staircase ground
        end
        u_rx(j, :) = interp1(z, u, zr, 'linear', 0);
        x_rx(j) = x;
    end
end
if any(~isfinite(u))
    error('itmexp:pe2d', 'Non-finite field.');
end
% Free-space reference: the same source, grid and steps, no ground, no
% terrain, no refraction, evaluated along the straight line from the source
% to each receiver (so the source pattern at the receiver's elevation angle
% cancels in F).
rise = (zt(end) + h_rx_m) - (zt(1) + h_tx_m);      % true elevation rise of each direct ray
uf = free_space_rays(k, dz, dx, nstep, nwin, W, rise, x_rx, margin, opts.AbsorbFrac, opts.AbsorbRate, d, opts.Propagator);
F = u_rx ./ uf;
out = struct('dz', dz, 'dx', dx, 'N', N, 'nstep', nstep, 'H', H, 'nwin', nwin, ...
    'max_slope_deg', atand(max([0; abs(slope)])));
out.F = F(end, :);
out.A_point_db = -20 * log10(abs(F(end, :)));
out.A_db = -10 * log10(mean(abs(F).^2, 1));
if any(~isfinite(out.A_db))
    error('itmexp:pe2d', 'Non-finite attenuation (field null or free-space reference zero).');
end
end

function P = propagator(p, k, dx, kind)
% One range step of free-space propagation in the vertical-wavenumber domain.
if kind == "narrow"
    P = exp(-1i * p.^2 * dx / (2 * k));
else
    kz = sqrt(complex(k^2 - p.^2));             % imaginary above p = k: evanescent decay
    P = exp(1i * dx * (kz - k));
    P(abs(p) > k) = exp(-dx * sqrt(p(abs(p) > k).^2 - k^2) - 1i * dx * k);
end
end

function zg = ground_level(z, tz)
% Highest grid point strictly below the terrain height tz (0 if none): the
% Dirichlet boundary the staircase imposes.
i = find(z < tz, 1, 'last');
if isempty(i), zg = 0; else, zg = z(i); end
end

function w = absorber(z, za, rate, dx)
% Per-step factor exp(-dx * rate * s^2), s the fractional depth into the layer above za.
s = max(0, (z - za) / (max(z) - za));
w = exp(-dx * rate * s.^2);
end

function uf = free_space_rays(k, dz, dx, nstep, nwin, W, rise, x_rx, margin, absfrac, rate, d, kind)
% Free-space PE run, source at z = 0, symmetric grid with absorbers at both ends.
half = (max(abs(rise)) + margin) / (1 - absfrac);
N = 2 * ceil(half / dz);
z = ((1:N)' - N / 2) * dz;
p = 2 * pi / (N * dz) * [0:N/2, -N/2+1:-1]';
prop = propagator(p, k, dx, kind);
za = half * (1 - absfrac);
s = max(0, (abs(z) - za) / (max(abs(z)) - za));
w = exp(-dx * rate * s.^2);
u = exp(-(z / W).^2);
uf = zeros(nwin, numel(rise));
for s = 1:nstep
    u = ifft(prop .* fft(u)) .* w;
    if s > nstep - nwin
        j = s - (nstep - nwin);
        uf(j, :) = interp1(z, u, rise * x_rx(j) / d, 'linear', 0);
    end
end
end
