function [P, D] = p2_read(root, s, va)
%P2_READ Read an ITS Phase 2 path file and data file.
%   Copied from read_set in nicklasorte/matlab_itm
%   docs/model_comparison/compare_its_phase2_rev1.m (commit 9bd6a4e).
fid = fopen(fullfile(root, s + "path.txt")); c = onCleanup(@() fclose(fid));
if va
    x = textscan(fid, '%s %f %f %f %f %f', 'HeaderLines', 1);
    P = table(string(x{1}), strings(numel(x{1}), 1), x{2}, x{3}, x{4}, x{5}, x{6}, ...
        'VariableNames', {'path', 'site', 'xlat', 'xlon', 'rlat', 'rlon', 'dist'});
else
    x = textscan(fid, '%s %s %f %f %f %f %f', 'HeaderLines', 1);
    P = table(string(x{1}), string(x{2}), x{3}, x{4}, x{5}, x{6}, x{7}, ...
        'VariableNames', {'path', 'site', 'xlat', 'xlon', 'rlat', 'rlon', 'dist'});
end
fid2 = fopen(fullfile(root, s + "data.txt")); c2 = onCleanup(@() fclose(fid2));
if va
    x = textscan(fid2, ['%s %f %s %f %s' repmat(' %f', 1, 7)], 'HeaderLines', 2);
    D = table(string(x{1}), x{2}, string(x{3}), x{4}, string(x{5}), [x{6:12}], ...
        'VariableNames', {'path', 'run', 'siting', 'rcvr', 'rht', 'A'});
else
    x = textscan(fid2, ['%s %f %s %f' repmat(' %f', 1, 7)], 'HeaderLines', 2);
    D = table(string(x{1}), x{2}, string(x{3}), x{4}, [x{5:11}], ...
        'VariableNames', {'path', 'run', 'siting', 'rht', 'A'});
end
end
