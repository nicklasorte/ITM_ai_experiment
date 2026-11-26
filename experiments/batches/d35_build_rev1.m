function T = d35_build_rev1(root, options)
%D35_BUILD_REV1 B35 steps 1 to 3: keys and model predictions for ITS Phase 2 site R4 (no measured value is read).
%   T = D35_BUILD_REV1(root) reads the keys of phase_2/r4data.txt (path,
%   season and receiver height only), r4path.txt and r4pars.txt from
%   data/raw/its_phase2.zip, checks the counts B35.md section 5 step 1
%   lists, builds one terrain profile per path with itm_terrain_profile_rev1
%   (30 m, default source, transmitter first), and predicts the 50 %
%   attenuation relative to free space for every path, frequency and
%   receiver height 1 to 24 m with four arms: stock ITM, 707-O, 707-C and a
%   parity arm (itm_p2p_core_exp at params_exp() defaults). Writes
%   experiments/D35-r4-grove/predictions_rev1.csv and paths_rev1.csv.
%
%   T = D35_BUILD_REV1(root, Smoke=true) runs path R4-003-T1 only, checks
%   parity and the 707-C/707-O relation, and writes nothing.
%
%   The six attenuation columns of r4data.txt are never parsed. Prints
%   counts only. Fails loud. See experiments/batches/B35.md.
arguments
    root (1,1) string
    options.Smoke (1,1) logical = false
end
itm_exp_paths_rev1();
S = settings_rev1();
tmp = fullfile(tempdir, 'd35_r4');
if isfolder(tmp), rmdir(tmp, 's'); end
mkdir(tmp);
unzip(fullfile(root, 'data', 'raw', 'its_phase2.zip'), tmp);
base = fullfile(tmp, 'phase_2');
cleaner = onCleanup(@() rmdir(tmp, 's'));

% ---- Step 1: keys only
lines = readlines(fullfile(base, 'r4data.txt'), 'EmptyLineRule', 'skip');
lines = strtrim(lines(2:end));
lines = lines(~startsWith(lines, "-"));
tok = split(lines);                                   % n x 9 string array
if size(tok, 2) ~= 9
    error('itmexp:d35', 'r4data.txt lines don''t all have nine fields.');
end
kpath = tok(:, 1); kseason = tok(:, 2); kh = double(tok(:, 3));
tok = []; lines = []; %#ok<NASGU>  the attenuation fields are dropped unparsed
P = readtable(fullfile(base, 'r4path.txt'), 'FileType', 'text', 'TextType', 'string');
pars = readmatrix(fullfile(base, 'r4pars.txt'), 'NumHeaderLines', 1, 'FileType', 'text');
upath = unique(kpath, 'stable');
checks = [numel(kpath) == 1728, numel(upath) == 36, height(P) == 36, isempty(setxor(upath, P.Path)), ...
    nnz(kseason == "S") == 864, nnz(kseason == "W") == 864, ...
    all(histcounts(kh, 0.5:1:24.5) == 72), size(pars, 1) == 7, isequal(pars(6, :), pars(7, :))];
names = ["1728 lines", "36 data paths", "36 path rows", "same path names", "864 S", "864 W", ...
    "72 per height 1-24", "7 pars rows", "9190 rows equal"];
if ~all(checks)
    error('itmexp:d35', 'Step 1 failed: %s.', strjoin(names(~checks), ', '));
end
fprintf('Step 1: %s: all pass\n', strjoin(names, ', '));
F = pars(1:6, 1)'; htx = pars(1:6, 2)';
if ~isequal(F, [230 410 910 1846 4595 9190])
    error('itmexp:d35', 'Unexpected frequencies in r4pars.txt.');
end

% ---- Paths
if options.Smoke
    P = P(P.Path == "R4-003-T1", :);
end
np_ = height(P);
[pfls, pinfo] = itm_terrain_profile_rev1(P.Xlat, P.Xlon, P.Rlat, P.Rlon, spacing_m=S.profile_spacing_m);
if ~iscell(pfls), pfls = {pfls}; end
dprof = zeros(np_, 1); clim = zeros(np_, 1); n0 = zeros(np_, 1);
for j = 1:np_
    pf = pfls{j};
    if any(~isfinite(pf)), error('itmexp:d35', 'Profile %s has non-finite elevations.', P.Path(j)); end
    dprof(j) = pf(1) * pf(2) / 1000;
    mid = pinfo(j).midpoint_deg;
    clim(j) = itm_radio_climate_rev1(mid(1), mid(2));        % as data/build_links_rev1.m lines 137 to 139
    if clim(j) == 7
        clim(j) = min(itm_radio_climate_rev1(P.Xlat(j), P.Xlon(j)), itm_radio_climate_rev1(P.Rlat(j), P.Rlon(j)));
    end
    n0(j) = itm_surface_refractivity_rev1(mid(1), mid(2));
end
rel = abs(dprof - P.Dist) ./ P.Dist;
if any(rel > 0.02)
    k = find(rel > 0.02, 1);
    error('itmexp:d35', 'Profile %s is %.3f km against %.3f km in r4path.txt (%.1f %%).', P.Path(k), dprof(k), P.Dist(k), 100 * rel(k));
end
fprintf('Step 3 length check: largest difference %.2f %% (limit 2 %%)\n', 100 * max(rel));

% ---- Configurations
setenv('ITMEXP_OVERRIDES', ''); cfg0 = params_exp();
ov = '{"diffraction":"delta_cascaded_isolated","diffraction_bound":"itm_troposcatter_line","terminal_clutter":"p2108_height_gain","terminal_clutter_base":"clutter_height","terminal_clutter_frange":"hold3"}';
setenv('ITMEXP_OVERRIDES', ov); cfg7 = params_exp(); setenv('ITMEXP_OVERRIDES', '');
want = struct('diffraction', "delta_cascaded_isolated", 'diffraction_bound', "itm_troposcatter_line", ...
    'terminal_clutter', "p2108_height_gain", 'terminal_clutter_base', "clutter_height", ...
    'terminal_clutter_frange', "hold3", 'terminal_clutter_type', "trees_forest", 'path_vegetation', "none");
for f = string(fieldnames(want))'
    if cfg7.(f) ~= want.(f)
        error('itmexp:d35', 'params_exp().%s is "%s", expected "%s" for 707.', f, cfg7.(f), want.(f));
    end
end
pol = 0;                                                     % horizontal (OT/TRER 19 section 2)

% ---- Predictions
hs = 1:24;
n = np_ * numel(F) * numel(hs);
rows = struct('path', strings(n, 1), 'f_mhz', zeros(n, 1), 'rx_ant_m', zeros(n, 1), 'htx_m', zeros(n, 1), ...
    'd_km', zeros(n, 1), 'profile_km', zeros(n, 1), 'climate', zeros(n, 1), 'N_0', zeros(n, 1));
A = NaN(n, 4); mode7 = NaN(n, 1);
r = 0;
for j = 1:np_
    pf = pfls{j};
    lfs = 32.45 + 20 * log10(F) + 20 * log10(P.Dist(j));      % as data/build_links_rev1.m line 172
    for fi = 1:numel(F)
        for h = hs
            r = r + 1;
            rows.path(r) = P.Path(j); rows.f_mhz(r) = F(fi); rows.rx_ant_m(r) = h; rows.htx_m(r) = htx(fi);
            rows.d_km(r) = P.Dist(j); rows.profile_km(r) = dprof(j); rows.climate(r) = clim(j); rows.N_0(r) = n0(j);
            args = {htx(fi), h, pf, F(fi), 50, S.confidence, S.location, clim(j), n0(j), pol, S.epsilon, S.sigma, S.mdvar, false, []};
            Ls = itm_p2p_rev1(htx(fi), h, pf, F(fi), 50, confidence=S.confidence, climate=clim(j), N_0=n0(j), ...
                polarization=pol, epsilon=S.epsilon, sigma=S.sigma, mdvar=S.mdvar, validity="off");
            c = cfg7; c.row = struct('set', "R4", 'siting', "O", 'reversed', false, 'path_id', P.Path(j));
            [L7o, ~, ~, ~, mc] = itm_p2p_core_exp(args{:}, c);
            c.row = struct('set', "R4", 'siting', "C", 'reversed', true, 'path_id', P.Path(j));
            L7c = itm_p2p_core_exp(args{:}, c);
            c0 = cfg0; c0.row = struct('set', "R4", 'siting', "O", 'reversed', false, 'path_id', P.Path(j));
            L0 = itm_p2p_core_exp(args{:}, c0);
            A(r, :) = [Ls L7o L7c L0] - lfs(fi);
            mode7(r) = mc;
        end
    end
end
if any(~isfinite(A(:))) || ~isreal(A)
    error('itmexp:d35', 'Non-finite or complex loss.');
end
par = max(abs(A(:, 4) - A(:, 1)));
if par > 1e-9
    error('itmexp:d35', 'Parity failed: core at defaults differs from stock ITM by %.3g dB.', par);
end
fprintf('Parity: largest difference %.2g dB on %d rows\n', par, n);
hi = rows.rx_ant_m >= 15;
dhi = max(abs(A(hi, 3) - A(hi, 2)));
lo230 = rows.rx_ant_m < 15 & rows.f_mhz == 230;
dlo = min(abs(A(lo230, 3) - A(lo230, 2)));
if dhi > 1e-9 || ~(dlo > 0.01)
    error('itmexp:d35', '707-C/707-O check failed: max difference at 15 m and above %.3g dB; min below 15 m at 230 MHz %.3g dB.', dhi, dlo);
end
fprintf('707-C equals 707-O at 15 m and above (max %.2g dB); differs below 15 m at 230 MHz (min %.2f dB)\n', dhi, dlo);
T = struct2table(rows);
T.A_stock_db = A(:, 1); T.A_707O_db = A(:, 2); T.A_707C_db = A(:, 3); T.A_parity_db = A(:, 4); T.mode_707O = mode7;
fprintf('Modes (707-O): line of sight %d, single horizon %d, double horizon %d, of %d rows\n', ...
    nnz(mode7 < 4), nnz(mode7 >= 4 & mode7 < 8), nnz(mode7 >= 8), n);
if options.Smoke
    return
end
out = fullfile(root, 'experiments', 'D35-r4-grove');
if ~isfolder(out), mkdir(out); end
writetable(T, fullfile(out, 'predictions_rev1.csv'));
Pt = P(:, {'Path', 'Xlat', 'Xlon', 'Rlat', 'Rlon', 'Dist'});
Pt.profile_km = dprof; Pt.climate = clim; Pt.N_0 = n0;
Pt.n_points = cellfun(@(p) p(1) + 1, pfls(:)); Pt.spacing_m = cellfun(@(p) p(2), pfls(:));
writetable(Pt, fullfile(out, 'paths_rev1.csv'));
fprintf('Wrote %s (%d rows)\n', out, n);
end
