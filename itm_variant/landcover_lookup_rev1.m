function [cls, ctype] = landcover_lookup_rev1(path_id, end_name)
%LANDCOVER_LOOKUP_REV1 NLCD 2001 class at a Phase 2 terminal and its ITU-R P.2108 clutter category (B11).
%   [cls, ctype] = LANDCOVER_LOOKUP_REV1(path_id, end_name) returns the NLCD
%   2001 class at the pixel of terminal end_name ("tx" or "rx") of path
%   path_id, read from data/landcover/phase2_terminals_nlcd_rev1.csv (built
%   by data/build_landcover_rev1.m; checked against its .sha256 on first
%   use), and the P.2108-1 Table 3 category it maps to:
%     41, 42, 43 (forest), 90 (woody wetlands)  -> "trees_forest"
%     22 (developed, low intensity)             -> "suburban"
%     23 (developed, medium intensity)          -> "urban"
%     24 (developed, high intensity)            -> "dense_urban"
%     anything else                             -> "" (no terminal clutter)
%   The mapping was fixed before the land cover was extracted or any error
%   examined (LOG, B11 planned). Fails loud when the file, its hash, or the
%   row is missing.
persistent T
if isempty(T)
    P = itm_exp_paths_rev1();
    f = fullfile(P.root, 'data', 'landcover', 'phase2_terminals_nlcd_rev1.csv');
    h = fullfile(P.root, 'data', 'landcover', 'phase2_terminals_nlcd_rev1.sha256');
    if ~isfile(f) || ~isfile(h)
        error('itmexp:landcover', 'Land cover file missing: %s (build with data/build_landcover_rev1.m).', f);
    end
    md = java.security.MessageDigest.getInstance('SHA-256');
    fid = fopen(f); b = fread(fid, Inf, '*uint8'); fclose(fid); md.update(b);
    if string(sprintf('%02x', typecast(md.digest, 'uint8'))) ~= strtrim(string(fileread(h)))
        error('itmexp:landcover', 'data/landcover/phase2_terminals_nlcd_rev1.csv does not match its hash.');
    end
    T = readtable(f, 'TextType', 'string', 'VariableNamingRule', 'preserve');
end
k = find(T.path_id == path_id & T.("end") == end_name);
if numel(k) ~= 1
    error('itmexp:landcover', 'No unique land cover row for %s, end %s.', path_id, end_name);
end
cls = T.nlcd2001(k);
switch cls
    case {41, 42, 43, 90}
        ctype = "trees_forest";
    case 22
        ctype = "suburban";
    case 23
        ctype = "urban";
    case 24
        ctype = "dense_urban";
    otherwise
        ctype = "";
end
end
