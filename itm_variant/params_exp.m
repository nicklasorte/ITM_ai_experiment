function cfg = params_exp()
%PARAMS_EXP Submodel switches and constants for the ITM variant. THE AGENT EDITS THIS FILE.
%   cfg = PARAMS_EXP() returns the settings itm_p2p_core_exp reads. At the
%   values below, every switch selects the original ITM v1.4 behavior and
%   the variant is bit-identical to the baseline.
%
%   Rules (program.md):
%     - Every new constant gets a comment citing its source, or TODO.
%     - Fitted constants are fitted inside cross-validation by eval/, never
%       by hand against held-out scores.
%     - Bump cfg.version when the meaning of a field changes.
%
%   Switch values are names of physics and public sources, for example
%   "itm" (ITM v1.4), "delta_bullington" (ITU-R P.526 section 4.5.2),
%   "p2001_clear_air" (ITU-R P.2001 Attachment B).

cfg = struct();
cfg.version = 1;

% Diffraction between the horizons (diffraction_loss, knife_edge_diffraction)
%   "itm"               ITM v1.4 double knife edge on the line through d_3, d_4
%   "epstein_peterson"  Epstein and Peterson 1953 over the two horizon obstacles
%   "deygout"           Deygout 1966, principal edge plus one edge each side
%   "p526_cascaded"     ITU-R P.526-11 section 4.4.2 (Deygout with correction)
%   "bullington"        ITU-R P.526-16 section 4.5.1
% The last four replace the knife-edge part of ITM's diffraction loss with a
% profile-based loss at the path's own distance, on transhorizon paths
% (multi_edge_diffraction_rev1; experiments/batches/B01.md).
cfg.diffraction = "itm";

% Line-of-sight loss (line_of_sight_loss) and the line-of-sight region test
%   "itm"               region from the smooth-earth horizons of the effective heights
%   "profile_horizons"  a path whose profile blocks the direct ray is transhorizon
cfg.line_of_sight = "profile_horizons";

% Troposcatter loss and the diffraction/troposcatter switch (troposcatter_loss, longley_rice)
cfg.troposcatter = "itm";

% Effective antenna height (quick_pfl). alpha = 1 keeps ITM's effective height;
% 0 uses the structural height (Paul 2003, ISART SP-03-401).
cfg.effective_height = "itm";
cfg.effective_height_alpha = 1;

% Time variability (variability)
cfg.variability = "itm";

% Recalibration constants (Tier 1). At these values ITM v1.4 is unchanged.
% eval/cv_calibrate_rev1 fits them inside cross-validation for the
% recalibrated-ITM baseline; the agent doesn't hand-tune them.
cfg.cal = struct( ...
    'w_const', 25.1, ...          % smooth-earth weight constant in diffraction_loss (ITM v1.4)
    'afo_scale', 1, ...           % scale on the terrain clutter term A_fo (ITM v1.4: 1)
    'knife_scale', 1, ...         % scale on the double knife-edge loss A_k (ITM v1.4: 1)
    'los_w_scale', 1, ...         % scale on f*dh/d in the line-of-sight blend weight (ITM v1.4: 1)
    'time_minus_scale', 1, ...    % scale on sigma_T for z_T < 0, enhancement side (ITM v1.4: 1)
    'time_plus_scale', 1);        % scale on sigma_T for z_T >= 0, fading side (ITM v1.4: 1)
end
