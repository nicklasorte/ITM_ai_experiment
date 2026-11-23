function dN = refractivity_lookup_rev1(path_id)
%REFRACTIVITY_LOOKUP_REV1 Refractivity lapse rate dN at a path midpoint (N-units/km).
%   dN = REFRACTIVITY_LOOKUP_REV1(path_id) returns dN for the path from
%   data/links/path_refractivity_rev1.csv (ITU-R P.617-6 Table 1 file
%   DN50.txt at the path midpoint; built by data/build_refractivity_rev1.m).
%   The file's SHA-256 is checked against its .sha256 on first use. An
%   unknown path_id is an error.
%
%   dN = REFRACTIVITY_LOOKUP_REV1("") returns the mean dN of the long-term
%   paths, for synthetic paths with no location (the physics battery).
arguments
    path_id (1,1) string
end
persistent map mean_lt
if isempty(map)
    root = fileparts(fileparts(mfilename('fullpath')));
    f = fullfile(root, 'data', 'links', 'path_refractivity_rev1.csv');
    if ~isfile(f)
        error('itmexp:data', ['%s is missing. It comes from the data/ PR that adds dN ' ...
            '(build_refractivity_rev1.m); merge it before using P.617 switches.'], f);
    end
    want = strtok(strtrim(fileread(f + ".sha256")));
    md = java.security.MessageDigest.getInstance('SHA-256');
    fid = fopen(f, 'r');
    b = fread(fid, Inf, '*uint8');
    fclose(fid);
    md.update(b);
    got = sprintf('%02x', typecast(md.digest, 'uint8'));
    if ~strcmp(got, want)
        error('itmexp:data', 'SHA-256 of %s doesn''t match its .sha256.', f);
    end
    T = readtable(f, 'TextType', 'string', 'VariableNamingRule', 'preserve');
    map = containers.Map(cellstr(T.path_id), num2cell(T.dN));
    mean_lt = mean(T.dN(T.dataset == "longterm"));
end
if path_id == ""
    dN = mean_lt;
    return
end
if ~isKey(map, char(path_id))
    error('itmexp:data', 'No dN for path "%s" in path_refractivity_rev1.csv.', path_id);
end
dN = map(char(path_id));
end
