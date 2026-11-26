function T = d34_trace_rev1(root)
%D34_TRACE_REV1 B34 D34c: find the first integer truncation that differs between fresh and CSV-spacing profiles.
%   T = D34_TRACE_REV1(root) copies itm_variant/ to a scratch folder,
%   renames the core to d34_core_trace, and inserts logging after each
%   integer truncation in ITM's terrain analysis (quick_pfl horizon
%   indices, linear_least_squares_fit, compute_delta_h, and the q at the
%   diffraction distance). The repo's itm_variant/ is not changed. For each
%   row where D34c found stock ITM differs by more than 1e-6 dB between the
%   fresh and the spacing-only profile, it runs the traced core at
%   params_exp() defaults (bit-identical to stock ITM) on both profiles and
%   records the first logged quantity that differs. It also checks that the
%   traced core reproduces both stored stock losses. Writes
%   experiments/D34c-profile-roundtrip/trace_rev1.csv.
arguments
    root (1,1) string
end
itm_exp_paths_rev1();
S = settings_rev1();
out = fullfile(root, 'experiments', 'D34c-profile-roundtrip');
P = readtable(fullfile(out, 'parity_rev1.csv'), 'TextType', 'string');
M = load(fullfile(out, 'profiles_lossless_rev1.mat'));
Pr = readtable(fullfile(root, 'experiments', 'D32-ot7574-heights', 'predictions_rev1.csv'), 'TextType', 'string');
G = readtable(fullfile(root, 'experiments', 'D32-ot7574-heights', 'paths_rev1.csv'), 'TextType', 'string');

% ---- Scratch copy with logging
scratch = fullfile(tempdir, 'd34trace');
if isfolder(scratch), rmdir(scratch, 's'); end
copyfile(fullfile(root, 'itm_variant'), scratch);
src = fileread(fullfile(scratch, 'itm_p2p_core_exp.m'));
delete(fullfile(scratch, 'itm_p2p_core_exp.m'));
src = regexprep(src, 'function \[A_db, info, wbits, elev_deg, mode_code\] = itm_p2p_core_exp\(', ...
    'function [A_db, info, wbits, elev_deg, mode_code] = d34_core_trace(', 'once');
ins = {
    "[theta_hzn, d_hzn_m] = find_horizons(pfl, a_e, h_m);", ...
        "d34_log(""hzn_idx"", d_hzn_m(1) / pfl(2), d_hzn_m(2) / pfl(2), 0, 0);"
    "i_end = np - fix(fdim(np, d_end / pfl(2)));", ...
        "d34_log(""llsf"", d_start / pfl(2), d_end / pfl(2), i_start, i_end);"
    "p10 = fix(0.1 * (x_end - x_start + 8.0));", ...
        "d34_log(""cdh"", x_start, x_end, p10, fix(x_start));"
    "q = fix(d_m - d_hzn_m(1) - d_hzn_m(2));", ...
        "d34_log(""q"", d_m - d_hzn_m(1) - d_hzn_m(2), 0, q, 0);"
    };
for k = 1:size(ins, 1)
    if numel(strfind(src, ins{k, 1})) ~= 1
        error('itmexp:d34c', 'Instrumentation anchor not unique: %s', ins{k, 1});
    end
    src = strrep(src, ins{k, 1}, ins{k, 1} + newline + "    " + ins{k, 2});
end
fid = fopen(fullfile(scratch, 'd34_core_trace.m'), 'w'); fwrite(fid, src); fclose(fid);
fid = fopen(fullfile(scratch, 'd34_log.m'), 'w');
fwrite(fid, sprintf(['function d34_log(tag, a, b, c, d)\nglobal D34LOG\n' ...
    'D34LOG(end + 1) = struct(''tag'', string(tag), ''a'', a, ''b'', b, ''c'', c, ''d'', d);\nend\n']));
fclose(fid);
addpath(scratch);
cleaner = onCleanup(@() rmpath(scratch));

% ---- Discrepant rows
bad = find(abs(P.stock_spacing - P.stock_fresh) > 1e-6);
fprintf('Tracing %d rows\n', numel(bad));
setenv('ITMEXP_OVERRIDES', ''); cfg0 = params_exp();
keys = string({M.profiles.geom_key});
global D34LOG
rows = {};
for r = bad'
    k = find(keys == P.geom_key(r));
    f = M.profiles(k).pfl;
    g = find(G.geom_key == P.geom_key(r));
    s = [f(1); G.spacing_m(g); f(3:end)];
    q = Pr(Pr.geom_key == P.geom_key(r) & Pr.table == P.table(r) & Pr.band == P.band(r) & Pr.rx_ant_m == P.rx_ant_m(r), :);
    q = q(1, :);
    c = cfg0; c.row = struct('set', "OT7574", 'siting', "O", 'reversed', false, 'path_id', "trace");
    logs = cell(1, 2); L = zeros(1, 2);
    pfls = {f, s};
    for v = 1:2
        D34LOG = struct('tag', {}, 'a', {}, 'b', {}, 'c', {}, 'd', {});
        L(v) = d34_core_trace(q.tx_model_m, q.rx_model_m, pfls{v}, q.f_mhz, 50, S.confidence, S.location, ...
            q.climate, q.N_0, 1, q.epsilon, q.sigma, S.mdvar, false, [], c);
        logs{v} = D34LOG;
    end
    if abs(L(1) - P.stock_fresh(r)) > 1e-9 || abs(L(2) - P.stock_spacing(r)) > 1e-9
        error('itmexp:d34c', 'Traced core does not reproduce stock on row %d.', r);
    end
    A = logs{1}; B = logs{2};
    first = "none"; detail = "";
    for e = 1:min(numel(A), numel(B))
        if A(e).tag ~= B(e).tag
            first = "branch"; detail = A(e).tag + " vs " + B(e).tag; break
        end
        if A(e).c ~= B(e).c || A(e).d ~= B(e).d
            first = A(e).tag;
            detail = sprintf('a %.17g vs %.17g; b %.17g vs %.17g; int %g,%g vs %g,%g', A(e).a, B(e).a, ...
                A(e).b, B(e).b, A(e).c, A(e).d, B(e).c, B(e).d);
            break
        end
    end
    if first == "none" && numel(A) ~= numel(B), first = "length"; end
    rows(end + 1, :) = {P.geom_key(r), P.table(r), P.band(r), P.rx_ant_m(r), P.stock_fresh(r), ...
        P.stock_spacing(r), first, string(detail)}; %#ok<AGROW>
end
T = cell2table(rows, 'VariableNames', {'geom_key', 'table', 'band', 'rx_ant_m', 'stock_fresh', ...
    'stock_spacing', 'first_divergence', 'detail'});
writetable(T, fullfile(out, 'trace_rev1.csv'));
disp(T(:, {'geom_key', 'band', 'rx_ant_m', 'stock_fresh', 'stock_spacing', 'first_divergence'}));
disp(T.detail);
end
