function S = settings_rev1()
%SETTINGS_REV1 Fixed ITM inputs the harness passes to every model. Read-only.
%   These match the defaults of itm_pathloss_rev1 and pathloss_rev1 in
%   nicklasorte/matlab_itm and matlab_itu_p452, which produced the
%   baseline in experiments/LOG.md entry 000. Changing them changes the
%   inputs, not the model, so the agent may not edit this file.

S.epsilon = 25;          % ground relative permittivity
S.sigma = 0.02;          % ground conductivity, S/m
S.mdvar = 13;            % mode of variability: broadcast (ITM default in itm_pathloss_rev1)
S.confidence = 50;       % percent of situations
S.location = 50;         % percent of locations
S.profile_spacing_m = 30;    % terrain profile spacing; terrain source never changes

% Time percentages scored on the long-term set, and the full set stored
S.p_scored = [1 10 50 90 99];
S.p_all = [0.01 0.1 1 10 50 90 99 99.9 99.99];
S.p_tags = ["0_01" "0_1" "1" "10" "50" "90" "99" "99_9" "99_99"];

% Score cells
S.band_edges_mhz = [0 300 1000 3000 6000 Inf];
S.band_names = ["<0.3" "0.3-1" "1-3" "3-6" "6-10"];
S.lt_band_edges_mhz = [0 300 1000 3000 Inf];
S.lt_band_names = ["<0.3" "0.3-1" "1-3" "3-10"];
S.lt_dist_edges_km = [0 100 300 Inf];
S.lt_dist_names = ["<100" "100-300" ">=300"];
end
