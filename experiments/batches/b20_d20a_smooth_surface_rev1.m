function T = b20_d20a_smooth_surface_rev1(out_dir)
%B20_D20A_SMOOTH_SURFACE_REV1 D20a (B20): which term of 707's delta flattens height gain.
%   T = B20_D20A_SMOOTH_SURFACE_REV1(out_dir) sweeps one antenna from 1 to 30 m
%   in 0.25 m steps on three geometries and six settings, and writes
%   out_dir/d20a_sweeps_rev1.csv and out_dir/summary.txt.
%
%   Geometries:
%     ridge40   the physics battery's rx_height_ridge40 sweep: 40 km, 30 m
%               spacing, triangular 150 m ridge, transmitter 10 m, receiver
%               swept, 3000 MHz, climate 5, N_0 301, horizontal
%     R2-020    P2_R2_R2-020-T2_O at 9190 MHz, antenna 2 swept (B18 worst)
%     R1-005    P2_R1_R1-005-T5_O at 230 MHz, antenna 1 swept (the inversion)
%   Settings: 707; 707 with no bound; 707 with smooth_heights p452_ducting,
%   itm_effective, structural; stock ITM.
%   Per point: A_ref and info.delta_parts (L_ba, L_bs, A_s, bound value,
%   whether it binds, smooth-surface heights). First reproduces 707's stored
%   prediction on one row of each real path to 1e-9 dB, or stops.
%   Development data only; no measured loss is read.
P = itm_exp_paths_rev1(); St = settings_rev1();
if ~isfolder(out_dir), mkdir(out_dir); end
profiles = load_profiles_rev1(P.root); ids = string({profiles.path_id});
L = readtable(fullfile(P.root, 'data', 'links', 'phase2_links_rev1.csv'), 'TextType', 'string');
E7 = readtable(fullfile(P.root, 'experiments', '707-cascaded-isolated-clutter-at-r', 'predictions_phase2.csv'), 'TextType', 'string');

setenv('ITMEXP_OVERRIDES', '');
c707 = params_exp();
c707.diffraction = "delta_cascaded_isolated"; c707.diffraction_bound = "itm_troposcatter_line";
c707.terminal_clutter = "p2108_height_gain"; c707.terminal_clutter_base = "clutter_height";
c707.terminal_clutter_frange = "hold3";
names = ["707" "707_no_bound" "707_p452_ducting" "707_itm_effective" "707_structural" "stock"];
cfgs = {c707, setfield(c707, 'diffraction_bound', "none"), setfield(c707, 'smooth_heights', "p452_ducting"), ...
    setfield(c707, 'smooth_heights', "itm_effective"), setfield(c707, 'smooth_heights', "structural"), []}; %#ok<SFLD>

% Geometries
G = struct('name', {}, 'pfl', {}, 'f', {}, 'h_fixed', {}, 'end_swept', {}, 'clim', {}, 'n0', {}, 'pol', {}, 'row', {});
x = (0:30:40000)'; xr = linspace(0, 1, numel(x))';
G(1) = struct('name', "ridge40", 'pfl', [numel(x) - 1; 30; 150 * max(0, 1 - abs(xr - 0.5) / 0.05)], 'f', 3000, ...
    'h_fixed', 10, 'end_swept', 2, 'clim', 5, 'n0', 301, 'pol', 0, 'row', struct('set', "", 'siting', "", 'reversed', false, 'path_id', "synthetic"));
G(2) = real_path("P2_R2_R2-020-T2_O", 9190, 2);
G(3) = real_path("P2_R1_R1-005-T5_O", 230, 1);

hh = 1:0.25:30;
rows = {};
for gi = 1:numel(G)
    g = G(gi);
    for si = 1:numel(names)
        for h = hh
            if g.end_swept == 1, ht = h; hr = g.h_fixed; else, ht = g.h_fixed; hr = h; end
            q = struct('L_ba_db', NaN, 'L_bs_db', NaN, 'A_s_db', NaN, 'A_delta_db', NaN, 'A_bounded_db', NaN, ...
                'bound_binds', false, 'h_st_m', NaN, 'h_sr_m', NaN, 'h_p_m', [NaN NaN]);
            if names(si) == "stock"
                a = itm_p2p_rev1(ht, hr, g.pfl, g.f, 50, confidence=St.confidence, climate=g.clim, N_0=g.n0, ...
                    polarization=g.pol, epsilon=St.epsilon, sigma=St.sigma, mdvar=St.mdvar, validity="off");
                aref = NaN;
            else
                c = cfgs{si}; c.row = g.row;
                [a, info] = itm_p2p_core_exp(ht, hr, g.pfl, g.f, 50, St.confidence, St.location, g.clim, g.n0, ...
                    g.pol, St.epsilon, St.sigma, St.mdvar, true, [], c);
                aref = info.A_ref_db;
                if isfield(info.delta_parts, 'L_ba_db'), q = info.delta_parts; end
            end
            if ~isfinite(a), error('itmexp:d20a', 'Non-finite loss: %s, %s, h %g.', g.name, names(si), h); end
            rows(end + 1, :) = {g.name, names(si), h, a, aref, q.L_ba_db, q.L_bs_db, q.A_s_db, q.A_delta_db, ...
                q.A_bounded_db, q.bound_binds, q.h_st_m, q.h_sr_m, q.h_p_m(1), q.h_p_m(2)}; %#ok<AGROW>
        end
    end
end
T = cell2table(rows, 'VariableNames', {'geometry', 'setting', 'h_swept_m', 'loss_db', 'A_ref_db', 'L_ba_db', ...
    'L_bs_db', 'A_s_db', 'A_delta_db', 'A_bounded_db', 'bound_binds', 'h_st_m', 'h_sr_m', 'h_p_tx_m', 'h_p_rx_m'});
writetable(T, fullfile(out_dir, 'd20a_sweeps_rev1.csv'));

% Summary: net change from 1 to 30 m, per setting and part
lines = "D20a: which term flattens height gain (B20)";
for gi = 1:numel(G)
    lines(end + 1) = ""; lines(end + 1) = sprintf("%s (%g MHz, antenna %d swept 1 to 30 m): net change, dB", G(gi).name, G(gi).f, G(gi).end_swept); %#ok<AGROW>
    for si = 1:numel(names)
        k = T.geometry == G(gi).name & T.setting == names(si);
        t = T(k, :); d = @(v) v(end) - v(1);
        lines(end + 1) = sprintf("  %-18s loss %+7.2f | L_ba %+7.2f  L_bs %+7.2f  A_s %+7.2f  delta %+7.2f | bound binds at %3d of %3d heights | h_p swept %+6.2f m", ...
            names(si), d(t.loss_db), d(t.L_ba_db), d(t.L_bs_db), d(t.A_s_db), d(t.A_delta_db), nnz(t.bound_binds), height(t), ...
            d(ternary(G(gi).end_swept == 1, t.h_p_tx_m, t.h_p_rx_m))); %#ok<AGROW>
    end
end
writelines(lines, fullfile(out_dir, 'summary.txt'));
fprintf('%s\n', lines);

    function g = real_path(pid, f, end_swept)
        r = L(L.path_id == pid & L.f_mhz == f, :);
        if isempty(r), error('itmexp:d20a', 'No row for %s at %g MHz.', pid, f); end
        r = r(1, :);
        k = find(ids == pid);
        if numel(k) ~= 1, error('itmexp:d20a', 'Profile for %s found %d times.', pid, numel(k)); end
        pr = profiles(k); pfl = [numel(pr.h_m) - 1; pr.spacing_m; pr.h_m(:)];
        row = struct('set', string(r.set), 'siting', string(r.siting), 'reversed', false, 'path_id', pid);
        % Parity: 707's stored prediction for this row
        c = c707; c.row = row;
        a = itm_p2p_core_exp(r.htx_m, r.hrx_m, pfl, f, 50, St.confidence, St.location, r.climate, r.N_0, ...
            r.pol, St.epsilon, St.sigma, St.mdvar, false, [], c);
        s = E7.var_lb_50(E7.link_id == r.link_id);
        if abs(a - s) > 1e-9
            error('itmexp:d20a', '707 prediction on %s differs from the stored run by %.3g dB.', r.link_id, a - s);
        end
        if end_swept == 1, hf = r.hrx_m; else, hf = r.htx_m; end
        g = struct('name', extractAfter(pid, "P2_"), 'pfl', pfl, 'f', f, 'h_fixed', hf, 'end_swept', end_swept, ...
            'clim', r.climate, 'n0', r.N_0, 'pol', r.pol, 'row', row);
    end
end

function v = ternary(c, a, b)
if c, v = a; else, v = b; end
end
