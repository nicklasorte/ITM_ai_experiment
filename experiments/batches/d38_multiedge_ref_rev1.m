function d38_multiedge_ref_rev1(out_file)
%D38_MULTIEDGE_REF_REV1 Save multi_edge_diffraction_rev1 outputs on random profiles, before the B38 edit.
%   D38_MULTIEDGE_REF_REV1(out_file) runs every existing method on 2,000
%   random profiles (seed 20261138) and saves the inputs and losses, so
%   test_cascade_parts_rev1 can check the edit changes no existing method
%   (B38 section 4, step 2c).
methods = ["epstein_peterson" "ep_isolated" "p526_double_edge" "string_ep" "deygout" ...
    "p526_cascaded" "p526_cascaded_isolated" "deygout_isolated" "bullington" "bullington_uc" ...
    "p526_cylinders_knife" "p526_cascaded_isolated_one" "p526_cascaded_isolated_tree3" "p526_cascaded_isolated_rival"];
[cases, L] = deal(cell(2000, 1));
rng(20261138);
for q = 1:2000
    n = randi([5 80]); dx = 20 + 80 * rand;
    x = (0:n - 1)' * dx;
    z = cumsum(randn(n, 1) * 8) + 200;
    z(1) = z(1) + 1 + 30 * rand; z(end) = z(end) + 1 + 30 * rand;
    f = 10^(log10(30) + rand * log10(6000 / 30)); ae = 6371e3 * 4 / 3 * (0.8 + 0.4 * rand);
    cases{q} = struct('x', x, 'z', z, 'f', f, 'ae', ae);
    v = NaN(1, numel(methods));
    for m = 1:numel(methods)
        v(m) = multi_edge_diffraction_rev1(methods(m), x, z, f, ae);
    end
    L{q} = v;
end
save(out_file, 'methods', 'cases', 'L');
end
