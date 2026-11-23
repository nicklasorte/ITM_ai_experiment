function T = build_landcover_profiles_rev1(root)
%BUILD_LANDCOVER_PROFILES_REV1 NLCD 2001 class at every profile sample of every Phase 2 path (proposed in PR, B17).
%   T = BUILD_LANDCOVER_PROFILES_REV1(root) reads the Phase 2 paths in
%   data/profiles/profiles_index_rev1.csv, places the profile's samples on
%   the great circle from transmitter to receiver (n_points samples, the
%   transmitter first, as the profile files are), requests one land-cover
%   window per path from the MRLC GeoServer WCS covering the path's bounding
%   box, and takes the class of the pixel under each sample. It writes
%   data/landcover/phase2_profiles_nlcd_rev1.csv, run-length encoded (one
%   row per run of equal class along a path), and its .sha256.
%
%   Source (public, USGS / MRLC, https://www.mrlc.gov): NLCD 2001 Land
%   Cover, CONUS, 30 m, coverage mrlc_download__NLCD_2001_Land_Cover_L48,
%   the edition and service already approved for the terminal file
%   (build_landcover_rev1.m, PR #6). The Phase 2 measurements are from the
%   1960s, so the earliest legacy edition is used; land cover can have
%   changed since (PR #6 records the 1985-2023 change count at terminals).
%
%   Purpose: path vegetation (ITU-R P.833) on terrain-clear Phase 2 rows,
%   batch B17. The file is an input; no model reads it until a batch plan
%   registers a switch that does.
%
%   Columns: path_id, i_first, i_last (1-based sample indices, inclusive,
%   transmitter = 1), nlcd2001 (class; 0 where the service returns no
%   class). Every sample of every path is covered exactly once; the build
%   checks this and fails loud on a failed request, a path outside the
%   coverage, or a gap.
arguments
    root (1,1) string
end
idx = readtable(fullfile(root, 'data', 'profiles', 'profiles_index_rev1.csv'), 'TextType', 'string');
idx = idx(idx.dataset == "phase2", :);
opts = weboptions('Timeout', 180);
tmp = [tempname '.tif'];
pid = strings(0, 1); i1 = zeros(0, 1); i2 = zeros(0, 1); cl = zeros(0, 1);
wgs = wgs84Ellipsoid('m');
for k = 1:height(idx)
    n = idx.n_points(k);
    [la, lo] = track2('gc', idx.tx_lat(k), idx.tx_lon(k), idx.rx_lat(k), idx.rx_lon(k), wgs, 'degrees', n);
    pad = 0.003;                                   % about 300 m beyond the path ends
    [A, R] = window(min(la) - pad, max(la) + pad, min(lo) - pad, max(lo) + pad, tmp, opts);
    [r, c] = geographicToDiscrete(R, la, lo);
    if any(isnan(r)) || any(isnan(c))
        error('itmexp:landcover', 'Path %s has samples outside the returned NLCD window.', idx.path_id(k));
    end
    v = double(A(sub2ind(size(A), r, c)));
    edges = [1; find(diff(v) ~= 0) + 1; n + 1];
    for j = 1:numel(edges) - 1
        pid(end + 1, 1) = idx.path_id(k); i1(end + 1, 1) = edges(j); %#ok<AGROW>
        i2(end + 1, 1) = edges(j + 1) - 1; cl(end + 1, 1) = v(edges(j)); %#ok<AGROW>
    end
    if mod(k, 50) == 0, fprintf('%d of %d paths\n', k, height(idx)); end
end
T = table(pid, i1, i2, cl, 'VariableNames', ["path_id" "i_first" "i_last" "nlcd2001"]);
% Coverage check: each path's runs tile 1..n_points exactly
for k = 1:height(idx)
    q = T(T.path_id == idx.path_id(k), :);
    if q.i_first(1) ~= 1 || q.i_last(end) ~= idx.n_points(k) || any(q.i_first(2:end) ~= q.i_last(1:end - 1) + 1)
        error('itmexp:landcover', 'Runs for %s don''t tile the profile.', idx.path_id(k));
    end
end
outdir = fullfile(root, 'data', 'landcover');
if ~isfolder(outdir), mkdir(outdir); end
f = fullfile(outdir, 'phase2_profiles_nlcd_rev1.csv');
writetable(T, f);
md = java.security.MessageDigest.getInstance('SHA-256');
fid = fopen(f); b = fread(fid, Inf, '*uint8'); fclose(fid); md.update(b);
writelines(string(sprintf('%02x', typecast(md.digest, 'uint8'))), fullfile(outdir, 'phase2_profiles_nlcd_rev1.sha256'));
fprintf('wrote %s: %d runs over %d paths; %d samples with no class\n', f, height(T), height(idx), ...
    sum((T.i_last - T.i_first + 1) .* (T.nlcd2001 == 0)));
end

function [A, R] = window(lat1, lat2, lon1, lon2, tmp, opts)
% Land cover over a latitude-longitude box, on geographic coordinates
url = sprintf(['https://www.mrlc.gov/geoserver/ows?service=WCS&version=2.0.1&request=GetCoverage' ...
    '&coverageId=mrlc_download__NLCD_2001_Land_Cover_L48' ...
    '&subsettingCRS=http://www.opengis.net/def/crs/EPSG/0/4326&subset=Lat(%.6f,%.6f)&subset=Long(%.6f,%.6f)&format=image/geotiff'], ...
    lat1, lat2, lon1, lon2);
% The service occasionally returns an unreadable response (seen once in
% 515 requests, 2026-11-23); retry up to three times, then fail loud.
for attempt = 1:3
    try
        websave(tmp, url, opts);
        [A, R] = readgeoraster(tmp);
        return
    catch err
        if attempt == 3
            error('itmexp:landcover', 'MRLC request failed three times: %s (%s)', err.message, url);
        end
        pause(5 * attempt);
    end
end
end
