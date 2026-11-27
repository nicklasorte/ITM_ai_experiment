function d39_edges_rev1(root)
%D39_EDGES_REV1 B39: the C2 arm's L_ba edges at full precision (model only).
%   D39_EDGES_REV1(root) reruns B38's C2 arm (delta_cascaded_isolated, bound
%   none) on B38's rows and writes experiments/D39-secondary-edges-canopy/
%   edges_rev2.csv with nu and weights in %.17g. B38's edges_rev1.csv rounds
%   them to 5 significant digits, which keeps B39's rebuild check from
%   reaching 1e-9 dB (largest mismatch 4.3e-4 dB). It checks the loss
%   against B38's L_C2 and the edge indices against edges_rev1.csv. It uses
%   no measured value.
itm_exp_paths_rev1(); St = settings_rev1();
setenv('ITMEXP_OVERRIDES', '');
B = readtable(fullfile(root, 'experiments', 'D38-cascade-parts-landcover', 'parts_rev1.csv'), 'TextType', 'string');
f1 = fullfile(root, 'experiments', 'D38-cascade-parts-landcover', 'edges_rev1.csv');
o1 = detectImportOptions(f1, 'TextType', 'string');
o1 = setvartype(o1, {'edges', 'nu', 'weights'}, 'string');   % space-separated lists, not numbers
E1 = readtable(f1, o1);
if ~isequal(E1.link_id, B.link_id), error('itmexp:d39', 'B38 parts and edges rows differ in order.'); end
L = readtable(fullfile(root, 'data', 'links', 'phase2_links_rev1.csv'), 'TextType', 'string');
L = L(:, {'link_id', 'path_id', 'set', 'siting', 'f_mhz', 'htx_m', 'hrx_m', 'N_0', 'climate', 'pol'});
[tf, jl] = ismember(B.link_id, L.link_id);
if ~all(tf), error('itmexp:d39', 'B38 rows missing from the link table.'); end
L = L(jl, :);
P = load_profiles_rev1(root); ids = [P.path_id];
[~, ip] = ismember(L.path_id, ids);
c = params_exp(); c.diffraction = "delta_cascaded_isolated"; c.diffraction_bound = "none";
n = height(L); out = strings(n, 3); dl = 0; de = 0;
for i = 1:n
    pr = P(ip(i)); pfl = [numel(pr.h_m) - 1; pr.spacing_m; pr.h_m(:)];
    cc = c; cc.row = struct('set', L.set(i), 'siting', L.siting(i), 'reversed', false, 'path_id', L.path_id(i));
    [v, info] = itm_p2p_core_exp(L.htx_m(i), L.hrx_m(i), pfl, L.f_mhz(i), 50, St.confidence, St.location, ...
        L.climate(i), L.N_0(i), L.pol(i), St.epsilon, St.sigma, St.mdvar, true, [], cc);
    q = info.delta_parts;
    dl = max(dl, abs(v - B.L_C2(i)));
    if ~strcmp(strjoin(string(q.edges_ba), ' '), E1.edges(i)), de = de + 1; end
    out(i, 1) = string(strtrim(sprintf('%d ', q.edges_ba)));
    out(i, 2) = string(strtrim(sprintf('%.17g ', q.nu_ba)));
    out(i, 3) = string(strtrim(sprintf('%.17g ', q.weight_ba)));
end
fprintf('loss vs B38 L_C2: %.3g dB; edge-index mismatches: %d\n', dl, de);
if dl > 1e-9 || de > 0, error('itmexp:d39', 'Rerun differs from B38.'); end
od = fullfile(root, 'experiments', 'D39-secondary-edges-canopy');
if ~isfolder(od), mkdir(od); end
T = table(B.link_id, out(:, 1), out(:, 2), out(:, 3), 'VariableNames', {'link_id', 'edges', 'nu', 'weights'});
writetable(T, fullfile(od, 'edges_rev2.csv'));
fprintf('wrote %d rows\n', n);
end
