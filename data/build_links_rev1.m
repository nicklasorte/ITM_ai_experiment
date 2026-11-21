function build_links_rev1(options)
%BUILD_LINKS_REV1 Build the frozen link tables, profiles, splits, and baseline predictions.
%   BUILD_LINKS_REV1() reads the raw public data in data/raw/ and writes:
%     data/links/phase2_links_rev1.csv     ITS Phase 2 spot measurements (50 % time)
%     data/links/longterm_links_rev1.csv   ITS long-term time distributions
%     data/links/manifest_rev1.json        counts, source hashes, dependency commits, profile hashes
%     data/splits/folds_rev1.csv           fold of every path (dataset, path_id, fold)
%     data/splits/folds_rev1.sha256        hash the evaluator checks before every run
%     data/cache/profiles_rev1.mat         terrain profiles (not committed; rebuilt on demand)
%
%   Every row carries the baseline ITM prediction from the public
%   itm_p2p_rev1 in the pinned matlab_itm, with the inputs in
%   eval/settings_rev1, and (with References=true) P.452 and P.2001 from
%   pathloss_rev1 on the same profile.
%
%   Terrain: Phase 2 uses the surveyed profiles in the data set, resampled
%   linearly to 30 m. The long-term set has no profiles in the public
%   archive, so its profiles come from itm_terrain_profile_rev1 at 30 m with
%   its default source, the same source matlab_itm uses everywhere. Only
%   paths with both ends in the conterminous US are kept (Nick,
%   2026-11-21), so that source is 30 m everywhere. The
%   terrain source is fixed for this project and is never a variable.
%
%   Options:
%     Datasets      ["phase2" "longterm"]
%     References    true    also compute P.452 and P.2001
%     ProfilesOnly  false   rebuild data/cache/profiles_rev1.mat and stop
%     MaxPaths      Inf     for a quick test
%
%   Human-owned. The agent doesn't run or edit this file.

arguments
    options.Datasets (1,:) string = ["phase2" "longterm"]
    options.References (1,1) logical = true
    options.ProfilesOnly (1,1) logical = false
    options.MaxPaths (1,1) double = Inf
end
here = fileparts(mfilename('fullpath'));
addpath(fullfile(fileparts(here), 'eval'));
P = itm_exp_paths_rev1(References=options.References);
S = settings_rev1();
for d = ["links" "splits" "cache"]
    if ~isfolder(fullfile(here, d)), mkdir(fullfile(here, d)); end
end
prof_file = fullfile(here, 'cache', 'profiles_rev1.mat');
if isfile(prof_file)
    C = load(prof_file); profiles = C.profiles;
else
    profiles = struct('path_id', {}, 'dataset', {}, 'd_km', {}, 'h_m', {}, 'spacing_m', {}, 'midpoint_deg', {}, ...
        'tx', {}, 'rx', {}, 'climate', {}, 'N_0', {});
end
man = struct('built', string(datetime('now', 'TimeZone', 'UTC', 'Format', 'yyyy-MM-dd''T''HH:mm:ss''Z''')), ...
    'matlab', string(version), 'matlab_itm_commit', P.itm_head);
man.p452_commit = git_head(P.p452); man.p2001_commit = git_head(P.p2001);
folds = table(strings(0, 1), strings(0, 1), zeros(0, 1), 'VariableNames', {'dataset', 'path_id', 'fold'});
if isfile(fullfile(here, 'splits', 'folds_rev1.csv'))
    folds = readtable(fullfile(here, 'splits', 'folds_rev1.csv'), 'TextType', 'string');
end

if any(options.Datasets == "phase2")
    [T2, pr2, f2] = build_phase2(here, S, options);
    profiles = merge_profiles(profiles, pr2);
    folds = [folds(folds.dataset ~= "phase2", :); f2];
    if ~options.ProfilesOnly
        T2 = add_baseline(T2, profiles, S, false);
        if options.References, T2 = add_references(T2, profiles, S, false); end
        writetable(T2, fullfile(here, 'links', 'phase2_links_rev1.csv'));
    end
    man.phase2 = summarize(T2, pr2, fullfile(here, 'raw', 'its_phase2.zip'));
end
if any(options.Datasets == "longterm")
    [TL, prl, fl, drop] = build_longterm(here, S, options);
    profiles = merge_profiles(profiles, prl);
    folds = [folds(folds.dataset ~= "longterm", :); fl];
    if ~options.ProfilesOnly
        TL = add_baseline(TL, profiles, S, true);
        if options.References, TL = add_references(TL, profiles, S, true); end
        writetable(TL, fullfile(here, 'links', 'longterm_links_rev1.csv'));
        writematrix(drop, fullfile(here, 'links', 'longterm_dropped_rev1.csv'));
    end
    man.longterm = summarize(TL, prl, fullfile(here, 'raw', 'longterm.zip'));
    man.longterm.dropped = height(drop);
end

save(prof_file, 'profiles', '-v7.3');
if ~options.ProfilesOnly
    writetable(folds, fullfile(here, 'splits', 'folds_rev1.csv'));
    h = file_sha256(fullfile(here, 'splits', 'folds_rev1.csv'));
    writelines(h, fullfile(here, 'splits', 'folds_rev1.sha256'));
    writelines(jsonencode(man, 'PrettyPrint', true), fullfile(here, 'links', 'manifest_rev1.json'));
end
fprintf('Done. %d profiles in cache.\n', numel(profiles));
end

%% ---- ITS Phase 2 --------------------------------------------------------
function [T, prof, folds] = build_phase2(here, S, options)
tmp = fullfile(tempdir, 'itm_exp_phase2');
if ~isfolder(fullfile(tmp, 'phase_2')), unzip(fullfile(here, 'raw', 'its_phase2.zip'), tmp); end
root = fullfile(tmp, 'phase_2');
E = wgs84Ellipsoid('km');
rows = {}; prof = struct('path_id', {}, 'dataset', {}, 'd_km', {}, 'h_m', {}, 'spacing_m', {}, ...
    'midpoint_deg', {}, 'tx', {}, 'rx', {}, 'climate', {}, 'N_0', {});
for s = ["r1" "r2" "r3" "va"]
    va = s == "va";
    pars = readmatrix(fullfile(root, s + "pars.txt"), 'NumHeaderLines', 1, 'FileType', 'text');
    F = pars(:, 1)';
    [Pp, D] = p2_read(root, s, va);
    keys = unique(D(:, {'path', 'siting'}), 'rows', 'stable');
    nk = min(height(keys), options.MaxPaths);
    for k = 1:nk
        pth = keys.path(k); site = keys.siting(k);
        if va
            ip = find(Pp.path == pth, 1);
        else
            ip = find(Pp.path == pth & Pp.site == site, 1);
            if isempty(ip), ip = find(Pp.path == pth, 1); end
        end
        if isempty(ip), continue, end
        tx = [Pp.xlat(ip), Pp.xlon(ip)]; rx = [Pp.rlat(ip), Pp.rlon(ip)]; dlist = Pp.dist(ip);
        [~, v, why] = p2_profile(root, s, pth, site, va, dlist);
        if why ~= "", continue, end
        % Resample to 30 m, as compare_its_phase2_rev1 (make_profile)
        dt = v(end, 1); npt = max(10, round(dt / (S.profile_spacing_m / 1000)));
        dd = linspace(0, dt, npt + 1)'; hh = interp1(v(:, 1), v(:, 2), dd, 'linear');
        [arclen, az] = distance(tx(1), tx(2), rx(1), rx(2), E);
        [mla, mlo] = reckon(tx(1), tx(2), arclen / 2, az, E);
        clim = itm_radio_climate_rev1(mla, mlo);
        if clim == 7, clim = min(itm_radio_climate_rev1(tx(1), tx(2)), itm_radio_climate_rev1(rx(1), rx(2))); end
        n0 = itm_surface_refractivity_rev1(mla, mlo);
        path_id = "P2_" + upper(s) + "_" + replace(pth, "'", "_") + "_" + site;
        prof(end + 1) = struct('path_id', path_id, 'dataset', "phase2", 'd_km', dt, 'h_m', hh, ...
            'spacing_m', 1000 * dt / npt, 'midpoint_deg', [mla mlo], 'tx', tx, 'rx', rx, ...
            'climate', clim, 'N_0', n0); %#ok<AGROW>

        R = D(D.path == pth & D.siting == site, :);
        if va
            cfg = unique(R(:, {'rcvr', 'rht'}), 'rows');
        else
            cfg = unique(R(:, {'rht'}), 'rows'); cfg.rcvr = zeros(height(cfg), 1);
        end
        nc = height(cfg);
        for j = 1:numel(F)
            if j > 1 && F(j) == F(j - 1), continue, end
            htx = pars(j, 2);
            hrx = zeros(nc, 1);
            for c = 1:nc
                if va
                    if cfg.rht(c) == "Lo", hrx(c) = pars(j, 5); else, hrx(c) = pars(j, 2 + cfg.rcvr(c)); end
                else
                    hrx(c) = double(cfg.rht(c));
                end
            end
            for c = 1:nc
                if va
                    sel = R.rcvr == cfg.rcvr(c) & R.rht == cfg.rht(c);
                else
                    sel = R.rht == cfg.rht(c);
                end
                a = R.A(sel, j); a = a(a < 999);
                if isempty(a), continue, end
                b = a >= 500; a(b) = a(b) - 500;
                fs = 32.45 + 20 * log10(F(j)) + 20 * log10(dlist);
                link_id = sprintf('%s_f%g_h%g_c%d', path_id, F(j), hrx(c), c);
                rows(end + 1, :) = {string(link_id), path_id, upper(s), string(site), dlist, dt, F(j), htx, hrx(c), ...
                    0, numel(a), any(b), fs + median(a), fs, clim, n0}; %#ok<AGROW>
            end
        end
    end
    fprintf('Phase 2 %s: %d rows so far\n', upper(s), size(rows, 1));
end
T = cell2table(rows, 'VariableNames', {'link_id', 'path_id', 'set', 'siting', 'd_km', 'profile_km', 'f_mhz', ...
    'htx_m', 'hrx_m', 'pol', 'runs', 'censored', 'meas_lb_db', 'fs_db', 'climate', 'N_0'});
u = unique(T(:, {'path_id', 'set'}), 'rows', 'stable');
folds = table(repmat("phase2", height(u), 1), u.path_id, double(categorical(u.set, ["R1" "R2" "R3" "VA"])), ...
    'VariableNames', {'dataset', 'path_id', 'fold'});
end

%% ---- ITS long-term ------------------------------------------------------
function [T, prof, folds, drop] = build_longterm(here, S, options)
tmp = fullfile(tempdir, 'itm_exp_longterm');
if ~isfolder(fullfile(tmp, 'longterm')), unzip(fullfile(here, 'raw', 'longterm.zip'), tmp); end
[T, drop] = lt_read(fullfile(tmp, 'longterm'));
% Nick, 2026-11-21: US paths only, so every profile uses the same 30 m terrain
% source as matlab_itm (worldwide 30 m tiles exceed the Mac's disk). Both
% terminals must be inside the conterminous-US box.
in_us = @(lat, lon) lat > 24 & lat < 50 & lon > -125 & lon < -66;
keep = in_us(T.tx_lat, T.tx_lon) & in_us(T.rx_lat, T.rx_lon);
drop = [drop; [T.link_id(~keep), repmat("outside conterminous US", nnz(~keep), 1)]];
T = T(keep, :);
up = unique(T.path_id, 'stable');
if isfinite(options.MaxPaths), up = up(1:min(end, options.MaxPaths)); T = T(ismember(T.path_id, up), :); end
first = arrayfun(@(p) find(T.path_id == p, 1), up);
fprintf('Long-term: %d rows on %d paths; sampling terrain...\n', height(T), numel(up));
[pfls, pinfo] = itm_terrain_profile_rev1(T.tx_lat(first), T.tx_lon(first), T.rx_lat(first), T.rx_lon(first), ...
    spacing_m=S.profile_spacing_m);
if ~iscell(pfls), pfls = {pfls}; end
prof = struct('path_id', {}, 'dataset', {}, 'd_km', {}, 'h_m', {}, 'spacing_m', {}, ...
    'midpoint_deg', {}, 'tx', {}, 'rx', {}, 'climate', {}, 'N_0', {});
for k = 1:numel(up)
    i = first(k); pf = pfls{k}; mid = pinfo(k).midpoint_deg;
    clim = itm_radio_climate_rev1(mid(1), mid(2));
    if clim == 7
        clim = min(itm_radio_climate_rev1(T.tx_lat(i), T.tx_lon(i)), itm_radio_climate_rev1(T.rx_lat(i), T.rx_lon(i)));
    end
    prof(k) = struct('path_id', "LT_" + up(k), 'dataset', "longterm", 'd_km', pf(1) * pf(2) / 1000, ...
        'h_m', pf(3:end), 'spacing_m', pf(2), 'midpoint_deg', mid, 'tx', [T.tx_lat(i) T.tx_lon(i)], ...
        'rx', [T.rx_lat(i) T.rx_lon(i)], 'climate', clim, 'N_0', itm_surface_refractivity_rev1(mid(1), mid(2)));
end
T.path_id = "LT_" + T.path_id;
[~, ip] = ismember(T.path_id, [prof.path_id]);
T.climate = [prof(ip).climate]'; T.N_0 = [prof(ip).N_0]';
T.fs_db = 32.45 + 20 * log10(T.f_mhz) + 20 * log10(T.d_km);
T.pol = double(T.pol == "V");                  % 0 horizontal, 1 vertical
for j = 1:numel(S.p_tags)
    T.("meas_lb_" + S.p_tags(j)) = T.fs_db + T.("meas_a_" + S.p_tags(j));
end

% Folds: group paths by receiver site (0.1 degree), then assign groups to
% five folds, largest group first, each to the fold with the fewest rows
g = compose("%.1f_%.1f", round(T.rx_lat, 1), round(T.rx_lon, 1));
[ug, ~, gi] = unique(g);
cnt = accumarray(gi, 1);
[~, order] = sortrows([-cnt, (1:numel(ug))']);
gf = zeros(numel(ug), 1); load_ = zeros(5, 1);
for k = order'
    [~, f] = min(load_); gf(k) = f; load_(f) = load_(f) + cnt(k);
end
T.group = ug(gi); T.fold = gf(gi);
u = unique(T(:, {'path_id', 'fold'}), 'rows', 'stable');
if numel(unique(u.path_id)) ~= height(u)
    error('itmexp:folds', 'A long-term path spans two receiver groups; fix the grouping rule.');
end
folds = table(repmat("longterm", height(u), 1), u.path_id, u.fold, 'VariableNames', {'dataset', 'path_id', 'fold'});
end

%% ---- Predictions --------------------------------------------------------
function T = add_baseline(T, profiles, S, timevar)
ids = [profiles.path_id];
if timevar
    p = S.p_all; cols = "itm_lb_" + S.p_tags;
else
    p = 50; cols = "itm_lb_50";
end
L = NaN(height(T), numel(p)); err = strings(height(T), 1);
for i = 1:height(T)
    pr = profiles(ids == T.path_id(i));
    pfl = [numel(pr.h_m) - 1; pr.spacing_m; pr.h_m(:)];
    try
        L(i, :) = itm_p2p_rev1(T.htx_m(i), T.hrx_m(i), pfl, T.f_mhz(i), p, confidence=S.confidence, ...
            climate=T.climate(i), N_0=T.N_0(i), polarization=T.pol(i), epsilon=S.epsilon, ...
            sigma=S.sigma, mdvar=S.mdvar, validity="off");
    catch e
        err(i) = string(e.identifier);
    end
end
for j = 1:numel(cols), T.(cols(j)) = L(:, j); end
T.itm_error = err;
fprintf('Baseline ITM: %d rows, %d errors\n', height(T), nnz(err ~= ""));
end

function T = add_references(T, profiles, S, timevar)
ids = [profiles.path_id];
models = ["p452" "p2001"];
if timevar, p = S.p_all; tags = S.p_tags; else, p = 50; tags = "50"; end
for m = models
    L = NaN(height(T), numel(p));
    for i = 1:height(T)
        pr = profiles(ids == T.path_id(i));
        np = numel(pr.h_m);
        st = struct('d_km', linspace(0, pr.d_km, np)', 'h_m', pr.h_m(:), 'g_m', pr.h_m(:), 'zone', 2 * ones(np, 1), ...
            'spacing_m', pr.spacing_m, 'midpoint_deg', pr.midpoint_deg, 'distance_km', pr.d_km);
        pols = ["horizontal" "vertical"]; pol = pols(T.pol(i) + 1);
        if m == "p452"
            ok = p >= 0.001 & p <= 50;
            if T.f_mhz(i) < 100, continue, end
            mo = {'polarization', pol};
        else
            ok = true(size(p));
            mo = {'Polarization', pol};
        end
        try
            L(i, ok) = pathloss_rev1([pr.tx T.htx_m(i)], [pr.rx T.hrx_m(i)], T.f_mhz(i), p(ok), 'model', m, ...
                'model_options', mo, 'profile', st, 'validity', "off", 'surface_source', "none", 'download', false);
        catch
        end
    end
    for j = 1:numel(tags), T.(m + "_lb_" + tags(j)) = L(:, j); end
    fprintf('%s: %d of %d rows computed\n', m, nnz(any(isfinite(L), 2)), height(T));
end
end

%% ---- Helpers ------------------------------------------------------------
function profiles = merge_profiles(profiles, new)
if isempty(profiles), profiles = new; return, end
keep = ~ismember([profiles.path_id], [new.path_id]);
profiles = [profiles(keep), new];
end

function s = summarize(T, prof, rawfile)
s = struct('rows', height(T), 'paths', numel(prof), 'raw_sha256', file_sha256(rawfile));
h = strings(numel(prof), 1);
for k = 1:numel(prof), h(k) = sha256_bytes(typecast(double(prof(k).h_m(:)'), 'uint8')); end
s.profiles_sha256 = sha256_bytes(uint8(char(join(h, ""))));
end

function h = git_head(d)
h = git_head_rev1(d);
end

function h = file_sha256(f)
fid = fopen(f, 'r'); c = onCleanup(@() fclose(fid));
h = sha256_bytes(fread(fid, Inf, '*uint8')');
end

function h = sha256_bytes(b)
md = java.security.MessageDigest.getInstance('SHA-256');
md.update(b(:));
h = string(sprintf('%02x', typecast(md.digest(), 'uint8')));
end
