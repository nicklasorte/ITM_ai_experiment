function out = b12_battery_rev1()
%B12_BATTERY_REV1 Physics battery for the two B12 settings on 707's base.
P = itm_exp_paths_rev1(); profiles = load_profiles_rev1(P.root);
P2 = readtable(fullfile(P.root,'data','links','phase2_links_rev1.csv'),'TextType','string');
if ~isnumeric(P2.itm_error), P2 = P2(ismissing(P2.itm_error) | P2.itm_error == "", :); end
base = ['{"diffraction":"delta_cascaded_isolated","diffraction_bound":"itm_troposcatter_line",' ...
    '"terminal_clutter":"p2108_height_gain","terminal_clutter_base":"clutter_height",' ...
    '"terminal_clutter_frange":"hold3"%s}'];
extras = [",""los_phase"":""curved_specular""", ",""time_variability"":""two_leg"""];
out = strings(numel(extras), 1);
for k = 1:numel(extras)
    setenv('ITMEXP_OVERRIDES', sprintf(base, extras(k))); c = params_exp(); setenv('ITMEXP_OVERRIDES', '');
    B = physics_battery_rev1(c, P2, profiles); ch = B.checks; fn = fieldnames(ch); s = "";
    for q = 1:numel(fn)
        x = ch.(fn{q});
        if isfield(x, 'pass') && ~x.pass, s = s + fn{q} + " FAIL "; end
    end
    out(k) = sprintf('%s: battery %d %s| dist rough %.1f/%.1f, freq %.2f/%.2f, recip %.2g, two-ray %.2f, height_gain_real %.1f', ...
        extras(k), B.pass, s, ch.continuity_distance_rough.variant_max_step_db, ch.continuity_distance_rough.baseline_max_step_db, ...
        ch.continuity_frequency_rough60.variant_max_step_db, ch.continuity_frequency_rough60.baseline_max_step_db, ...
        ch.reciprocity.variant_p95_db, ch.two_ray_bound.variant_min_excess_db, ch.height_gain_real.worst_excess_db);
    fprintf('%s\n', out(k));
end
end
