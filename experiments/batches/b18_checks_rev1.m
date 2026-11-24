function S = b18_checks_rev1(names, cand_jsons, out_dir)
%B18_CHECKS_REV1 Model-only defect checks for the B18 repair candidates (B18).
%   S = B18_CHECKS_REV1(names, cand_jsons, out_dir) runs, for each
%   candidate (full override JSON, as the launcher takes it) and for 707:
%     1. The B16a sweeps: P2_R2_R2-020-T1_O and -T2_O, receiver 1 to 40 m in
%        0.05 m steps, the seven R2 frequencies, basic transmission loss at
%        50 %. Largest change between adjacent heights.
%     2. The real-path height check of eval/physics_battery_rev1.m
%        (height_gain_real: each antenna raised 10 m on every Phase 2 row;
%        excess = variant change - max(stock change, 0)), with counts: row-
%        ends over the 1 dB limit, paths, and the worst. The battery itself
%        reports only the worst row.
%     3. eval/physics_battery_rev1.m itself (read-only call): pass, the
%        pointwise continuity check and height_gain_real.
%   Writes summary.txt and per-row CSVs to out_dir. Reads geometry,
%   frequency and climate columns only; no measured loss.
P = itm_exp_paths_rev1(); St = settings_rev1();
if ~isfolder(out_dir), mkdir(out_dir); end
profiles = load_profiles_rev1(P.root); ids = string({profiles.path_id});
opts = {'TextType', 'string'};
P2 = readtable(fullfile(P.root, 'data', 'links', 'phase2_links_rev1.csv'), opts{:});
P2 = P2(baseline_ok_rows(P2), :);
b707 = ['{"diffraction":"delta_cascaded_isolated","diffraction_bound":"itm_troposcatter_line",' ...
    '"terminal_clutter":"p2108_height_gain","terminal_clutter_base":"clutter_height","terminal_clutter_frange":"hold3"}'];
names = ["707" string(names)];
jsons = [string(b707) string(cand_jsons)];
fid = fopen(fullfile(out_dir, 'summary.txt'), 'w');
cleanup = onCleanup(@() fclose(fid));
out = @(varargin) both(fid, varargin{:});
out('B18 model-only checks. Generated %s.\n', string(datetime('now'), 'yyyy-MM-dd HH:mm'));
freqs = [230 410 751 910 1846 4595 9190];
hr = (1:0.05:40)';
paths = ["P2_R2_R2-020-T1_O" "P2_R2_R2-020-T2_O"];
% stock changes for check 2, computed once
fbase = @(htx, hrx, pfl, f, clim, n0, pol) itm_p2p_rev1(htx, hrx, pfl, f, 50, confidence=St.confidence, ...
    climate=clim, N_0=n0, polarization=pol, epsilon=St.epsilon, sigma=St.sigma, mdvar=St.mdvar, validity="off");
[~, ip] = ismember(P2.path_id, ids);
if any(ip == 0), error('itmexp:b18', 'Missing profile.'); end
n2 = height(P2);
dB = zeros(n2, 2);
for i = 1:n2
    r = P2(i, :); pr = profiles(ip(i)); pfl = [numel(pr.h_m) - 1; pr.spacing_m; pr.h_m(:)];
    h = [r.htx_m r.hrx_m];
    b0 = fbase(h(1), h(2), pfl, r.f_mhz, r.climate, r.N_0, r.pol);
    for e = 1:2
        hh = h; hh(e) = hh(e) + 10;
        dB(i, e) = fbase(hh(1), hh(2), pfl, r.f_mhz, r.climate, r.N_0, r.pol) - b0;
    end
end
for c = 1:numel(names)
    setenv('ITMEXP_OVERRIDES', char(jsons(c))); cfg = params_exp(); setenv('ITMEXP_OVERRIDES', '');
    out('\n== %s  %s\n', names(c), jsons(c));
    % 1. sweeps
    for pid = paths
        R = P2(P2.path_id == pid, :);
        pr = profiles(ids == pid); pfl = [numel(pr.h_m) - 1; pr.spacing_m; pr.h_m(:)];
        row = struct('set', R.set(1), 'siting', R.siting(1), 'reversed', false, 'path_id', pid);
        cr = cfg; cr.row = row;
        steps = zeros(1, numel(freqs));
        for fi = 1:numel(freqs)
            f = freqs(fi); htx = unique(R.htx_m(R.f_mhz == f));
            if numel(htx) ~= 1, error('itmexp:b18', 'Transmitter height at %d MHz on %s.', f, pid); end
            A = zeros(size(hr));
            for i = 1:numel(hr)
                A(i) = itm_p2p_core_exp(htx, hr(i), pfl, f, 50, St.confidence, St.location, R.climate(1), ...
                    R.N_0(1), R.pol(1), St.epsilon, St.sigma, St.mdvar, false, [], cr);
            end
            steps(fi) = max(abs(diff(A)));
        end
        out('  sweep %s, largest step per 0.05 m (dB) at %s MHz: %s\n', pid, mat2str(freqs), mat2str(steps, 3));
    end
    % 2. real-path height check with counts
    xs = zeros(n2, 2);
    for i = 1:n2
        r = P2(i, :); pr = profiles(ip(i)); pfl = [numel(pr.h_m) - 1; pr.spacing_m; pr.h_m(:)];
        cr = cfg; cr.row = struct('set', r.set, 'siting', r.siting, 'reversed', false, 'path_id', r.path_id);
        h = [r.htx_m r.hrx_m];
        v0 = itm_p2p_core_exp(h(1), h(2), pfl, r.f_mhz, 50, St.confidence, St.location, r.climate, r.N_0, ...
            r.pol, St.epsilon, St.sigma, St.mdvar, false, [], cr);
        for e = 1:2
            hh = h; hh(e) = hh(e) + 10;
            dv = itm_p2p_core_exp(hh(1), hh(2), pfl, r.f_mhz, 50, St.confidence, St.location, r.climate, ...
                r.N_0, r.pol, St.epsilon, St.sigma, St.mdvar, false, [], cr) - v0;
            xs(i, e) = dv - max(dB(i, e), 0);
        end
    end
    over = xs > 1;
    [w, j] = max(xs(:)); [ii, ee] = ind2sub(size(xs), j);
    pids = unique(P2.path_id(any(over, 2)));
    out('  real-path height check: %d row-ends over 1 dB on %d paths; worst %.1f dB (%s, %g MHz, antenna %d)\n', ...
        nnz(over), numel(pids), w, P2.path_id(ii), P2.f_mhz(ii), ee);
    writetable(table(P2.link_id, xs(:, 1), xs(:, 2), 'VariableNames', ["link_id" "excess_tx_db" "excess_rx_db"]), ...
        fullfile(out_dir, "height_excess_" + names(c) + ".csv"));
    % 3. the battery itself
    B = physics_battery_rev1(cfg, P2, profiles);
    cp = B.checks.continuity_pointwise; hg = B.checks.height_gain_real;
    out('  battery: pass %d; pointwise continuity worst %.1f dB (%s); height_gain_real worst %.1f dB\n', ...
        B.pass, cp.worst_excess_db, cp.worst_sweep, hg.worst_excess_db);
    S.(matlab.lang.makeValidName("c" + names(c))) = struct('xs', xs, 'battery', B);
end
end

function ok = baseline_ok_rows(T)
% Same rows the evaluator passes to the battery (copy of baseline_ok in eval/run_eval_rev1.m)
if ~ismember('itm_error', T.Properties.VariableNames) || isnumeric(T.itm_error)
    ok = true(height(T), 1);
else
    ok = ismissing(T.itm_error) | T.itm_error == "";
end
end

function both(fid, varargin)
fprintf(varargin{:}); fprintf(fid, varargin{:});
end
