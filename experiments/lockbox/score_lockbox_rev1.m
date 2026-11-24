function T = score_lockbox_rev1(links_csv, profile_index_csv, profile_dir, out_dir, options)
%SCORE_LOCKBOX_REV1 Run one lockbox panel model on one link table (for Nick).
%   T = SCORE_LOCKBOX_REV1(links_csv, profile_index_csv, profile_dir,
%   out_dir, Model="707") runs the ITM variant on every row of links_csv at
%   50 % time and writes out_dir/<set name>_<Model>_rev1.csv and a
%   matching _meta.json. It implements LOCKBOX_REGISTRATION_rev2.md,
%   sections 2 and 3. Nick runs it; the agent never runs it on lockbox data.
%
%   Run it once per model, from the commit the registration names:
%     707   best 2baa02b, ITMEXP_OVERRIDES unset
%     R03   best 2baa02b, ITMEXP_OVERRIDES = {"diffraction":"delta_bullington"}
%     R02   main e76ca9d, ITMEXP_OVERRIDES unset; cal.time_minus_scale = 0.8
%           is set here (cal can't be overridden by JSON)
%   Stock ITM and the P.452 and P.2001 references are read from the link
%   table's itm_lb_50, p452_lb_50 and p2001_lb_50 columns, not run here.
%
%   links_csv: the converted lockbox link table, same columns as
%     data/links/phase2_links_rev1.csv. Required: link_id, path_id, f_mhz,
%     htx_m, hrx_m, pol, climate, N_0, meas_lb_db, itm_lb_50. Optional:
%     censored (default 0), site (used for the site-cluster bootstrap),
%     itm_error, p452_lb_50, p2001_lb_50.
%   profile_index_csv: path_id, n_points, spacing_m and optionally sha256,
%     as data/profiles/profiles_index_rev1.csv.
%   profile_dir: folder with <path_id>.csv, one column h_m (30 m spacing).
%
%   Every row runs with cfg.row.set = "" and siting = "", so the P.2108-1
%   terminal clutter term is zero (registration section 3).
%
%   Options:
%     Model     "707" | "R03" | "R02"
%     SetName   label for the output files (default: links_csv's name)
%     TestOnly  false. true skips the commit and override checks and marks
%               the output TEST; for checking the scorer on development
%               rows only. A TEST file is never a lockbox result.

arguments
    links_csv (1,1) string
    profile_index_csv (1,1) string
    profile_dir (1,1) string
    out_dir (1,1) string
    options.Model (1,1) string {mustBeMember(options.Model, ["707" "R03" "R02"])} = "707"
    options.SetName (1,1) string = ""
    options.TestOnly (1,1) logical = false
end

% Registration section 2: commit and overrides per model
want_commit = struct('m707', "2baa02b", 'mR03', "2baa02b", 'mR02', "e76ca9d");
want_ovr = struct('m707', "", 'mR03', '{"diffraction":"delta_bullington"}', 'mR02', "");
key = "m" + options.Model;

P = itm_exp_paths_rev1();
S = settings_rev1();
head = git_head_rev1(P.root);
ovr = string(getenv('ITMEXP_OVERRIDES'));
if ~options.TestOnly
    if head ~= want_commit.(key)
        error('lockbox:commit', 'Model %s runs from %s; this checkout is at %s.', ...
            options.Model, want_commit.(key), head);
    end
    if strtrim(ovr) ~= want_ovr.(key)
        error('lockbox:overrides', 'Model %s needs ITMEXP_OVERRIDES = ''%s''; it is ''%s''.', ...
            options.Model, want_ovr.(key), ovr);
    end
end

cfg = params_exp();
if options.Model == "R02"
    cfg.cal.time_minus_scale = 0.8;   % R02's fitted constant, all five folds (params_by_fold.csv)
end

% Links
L = readtable(links_csv, 'TextType', 'string');
need = ["link_id" "path_id" "f_mhz" "htx_m" "hrx_m" "pol" "climate" "N_0" "meas_lb_db" "itm_lb_50"];
miss = need(~ismember(need, string(L.Properties.VariableNames)));
if ~isempty(miss)
    error('lockbox:columns', '%s lacks columns: %s.', links_csv, strjoin(miss, ', '));
end
if ~ismember('censored', L.Properties.VariableNames), L.censored = zeros(height(L), 1); end
if ismember('itm_error', L.Properties.VariableNames) && ~isnumeric(L.itm_error)
    bad = ~(ismissing(L.itm_error) | L.itm_error == "");
    if any(bad)
        fprintf('Leaving out %d rows where stock ITM returned an error (as the evaluator does).\n', nnz(bad));
        L = L(~bad, :);
    end
end

% Profiles
I = readtable(profile_index_csv, 'TextType', 'string');
[~, ip] = ismember(L.path_id, I.path_id);
if any(ip == 0)
    error('lockbox:profiles', 'No profile index entry for %d rows (first: %s).', nnz(ip == 0), ...
        L.path_id(find(ip == 0, 1)));
end
up = unique(ip);
H = cell(height(I), 1);
for k = up(:)'
    f = fullfile(profile_dir, I.path_id(k) + ".csv");
    if ismember('sha256', I.Properties.VariableNames) && sha256_file(f) ~= I.sha256(k)
        error('lockbox:profiles', 'Profile %s does not match its hash in the index.', I.path_id(k));
    end
    h = readmatrix(f, 'NumHeaderLines', 1);
    if numel(h) ~= I.n_points(k)
        error('lockbox:profiles', 'Profile %s has %d points; the index says %d.', I.path_id(k), numel(h), I.n_points(k));
    end
    H{k} = h(:);
end

% Rows (registration section 3: no siting, so no terminal clutter)
pred = NaN(height(L), 1);
for i = 1:height(L)
    k = ip(i);
    pfl = [numel(H{k}) - 1; I.spacing_m(k); H{k}];
    c = cfg;
    c.row = struct('set', "", 'siting', "", 'reversed', false, 'path_id', L.path_id(i));
    a = itm_p2p_core_exp(L.htx_m(i), L.hrx_m(i), pfl, L.f_mhz(i), 50, S.confidence, S.location, ...
        L.climate(i), L.N_0(i), L.pol(i), S.epsilon, S.sigma, S.mdvar, false, [], c);
    if ~isscalar(a) || ~isfinite(a) || ~isreal(a)
        error('lockbox:nonfinite', 'Model %s returned a non-finite or complex loss on %s.', options.Model, L.link_id(i));
    end
    pred(i) = a;
end

% Output
if options.SetName == "", [~, sn] = fileparts(links_csv); else, sn = options.SetName; end
tag = sn + "_" + options.Model + "_rev1";
if options.TestOnly, tag = "TEST_" + tag; end
if ~isfolder(out_dir), mkdir(out_dir); end
cols = intersect(["link_id" "path_id" "set" "site" "f_mhz" "d_km" "htx_m" "hrx_m" "censored" "meas_lb_db" ...
    "itm_lb_50" "p452_lb_50" "p2001_lb_50"], string(L.Properties.VariableNames), 'stable');
T = L(:, cols);
T.model_lb_50 = pred;
writetable(T, fullfile(out_dir, tag + ".csv"));
meta = struct('model', options.Model, 'set_name', sn, 'test_only', options.TestOnly, ...
    'itm_ai_experiment_head', head, 'itm_exp_overrides', ovr, 'cfg', cfg, ...
    'matlab_itm', P.itm_head, 'links_csv', links_csv, 'links_sha256', sha256_file(links_csv), ...
    'scorer_md5', md5_file(string(mfilename('fullpath')) + ".m"), 'n_rows', height(T), ...
    'run_at', string(datetime('now', 'TimeZone', 'local')), 'matlab', string(version));
writelines(jsonencode(meta, 'PrettyPrint', true), fullfile(out_dir, tag + "_meta.json"));
fprintf('%s: %d rows written to %s\n', tag, height(T), out_dir);
end

function h = sha256_file(f)
h = digest_file(f, 'SHA-256');
end

function h = md5_file(f)
h = digest_file(f, 'MD5');
end

function h = digest_file(f, alg)
fid = fopen(f, 'r');
if fid < 0, error('lockbox:file', 'Cannot open %s.', f); end
b = fread(fid, Inf, '*uint8'); fclose(fid);
md = java.security.MessageDigest.getInstance(alg);
md.update(b);
h = string(lower(reshape(dec2hex(typecast(md.digest(), 'uint8'))', 1, [])));
end
