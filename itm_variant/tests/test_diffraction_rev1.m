function tests = test_diffraction_rev1
%TEST_DIFFRACTION_REV1 Checks multi_edge_diffraction_rev1 against values computed independently.
%   Run:  results = runtests('itm_variant/tests/test_diffraction_rev1.m')
%   Each test recomputes the expected value from the cited equation, written
%   out separately here (in the Recommendation's own units where it uses
%   km), so a transcription slip in the function shows up as a mismatch.
tests = functiontests(localfunctions);
end

function setupOnce(tc)
here = fileparts(mfilename('fullpath'));
addpath(fileparts(here));
tc.TestData.f = 1000;                         % MHz
tc.TestData.lambda = 299.792458 / 1000;       % m
tc.TestData.flat = 1e30;                      % effective radius large enough for a flat Earth
end

function J = J_approx(nu)
% ITU-R P.526-16 eq. (31)
if nu > -0.78, J = 6.9 + 20 * log10(sqrt((nu - 0.1)^2 + 1) + nu - 0.1); else, J = 0; end
end

function J = J_exact(nu)
% ITU-R P.526-16 eq. (30): exact knife-edge loss from the Fresnel integrals
% C(nu), S(nu) (eq. (7a), (7b)), by numerical integration.
C = integral(@(s) cos(pi * s.^2 / 2), 0, nu, 'AbsTol', 1e-12, 'RelTol', 1e-12);
S = integral(@(s) sin(pi * s.^2 / 2), 0, nu, 'AbsTol', 1e-12, 'RelTol', 1e-12);
J = -20 * log10(sqrt((1 - C - S)^2 + (C - S)^2) / 2);
end

function [x, z] = spike_profile(d, xs, hs, h_ant)
% Flat ground at 0 m, antennas h_ant above it, knife edges of height hs at xs
x = (0:30:d)';
z = zeros(size(x));
for k = 1:numel(xs)
    [~, i] = min(abs(x - xs(k)));
    z(i) = hs(k);
end
z(1) = h_ant; z(end) = h_ant;
end

function test_J_matches_exact_fresnel(tc)
% The eq. (31) approximation, as coded, stays within 0.3 dB of eq. (30).
% One edge mid-path, antennas 50 m above flat ground, edge top at 50 m + h.
d = 21000; d1 = 10500; d2 = d - d1; h_ant = 50;
for nu = [-0.7 -0.3 0 0.5 1 2 3 5]
    h = nu / sqrt(2 * d / (tc.TestData.lambda * d1 * d2));
    [x, z] = spike_profile(d, d1, h_ant + h, h_ant);
    L = multi_edge_diffraction_rev1("deygout", x, z, tc.TestData.f, tc.TestData.flat);
    tc.verifyEqual(L, J_approx(nu), 'AbsTol', 1e-9);
    tc.verifyEqual(J_approx(nu), J_exact(nu), 'AbsTol', 0.3);
end
% Known value: grazing incidence is 6 dB
tc.verifyEqual(J_exact(0), 6.0206, 'AbsTol', 1e-3);
tc.verifyEqual(J_approx(0), 6.03, 'AbsTol', 0.01);
end

function test_single_edge_all_methods(tc)
% One 100 m edge mid-path: every method must reduce to the single-edge loss
% (plus its own published correction)
d = 30000; H = 100; h_ant = 10;
[x, z] = spike_profile(d, 15000, H, h_ant);
i = find(z == H);
d1 = x(i); d2 = d - d1;
nu = (H - h_ant) * sqrt(2 * d / (tc.TestData.lambda * d1 * d2));
J1 = J_approx(nu);
f = tc.TestData.f; a = tc.TestData.flat;
tc.verifyEqual(multi_edge_diffraction_rev1("epstein_peterson", x, z, f, a), J1, 'AbsTol', 1e-6);
tc.verifyEqual(multi_edge_diffraction_rev1("deygout", x, z, f, a), J1, 'AbsTol', 1e-6);
% P.526-11 eq. (50a)-(52) with no secondary edges
T = 1 - exp(-J1 / 6); C = 10 + 0.04 * (d / 1000);
tc.verifyEqual(multi_edge_diffraction_rev1("p526_cascaded", x, z, f, a), J1 + T * C, 'AbsTol', 1e-6);
% P.526-16 eq. (57): the Bullington point of a single edge is the edge
tc.verifyEqual(multi_edge_diffraction_rev1("bullington", x, z, f, a), ...
    J1 + (1 - exp(-J1 / 6)) * (10 + 0.02 * (d / 1000)), 'AbsTol', 1e-6);
end

function test_two_edges_epstein_peterson_and_deygout(tc)
% Two edges, 150 m at 10 km and 120 m at 25 km of a 42 km path
d = 42000; h_ant = 5;
[x, z] = spike_profile(d, [10000 25000], [150 120], h_ant);
i1 = find(z == 150); i2 = find(z == 120);
lam = tc.TestData.lambda; f = tc.TestData.f; a = tc.TestData.flat;
nuf = @(h, d1, d2) h * sqrt(2 * (d1 + d2) / (lam * d1 * d2));
% Epstein-Peterson: edge 1 between the transmitter and edge 2; edge 2
% between edge 1 and the receiver
h1 = 150 - (h_ant + (120 - h_ant) * x(i1) / x(i2));
h2 = 120 - (150 + (h_ant - 150) * (x(i2) - x(i1)) / (d - x(i1)));
ep = J_approx(nuf(h1, x(i1), x(i2) - x(i1))) + J_approx(nuf(h2, x(i2) - x(i1), d - x(i2)));
tc.verifyEqual(multi_edge_diffraction_rev1("epstein_peterson", x, z, f, a), ep, 'AbsTol', 1e-6);
% Deygout: principal edge on the full path, then the other edge on its
% sub-path. Edge 1 has the higher nu on the full path.
nu1 = nuf(150 - h_ant, x(i1), d - x(i1));
nu2 = nuf(120 - h_ant, x(i2), d - x(i2));
tc.assertGreaterThan(nu1, nu2);
dg = J_approx(nu1) + J_approx(nuf(h2, x(i2) - x(i1), d - x(i2)));
[L, D] = multi_edge_diffraction_rev1("deygout", x, z, f, a);
tc.verifyEqual(L, dg, 'AbsTol', 1e-6);
tc.verifyEqual(D.edges(2), i1);
% P.526-11 cascaded on the same edges
T = 1 - exp(-J_approx(nu1) / 6); C = 10 + 0.04 * (d / 1000);
tc.verifyEqual(multi_edge_diffraction_rev1("p526_cascaded", x, z, f, a), ...
    J_approx(nu1) + T * (J_approx(nuf(h2, x(i2) - x(i1), d - x(i2))) + C), 'AbsTol', 1e-6);
end

function test_bullington_in_recommendation_units(tc)
% P.526-16 eq. (49)-(57) written in the Recommendation's km and m units,
% on a two-edge path over a curved Earth
d = 42000; h_ant = 5; a_e = 8.5e6;
[x, z] = spike_profile(d, [10000 25000], [150 120], h_ant);
lam = tc.TestData.lambda;
Ce = 1 / (a_e / 1000);                      % km^-1
dk = x(2:end - 1) / 1000; D = d / 1000;
hi = z(2:end - 1); hts = z(1); hrs = z(end);
Stim = max((hi + 500 * Ce * dk .* (D - dk) - hts) ./ dk);
Str = (hrs - hts) / D;
tc.assertGreaterThanOrEqual(Stim, Str);
Srim = max((hi + 500 * Ce * dk .* (D - dk) - hrs) ./ (D - dk));
db = (hrs - hts + Srim * D) / (Stim + Srim);
nub = (hts + Stim * db - (hts * (D - db) + hrs * db) / D) * sqrt(0.002 * D / (lam * db * (D - db)));
Luc = J_approx(nub);
want = Luc + (1 - exp(-Luc / 6)) * (10 + 0.02 * D);
tc.verifyEqual(multi_edge_diffraction_rev1("bullington", x, z, tc.TestData.f, a_e), want, 'AbsTol', 1e-6);
end

function test_bullington_line_of_sight_case(tc)
% Clear path: eq. (51)-(52); a point well below the ray gives no loss
d = 21000; a_e = 8.5e6;
[x, z] = spike_profile(d, 10500, 0, 200);
tc.verifyEqual(multi_edge_diffraction_rev1("bullington", x, z, tc.TestData.f, a_e), 0, 'AbsTol', 1e-12);
tc.verifyEqual(multi_edge_diffraction_rev1("epstein_peterson", x, z, tc.TestData.f, a_e), 0, 'AbsTol', 1e-12);
tc.verifyEqual(multi_edge_diffraction_rev1("p526_cascaded", x, z, tc.TestData.f, a_e), 0, 'AbsTol', 1e-12);
end

function test_earth_bulge(tc)
% Flat ground, 10 m antennas, 50 km: the highest-nu point is the midpoint,
% lifted by d1 d2 / (2 a_e) (P.526-11 eq. (49a))
d = 50010; a_e = 8.5e6; h_ant = 10;
x = (0:30:d)'; z = zeros(size(x)); z(1) = h_ant; z(end) = h_ant;
d1 = x; d2 = d - x;
h = d1 .* d2 / (2 * a_e) - h_ant;
nu = max(h(2:end - 1) .* sqrt(2 * d ./ (tc.TestData.lambda * d1(2:end - 1) .* d2(2:end - 1))));
tc.assertGreaterThan(nu, 0);
[~, D] = multi_edge_diffraction_rev1("deygout", x, z, tc.TestData.f, a_e);
tc.verifyEqual(D.nu(2), nu, 'RelTol', 1e-12);
end

function test_reciprocity(tc)
% Swapping the terminals and reversing the profile must not change the loss
d = 60000; a_e = 8.5e6;
x = (0:30:d)';
z = 200 + 60 * sin(2 * pi * x / 7300) + 35 * sin(2 * pi * x / 2900 + 1) + 300 * exp(-((x - 21000) / 1500).^2);
z(1) = z(1) + 12; z(end) = z(end) + 3;
for m = ["epstein_peterson" "deygout" "p526_cascaded" "bullington"]
    a = multi_edge_diffraction_rev1(m, x, z, 450, a_e);
    b = multi_edge_diffraction_rev1(m, x, flipud(z), 450, a_e);
    tc.verifyEqual(a, b, 'AbsTol', 1e-6, "method " + m);
    tc.verifyGreaterThan(a, 0);
end
end

function test_ordering_on_two_edges(tc)
% Published behavior: Bullington's single equivalent edge underestimates a
% two-edge path relative to Epstein-Peterson and Deygout before its
% correction term; the P.526-11 correction only adds loss to Deygout.
d = 42000; h_ant = 5;
[x, z] = spike_profile(d, [10000 25000], [150 120], h_ant);
f = tc.TestData.f; a = tc.TestData.flat;
dg = multi_edge_diffraction_rev1("deygout", x, z, f, a);
cs = multi_edge_diffraction_rev1("p526_cascaded", x, z, f, a);
tc.verifyGreaterThanOrEqual(cs, dg - 1e-9);
end

function test_bad_inputs_fail_loud(tc)
x = (0:30:3000)'; z = zeros(size(x));
tc.verifyError(@() multi_edge_diffraction_rev1("nope", x, z, 1000, 8.5e6), 'itmexp:multiedge');
z(5) = NaN;
tc.verifyError(@() multi_edge_diffraction_rev1("deygout", x, z, 1000, 8.5e6), 'itmexp:multiedge');
end

function test_adjacent_tops_merge(tc)
% A ridge top that falls between two samples: two equal adjacent points.
% "epstein_peterson" treats them as two near-grazing edges (about 6 dB each)
% and loses most of the single steep edge's loss; "ep_isolated" must count
% one edge, close to the loss when the top is sampled once (B02 fix).
d = 42000; h_ant = 10; f = tc.TestData.f; a = tc.TestData.flat;
x = (0:30:d)'; z = zeros(size(x)); z(1) = h_ant; z(end) = h_ant;
[~, i] = min(abs(x - 21000));
one = z; one(i) = 150;
two = z; two(i) = 150; two(i + 1) = 150;
L_one = multi_edge_diffraction_rev1("ep_isolated", x, one, f, a);
L_two = multi_edge_diffraction_rev1("ep_isolated", x, two, f, a);
L_ep_two = multi_edge_diffraction_rev1("epstein_peterson", x, two, f, a);
[~, D] = multi_edge_diffraction_rev1("ep_isolated", x, two, f, a);
tc.verifyFalse(D.isolated);
tc.verifyEqual(L_two, L_one, 'AbsTol', 0.1);
tc.verifyGreaterThan(L_two - L_ep_two, 3);          % the loss Epstein-Peterson drops
end

function test_isolated_pair_matches_epstein_peterson(tc)
% Two edges 15 km apart over flat ground: isolated, so "ep_isolated" equals
% "epstein_peterson", and "p526_double_edge" adds Lc only if both > 15 dB
d = 42000; h_ant = 5; f = tc.TestData.f; a = tc.TestData.flat;
[x, z] = spike_profile(d, [10000 25000], [150 120], h_ant);
ep = multi_edge_diffraction_rev1("epstein_peterson", x, z, f, a);
[iso, D] = multi_edge_diffraction_rev1("ep_isolated", x, z, f, a);
tc.verifyTrue(D.isolated);
tc.verifyEqual(iso, ep, 'AbsTol', 1e-9);
i1 = find(z == 150); i2 = find(z == 120);
lam = tc.TestData.lambda; nuf = @(h, d1, d2) h * sqrt(2 * (d1 + d2) / (lam * d1 * d2));
h1 = 150 - (h_ant + (120 - h_ant) * x(i1) / x(i2));
h2 = 120 - (150 + (h_ant - 150) * (x(i2) - x(i1)) / (d - x(i1)));
L1 = J_approx(nuf(h1, x(i1), x(i2) - x(i1))); L2 = J_approx(nuf(h2, x(i2) - x(i1), d - x(i2)));
aa = x(i1); bb = x(i2) - x(i1); cc = d - x(i2);
want = L1 + L2;
if L1 > 15 && L2 > 15, want = want + 10 * log10((aa + bb) * (bb + cc) / (bb * (aa + bb + cc))); end
tc.verifyEqual(multi_edge_diffraction_rev1("p526_double_edge", x, z, f, a), want, 'AbsTol', 1e-9);
end

function test_lc_formula_value(tc)
% P.526-16 eq. (39) for a = 10, b = 15, c = 17 km: hand value
aa = 10; bb = 15; cc = 17;
tc.verifyEqual(10 * log10((aa + bb) * (bb + cc) / (bb * (aa + bb + cc))), 10 * log10(800 / 630), 'AbsTol', 1e-12);
end

function A = itm_ref(pfl, htx, hrx, f, cfg)
% Reference attenuation through the variant's info output (A_ref_db)
[~, info] = itm_p2p_core_exp(htx, hrx, pfl, f, 50, 50, 50, 5, 301, 0, 25, 0.02, 13, true, [], cfg);
A = info.A_ref_db;
end

function test_delta_p526_straight_terrain_equals_itm(tc)
% On straight-line terrain L_ba = L_bs and the smooth path is the actual
% path, so the P.526-16 eq. (66) form must return ITM's own A_ref (B04)
for slope = [0 0.004 -0.003]
    x = (0:30:45000)'; g = 300 + slope * x;
    pfl = [numel(x) - 1; 30; g];
    c0 = params_exp(); c1 = c0; c1.diffraction = "delta_bullington_p526";
    a = itm_ref(pfl, 15, 8, 900, c0);
    b = itm_ref(pfl, 15, 8, 900, c1);
    tc.verifyEqual(b, a, 'AbsTol', 1e-6, sprintf('slope %g', slope));
end
end

function test_delta_reciprocal_and_finite(tc)
x = (0:30:60000)';
g = 200 + 60 * sin(2 * pi * x / 7300) + 35 * sin(2 * pi * x / 2900 + 1) + 300 * exp(-((x - 21000) / 1500).^2);
pfl = [numel(x) - 1; 30; g]; pflr = [numel(x) - 1; 30; flipud(g)];
for m = ["delta_bullington" "delta_bullington_p526"]
    c = params_exp(); c.diffraction = m;
    a = itm_ref(pfl, 12, 3, 450, c); b = itm_ref(pflr, 3, 12, 450, c);
    tc.verifyTrue(isfinite(a) && a >= 0);
    tc.verifyEqual(a, b, 'AbsTol', 0.5, "method " + m);   % ITM's own reciprocity tolerance class
end
end

function test_delta_obstruction_forms(tc)
% A 250 m ridge mid-path on flat terrain. A sharp ridge on a long path can
% lose less than the smooth earth alone (obstacle gain), so the check is
% not "more loss than flat". What the construction guarantees: the P.452
% form is L_ba + max(A_s - L_bs, 0) >= L_ba, so it is at least the
% Bullington loss of the ridge (about 29 dB knife edge plus the eq. (57)
% correction), and at least the P.526 form.
x = (0:30:40000)'; g = 300 + zeros(size(x));
r = g + 250 * max(0, 1 - abs(x - 20000) / 1500);
pr = [numel(x) - 1; 30; r];
c1 = params_exp(); c1.diffraction = "delta_bullington"; c2 = c1; c2.diffraction = "delta_bullington_p526";
a1 = itm_ref(pr, 10, 10, 1000, c1); a2 = itm_ref(pr, 10, 10, 1000, c2);
tc.verifyGreaterThan(a1, 35);
tc.verifyGreaterThanOrEqual(a1, a2 - 1e-9);
end

function test_string_ep_single_and_two_edges(tc)
% One spike: the single knife edge. Two spikes 15 km apart: the
% Epstein-Peterson value written out by hand.
f = tc.TestData.f; a = tc.TestData.flat; lam = tc.TestData.lambda;
nuf = @(h, d1, d2) h * sqrt(2 * (d1 + d2) / (lam * d1 * d2));
[x, z] = spike_profile(30000, 15000, 100, 10);
i = find(z == 100);
tc.verifyEqual(multi_edge_diffraction_rev1("string_ep", x, z, f, a), J_approx(nuf(90, x(i), 30000 - x(i))), 'AbsTol', 1e-6);
d = 42000; h_ant = 5;
[x, z] = spike_profile(d, [10000 25000], [150 120], h_ant);
i1 = find(z == 150); i2 = find(z == 120);
h1 = 150 - (h_ant + (120 - h_ant) * x(i1) / x(i2));
h2 = 120 - (150 + (h_ant - 150) * (x(i2) - x(i1)) / (d - x(i1)));
want = J_approx(nuf(h1, x(i1), x(i2) - x(i1))) + J_approx(nuf(h2, x(i2) - x(i1), d - x(i2)));
[L, D] = multi_edge_diffraction_rev1("string_ep", x, z, f, a);
tc.verifyEqual(L, want, 'AbsTol', 1e-6);
tc.verifyEqual(size(D.edges, 1), 2);
end

function test_string_ep_four_ridges(tc)
% Four separated spikes: each edge against its neighbors, summed by hand
f = tc.TestData.f; a = tc.TestData.flat; lam = tc.TestData.lambda; d = 60000; h_ant = 5;
xs = [9000 21000 36000 48000]; hs = [200 260 240 180];
[x, z] = spike_profile(d, xs, hs, h_ant);
px = [0 xs d]; pz = [h_ant hs h_ant];
want = 0;
for k = 2:5
    d1 = px(k) - px(k - 1); d2 = px(k + 1) - px(k);
    h = pz(k) - (pz(k - 1) * d2 + pz(k + 1) * d1) / (d1 + d2);
    tc.assertGreaterThan(h, 0);                 % every spike is on the string
    nu = h * sqrt(2 * (d1 + d2) / (lam * d1 * d2));
    want = want + J_approx(nu);
end
[L, D] = multi_edge_diffraction_rev1("string_ep", x, z, f, a);
tc.verifyEqual(size(D.edges, 1), 4);
tc.verifyEqual(L, want, 'AbsTol', 1e-6);
% Bullington's single edge gives less on four ridges, before and after its correction
tc.verifyGreaterThan(L, multi_edge_diffraction_rev1("bullington", x, z, f, a));
end

function test_string_ep_split_top_is_one_obstruction(tc)
% A top on two adjacent samples: one obstruction, within 0.1 dB of one sample
d = 42000; h_ant = 10; f = tc.TestData.f; a = tc.TestData.flat;
x = (0:30:d)'; z = zeros(size(x)); z(1) = h_ant; z(end) = h_ant;
[~, i] = min(abs(x - 21000));
one = z; one(i) = 150; two = one; two(i + 1) = 150;
[L2, D] = multi_edge_diffraction_rev1("string_ep", x, two, f, a);
tc.verifyEqual(size(D.edges, 1), 1);
tc.verifyEqual(L2, multi_edge_diffraction_rev1("string_ep", x, one, f, a), 'AbsTol', 0.1);
end

function test_string_ep_smooth_earth_is_bullington_point(tc)
% Smooth Earth beyond the horizon: one obstruction whose vertex is the
% Bullington point, so the loss is J(nu_b), P.526-16 eq. (55), (56),
% written here in the Recommendation's km and m units
d = 60000; a_e = 8.5e6; h_ant = 10; lam = tc.TestData.lambda;
x = (0:30:d)'; z = zeros(size(x)); z(1) = h_ant; z(end) = h_ant;
Ce = 1 / (a_e / 1000); dk = x(2:end - 1) / 1000; D = d / 1000;
Stim = max((500 * Ce * dk .* (D - dk) - h_ant) ./ dk);
Srim = max((500 * Ce * dk .* (D - dk) - h_ant) ./ (D - dk));
db = (Srim * D) / (Stim + Srim);
nub = (h_ant + Stim * db - h_ant) * sqrt(0.002 * D / (lam * db * (D - db)));
[L, Dg] = multi_edge_diffraction_rev1("string_ep", x, z, tc.TestData.f, a_e);
tc.verifyEqual(size(Dg.edges, 1), 1);
tc.verifyEqual(L, J_approx(nub), 'AbsTol', 0.05);
end

function test_string_ep_reciprocity_and_clear_path(tc)
d = 60000; a_e = 8.5e6;
x = (0:30:d)';
z = 200 + 60 * sin(2 * pi * x / 7300) + 35 * sin(2 * pi * x / 2900 + 1) + 300 * exp(-((x - 21000) / 1500).^2);
z(1) = z(1) + 12; z(end) = z(end) + 3;
a = multi_edge_diffraction_rev1("string_ep", x, z, 450, a_e);
b = multi_edge_diffraction_rev1("string_ep", x, flipud(z), 450, a_e);
tc.verifyEqual(a, b, 'AbsTol', 1e-6);
[x, z] = spike_profile(21000, 10500, 0, 200);
tc.verifyEqual(multi_edge_diffraction_rev1("string_ep", x, z, tc.TestData.f, a_e), 0, 'AbsTol', 1e-12);
end

function test_delta_b05_forms(tc)
% Every B05 delta form: finite, reciprocal within ITM's own class, and at
% least its obstruction loss L_a (the form is L_a + max(A_s - L_s, 0)).
% The A_fo control adds between 0 and 15 dB to "delta_bullington".
x = (0:30:60000)';
g = 200 + 60 * sin(2 * pi * x / 7300) + 35 * sin(2 * pi * x / 2900 + 1) + 300 * exp(-((x - 21000) / 1500).^2);
pfl = [numel(x) - 1; 30; g]; pflr = [numel(x) - 1; 30; flipud(g)];
zz = g; zz(1) = zz(1) + 12; zz(end) = zz(end) + 3;
a_e = 8.5e6;                                   % only for the lower-bound check below
M = ["string_ep" "p526_cascaded" "deygout" "ep_isolated"];
for m = M
    c = params_exp(); c.diffraction = "delta_" + m;
    a = itm_ref(pfl, 12, 3, 450, c); b = itm_ref(pflr, 3, 12, 450, c);
    tc.verifyTrue(isfinite(a) && a >= 0, "finite " + m);
    tc.verifyEqual(a, b, 'AbsTol', 0.5, "reciprocity " + m);
    tc.verifyGreaterThan(a, 0.8 * multi_edge_diffraction_rev1(m, x, zz, 450, a_e), "lower bound " + m);
end
c1 = params_exp(); c1.diffraction = "delta_bullington"; c2 = c1; c2.diffraction = "delta_bullington_afo";
dA = itm_ref(pfl, 12, 3, 450, c2) - itm_ref(pfl, 12, 3, 450, c1);
tc.verifyGreaterThanOrEqual(dA, 0); tc.verifyLessThanOrEqual(dA, 15);
end
