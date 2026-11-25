function out = b28_calibrate_rev1(tag, params, options)
%B28_CALIBRATE_REV1 One B28 run: constrained Tier 1 calibration of 707's constants.
%   out = B28_CALIBRATE_REV1(tag, params) sets ITMEXP_OVERRIDES to 707's
%   switches, checks that params_exp() returns 707 with ITM's constants,
%   runs eval/cv_calibrate_rev1 (Constrained=true, as R02) on the named
%   constant group, then the paired bootstrap against the scored 707
%   (707r-rescore-screen36) with 2,000 draws. See experiments/batches/B28.md.
%
%   Run as a MATLAB batch job with 'EnvironmentVariables' not needed: the
%   override is set here.
%
%   Inputs:
%     tag     experiment tag, e.g. "2801-cal707-diffraction"
%     params  string array, a subset of params_exp().cal field names
%   Options:
%     MaxEvals  40
%     Best      "707r-rescore-screen36"
%     N         2000

arguments
    tag (1,1) string
    params (1,:) string
    options.MaxEvals (1,1) double = 40
    options.Best (1,1) string = "707r-rescore-screen36"
    options.N (1,1) double = 2000
end
% 707's switches, copied from experiments/707r-rescore-screen36/metrics.json (cfg.overrides)
ov = '{"diffraction":"delta_cascaded_isolated","diffraction_bound":"itm_troposcatter_line","terminal_clutter":"p2108_height_gain","terminal_clutter_base":"clutter_height","terminal_clutter_frange":"hold3"}';
setenv('ITMEXP_OVERRIDES', ov);
cfg = params_exp();
want = struct('diffraction', "delta_cascaded_isolated", 'diffraction_bound', "itm_troposcatter_line", ...
    'terminal_clutter', "p2108_height_gain", 'terminal_clutter_base', "clutter_height", ...
    'terminal_clutter_frange', "hold3", 'smooth_heights', "p452_diffraction", 'smooth_reference', "itm", ...
    'path_vegetation', "none");
for f = string(fieldnames(want))'
    if cfg.(f) ~= want.(f)
        error('itmexp:b28', 'params_exp().%s is "%s", expected "%s" for 707.', f, cfg.(f), want.(f));
    end
end
itm = struct('w_const', 25.1, 'afo_scale', 1, 'knife_scale', 1, 'los_w_scale', 1, ...
    'time_minus_scale', 1, 'time_plus_scale', 1);   % ITM v1.4 values (params_exp.m comments)
for f = string(fieldnames(itm))'
    if cfg.cal.(f) ~= itm.(f)
        error('itmexp:b28', 'params_exp().cal.%s is %g, expected ITM''s %g.', f, cfg.cal.(f), itm.(f));
    end
end
P = itm_exp_paths_rev1();
if isfolder(fullfile(P.root, 'experiments', tag))
    error('itmexp:b28', 'experiments/%s already exists; pick a new tag.', tag);
end
if ~isfolder(fullfile(P.root, 'experiments', options.Best))
    error('itmexp:b28', 'Reference run experiments/%s is missing.', options.Best);
end
R = cv_calibrate_rev1(Tag=tag, Params=params, Constrained=true, MaxEvals=options.MaxEvals, Seed=1);
G = paired_gain_rev1(tag, options.Best, N=options.N, Write=true);
out = struct('R', R, 'G', G);
end
