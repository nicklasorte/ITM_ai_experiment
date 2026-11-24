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
%   "delta_deygout_isolated" | "delta_bullington_uc" |
%   "delta_p526_cylinders_knife" (ITU-R P.526-16 section 4.4, zero radius; B09)
%                            the delta construction with the empirical
%                            correction removed (P.526-11 C; P.526-16
%                            eq. (57)), for use with terminal clutter (B07)
%   "delta_cascaded_isolated" | "delta_cascaded_isolated_afo"
%                            the delta construction with ITU-R P.526-11
%                            section 4.4.2 and isolation-weighted secondary
%                            edges (ITU-R P.526-16 section 2.5), without and
%                            with A_fo (B06)
%   "delta_cascaded_isolated_one" | "delta_cascaded_isolated_tree3"
%                            the same cascade with one secondary edge in
%                            total, or three edges whenever three exist
%                            (B18 repair bracket, candidates 1801 and 1802)
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
cfg.diffraction_bound = "none";

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
cfg.terminal_clutter = "none";
cfg.terminal_clutter_type = "trees_forest";
cfg.terminal_clutter_frange = "extend";
cfg.terminal_clutter_db = 0;
% Base height (B08): "actual" computes the path with the mobile antenna at
% its real height and adds A_h (B07; counts the height gain twice);
% "clutter_height" computes it at max(h, R) and adds A_h, as ITU-R P.2108-1
% section 3.1 and Table 1 say.
cfg.terminal_clutter_base = "actual";
% Open and A sitings (B11): "none" (B07/B08 behavior) or "nlcd", the
% ITU-R P.2108-1 section 3.1 term at the mobile terminal with the category of
% the NLCD 2001 class there (landcover_lookup_rev1; Nick approved the input
% 2026-11-22), or "nlcd_forest", forest and woody-wetland classes only (712).
% Needs cfg.terminal_clutter = "p2108_height_gain" and cfg.row.path_id.
cfg.terminal_clutter_open = "none";
% Woodland along the terminal rays (B17): "none" or "p833_eq1", ITU-R
% P.833-10 section 2.1 eq. (1) and Table 1 on each terminal's ray to its
% horizon, with NLCD 2001 along the Phase 2 profile (PR #10;
% path_vegetation_rev1). Phase 2 rows only; needs cfg.row.path_id.
cfg.path_vegetation = "none";
% Heights above the smooth surface in the delta construction (B18):
% "p452_diffraction" (P.452-18 section 5.1.6.3, default), "p452_ducting"
% (section 5.1.6.4 eq. (154a)-(156): no obstruction adjustment),
% "itm_effective" (ITM's h_e), "structural" (antenna above local ground).
cfg.smooth_heights = "p452_diffraction";
% Representative clutter heights on the actual profile for L_ba (B18):
% "none" or "p1812_representative" (ITU-R P.1812-8 section 3.2.1 eq. (1d),
% Table 2: 15 m on woodland samples, not at the terminals; Phase 2 rows only).
cfg.profile_clutter = "none";

% Line-of-sight loss (line_of_sight_loss) and the line-of-sight region test
%   "itm"               region from the smooth-earth horizons of the effective heights
%   "profile_horizons"  a path whose profile blocks the direct ray is transhorizon
cfg.line_of_sight = "itm";
% Reflected-ray phase in ITM's line-of-sight term (B12, research package
% H02): "itm" (flat-Earth h1 h2 product) or "curved_specular" (heights above
% the tangent plane at the curved-Earth specular point, ITU-R P.530-19
% eq. (121)-(126); los_phase_curved_rev1).
cfg.los_phase = "itm";
% Time variability (B12, research package H03): "itm" or "two_leg" (two legs
% over a common crest, ITM's time curve per leg convolved; NBS TN 101
% section 10.8; changes non-median percentiles only).
cfg.time_variability = "itm";

% Troposcatter loss and the diffraction/troposcatter switch (troposcatter_loss, longley_rice)
cfg.troposcatter = "itm";

% Effective antenna height (quick_pfl). alpha = 1 keeps ITM's effective height;
% 0 uses the structural height (Paul 2003, ISART SP-03-401). Not implemented:
% the core stops with an error if either value differs from stock.
cfg.effective_height = "itm";
cfg.effective_height_alpha = 1;

% Time variability (variability). Not implemented (see cfg.time_variability):
% the core stops with an error if this differs from "itm".
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

% Per-run overrides (B09 tooling). A batch job can set the environment
% variable ITMEXP_OVERRIDES to a JSON object of switch values, for example
%   {"diffraction":"delta_cascaded_isolated","terminal_clutter":"p2108_height_gain"}
% so several experiments run at once without editing this file. Only
% existing top-level fields can be set (not version or cal), each value
% must have the field's type, and the raw text is kept in cfg.overrides,
% which run_eval_rev1 writes to metrics.json. Unset or empty: no change.
cfg.overrides = "";
cfg = apply_overrides(cfg, string(getenv('ITMEXP_OVERRIDES')));
end

function cfg = apply_overrides(cfg, txt)
if strlength(strtrim(txt)) == 0
    return
end
try
    o = jsondecode(char(txt));
catch err
    error('itmexp:overrides', 'ITMEXP_OVERRIDES is not valid JSON: %s', err.message);
end
if ~isstruct(o) || ~isscalar(o)
    error('itmexp:overrides', 'ITMEXP_OVERRIDES must be one JSON object.');
end
for f = string(fieldnames(o))'
    if ~isfield(cfg, f) || any(f == ["version" "cal" "overrides"])
        error('itmexp:overrides', 'ITMEXP_OVERRIDES sets unknown or protected field "%s".', f);
    end
    v = o.(f);
    if isstring(cfg.(f))
        if ~(ischar(v) || isstring(v)), error('itmexp:overrides', 'Field "%s" needs a string.', f); end
        cfg.(f) = string(v);
    elseif isnumeric(cfg.(f))
        if ~(isnumeric(v) && isscalar(v) && isfinite(v)), error('itmexp:overrides', 'Field "%s" needs a finite number.', f); end
        cfg.(f) = double(v);
    else
        error('itmexp:overrides', 'Field "%s" can''t be overridden.', f);
    end
end
cfg.overrides = txt;
end
