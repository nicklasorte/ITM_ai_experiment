function [T, drop] = lt_read(folder)
%LT_READ Parse the ITS long-term data (ltdata.txt, ltpath.txt) into one row per measurement set.
%   Source: https://its.ntia.gov/data/legacy-radio-propagation-data/
%   (longterm.zip), from Longley, Reasoner, and Fuller, OT/TRER 16 (1971).
%   Values are quantiles of hourly-median attenuation relative to free
%   space (Base FS) or to a nominal level (NM, CM).
%
%   Quantile columns q0_01 ... q99_99 hold attenuation in dB, NaN when
%   missing. The files write a missing quantile as .0, but 0.0 dB can also
%   be a real attenuation on a line-of-sight path. A 0.0 is kept only when
%   both neighboring quantiles are present and bracket it (lower < 0 <
%   upper); otherwise it is treated as missing.
%
%   drop lists rows left out and why. Rows are kept only if Base is FS,
%   both antenna heights are positive, polarization is H or V, both
%   terminals have coordinates, the path is not over sea, and the
%   geodesic distance matches the listed distance within 5 %.

tags = ["0_01" "0_1" "1" "10" "50" "90" "99" "99_9" "99_99"];

% ---- paths ----
P = readlines(fullfile(folder, "ltpath.txt"));
P = P(2:end); P = P(strlength(strtrim(P)) > 0);
np = numel(P);
pid = strings(np, 1); xlat = NaN(np, 1); xlon = xlat; rlat = xlat; rlon = xlat; pdist = xlat;
env = strings(np, 1); ptype = strings(np, 1); xname = strings(np, 1); rname = strings(np, 1);
for k = 1:np
    s = char(P(k));
    pid(k) = string(strtrim(s(1:min(6, end))));
    tok = regexp(s, '\s([A-Z]{2})\s+(-?\d*\.\d+)\s+(-?\d*\.\d+)', 'tokens');
    if numel(tok) < 2, continue, end
    xlat(k) = str2double(tok{1}{2}); xlon(k) = str2double(tok{1}{3});
    rlat(k) = str2double(tok{2}{2}); rlon(k) = str2double(tok{2}{3});
    [~, e] = regexp(s, '\s[A-Z]{2}\s+-?\d*\.\d+\s+-?\d*\.\d+', 'start', 'end');
    rest = strtrim(string(s(e(2) + 1:end)));
    parts = split(rest);
    pdist(k) = str2double(parts(1));
    if numel(parts) >= 2
        for t = parts(2:end)'
            if t == "SEA", env(k) = "SEA"; else, ptype(k) = t; end
        end
    end
    xname(k) = string(strtrim(s(13:min(43, end))));
    rname(k) = string(strtrim(s(71:min(101, end))));
end
Pt = table(pid, xname, xlat, xlon, rname, rlat, rlon, pdist, env, ptype, ...
    'VariableNames', {'path_id', 'tx_name', 'tx_lat', 'tx_lon', 'rx_name', 'rx_lat', 'rx_lon', 'path_dist_km', 'env', 'path_type'});

% ---- measurement sets ----
L = readlines(fullfile(folder, "ltdata.txt"));
L = L(2:end); L = L(strlength(strtrim(L)) > 0);
n = numel(L);
rows = cell(n, 1);
drop = strings(0, 2);
for k = 1:n
    s = char(L(k));
    t = string(strsplit(strtrim(s)));
    q = str2double(t(end - 8:end));
    % Heights, gains, polarization, and base. The columns are fixed width
    % and a receiver height of 100 m or more runs into the transmitter
    % height ("11.90111.30"), so read them by pattern: heights and gains
    % always have two decimals; no other field before them does.
    m = regexp(s, '(\d*\.\d\d)\s*(\d*\.\d\d)\s+(-?\d*\.\d\d)\s+(-?\d*\.\d\d)\s+([HVC]?)\s*(FS|NM|CM)\s', 'tokens', 'once');
    if isempty(m)
        drop(end + 1, :) = [string(sprintf('%s_%04d', t(1), k)), "unparsed row"]; %#ok<AGROW>
        continue
    end
    h = str2double(string(m(1:2)));
    pol = string(m{5}); base = string(m{6});
    path = t(1); dist = str2double(t(2)); f = str2double(t(3));
    id = sprintf('%s_%04d', path, k);
    ip = find(Pt.path_id == path, 1);
    why = "";
    if base ~= "FS", why = "base " + base;
    elseif any(~(h > 0)), why = "antenna height missing";
    elseif ~any(pol == ["H" "V"]), why = "polarization " + pol;
    elseif isempty(ip), why = "path not in ltpath";
    elseif any(Pt{ip, {'tx_lat', 'tx_lon', 'rx_lat', 'rx_lon'}} == 0) || any(isnan(Pt{ip, {'tx_lat', 'tx_lon', 'rx_lat', 'rx_lon'}}))
        why = "no coordinates";
    elseif Pt.env(ip) == "SEA", why = "over sea";
    elseif ~(f >= 20 && f <= 20000), why = "frequency outside ITM range";
    end
    if why ~= ""
        drop(end + 1, :) = [string(id), why]; %#ok<AGROW>
        continue
    end
    q = clean_quantiles(q);
    if ~isfinite(q(5))
        drop(end + 1, :) = [string(id), "no median"]; %#ok<AGROW>
        continue
    end
    yr = ""; season = ""; len = "";
    m = regexp(s, '^\S+\s+\S+\s+\S+\s+(\S*)\s+(\d+)\s+(hr|mo|yr|da|wk)\s+([WPSADN]*)', 'tokens', 'once');
    if ~isempty(m), yr = string(m{1}); len = string(m{2}) + " " + string(m{3}); season = string(m{4}); end
    rows{k} = {string(id), path, dist, f, yr, len, season, h(1), h(2), pol, q};
end
rows = rows(~cellfun(@isempty, rows));
R = vertcat(rows{:});
T = table(string(R(:, 1)), string(R(:, 2)), cell2mat(R(:, 3)), cell2mat(R(:, 4)), string(R(:, 5)), ...
    string(R(:, 6)), string(R(:, 7)), cell2mat(R(:, 8)), cell2mat(R(:, 9)), string(R(:, 10)), ...
    'VariableNames', {'link_id', 'path_id', 'd_km', 'f_mhz', 'year', 'length', 'season', 'htx_m', 'hrx_m', 'pol'});
Q = vertcat(R{:, 11});
for j = 1:9
    T.("meas_a_" + tags(j)) = Q(:, j);
end
[~, ip] = ismember(T.path_id, Pt.path_id);
T = [T, Pt(ip, {'tx_name', 'tx_lat', 'tx_lon', 'rx_name', 'rx_lat', 'rx_lon', 'path_type'})];

% Coordinates must agree with the listed distance
E = wgs84Ellipsoid('km');
dg = distance(T.tx_lat, T.tx_lon, T.rx_lat, T.rx_lon, E);
bad = abs(dg - T.d_km) > 0.05 * T.d_km | T.d_km < 1;
drop = [drop; [T.link_id(bad), repmat("distance mismatch", nnz(bad), 1)]];
T = T(~bad, :);
T.geo_dist_km = dg(~bad);
end

function q = clean_quantiles(q)
z = q == 0;
for j = find(z)
    lo = NaN; hi = NaN;
    if j > 1, lo = q(j - 1); end
    if j < 9, hi = q(j + 1); end
    if ~(isfinite(lo) && isfinite(hi) && lo ~= 0 && hi ~= 0 && lo < 0 && hi > 0)
        q(j) = NaN;
    end
end
end
