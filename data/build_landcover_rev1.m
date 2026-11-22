function T = build_landcover_rev1(root)
%BUILD_LANDCOVER_REV1 Land cover at every Phase 2 terminal from USGS NLCD (approved by Nick 2026-11-22).
%   T = BUILD_LANDCOVER_REV1(root) reads the Phase 2 terminal coordinates in
%   data/profiles/profiles_index_rev1.csv, queries the MRLC GeoServer WCS for
%   a small window of land cover around each distinct point, and writes
%   data/landcover/phase2_terminals_nlcd_rev1.csv (one row per path and end)
%   with its .sha256.
%
%   Sources (public, USGS / MRLC, https://www.mrlc.gov):
%     NLCD 2001 Land Cover, CONUS, 30 m
%       coverage mrlc_download__NLCD_2001_Land_Cover_L48 (the earliest
%       legacy NLCD edition; the Phase 2 measurements are from the 1960s)
%     Annual NLCD land cover change count 1985-2023, Collection 1
%       coverage mrlc_download__Annual_NLCD_Smy_LndCov_ChgCnt_1985_2023_CU_C1V0
%       (number of land-cover changes at the pixel, used to flag cover that
%       changed since 1985)
%
%   Columns: path_id, end ("tx" or "rx"), lat, lon (as in the profile index),
%   nlcd2001 (class at the pixel), frac_forest_100m (classes 41, 42, 43, 90
%   within 100 m), frac_developed_100m (classes 22, 23, 24 within 100 m),
%   frac_valid_100m (share of window cells with a class), chgcnt_1985_2023
%   (at the pixel; NaN when the service returns no value).
%   Fails loud on a failed request or a point outside the coverage.
arguments
    root (1,1) string
end
idx = readtable(fullfile(root, 'data', 'profiles', 'profiles_index_rev1.csv'), 'TextType', 'string');
idx = idx(idx.dataset == "phase2", :);
ends = ["tx" "rx"];
pid = strings(0, 1); en = strings(0, 1); la = strings(0, 1); lo = strings(0, 1);
for k = 1:height(idx)
    for e = 1:2
        pid(end + 1, 1) = idx.path_id(k); en(end + 1, 1) = ends(e); %#ok<AGROW>
        la(end + 1, 1) = string(idx.(ends(e) + "_lat")(k)); lo(end + 1, 1) = string(idx.(ends(e) + "_lon")(k)); %#ok<AGROW>
    end
end
key = la + "," + lo;
[ukey, ~, ic] = unique(key);
n = numel(ukey);
cls = zeros(n, 1); ff = NaN(n, 1); fd = NaN(n, 1); fv = NaN(n, 1); cc = NaN(n, 1);
opts = weboptions('Timeout', 90);
tmp = [tempname '.tif'];
for k = 1:n
    p = double(split(ukey(k), ","));
    [A, R] = window('mrlc_download__NLCD_2001_Land_Cover_L48', p(1), p(2), tmp, opts);
    [r0, c0] = geographicToDiscrete(R, p(1), p(2));
    if isnan(r0) || A(r0, c0) == 0
        error('itmexp:landcover', 'No NLCD 2001 class at %s.', ukey(k));
    end
    cls(k) = double(A(r0, c0));
    [la_g, lo_g] = ndgrid(R.LatitudeLimits(2) - ((1:size(A, 1))' - 0.5) * R.CellExtentInLatitude, ...
        R.LongitudeLimits(1) + ((1:size(A, 2)) - 0.5) * R.CellExtentInLongitude);
    dist = distance(p(1), p(2), la_g, lo_g, wgs84Ellipsoid('m'));
    in = dist <= 100;
    v = A(in);
    fv(k) = mean(v > 0);
    v = v(v > 0);
    ff(k) = mean(ismember(v, [41 42 43 90]));
    fd(k) = mean(ismember(v, [22 23 24]));
    [B, RB] = window('mrlc_download__Annual_NLCD_Smy_LndCov_ChgCnt_1985_2023_CU_C1V0', p(1), p(2), tmp, opts);
    [r1, c1] = geographicToDiscrete(RB, p(1), p(2));
    if ~isnan(r1)
        cc(k) = double(B(r1, c1));
    end
end
T = table(pid, en, la, lo, cls(ic), ff(ic), fd(ic), fv(ic), cc(ic), 'VariableNames', ...
    ["path_id" "end" "lat" "lon" "nlcd2001" "frac_forest_100m" "frac_developed_100m" "frac_valid_100m" "chgcnt_1985_2023"]);
outdir = fullfile(root, 'data', 'landcover');
if ~isfolder(outdir), mkdir(outdir); end
f = fullfile(outdir, 'phase2_terminals_nlcd_rev1.csv');
writetable(T, f);
md = java.security.MessageDigest.getInstance('SHA-256');
fid = fopen(f); b = fread(fid, Inf, '*uint8'); fclose(fid); md.update(b);
writelines(string(sprintf('%02x', typecast(md.digest, 'uint8'))), fullfile(outdir, 'phase2_terminals_nlcd_rev1.sha256'));
end

function [A, R] = window(coverage, lat, lon, tmp, opts)
% About +/-280 m around the point, returned on geographic coordinates
d = 0.0025;
url = sprintf(['https://www.mrlc.gov/geoserver/ows?service=WCS&version=2.0.1&request=GetCoverage&coverageId=%s' ...
    '&subsettingCRS=http://www.opengis.net/def/crs/EPSG/0/4326&subset=Lat(%.6f,%.6f)&subset=Long(%.6f,%.6f)&format=image/geotiff'], ...
    coverage, lat - d, lat + d, lon - d, lon + d);
websave(tmp, url, opts);
[A, R] = readgeoraster(tmp);
end
