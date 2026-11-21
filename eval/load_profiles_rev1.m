function profiles = load_profiles_rev1(root)
%LOAD_PROFILES_REV1 Load the canonical terrain profiles from data/profiles. Read-only.
%   profiles = LOAD_PROFILES_REV1(root) reads data/profiles/profiles_index_rev1.csv
%   and one CSV of elevations per path (data/profiles/<dataset>/<path_id>.csv,
%   one elevation in metres per line, transmitter first, equal spacing) and
%   returns a struct array with fields path_id, dataset, d_km, h_m,
%   spacing_m, midpoint_deg, tx, rx, climate, N_0.
%
%   The CSVs are the source of truth for terrain: no terrain tiles are
%   needed to reproduce any result. Each file's SHA-256 is checked against
%   the index. A MAT copy is cached in data/cache/, keyed by the index hash.

idx_file = fullfile(root, 'data', 'profiles', 'profiles_index_rev1.csv');
if ~isfile(idx_file)
    error('itmexp:profiles', 'No profile index at %s. Run data/export_profiles_rev1 first.', idx_file);
end
key = file_sha256(idx_file);
cache = fullfile(root, 'data', 'cache', "profiles_csv_" + extractBefore(key, 13) + ".mat");
if isfile(cache)
    C = load(cache); profiles = C.profiles; return
end
I = readtable(idx_file, 'TextType', 'string');
n = height(I);
profiles = repmat(struct('path_id', "", 'dataset', "", 'd_km', 0, 'h_m', [], 'spacing_m', 0, ...
    'midpoint_deg', [0 0], 'tx', [0 0], 'rx', [0 0], 'climate', 0, 'N_0', 0), 1, n);
for k = 1:n
    f = fullfile(root, 'data', 'profiles', I.dataset(k), I.path_id(k) + ".csv");
    if file_sha256(f) ~= I.sha256(k)
        error('itmexp:profiles', 'Profile %s does not match its hash in the index.', I.path_id(k));
    end
    h = readmatrix(f, 'NumHeaderLines', 1);
    if numel(h) ~= I.n_points(k)
        error('itmexp:profiles', 'Profile %s has %d points; the index says %d.', I.path_id(k), numel(h), I.n_points(k));
    end
    profiles(k) = struct('path_id', I.path_id(k), 'dataset', I.dataset(k), 'd_km', I.d_km(k), 'h_m', h(:), ...
        'spacing_m', I.spacing_m(k), 'midpoint_deg', [I.mid_lat(k) I.mid_lon(k)], 'tx', [I.tx_lat(k) I.tx_lon(k)], ...
        'rx', [I.rx_lat(k) I.rx_lon(k)], 'climate', I.climate(k), 'N_0', I.N_0(k));
end
if ~isfolder(fileparts(cache)), mkdir(fileparts(cache)); end
save(cache, 'profiles');
end

function h = file_sha256(f)
fid = fopen(f, 'r'); c = onCleanup(@() fclose(fid));
b = fread(fid, Inf, '*uint8');
md = java.security.MessageDigest.getInstance('SHA-256'); md.update(b);
h = string(sprintf('%02x', typecast(md.digest(), 'uint8')));
end
