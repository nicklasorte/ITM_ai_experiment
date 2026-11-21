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
cfg.diffraction = "itm";

% Line-of-sight loss (line_of_sight_loss)
cfg.line_of_sight = "itm";

% Troposcatter loss and the diffraction/troposcatter switch (troposcatter_loss, longley_rice)
cfg.troposcatter = "itm";

% Effective antenna height (quick_pfl). alpha = 1 keeps ITM's effective height;
% 0 uses the structural height (Paul 2003, ISART SP-03-401).
cfg.effective_height = "itm";
cfg.effective_height_alpha = 1;

% Time variability (variability)
cfg.variability = "itm";
end
