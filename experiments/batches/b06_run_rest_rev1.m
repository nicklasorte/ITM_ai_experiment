function tags = b06_run_rest_rev1()
%B06_RUN_REST_REV1 Run B06 experiments 603, 604, 602, 605 in order, one after another.
%   Sets only cfg.diffraction and cfg.diffraction_bound in
%   itm_variant/params_exp.m for each run, calls run_eval_rev1 with
%   Best="000-baseline", and restores the defaults afterward, also on error.
P = itm_exp_paths_rev1();
f = fullfile(P.root, 'itm_variant', 'params_exp.m');
t0 = fileread(f);
restore = onCleanup(@() writelines(splitlines(t0), f));
R = ["603-delta-bullington-afo-bounded"     "delta_bullington_afo"        "itm_troposcatter_line"
     "604-delta-cascaded-isolated-bounded"  "delta_cascaded_isolated"     "itm_troposcatter_line"
     "602-delta-cascaded-isolated-afo"      "delta_cascaded_isolated_afo" "none"
     "605-delta-p526-cascaded-bounded"      "delta_p526_cascaded"         "itm_troposcatter_line"];
tags = R(:, 1);
for k = 1:size(R, 1)
    t = strrep(t0, 'cfg.diffraction = "itm";', "cfg.diffraction = """ + R(k, 2) + """;");
    t = strrep(t, 'cfg.diffraction_bound = "none";', "cfg.diffraction_bound = """ + R(k, 3) + """;");
    writelines(splitlines(t), f);
    clear functions; rehash;
    c = params_exp();
    if c.diffraction ~= R(k, 2) || c.diffraction_bound ~= R(k, 3)
        error('itmexp:b06', 'Settings for %s did not apply.', R(k, 1));
    end
    fprintf('running %s\n', R(k, 1));
    run_eval_rev1(Tag=R(k, 1), Best="000-baseline");
end
end
