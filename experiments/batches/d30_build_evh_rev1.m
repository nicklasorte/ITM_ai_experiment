function T = d30_build_evh_rev1(root, options)
%D30_BUILD_EVH_REV1 LANDFIRE 2016 Remap EVH code at every sample of every Phase 2 profile (B30, diagnostic).
%   T = D30_BUILD_EVH_REV1(root) places each Phase 2 profile's samples on the
%   great circle from transmitter to receiver (n_points samples, transmitter
%   first, as data/build_landcover_profiles_rev1.m does), requests one EVH
%   window per path from the USGS LANDFIRE image service, and takes the code
%   of the nearest pixel under each sample. It writes
%   experiments/D30-landfire-evh/phase2_profiles_evh_rev1.csv, run-length
%   encoded (path_id, i_first, i_last, evh_code), and its .sha256.
%
%   T = D30_BUILD_EVH_REV1(root, Paths=ids) builds only the listed paths and
%   writes nothing (smoke check).
%
%   Source (public, USGS / LANDFIRE): LF2016 Remap Existing Vegetation
%   Height, CONUS, 30 m, ImageServer
%   https://lfps.usgs.gov/arcgis/rest/services/Landfire_LF2016/LF2016_EVH_CONUS/ImageServer
%   Codes: LF2016 Remap EVH data dictionary (101-199 tree height = code-100 m;
%   201-230 shrub = (code-200)/10 m; 301-310 herb = (code-300)/10 m).
%
%   Fails loud on a failed request, a sample outside the returned window, or
%   a path whose runs don't tile its profile.
arguments
    root (1,1) string
    options.Paths (1,:) string = strings(1, 0)
end
idx = readtable(fullfile(root, 'data', 'profiles', 'profiles_index_rev1.csv'), 'TextType', 'string');
idx = idx(idx.dataset == "phase2", :);
smoke = ~isempty(options.Paths);
if smoke
    idx = idx(ismember(idx.path_id, options.Paths), :);
    if height(idx) ~= numel(options.Paths)
        error('itmexp:evh', 'Some requested paths are not Phase 2 paths.');
    end
end
opts = weboptions('Timeout', 180);
tmp = [tempname '.tif'];
pid = strings(0, 1); i1 = zeros(0, 1); i2 = zeros(0, 1); cl = zeros(0, 1);
wgs = wgs84Ellipsoid('m');
for k = 1:height(idx)
    n = idx.n_points(k);
    [la, lo] = track2('gc', idx.tx_lat(k), idx.tx_lon(k), idx.rx_lat(k), idx.rx_lon(k), wgs, 'degrees', n);
    pad = 0.003;                                   % about 300 m beyond the sample box
    % Long paths are split into chunks of samples so each window stays
    % under 3,000 pixels on a side at 1 arc-second.
    span = max(max(la) - min(la), max(lo) - min(lo)) * 3600;
    nchunk = max(1, ceil(span / 3000));
    cut = round(linspace(0, n, nchunk + 1));
    v = nan(n, 1);
    for q = 1:nchunk
        ii = cut(q) + 1:cut(q + 1);
        [A, R] = window(min(la(ii)) - pad, max(la(ii)) + pad, min(lo(ii)) - pad, max(lo(ii)) + pad, tmp, opts);
        [r, c] = geographicToDiscrete(R, la(ii), lo(ii));
        if any(isnan(r)) || any(isnan(c))
            error('itmexp:evh', 'Path %s has samples outside the returned EVH window.', idx.path_id(k));
        end
        v(ii) = double(A(sub2ind(size(A), r, c)));
    end
    if any(isnan(v))
        error('itmexp:evh', 'Path %s has unsampled points.', idx.path_id(k));
    end
    edges = [1; find(diff(v) ~= 0) + 1; n + 1];
    for j = 1:numel(edges) - 1
        pid(end + 1, 1) = idx.path_id(k); i1(end + 1, 1) = edges(j); %#ok<AGROW>
        i2(end + 1, 1) = edges(j + 1) - 1; cl(end + 1, 1) = v(edges(j)); %#ok<AGROW>
    end
    if mod(k, 50) == 0, fprintf('%d of %d paths\n', k, height(idx)); end
end
T = table(pid, i1, i2, cl, 'VariableNames', ["path_id" "i_first" "i_last" "evh_code"]);
for k = 1:height(idx)
    q = T(T.path_id == idx.path_id(k), :);
    if q.i_first(1) ~= 1 || q.i_last(end) ~= idx.n_points(k) || any(q.i_first(2:end) ~= q.i_last(1:end - 1) + 1)
        error('itmexp:evh', 'Runs for %s don''t tile the profile.', idx.path_id(k));
    end
end
if smoke
    return
end
outdir = fullfile(root, 'experiments', 'D30-landfire-evh');
if ~isfolder(outdir), mkdir(outdir); end
f = fullfile(outdir, 'phase2_profiles_evh_rev1.csv');
writetable(T, f);
md = java.security.MessageDigest.getInstance('SHA-256');
fid = fopen(f); b = fread(fid, Inf, '*uint8'); fclose(fid); md.update(b);
writelines(string(sprintf('%02x', typecast(md.digest, 'uint8'))), fullfile(outdir, 'phase2_profiles_evh_rev1.sha256'));
fprintf('wrote %s: %d runs over %d paths\n', f, height(T), height(idx));
end

function [A, R] = window(lat1, lat2, lon1, lon2, tmp, opts)
% EVH over a latitude-longitude box, resampled by nearest neighbor onto a
% geographic grid of about 1 arc-second (finer than the 30 m source, so
% each source pixel is kept).
d = 1 / 3600;
w = max(2, ceil((lon2 - lon1) / d)); h = max(2, ceil((lat2 - lat1) / d));
if w > 4000 || h > 4000
    error('itmexp:evh', 'Window %d x %d exceeds the service limit.', w, h);
end
url = sprintf(['https://lfps.usgs.gov/arcgis/rest/services/Landfire_LF2016/LF2016_EVH_CONUS/ImageServer/exportImage' ...
    '?bbox=%.6f,%.6f,%.6f,%.6f&bboxSR=4326&imageSR=4326&size=%d,%d&format=tiff&pixelType=S16' ...
    '&interpolation=RSP_NearestNeighbor&noData=-9999&f=image'], lon1, lat1, lon2, lat2, w, h);
for attempt = 1:3
    try
        websave(tmp, url, opts);
        [A, R] = readgeoraster(tmp);
        if isempty(A), error('itmexp:evh', 'empty raster'); end
        return
    catch e
        if attempt == 3
            error('itmexp:evh', 'EVH request failed three times: %s', e.message);
        end
        pause(2 * attempt);
    end
end
end
