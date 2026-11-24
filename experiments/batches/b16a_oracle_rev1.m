function S = b16a_oracle_rev1(out_dir)
%B16A_ORACLE_REV1 Fixed-geometry coupled two-screen oracle on the R2-020 height sweeps (B16a).
%   S = B16A_ORACLE_REV1(out_dir) runs the registered B16a design
%   (experiments/batches/B16.md) and writes, to out_dir:
%     sweep_<path>.csv   one row per receiver height and frequency
%     summary.txt        the numerical-stage and measurement-stage tables
%   Paths: P2_R2_R2-020-T1_O and -T2_O, the two paths that carry 75 % of
%   707's real-path height-gain failures (LOG, 2026-11-22).
%
%   Stage 1 (numerical, model only):
%   - Screens are frozen from geometry before any measurement is read: at
%     9190 MHz, the 707 principal edges (P.526-11 section 4.4.2,
%     "p526_cascaded_isolated") just below and just above the largest step
%     of 707's L_ba on the receiver-height sweep 1:0.05:40 m. The same two
%     profile points are used at every frequency and height.
%   - Series at every height: coupled two-screen loss (Vogler,
%     vogler_two_screen_rev1), independent edges at the same coordinates
%     (Epstein-Peterson, exact single-edge losses), each screen alone
%     between the antennas, the spacing term L_c, 707's L_ba with its
%     selected edges, 707's full basic transmission loss at 50 % and stock
%     ITM's, all on ITM's effective Earth (a_e = 1/gamma_e). Earth
%     curvature enters as the bulge x (d - x) / (2 a_e) (P.526-11 eq. (49a)).
%   - Checks: integration tolerance 1e-10 against 1e-12 on every 20th
%     height; terminal reversal of the oracle (must be exact) and of 707.
%     The CSV carries the flat-Earth screen coordinates (bulge applied), so
%     b16a_crosscheck_rev1.py can recompute the coupled loss with SciPy.
%   Stage 2 (measurement, only after stage 1 passes): on each frequency with
%   detected (uncensored) rows at the measured heights 1-13 m, the measured
%   contrast mean(h >= switch) - mean(h < switch) against each prediction's.
%   Reads Phase 2 geometry, frequency and climate columns for stage 1 and
%   the measured loss of these two paths for stage 2 only.

P = itm_exp_paths_rev1(); St = settings_rev1();
if ~isfolder(out_dir), mkdir(out_dir); end
profiles = load_profiles_rev1(P.root); ids = string({profiles.path_id});
T2 = readtable(fullfile(P.root, 'data', 'links', 'phase2_links_rev1.csv'), 'TextType', 'string');
setenv('ITMEXP_OVERRIDES', ['{"diffraction":"delta_cascaded_isolated","diffraction_bound":"itm_troposcatter_line",' ...
    '"terminal_clutter":"p2108_height_gain","terminal_clutter_base":"clutter_height",' ...
    '"terminal_clutter_frange":"hold3"}']);
c707 = params_exp(); setenv('ITMEXP_OVERRIDES', ''); c0 = params_exp();
freqs = [230 410 751 910 1846 4595 9190];
hr = (1:0.05:40)';
paths = ["P2_R2_R2-020-T1_O" "P2_R2_R2-020-T2_O"];
fid = fopen(fullfile(out_dir, 'summary.txt'), 'w');
cleanup = onCleanup(@() fclose(fid));
out = @(varargin) fprintf_both(fid, varargin{:});
out('B16a fixed-geometry coupled two-screen oracle. Generated %s.\n', string(datetime('now'), 'yyyy-MM-dd HH:mm'));
S = struct();
for pid = paths
    R = T2(T2.path_id == pid, :);
    if isempty(R), error('itmexp:b16a', 'No rows for %s.', pid); end
    clim = R.climate(1); N0 = R.N_0(1); pol = R.pol(1);
    htx_of = @(f) unique(R.htx_m(R.f_mhz == f));    % 6.6 m below 910 MHz, 7.3 m above (r2pars.txt)
    for f = freqs
        if numel(htx_of(f)) ~= 1, error('itmexp:b16a', 'Expected one transmitter height at %d MHz on %s.', f, pid); end
    end
    htx = htx_of(9190);
    pr = profiles(ids == pid);
    g = pr.h_m(:); np = numel(g) - 1; x = (0:np)' * pr.spacing_m; d = x(end);
    pfl = [np; pr.spacing_m; g];
    row = struct('set', R.set(1), 'siting', R.siting(1), 'reversed', false, 'path_id', pid);
    [~, info] = itm_p2p_core_exp(htx, 5, pfl, 1000, 50, St.confidence, St.location, clim, N0, pol, ...
        St.epsilon, St.sigma, St.mdvar, true, [], setfield(c0, 'row', row)); %#ok<SFLD>
    a_e = 1 / (157e-9 * (1 - 0.04665 * exp(info.N_s / 179.3)));   % ITM v1.4 InitializePointToPoint: gamma_e
    bulge = x .* (d - x) / (2 * a_e);
    % ---- freeze the screens at 9190 MHz from 707's own edge selection
    Lb = zeros(size(hr)); Ep = zeros(numel(hr), 3);
    for i = 1:numel(hr)
        [Lb(i), Dm] = l_ba(x, g, htx, hr(i), 9190, a_e);
        Ep(i, :) = Dm.edges;
    end
    [step, j] = max(abs(diff(Lb)));
    s1 = Ep(j, 2); s2 = Ep(j + 1, 2);
    if s1 == s2, error('itmexp:b16a', 'Largest L_ba step on %s is not a principal-edge switch.', pid); end
    k = sort([s1 s2]);
    h_sw = hr(j + 1);
    out('\n== %s (d = %.2f km, a_e = %.0f km, h_tx = %.1f m at 9190 MHz)\n', pid, d / 1e3, a_e / 1e3, htx);
    out('Frozen screens: profile points %d (x = %.0f m, ground %.1f m) and %d (x = %.0f m, ground %.1f m), separation %.0f m.\n', ...
        k(1), x(k(1)), g(k(1)), k(2), x(k(2)), g(k(2)), x(k(2)) - x(k(1)));
    out('Selected from 707 at 9190 MHz: principal edge %d -> %d between h_rx %.2f and %.2f m (L_ba step %.1f dB).\n', ...
        s1, s2, hr(j), hr(j + 1), step);
    % ---- sweep every frequency
    rows = cell(numel(freqs), 1);
    for fi = 1:numel(freqs)
        f = freqs(fi);
        htx = htx_of(f);
        n = numel(hr);
        Lc = zeros(n, 1); Lep = Lc; L1 = Lc; L2 = Lc; Lsp = Lc; nu1 = Lc; nu2 = Lc;
        Lcr = Lc; Zt = Lc; Zr = Lc; Lba = Lc; Lbar = Lc; pe = Lc; A7 = Lc; As = Lc; Ltol = NaN(n, 1);
        for i = 1:n
            zt = g(1) + htx; zr = g(end) + hr(i);
            xs = [0; x(k(1)); x(k(2)); d];
            zs = [zt; g(k(1)) + bulge(k(1)); g(k(2)) + bulge(k(2)); zr];
            Zt(i) = zt; Zr(i) = zr;
            [Lc(i), ~, Dv] = vogler_two_screen_rev1(xs, zs, f);
            Lep(i) = Dv.L_ep_db; Lsp(i) = Dv.L_c_db; nu1(i) = Dv.nu(1); nu2(i) = Dv.nu(2);
            L1(i) = vogler_two_screen_rev1(xs([1 2 4]), zs([1 2 4]), f);
            L2(i) = vogler_two_screen_rev1(xs([1 3 4]), zs([1 3 4]), f);
            Lcr(i) = vogler_two_screen_rev1(d - flipud(xs), flipud(zs), f);
            if mod(i - 1, 20) == 0
                Ltol(i) = vogler_two_screen_rev1(xs, zs, f, 1e-12);
            end
            [Lba(i), Dm] = l_ba(x, g, htx, hr(i), f, a_e); pe(i) = Dm.edges(2);
            Lbar(i) = l_ba(d - flipud(x), flipud(g), hr(i), htx, f, a_e);
            A7(i) = itm_p2p_core_exp(htx, hr(i), pfl, f, 50, St.confidence, St.location, clim, N0, pol, ...
                St.epsilon, St.sigma, St.mdvar, false, [], setfield(c707, 'row', row)); %#ok<SFLD>
            As(i) = itm_p2p_core_exp(htx, hr(i), pfl, f, 50, St.confidence, St.location, clim, N0, pol, ...
                St.epsilon, St.sigma, St.mdvar, false, [], setfield(c0, 'row', row)); %#ok<SFLD>
        end
        geo = repmat([d, x(k(1)), g(k(1)) + bulge(k(1)), x(k(2)), g(k(2)) + bulge(k(2))], n, 1);
        rows{fi} = table(repmat(string(pid), n, 1), repmat(f, n, 1), hr, Zt, Zr, geo(:, 1), geo(:, 2), geo(:, 3), ...
            geo(:, 4), geo(:, 5), nu1, nu2, Lc, Lep, Lsp, L1, L2, Lcr, Ltol, ...
            Lba, Lbar, pe, A7, As, 'VariableNames', ["path_id" "f_mhz" "h_rx_m" "z_tx_m" "z_rx_m" "d_m" "x_s1_m" "z_s1_m" ...
            "x_s2_m" "z_s2_m" "nu1" "nu2" "L_coupled_db" ...
            "L_independent_db" "L_c_db" "L_screen1_alone_db" "L_screen2_alone_db" "L_coupled_reversed_db" ...
            "L_coupled_tol1e12_db" "L_ba_707_db" "L_ba_707_reversed_db" "principal_707" "A_707_lb_50" "A_stock_lb_50"]);
    end
    W = vertcat(rows{:});
    writetable(W, fullfile(out_dir, "sweep_" + pid + ".csv"));
    S.(matlab.lang.makeValidName(pid)) = W;
    % ---- stage 1 tables
    out('\nStage 1 (numerical). Largest step between adjacent heights (0.05 m apart), dB:\n');
    out('%6s %9s %9s %9s %9s %9s %9s %10s %10s\n', 'f', 'coupled', 'indep', 'L_ba707', 'A_707', 'A_stock', ...
        'tol_err', 'rev_oracle', 'rev_707');
    ok = true;
    for f = freqs
        V = W(W.f_mhz == f, :);
        ms = @(v) max(abs(diff(v)));
        te = max(abs(V.L_coupled_tol1e12_db - V.L_coupled_db), [], 'omitnan');
        re = max(abs(V.L_coupled_reversed_db - V.L_coupled_db));
        r7 = max(abs(V.L_ba_707_reversed_db - V.L_ba_707_db));
        out('%6d %9.3f %9.3f %9.2f %9.2f %9.2f %9.1e %10.1e %10.2f\n', f, ms(V.L_coupled_db), ms(V.L_independent_db), ...
            ms(V.L_ba_707_db), ms(V.A_707_lb_50), ms(V.A_stock_lb_50), te, re, r7);
        ok = ok && te < 1e-3 && re < 1e-6;
    end
    out('\nAcross 707''s switch (h_rx %.2f -> %.2f m), change in dB:\n', hr(j), hr(j + 1));
    out('%6s %9s %9s %9s %9s %9s %12s %12s\n', 'f', 'coupled', 'indep', 'L_ba707', 'A_707', 'A_stock', ...
        'coup-indep', 'coup-max1');
    for f = freqs
        V = W(W.f_mhz == f, :);
        out('%6d %9.3f %9.3f %9.2f %9.2f %9.2f %12.2f %12.2f\n', f, V.L_coupled_db(j + 1) - V.L_coupled_db(j), ...
            V.L_independent_db(j + 1) - V.L_independent_db(j), V.L_ba_707_db(j + 1) - V.L_ba_707_db(j), ...
            V.A_707_lb_50(j + 1) - V.A_707_lb_50(j), V.A_stock_lb_50(j + 1) - V.A_stock_lb_50(j), ...
            V.L_coupled_db(j) - V.L_independent_db(j), V.L_coupled_db(j) - max(V.L_screen1_alone_db(j), V.L_screen2_alone_db(j)));
    end
    out('\nAt the switch height (%.2f m): nu (edge-to-edge) %.2f and %.2f at 9190 MHz; coupled %.1f dB, independent %.1f dB, L_c %.2f dB, 707 L_ba %.1f -> %.1f dB.\n', ...
        h_sw, W.nu1(W.f_mhz == 9190 & W.h_rx_m == h_sw), W.nu2(W.f_mhz == 9190 & W.h_rx_m == h_sw), ...
        W.L_coupled_db(W.f_mhz == 9190 & W.h_rx_m == h_sw), W.L_independent_db(W.f_mhz == 9190 & W.h_rx_m == h_sw), ...
        W.L_c_db(W.f_mhz == 9190 & W.h_rx_m == h_sw), Lb(j), Lb(j + 1));
    out('Stage 1 numerical checks (tolerance error < 1e-3 dB, reversal < 1e-6 dB): %s\n', string(ok));
    if ~ok
        out('Stage 1 failed; stage 2 not run.\n');
        continue
    end
    % ---- stage 2: measured contrast across the switch height (after stage 1)
    out('\nStage 2 (measurement). Detected rows only; contrast = mean(h >= %.2f m) - mean(h < %.2f m), dB:\n', h_sw, h_sw);
    out('%6s %4s %4s %9s %9s %9s %9s %9s\n', 'f', 'n_lo', 'n_hi', 'measured', 'coupled', 'L_ba707', 'A_707', 'A_stock');
    for f = freqs
        M = R(R.f_mhz == f & R.censored == 0, :);
        lo = M.hrx_m < h_sw; hi = ~lo;
        if nnz(lo) < 2 || nnz(hi) < 2
            out('%6d %4d %4d %9s\n', f, nnz(lo), nnz(hi), 'too few');
            continue
        end
        V = W(W.f_mhz == f, :);
        pick = @(col, h) interp1(V.h_rx_m, V.(col), h);
        con = @(col) mean(pick(col, M.hrx_m(hi))) - mean(pick(col, M.hrx_m(lo)));
        out('%6d %4d %4d %9.2f %9.2f %9.2f %9.2f %9.2f\n', f, nnz(lo), nnz(hi), ...
            mean(M.meas_lb_db(hi)) - mean(M.meas_lb_db(lo)), con("L_coupled_db"), con("L_ba_707_db"), ...
            con("A_707_lb_50"), con("A_stock_lb_50"));
    end
end
end

function [L, D] = l_ba(x, g, h1, h2, f, a_e)
% 707's actual-profile loss L_ba: the diffraction method of delta_cascaded_isolated
z = g; z(1) = z(1) + h1; z(end) = z(end) + h2;
[L, D] = multi_edge_diffraction_rev1("p526_cascaded_isolated", x, z, f, a_e);
end

function fprintf_both(fid, varargin)
fprintf(varargin{:});
fprintf(fid, varargin{:});
end
