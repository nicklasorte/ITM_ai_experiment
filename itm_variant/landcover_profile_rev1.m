function cls = landcover_profile_rev1(path_id, n_samples)
%LANDCOVER_PROFILE_REV1 NLCD 2001 class at every sample of a Phase 2 terrain profile (B17).
%   cls = LANDCOVER_PROFILE_REV1(path_id, n_samples) returns a column of
%   NLCD 2001 classes, one per profile sample (transmitter = sample 1), for
%   Phase 2 path path_id, read from the run-length encoded
%   data/landcover/phase2_profiles_nlcd_rev1.csv (built by
%   data/build_landcover_profiles_rev1.m, merged as PR #10; checked against
%   its .sha256 on first use). n_samples is the length of the profile used;
%   it must equal the encoded length.
%   Fails loud when the file, its hash, the path, or the length don't match.
arguments
    path_id (1,1) string
    n_samples (1,1) double {mustBeInteger, mustBePositive}
end
persistent T
if isempty(T)
    P = itm_exp_paths_rev1();
    f = fullfile(P.root, 'data', 'landcover', 'phase2_profiles_nlcd_rev1.csv');
    h = fullfile(P.root, 'data', 'landcover', 'phase2_profiles_nlcd_rev1.sha256');
    if ~isfile(f) || ~isfile(h)
        error('itmexp:landcover', 'Profile land cover file missing: %s.', f);
    end
    md = java.security.MessageDigest.getInstance('SHA-256');
    fid = fopen(f); b = fread(fid, Inf, '*uint8'); fclose(fid); md.update(b);
    if string(sprintf('%02x', typecast(md.digest, 'uint8'))) ~= strtrim(string(fileread(h)))
        error('itmexp:landcover', 'data/landcover/phase2_profiles_nlcd_rev1.csv does not match its hash.');
    end
    T = readtable(f, 'TextType', 'string');
end
k = find(T.path_id == path_id);
if isempty(k)
    error('itmexp:landcover', 'No profile land cover for %s.', path_id);
end
R = T(k, :);
if R.i_first(1) ~= 1 || any(R.i_first(2:end) ~= R.i_last(1:end - 1) + 1) || R.i_last(end) ~= n_samples
    error('itmexp:landcover', 'Land cover runs of %s don''t cover samples 1..%d exactly.', path_id, n_samples);
end
cls = repelem(R.nlcd2001, R.i_last - R.i_first + 1);
end
