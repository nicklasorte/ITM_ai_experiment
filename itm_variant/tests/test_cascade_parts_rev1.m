function tests = test_cascade_parts_rev1
%TEST_CASCADE_PARTS_REV1 B38 checks for the report-only cascade variants (written before the code).
%   Run:  results = runtests('itm_variant/tests/test_cascade_parts_rev1.m')
%   "p526_cascaded_isolated_principal": L = J_p (principal knife edge only).
%   "p526_cascaded_isolated_uc": L = J_p + T (L_t + L_r), the cascade
%   without the ITU-R P.526-11 eq. (51) correction C.
%   Existing methods must be unchanged bit for bit against outputs saved
%   at the commit before the edit (experiments/batches/d38_multiedge_ref_rev1.m).
tests = functiontests(localfunctions);
end

function setupOnce(tc)
here = fileparts(mfilename('fullpath'));
addpath(fileparts(here));
root = fileparts(fileparts(here));
tc.TestData.ref = fullfile(root, 'experiments', 'D38-cascade-parts-landcover', 'multiedge_ref_rev1.mat');
end

function J = J_approx(nu)
% ITU-R P.526-16 eq. (31)
if nu > -0.78, J = 6.9 + 20 * log10(sqrt((nu - 0.1)^2 + 1) + nu - 0.1); else, J = 0; end
end

function testPrincipalIsKnifeOfPrincipalNu(tc)
S = load(tc.TestData.ref);
for q = 1:200
    c = S.cases{q};
    [Lf, D] = multi_edge_diffraction_rev1("p526_cascaded_isolated", c.x, c.z, c.f, c.ae);
    Lp = multi_edge_diffraction_rev1("p526_cascaded_isolated_principal", c.x, c.z, c.f, c.ae);
    % principal edge: the middle of [t p r], else the only edge (a secondary
    % edge can also have weight 1, so the weight doesn't identify it)
    if numel(D.nu) == 3, k = 2; else, k = 1; end
    tc.verifyEqual(Lp, J_approx(D.nu(k)), 'AbsTol', 1e-12);
    tc.verifyLessThanOrEqual(Lp, Lf + 1e-12);
end
end

function testUcIsFullMinusTC(tc)
S = load(tc.TestData.ref);
n = 0;
for q = 1:200
    c = S.cases{q};
    [Lf, D] = multi_edge_diffraction_rev1("p526_cascaded_isolated", c.x, c.z, c.f, c.ae);
    Lu = multi_edge_diffraction_rev1("p526_cascaded_isolated_uc", c.x, c.z, c.f, c.ae);
    if isfield(D, 'terms')
        tc.verifyEqual(Lu, Lf - D.terms.T * D.terms.C, 'AbsTol', 1e-9);
        n = n + 1;
    else
        tc.verifyEqual(Lu, Lf, 'AbsTol', 0);      % no obstruction: both zero
    end
end
tc.verifyGreaterThan(n, 20);                       % enough obstructed cases to mean something
end

function testExistingMethodsUnchanged(tc)
S = load(tc.TestData.ref);
for q = 1:numel(S.cases)
    c = S.cases{q};
    for m = 1:numel(S.methods)
        v = multi_edge_diffraction_rev1(S.methods(m), c.x, c.z, c.f, c.ae);
        tc.verifyEqual(v, S.L{q}(m), 'AbsTol', 0, sprintf('%s case %d', S.methods(m), q));
    end
end
end
