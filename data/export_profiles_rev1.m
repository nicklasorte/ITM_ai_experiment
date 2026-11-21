function export_profiles_rev1(options)
%EXPORT_PROFILES_REV1 Write terrain profiles to CSV so no terrain tiles are needed.
%   EXPORT_PROFILES_REV1() writes every profile in data/cache/profiles_rev1.mat
%   to data/profiles/<dataset>/<path_id>.csv (header "h_m", one elevation in
%   metres per line, 4 decimals, transmitter first) and rewrites
%   data/profiles/profiles_index_rev1.csv with each path's geometry, spacing,
%   climate, N_0, and file SHA-256. These CSVs become the canonical terrain.
%
%   EXPORT_PROFILES_REV1(Extract=true) also samples profiles for long-term
%   paths that don't have one yet (all paths that pass data/private/lt_read,
%   in the US or not), a few paths at a time: it downloads the tiles a chunk
%   needs, writes the profiles, then deletes the tiles the chunk added, so
%   disk use stays bounded. Tiles in the terrain cache that are older than
%   KeepTilesBefore are never deleted.
%
%   Options:
%     Extract          false
%     ChunkPaths       1       paths sampled per chunk (one at a time: download,
%                              write the profile, delete the new tiles)
%     DeleteNewTiles   true    delete tiles added by this run (and by any run
%                              after KeepTilesBefore) once used
%     KeepTilesBefore  datetime(2026,11,21,9,45,0,'TimeZone','America/New_York')
%     MinFreeGB        5       stop if free disk falls below this
%
%   Human-owned. The agent doesn't run or edit this file.

arguments
    options.Extract (1,1) logical = false
    options.ChunkPaths (1,1) double = 1
    options.DeleteNewTiles (1,1) logical = true
    options.KeepTilesBefore (1,1) datetime = datetime(2026, 11, 21, 9, 45, 0, 'TimeZone', 'America/New_York')
    options.MinFreeGB (1,1) double = 5
end
here = fileparts(mfilename('fullpath'));
root = fileparts(here);
addpath(fullfile(root, 'eval'));
itm_exp_paths_rev1();
S = settings_rev1();
outdir = fullfile(here, 'profiles');
C = load(fullfile(here, 'cache', 'profiles_rev1.mat'));
profiles = C.profiles;

if options.Extract
    tmp = fullfile(tempdir, 'itm_exp_longterm');
    if ~isfolder(fullfile(tmp, 'longterm')), unzip(fullfile(here, 'raw', 'longterm.zip'), tmp); end
    T = lt_read(fullfile(tmp, 'longterm'));
    [~, first] = unique(T.path_id, 'stable');
    U = T(first, :);
    have = [profiles.path_id];
    todo = find(~ismember("LT_" + U.path_id, have));
    tdir = itm_default_terrain_dir_public();
    cutoff = posixtime(options.KeepTilesBefore);
    fprintf('Long-term: %d paths need profiles\n', numel(todo));
    for c0 = 1:options.ChunkPaths:numel(todo)
        k = todo(c0:min(end, c0 + options.ChunkPaths - 1));
        free_gb = java.io.File(char(tdir)).getUsableSpace / 1e9;
        if free_gb < options.MinFreeGB
            error('itmexp:disk', 'Only %.1f GB free; stopping before chunk at path %d.', free_gb, c0);
        end
        try
            [pfls, pinfo] = itm_terrain_profile_rev1(U.tx_lat(k), U.tx_lon(k), U.rx_lat(k), U.rx_lon(k), ...
                spacing_m=S.profile_spacing_m);
        catch e
            % A tile deleted after an earlier path can still be listed in
            % matlab_itm's in-memory tile cache; clear it and retry once
            fprintf('  retrying path %d after: %s\n', c0, e.message);
            clear_tile_cache();
            [pfls, pinfo] = itm_terrain_profile_rev1(U.tx_lat(k), U.tx_lon(k), U.rx_lat(k), U.rx_lon(k), ...
                spacing_m=S.profile_spacing_m);
        end
        if ~iscell(pfls), pfls = {pfls}; end
        for i = 1:numel(k)
            r = U(k(i), :); pf = pfls{i}; mid = pinfo(i).midpoint_deg;
            clim = itm_radio_climate_rev1(mid(1), mid(2));
            if clim == 7
                clim = min(itm_radio_climate_rev1(r.tx_lat, r.tx_lon), itm_radio_climate_rev1(r.rx_lat, r.rx_lon));
            end
            profiles(end + 1) = struct('path_id', "LT_" + r.path_id, 'dataset', "longterm", ...
                'd_km', pf(1) * pf(2) / 1000, 'h_m', pf(3:end), 'spacing_m', pf(2), 'midpoint_deg', mid, ...
                'tx', [r.tx_lat r.tx_lon], 'rx', [r.rx_lat r.rx_lon], 'climate', clim, ...
                'N_0', itm_surface_refractivity_rev1(mid(1), mid(2))); %#ok<AGROW>
        end
        save(fullfile(here, 'cache', 'profiles_rev1.mat'), 'profiles', '-v7.3');
        if options.DeleteNewTiles
            [n, gb] = delete_new_tiles(tdir, cutoff);
            if n > 0, clear_tile_cache(); end
            fprintf('  chunk %d-%d done; deleted %d new tiles (%.1f GB); %.1f GB free\n', c0, c0 + numel(k) - 1, n, gb, ...
                java.io.File(char(tdir)).getUsableSpace / 1e9);
        end
    end
end

% ---- write CSVs and the index ----
for d = unique([profiles.dataset])
    if ~isfolder(fullfile(outdir, d)), mkdir(fullfile(outdir, d)); end
end
n = numel(profiles);
rows = cell(n, 1);
for k = 1:n
    p = profiles(k);
    f = fullfile(outdir, p.dataset, p.path_id + ".csv");
    fid = fopen(f, 'w');
    fprintf(fid, 'h_m\n'); fprintf(fid, '%.4f\n', p.h_m(:));
    fclose(fid);
    rows{k} = {p.path_id, p.dataset, numel(p.h_m), p.spacing_m, p.d_km, p.tx(1), p.tx(2), p.rx(1), p.rx(2), ...
        p.midpoint_deg(1), p.midpoint_deg(2), p.climate, p.N_0, file_sha256(f)};
end
R = vertcat(rows{:});
I = cell2table(R, 'VariableNames', {'path_id', 'dataset', 'n_points', 'spacing_m', 'd_km', 'tx_lat', 'tx_lon', ...
    'rx_lat', 'rx_lon', 'mid_lat', 'mid_lon', 'climate', 'N_0', 'sha256'});
I = sortrows(I, {'dataset', 'path_id'});
writetable(I, fullfile(outdir, 'profiles_index_rev1.csv'));
fprintf('Wrote %d profiles to %s\n', n, outdir);
end

function clear_tile_cache()
% matlab_itm keeps loaded tiles in persistent variables; drop them after
% tiles are deleted from disk so no stale entry points at a missing file
clear('itm_terrain_elevation_rev1', 'itm_terrain_profile_rev1');
end

function d = itm_default_terrain_dir_public()
% matlab_itm keeps tiles under ~/.matlab_itm/terrain by default
d = string(fullfile(getenv('HOME'), '.matlab_itm', 'terrain'));
end

function [n, gb] = delete_new_tiles(tdir, cutoff_posix)
% Delete tile files (and partial downloads) modified after the cutoff
f = dir(fullfile(tdir, '**', '*'));
f = f(~[f.isdir]);
t = posixtime(datetime([f.datenum], 'ConvertFrom', 'datenum', 'TimeZone', 'local'));
k = find(t > cutoff_posix);
n = numel(k); gb = sum([f(k).bytes]) / 1e9;
for i = k(:)'
    delete(fullfile(f(i).folder, f(i).name));
end
end

function h = file_sha256(f)
fid = fopen(f, 'r'); c = onCleanup(@() fclose(fid));
b = fread(fid, Inf, '*uint8');
md = java.security.MessageDigest.getInstance('SHA-256'); md.update(b);
h = string(sprintf('%02x', typecast(md.digest(), 'uint8')));
end
