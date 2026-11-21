function [fn, v, why] = p2_profile(root, s, pth, site, va, dlist)
%P2_PROFILE Find, read, and check the surveyed profile for an ITS Phase 2 path.
%   Logic copied from profile_name, read_pfl, and the profile checks in
%   nicklasorte/matlab_itm docs/model_comparison/compare_its_phase2_rev1.m
%   (commit 9bd6a4e). v is [distance_km, elevation_m], transmitter first.
%   why is "" when the profile is usable, else the reason it is left out.
fn = ""; v = zeros(0, 2); why = "";
p = split(pth, "-");
nom = replace(p(2), "_", "'");
d = fullfile(root, s + "_pfl");
if va
    cand = lower(nom + p(1) + p(3));
else
    num = extractAfter(p(3), 1);
    switch site
        case "C", cand = lower(nom + p(1) + "c" + num);
        case "A", cand = lower(nom + p(1) + "a" + num);
        otherwise, cand = [lower(nom + p(1) + "o" + num), lower(nom + p(1) + "t" + num)];
    end
end
for c = cand
    f = fullfile(d, c + ".pfl");
    if isfile(f), fn = string(f); break, end
end
if strlength(fn) == 0
    why = "no profile";
    return
end
[h, v] = read_pfl(fn);
if any(isnan(h(1:4))) || size(v, 1) < 2
    why = "unreadable profile";
    return
end
if h(5) == 1
    v = [v(end, 1) - flipud(v(:, 1)), flipud(v(:, 2))];   % transmitter first
end
if abs(v(end, 1) - dlist) > max(0.05 * dlist, 0.05)
    why = "profile length";
end
end

function [h, v] = read_pfl(fn)
txt = splitlines(string(fileread(fn)));
h = NaN(1, 5); v = zeros(0, 2);
for i = 1:numel(txt)
    t = txt(i);
    if startsWith(t, "TX CNTRY") || startsWith(t, "RX CNTRY")
        x = sscanf(char(extractAfter(t, 11)), '%f %f');
        if numel(x) == 2
            j = 1 + 2 * startsWith(t, "RX");
            lon = x(2); lon(lon > 180) = lon(lon > 180) - 360;
            h(j:j + 1) = [x(1), lon];
        end
    elseif contains(t, "First Point")
        h(5) = double(endsWith(strtrim(t), "R"));
    elseif ~isempty(regexp(t, '^\s*\d*\.?\d+\s+-?\d*\.?\d+', 'once'))
        x = sscanf(char(t), '%f %f');
        v(end + 1, :) = x(1:2)'; %#ok<AGROW>
    end
end
[~, ia] = unique(v(:, 1), 'stable'); v = v(ia, :);
end
