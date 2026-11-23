function T = build_refractivity_rev1(root, p452_dir)
%BUILD_REFRACTIVITY_REV1 Refractivity lapse rate dN and N_0 at every path midpoint (proposed in PR, B14).
%   T = BUILD_REFRACTIVITY_REV1(root, p452_dir) reads the path midpoints in
%   data/profiles/profiles_index_rev1.csv (both data sets), looks up the
%   ITU-R digital maps DN50.TXT (dN, average annual radio-refractivity lapse
%   rate through the lowest 1 km, N-units/km) and N050.TXT (N_0, sea-level
%   surface refractivity) at each midpoint, and writes
%   data/links/path_refractivity_rev1.csv with its .sha256.
%
%   Source: ITU-R P.617-6 section 4.1 step 1 and Table 1 (files N050.txt and
%   DN50.txt, 1.5 degree grid, which originate from ITU-R P.452). Lookup by
%   bilinear interpolation with the edge handling of the ITU-R P.452
%   reference implementation, through p452_refractivity_rev1 in Nick's
%   matlab_itu_p452 (p452_dir). The maps themselves aren't copied into this
%   repo: the ITU doesn't allow redistributing its digital products. Only
%   the per-path values derived from them are written, as with the existing
%   N_0 column.
%
%   P.617-6 asks for the values at the troposcatter common volume. The path
%   midpoint is used, as for N_0; on the 1.5 degree grid the two differ
%   little on paths of a few hundred km.
%
%   Columns: path_id, dataset, mid_lat, mid_lon (from the profile index),
%   dN (N-units/km), N0_map (N-units), N_0_index (the index's N_0, for
%   comparison). Fails loud if the map lookup returns a non-finite value.
arguments
    root (1,1) string
    p452_dir (1,1) string
end
if ~isfile(fullfile(p452_dir, 'p452_refractivity_rev1.m'))
    error('build:refractivity', 'p452_refractivity_rev1.m not found in %s.', p452_dir);
end
addpath(p452_dir);
cleanup = onCleanup(@() rmpath(p452_dir));
idx = readtable(fullfile(root, 'data', 'profiles', 'profiles_index_rev1.csv'), 'TextType', 'string');
[dN, N0] = p452_refractivity_rev1(idx.mid_lat, idx.mid_lon);
if ~all(isfinite(dN)) || ~all(isfinite(N0))
    error('build:refractivity', 'Non-finite map value at %d midpoints.', nnz(~isfinite(dN) | ~isfinite(N0)));
end
T = table(idx.path_id, idx.dataset, idx.mid_lat, idx.mid_lon, round(dN, 4), round(N0, 4), idx.N_0, ...
    'VariableNames', {'path_id', 'dataset', 'mid_lat', 'mid_lon', 'dN', 'N0_map', 'N_0_index'});
out = fullfile(root, 'data', 'links', 'path_refractivity_rev1.csv');
writetable(T, out);
h = sha256_file(out);
fid = fopen(out + ".sha256", 'w');
fprintf(fid, '%s  path_refractivity_rev1.csv\n', h);
fclose(fid);
fprintf('wrote %s: %d paths; dN %.1f to %.1f; max |N0_map - N_0_index| %.2f\n', out, height(T), ...
    min(dN), max(dN), max(abs(N0 - idx.N_0)));
end

function h = sha256_file(p)
md = java.security.MessageDigest.getInstance('SHA-256');
fid = fopen(p, 'r');
b = fread(fid, Inf, '*uint8');
fclose(fid);
md.update(b);
h = sprintf('%02x', typecast(md.digest, 'uint8'));
end
