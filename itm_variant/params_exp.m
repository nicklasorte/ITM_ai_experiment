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
cfg.diffraction = "delta_cascaded_isolated";
%   "ep_isolated"       Epstein-Peterson; horizon obstacles merged unless
%                       isolated (ITU-R P.526-16 section 2.5)
%   "p526_double_edge"  ITU-R P.526-16 section 4.3 (with Lc where valid)
%   "delta_bullington"       reference attenuation L_ba + max(A_s - L_bs, 0),
%                            ITU-R P.452-18 eq. (38)-(40), with ITM's own
%                            smooth-earth reference A_s in place of L_sph (B04)
%   "delta_bullington_p526"  max(L_ba + A_s - L_bs, 0), ITU-R P.526-16 eq. (66)
%   "delta_string_ep" | "delta_p526_cascaded" | "delta_deygout" |
%   "delta_ep_isolated"      the delta construction with a multi-edge
%                            obstruction loss in place of Bullington (B05)
%   "delta_bullington_afo"   "delta_bullington" plus ITM's clutter term A_fo (B05 control)
%   "delta_deygout_isolated" | "delta_bullington_uc"
%                            the delta construction with the empirical
%                            correction removed (P.526-11 C; P.526-16
%                            eq. (57)), for use with terminal clutter (B07)
%   "delta_cascaded_isolated" | "delta_cascaded_isolated_afo"
%                            the delta construction with ITU-R P.526-11
%                            section 4.4.2 and isolation-weighted secondary
%                            edges (ITU-R P.526-16 section 2.5), without and
%                            with A_fo (B06)
% Where the profile-based loss applies (only when cfg.diffraction ~= "itm"):
%   "transhorizon"   transhorizon paths only (batch B01)
%   "blocked_paths"  also line-of-sight-region paths whose profile blocks
%                    the direct ray; keeps the loss continuous at d_sML
%                    (B02: lowered half of Phase 2 rows by about 10 dB)
%   "transhorizon_phased"  transhorizon paths only, phased in linearly from
%                    ITM's value at d_sML to the full value at d_3 (B03)
cfg.diffraction_region = "transhorizon";
% Upper bound on the delta forms (only when cfg.diffraction starts with "delta_"):
%   "none"              no bound
%   "itm_troposcatter"       where ITM v1.4 finds the path in its
%                            troposcatter region, the loss can't exceed
%                            ITM's reference attenuation (B06; steps where
%                            ITM changes region)
%   "itm_troposcatter_line"  on every transhorizon path, the loss can't
%                            exceed ITM's troposcatter line at d (B06)
cfg.diffraction_bound = "itm_troposcatter_line";

% Terminal clutter at the Phase 2 mobile terminal, siting "C" only (B07)
%   "none"               no clutter term
%   "p2108_height_gain"  ITU-R P.2108-1 section 3.1
%   "constant"           cfg.terminal_clutter_db on the same rows (control)
% Type: a P.2108 Table 3 clutter type. "C" means "immediately behind a
% grove of trees or a building" (Phase 2 readme), mapped to
% "trees_forest" (R = 15 m), a design choice.
% Frequency rule: "recommendation" (error outside 0.03-3 GHz), "extend"
% (no upper limit; a design choice), or "hold3" (A_h at 3 GHz above 3 GHz;
% B08). See p2108_height_gain_rev1.
cfg.terminal_clutter = "p2108_height_gain";
cfg.terminal_clutter_type = "trees_forest";
cfg.terminal_clutter_frange = "hold3";
cfg.terminal_clutter_db = 0;
% Base height (B08): "actual" computes the path with the mobile antenna at
% its real height and adds A_h (B07; counts the height gain twice);
% "clutter_height" computes it at max(h, R) and adds A_h, as ITU-R P.2108-1
% section 3.1 and Table 1 say.
cfg.terminal_clutter_base = "clutter_height";

% Line-of-sight loss (line_of_sight_loss) and the line-of-sight region test
%   "itm"               region from the smooth-earth horizons of the effective heights
%   "profile_horizons"  a path whose profile blocks the direct ray is transhorizon
cfg.line_of_sight = "itm";

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
