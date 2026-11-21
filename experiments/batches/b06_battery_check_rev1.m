function T = b06_battery_check_rev1(settings)
%B06_BATTERY_CHECK_REV1 Physics battery for a list of settings, from code only.
%   T = B06_BATTERY_CHECK_REV1(settings) runs eval/physics_battery_rev1 for
%   each row of settings, a string array with columns [diffraction,
%   diffraction_region, diffraction_bound], and returns a table of the
%   continuity steps (variant/baseline), reciprocity, and pass or fail. It
%   reads the Phase 2 link table only for geometry (the battery's fixed
%   sample of 300 links); it reads and reports no measurement error.
P = itm_exp_paths_rev1();
profiles = load_profiles_rev1(P.root);
P2 = readtable(fullfile(P.root, 'data', 'links', 'phase2_links_rev1.csv'), 'TextType', 'string');
P2.set = string(P2.set);
if ismember('itm_error', P2.Properties.VariableNames) && ~isnumeric(P2.itm_error)
    P2 = P2(ismissing(P2.itm_error) | P2.itm_error == "", :);
end
n = size(settings, 1);
T = table('Size', [n 9], 'VariableTypes', ["string" repmat("string", 1, 7) "logical"], ...
    'VariableNames', ["setting" "flat" "ridge" "rough" "frequency" "rx_height" "reciprocity_p95" "two_ray" "pass"]);
for i = 1:n
    cfg = params_exp();
    cfg.diffraction = settings(i, 1); cfg.diffraction_region = settings(i, 2); cfg.diffraction_bound = settings(i, 3);
    B = physics_battery_rev1(cfg, P2, profiles);
    c = B.checks;
    s = @(q) sprintf('%.1f/%.1f', q.variant_max_step_db, q.baseline_max_step_db);
    T(i, :) = {join(settings(i, :), " | "), s(c.continuity_distance_flat), s(c.continuity_distance_ridge), ...
        s(c.continuity_distance_rough), s(c.continuity_frequency_rough60), s(c.continuity_rx_height_ridge40), ...
        sprintf('%.2f/%.2f', c.reciprocity.variant_p95_db, c.reciprocity.baseline_p95_db), ...
        sprintf('%.1f/%.1f', c.two_ray_bound.variant_min_excess_db, c.two_ray_bound.limit_db), B.pass};
end
end
