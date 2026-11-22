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
tc.TestData.nlcd_ids = struct('P2_VA_FOREST', "P2_VA_T1-010-R2_O", ...   % NLCD 41 at the VA receiver
    'P2_R3_URBAN', "P2_R3_R3-003-T1_O", 'P2_VA_PASTURE', "P2_VA_T1-003-R1_O");   % 23 at the R3 transmitter; 81
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

function test_cascaded_isolated_single_edge(tc)
% One spike on flat ground: no secondary edge, so L = J + T C with
% C = 10 + 0.04 D (P.526-11 eq. (50a), (51), (52)), computed here separately.
[x, z] = spike_profile(30000, 12000, 80, 10);
[L, D] = multi_edge_diffraction_rev1("p526_cascaded_isolated", x, z, tc.TestData.f, tc.TestData.flat);
h = 80 - 10; nu = h * sqrt(2 * 30000 / (tc.TestData.lambda * 12000 * 18000));
J = J_approx(nu);
tc.verifyEqual(L, J + (1 - exp(-J / 6)) * (10 + 0.04 * 30), 'AbsTol', 1e-9);
tc.verifyEqual(D.weight, [0 1 0]);
end

function test_cascaded_isolated_two_separated_edges(tc)
% Two spikes 9 km apart with flat ground between: the valley is far deeper
% than 0.6 F1, so the second spike counts in full (weight 1), as in Deygout.
[x, z] = spike_profile(30000, [9000 18000], [60 120], 10);
[L, D] = multi_edge_diffraction_rev1("p526_cascaded_isolated", x, z, tc.TestData.f, tc.TestData.flat);
lam = tc.TestData.lambda;
nu_p = (120 - 10) * sqrt(2 * 30000 / (lam * 18000 * 12000));
h_t = 60 - (10 + (120 - 10) * 9000 / 18000);
nu_t = h_t * sqrt(2 * 18000 / (lam * 9000 * 9000));
Jp = J_approx(nu_p);
tc.verifyEqual(L, Jp + (1 - exp(-Jp / 6)) * (J_approx(nu_t) + 10 + 0.04 * 30), 'AbsTol', 1e-9);
tc.verifyEqual(D.weight, [1 1 0]);
end

function test_cascaded_isolated_split_top_and_flank(tc)
% A top on two neighboring samples, and a triangular ridge: neither has a
% valley before the principal edge, so no secondary edge is counted. Plain
% P.526-11 counts the neighbor or the flank and gives more.
[x, z] = spike_profile(30000, [15000 15030], [100 100], 10);
[L, D] = multi_edge_diffraction_rev1("p526_cascaded_isolated", x, z, tc.TestData.f, tc.TestData.flat);
tc.verifyEqual(D.weight([1 3]), [0 0]);
tc.verifyLessThan(L, multi_edge_diffraction_rev1("p526_cascaded", x, z, tc.TestData.f, tc.TestData.flat) - 3);    % plain counts the neighboring sample as a grazing edge (about 6 dB)
x = (0:30:30000)'; z = 150 * max(0, 1 - abs(x - 15000) / 1500); z(1) = 10; z(end) = 10;
[L, D] = multi_edge_diffraction_rev1("p526_cascaded_isolated", x, z, tc.TestData.f, tc.TestData.flat);
tc.verifyEqual(D.weight([1 3]), [0 0]);
tc.verifyLessThanOrEqual(L, multi_edge_diffraction_rev1("p526_cascaded", x, z, tc.TestData.f, tc.TestData.flat) + 1e-9);
end

function test_cascaded_isolated_grows_from_zero(tc)
% Two hills joined by a saddle. As the saddle deepens from 0, the second
% hill's weight rises from 0 to 1 and the loss rises without a step.
x = (0:30:30000)';
depth = 0:0.5:30;
L = zeros(size(depth)); w = L;
for i = 1:numel(depth)
    z = zeros(size(x));
    k = x >= 12000 & x <= 18000;
    z(k) = 100 - depth(i) * sin(pi * (x(k) - 12000) / 6000);
    z(x == 18000) = 100.5;                     % the principal edge, a little higher
    z(1) = 10; z(end) = 10;
    [L(i), D] = multi_edge_diffraction_rev1("p526_cascaded_isolated", x, z, tc.TestData.f, tc.TestData.flat);
    w(i) = D.weight(1);
end
tc.verifyEqual(w(1), 0);
tc.verifyEqual(w(end), 1);
tc.verifyGreaterThanOrEqual(min(diff(w)), -1e-12);
tc.verifyLessThan(max(abs(diff(L))), 1.5);     % no step; each 0.5 m of depth adds little
tc.verifyGreaterThan(L(end) - L(1), 3);
end

function test_cascaded_isolated_reciprocity_and_smooth_earth(tc)
x = (0:30:60000)';
g = 200 + 60 * sin(2 * pi * x / 7300) + 35 * sin(2 * pi * x / 2900 + 1) + 300 * exp(-((x - 21000) / 1500).^2);
z = g; z(1) = z(1) + 12; z(end) = z(end) + 3;
a = multi_edge_diffraction_rev1("p526_cascaded_isolated", x, z, 450, 8.5e6);
b = multi_edge_diffraction_rev1("p526_cascaded_isolated", x, flipud(z), 450, 8.5e6);
tc.verifyEqual(a, b, 'AbsTol', 1e-6);
% Smooth Earth beyond the horizon: no valleys, so no secondary edges
z0 = zeros(size(x)); z0(1) = 10; z0(end) = 10;
[~, D] = multi_edge_diffraction_rev1("p526_cascaded_isolated", x, z0, 450, 8.5e6);
tc.verifyEqual(D.weight([1 3]), [0 0]);
end

function test_delta_b06_forms_and_bound(tc)
% B06 delta forms: finite, reciprocal within ITM's class, A_fo adds 0 to
% 15 dB. The troposcatter bound never raises the loss, and on a long
% smooth path in ITM's scatter region the bounded value is at most ITM's own.
x = (0:30:60000)';
g = 200 + 60 * sin(2 * pi * x / 7300) + 35 * sin(2 * pi * x / 2900 + 1) + 300 * exp(-((x - 21000) / 1500).^2);
pfl = [numel(x) - 1; 30; g]; pflr = [numel(x) - 1; 30; flipud(g)];
c1 = params_exp(); c1.diffraction = "delta_cascaded_isolated"; c2 = c1; c2.diffraction = "delta_cascaded_isolated_afo";
a = itm_ref(pfl, 12, 3, 450, c1); b = itm_ref(pflr, 3, 12, 450, c1);
tc.verifyTrue(isfinite(a) && a >= 0);
tc.verifyEqual(a, b, 'AbsTol', 0.5);
dA = itm_ref(pfl, 12, 3, 450, c2) - a;
tc.verifyGreaterThanOrEqual(dA, 0); tc.verifyLessThanOrEqual(dA, 15);
xl = (0:100:400000)'; pl = [numel(xl) - 1; 100; zeros(size(xl))];
c0 = params_exp();
for m = ["delta_bullington_afo" "delta_cascaded_isolated_afo" "delta_p526_cascaded"]
    for bd = ["itm_troposcatter" "itm_troposcatter_line"]
        cu = params_exp(); cu.diffraction = m; cb = cu; cb.diffraction_bound = bd;
        tc.verifyLessThanOrEqual(itm_ref(pfl, 12, 3, 450, cb), itm_ref(pfl, 12, 3, 450, cu) + 1e-9, "never raises " + m);
        tc.verifyLessThanOrEqual(itm_ref(pl, 10, 10, 1000, cb), itm_ref(pl, 10, 10, 1000, c0) + 1e-9, "scatter region " + m);
    end
end
cx = params_exp(); cx.diffraction = "delta_bullington"; cx.diffraction_bound = "nonsense";
tc.verifyError(@() itm_ref(pfl, 12, 3, 450, cx), 'itmexp:cfg');
end

function test_p2108_matches_ntia_test_vectors(tc)
% All NTIA/ITS P.2108 height-gain test vectors (github.com/NTIA/p2108-test-data,
% HeightGainTerminalCorrectionModelTestData.csv, MD5 of the copy used
% dff1d0fe1692cb4e03fd9726add47d71): the 18 valid rows (rtn 0) to the
% published 0.1 dB, and the 5 error rows (rtn 32-35) must fail loud.
% Columns: f (GHz), h (m), w_s (m), R (m), clutter type (1-6), A_h (dB).
% B07 checked only the 6 rows with Table 3 R and w_s = 27 m (B07 reviewer pass).
V = [1.5 2 27 10 1 16;   1.5 2 27 6 1 10.9;
    1.5 2 27 10 2 16;    1.5 2 27 6 2 10.9;
    1.5 2 27 10 3 20.5;  1.5 2 27 6 3 14.6;
    1.5 2 27 15 4 24.5;  1.5 2 27 6 4 14.6;
    1.5 2 27 15 5 24.5;  1.5 2 27 6 5 14.6;
    1.5 2 27 20 6 27.1;  1.5 2 27 6 6 14.6;
    3 3 15 15 6 29;      0.9 2.3 30 10 2 13.7;
    1.5 2.5 25 10 3 20.2; 0.03 2.1 24.5 9.8 3 5.7;
    1.7 30 24.5 9.8 3 0; 1.7 30 24.5 30 3 0];
names = ["water_sea" "open_rural" "suburban" "urban" "trees_forest" "dense_urban"];
tc.verifyEqual(size(V, 1), 18);
for i = 1:size(V, 1)
    a = p2108_height_gain_rev1(V(i, 1) * 1000, V(i, 2), names(V(i, 5)), "recommendation", ...
        R_m=V(i, 4), w_s_m=V(i, 3));
    tc.verifyEqual(a, V(i, 6), 'AbsTol', 0.051, sprintf('row %d', i));
end
E = [0.02 2 27 10 3; 4 2 27 10 3; 1 0 10 9 2; 2 1 0 9 6; 2 1 27 0 6];
for i = 1:size(E, 1)
    tc.verifyError(@() p2108_height_gain_rev1(E(i, 1) * 1000, E(i, 2), names(E(i, 5)), ...
        "recommendation", R_m=E(i, 4), w_s_m=E(i, 3)), 'itmexp:p2108', sprintf('error row %d', i));
end
% Defaults reproduce the Table 3 rows without overrides, and R is returned
[a, R] = p2108_height_gain_rev1(1500, 2, "trees_forest", "recommendation");
tc.verifyEqual(a, 24.5, 'AbsTol', 0.051); tc.verifyEqual(R, 15);
end

function test_p526_cylinders_knife_single_and_double(tc)
% ITU-R P.526-16 section 4.4 with zero-radius cylinders. One spike: the
% loss is J(nu) at the spike (eq. (33), (31)); sub-path losses are 0 over
% deep clearance and C_N = 1 for one cylinder. Two separated spikes: J of
% each edge seen from its neighbors (vertex to vertex) plus -20 log C_N,
% which for two cylinders equals eq. (39)'s L_c.
lam = tc.TestData.lambda; ae = tc.TestData.flat; f = tc.TestData.f;
[x, z] = spike_profile(30000, 12000, 100, 10);
s1 = 12000; s2 = 18000;
h = 100 - (10 * s2 + 10 * s1) / 30000;
nu = h * sqrt(2 * 30000 / (lam * s1 * s2));
[L, D] = multi_edge_diffraction_rev1("p526_cylinders_knife", x, z, f, ae);
tc.verifyEqual(L, J_approx(nu), 'AbsTol', 1e-9);
tc.verifyEqual(D.CN_db, 0, 'AbsTol', 1e-12);
a = 9000; b = 9000; c = 12000;
[x, z] = spike_profile(30000, [a a + b], [120 130], 10);
h1 = 120 - (10 * b + 130 * a) / (a + b);
h2 = 130 - (120 * c + 10 * b) / (b + c);
nu1 = h1 * sqrt(2 * (a + b) / (lam * a * b));
nu2 = h2 * sqrt(2 * (b + c) / (lam * b * c));
Lc = 10 * log10((a + b) * (b + c) / (b * (a + b + c)));               % eq. (39)
[L, D] = multi_edge_diffraction_rev1("p526_cylinders_knife", x, z, f, ae);
tc.verifyEqual(D.CN_db, Lc, 'AbsTol', 1e-9);
tc.verifyEqual(L, J_approx(nu1) + J_approx(nu2) + Lc, 'AbsTol', 1e-9);
end

function test_p526_cylinders_knife_los_continuity_reciprocity(tc)
% Line of sight: only the sub-path loss of Attachment 2, J(-C_F sqrt(2)),
% 0 with deep clearance. As a hill rises through the ray the loss changes
% smoothly (largest step under 0.6 dB for 0.25 m height steps: the
% sub-path term hands over to the cylinder term at grazing). Reversing the
% path gives the same loss on a rough profile.
lam = tc.TestData.lambda; ae = tc.TestData.flat; f = tc.TestData.f;
x = (0:30:30000)'; z = zeros(size(x)); z(1) = 30; z(end) = 30;
tc.verifyEqual(multi_edge_diffraction_rev1("p526_cylinders_knife", x, z, f, ae), 0);
bump = exp(-((x - 15000) / 1500).^2);
L = zeros(1, 161); H = 22:0.25:62;
for k = 1:numel(H)
    zz = H(k) * bump; zz(1) = 30; zz(end) = 30;
    L(k) = multi_edge_diffraction_rev1("p526_cylinders_knife", x, zz, f, ae);
end
tc.verifyLessThan(max(abs(diff(L))), 0.6);
tc.verifyGreaterThan(L(end), L(1));
% Below the ray: equals J(-C_F sqrt(2)) at the most intruding point
zz = 25 * bump; zz(1) = 30; zz(end) = 30;
i = (2:numel(x) - 1)'; F1 = sqrt(lam * x(i) .* (30000 - x(i)) / 30000);
CF = min((30 - zz(i)) ./ F1);
tc.verifyEqual(multi_edge_diffraction_rev1("p526_cylinders_knife", x, zz, f, ae), J_approx(-CF * sqrt(2)), 'AbsTol', 1e-9);
% Reciprocity on a rough profile with a curved Earth
g = 200 + 60 * sin(2 * pi * x / 7300) + 35 * sin(2 * pi * x / 2900 + 1) + 300 * exp(-((x - 21000) / 1500).^2);
z = g; z(1) = z(1) + 12; z(end) = z(end) + 3;
a = multi_edge_diffraction_rev1("p526_cylinders_knife", x, z, 450, 8.5e6);
b = multi_edge_diffraction_rev1("p526_cylinders_knife", x, flipud(z), 450, 8.5e6);
tc.verifyEqual(a, b, 'AbsTol', 1e-6);
end

function test_terminal_clutter_open_nlcd(tc)
% cfg.terminal_clutter_open = "nlcd" (B11): an open row whose mobile
% terminal is in NLCD forest gets ITM at max(h, R) plus A_h for trees/forest;
% developed medium intensity (23) gets "urban"; pasture (81) gets nothing;
% the reversed call matches; a concealed row is unchanged by the switch;
% missing path_id fails loud. Needs data/landcover/phase2_terminals_nlcd_rev1.csv.
x = (0:30:12000)';
g = 200 + 25 * sin(2 * pi * x / 3100) + 60 * exp(-((x - 7000) / 900).^2);
pfl = [numel(x) - 1; 30; g]; pflr = [numel(x) - 1; 30; flipud(g)];
c0 = params_exp();
c3 = c0; c3.terminal_clutter = "p2108_height_gain"; c3.terminal_clutter_base = "clutter_height";
c3.terminal_clutter_frange = "hold3";
cn = c3; cn.terminal_clutter_open = "nlcd";
cases = {"P2_VA_FOREST", "VA", "trees_forest"; "P2_R3_URBAN", "R3", "urban"; "P2_VA_PASTURE", "VA", ""};
ids = tc.TestData.nlcd_ids;
for k = 1:size(cases, 1)
    pid = ids.(cases{k, 1}); set_ = cases{k, 2}; ct = cases{k, 3};
    row = struct('set', set_, 'siting', "O", 'reversed', false, 'path_id', pid);
    rowr = row; rowr.reversed = true;
    htx = 7.3; hrx = 2; f = 1846;
    got = itm_ref(pfl, htx, hrx, f, setfield(cn, 'row', row)); %#ok<SFLD>
    if ct == ""
        tc.verifyEqual(got, itm_ref(pfl, htx, hrx, f, setfield(c3, 'row', row)), 'AbsTol', 1e-12, pid); %#ok<SFLD>
    else
        if set_ == "VA", hm = hrx; hs = [htx max(hrx, 15)]; else, hm = htx; hs = [max(htx, 15) hrx]; end
        A = p2108_height_gain_rev1(f, hm, ct, "hold3");
        tc.verifyEqual(got, itm_ref(pfl, hs(1), hs(2), f, c0) + A, 'AbsTol', 1e-9, pid);
    end
    if ct ~= ""
        if set_ == "VA", hsr = [max(hrx, 15) htx]; else, hsr = [hrx max(htx, 15)]; end
        tc.verifyEqual(itm_ref(pflr, hrx, htx, f, setfield(cn, 'row', rowr)), itm_ref(pflr, hsr(1), hsr(2), f, c0) + A, 'AbsTol', 1e-9); %#ok<SFLD>
    end
end
% "nlcd_forest": the forest row matches "nlcd"; the urban row gets nothing
cf = cn; cf.terminal_clutter_open = "nlcd_forest";
rowF = struct('set', "VA", 'siting', "O", 'reversed', false, 'path_id', ids.P2_VA_FOREST);
rowU = struct('set', "R3", 'siting', "O", 'reversed', false, 'path_id', ids.P2_R3_URBAN);
tc.verifyEqual(itm_ref(pfl, 7.3, 2, 1846, setfield(cf, 'row', rowF)), itm_ref(pfl, 7.3, 2, 1846, setfield(cn, 'row', rowF)), 'AbsTol', 1e-12); %#ok<SFLD>
tc.verifyEqual(itm_ref(pfl, 7.3, 2, 1846, setfield(cf, 'row', rowU)), itm_ref(pfl, 7.3, 2, 1846, setfield(c3, 'row', rowU)), 'AbsTol', 1e-12); %#ok<SFLD>
rowc = struct('set', "VA", 'siting', "C", 'reversed', false, 'path_id', ids.P2_VA_FOREST);
tc.verifyEqual(itm_ref(pfl, 7.3, 2, 1846, setfield(cn, 'row', rowc)), itm_ref(pfl, 7.3, 2, 1846, setfield(c3, 'row', rowc)), 'AbsTol', 1e-12); %#ok<SFLD>
rowx = struct('set', "VA", 'siting', "O", 'reversed', false);
tc.verifyError(@() itm_ref(pfl, 7.3, 2, 1846, setfield(cn, 'row', rowx)), 'itmexp:cfg'); %#ok<SFLD>
end

function test_params_overrides(tc)
% ITMEXP_OVERRIDES sets switches for one run without editing params_exp.m;
% unknown fields, protected fields, wrong types, and bad JSON fail loud;
% unset gives the defaults.
old = getenv('ITMEXP_OVERRIDES');
restore = onCleanup(@() setenv('ITMEXP_OVERRIDES', old));
setenv('ITMEXP_OVERRIDES', '');
c0 = params_exp();
tc.verifyEqual(c0.overrides, "");
setenv('ITMEXP_OVERRIDES', '{"diffraction":"delta_cascaded_isolated","terminal_clutter_db":16.75}');
c1 = params_exp();
tc.verifyEqual(c1.diffraction, "delta_cascaded_isolated");
tc.verifyEqual(c1.terminal_clutter_db, 16.75);
tc.verifyEqual(rmfield(c1, ["diffraction" "terminal_clutter_db" "overrides"]), ...
    rmfield(c0, ["diffraction" "terminal_clutter_db" "overrides"]));
for bad = ["{""nonsense"":1}" "{""version"":2}" "{""diffraction"":3}" "{""terminal_clutter_db"":""x""}" "{not json" "[1,2]"]
    setenv('ITMEXP_OVERRIDES', char(bad));
    tc.verifyError(@() params_exp(), 'itmexp:overrides', char(bad));
end
end

function test_p2108_hold3(tc)
% "hold3": above 3 GHz, A_h equals its value at 3 GHz; at or below 3 GHz it
% equals "recommendation".
for h = [2 6.6 7.3 14]
    a3 = p2108_height_gain_rev1(3000, h, "trees_forest", "recommendation");
    tc.verifyEqual(p2108_height_gain_rev1(9190, h, "trees_forest", "hold3"), a3, 'AbsTol', 1e-12);
    tc.verifyEqual(p2108_height_gain_rev1(4595, h, "trees_forest", "hold3"), a3, 'AbsTol', 1e-12);
    tc.verifyEqual(p2108_height_gain_rev1(1846, h, "trees_forest", "hold3"), ...
        p2108_height_gain_rev1(1846, h, "trees_forest", "recommendation"), 'AbsTol', 1e-12);
end
end

function test_terminal_clutter_base_height(tc)
% cfg.terminal_clutter_base = "clutter_height": on a concealed row the loss
% equals ITM with the mobile antenna at max(h, R) plus A_h at the actual
% height (ITU-R P.2108-1 section 3.1, Table 1); reversed gives the same;
% open rows and an antenna above R are unchanged by the base switch.
x = (0:30:30000)';
g = 200 + 40 * sin(2 * pi * x / 7300) + 120 * exp(-((x - 14000) / 1200).^2);
pfl = [numel(x) - 1; 30; g]; pflr = [numel(x) - 1; 30; flipud(g)];
c0 = params_exp();
c3 = c0; c3.terminal_clutter = "p2108_height_gain"; c3.terminal_clutter_base = "clutter_height";
c3.terminal_clutter_frange = "hold3";
for f = [450 1846 9190]
    for set_ = ["R2" "VA"]
        htx = 7.3; hrx = 2;
        row = struct('set', set_, 'siting', "C", 'reversed', false); rowr = row; rowr.reversed = true;
        if set_ == "VA", hm = hrx; hs = [htx 15]; else, hm = htx; hs = [15 hrx]; end
        A = p2108_height_gain_rev1(f, hm, "trees_forest", "hold3");
        want = itm_ref(pfl, hs(1), hs(2), f, c0) + A;
        tc.verifyEqual(itm_ref(pfl, htx, hrx, f, setfield(c3, 'row', row)), want, 'AbsTol', 1e-9, set_); %#ok<SFLD>
        tc.verifyEqual(itm_ref(pflr, hrx, htx, f, setfield(c3, 'row', rowr)), ...
            itm_ref(pflr, hs(2), hs(1), f, c0) + A, 'AbsTol', 1e-9, set_ + " reversed"); %#ok<SFLD>
        rowo = row; rowo.siting = "O";
        tc.verifyEqual(itm_ref(pfl, htx, hrx, f, setfield(c3, 'row', rowo)), itm_ref(pfl, htx, hrx, f, c0), 'AbsTol', 1e-12); %#ok<SFLD>
    end
end
% Mobile antenna above R: no height change and A_h = 0
row = struct('set', "VA", 'siting', "C", 'reversed', false);
tc.verifyEqual(itm_ref(pfl, 7.3, 20, 1846, setfield(c3, 'row', row)), itm_ref(pfl, 7.3, 20, 1846, c0), 'AbsTol', 1e-12); %#ok<SFLD>
cx = setfield(c3, 'row', row); cx.terminal_clutter_base = "nonsense"; %#ok<SFLD>
tc.verifyError(@() itm_ref(pfl, 7.3, 2, 1846, cx), 'itmexp:cfg');
end

function test_p2108_range_and_height(tc)
% Outside 0.03-3 GHz: error under "recommendation", allowed above 3 GHz
% under "extend". Loss is zero at or above R and falls as h rises.
tc.verifyError(@() p2108_height_gain_rev1(4000, 2, "trees_forest", "recommendation"), 'itmexp:p2108');
tc.verifyError(@() p2108_height_gain_rev1(20, 2, "trees_forest", "extend"), 'itmexp:p2108');
tc.verifyError(@() p2108_height_gain_rev1(1000, 0, "trees_forest", "extend"), 'itmexp:p2108');
tc.verifyError(@() p2108_height_gain_rev1(1000, 2, "shrubs", "extend"), 'itmexp:p2108');
tc.verifyEqual(p2108_height_gain_rev1(9190, 15, "trees_forest", "extend"), 0);
h = 1:0.5:15;
for f = [230 1846 9190]
    a = arrayfun(@(x) p2108_height_gain_rev1(f, x, "trees_forest", "extend"), h);
    tc.verifyLessThanOrEqual(max(diff(a)), 1e-12, sprintf('f %g', f));
end
% Extending eq. (2a): at 4.6 GHz and 2 m the value follows the formula
nu = 0.342 * sqrt(4.595) * sqrt(13 * atan(13 / 27) * 180 / pi);
tc.verifyEqual(p2108_height_gain_rev1(4595, 2, "trees_forest", "extend"), J_approx(nu) - 6.03, 'AbsTol', 1e-9);
end

function test_b07_obstruction_methods(tc)
% "deygout_isolated" = J_p + weighted secondary edges, no C or T;
% "bullington_uc" = Bullington without eq. (57).
[x, z] = spike_profile(30000, [9000 18000], [60 120], 10);
lam = tc.TestData.lambda;
nu_p = (120 - 10) * sqrt(2 * 30000 / (lam * 18000 * 12000));
h_t = 60 - (10 + (120 - 10) * 9000 / 18000);
nu_t = h_t * sqrt(2 * 18000 / (lam * 9000 * 9000));
L = multi_edge_diffraction_rev1("deygout_isolated", x, z, tc.TestData.f, tc.TestData.flat);
tc.verifyEqual(L, J_approx(nu_p) + J_approx(nu_t), 'AbsTol', 1e-9);
[x, z] = spike_profile(30000, 12000, 80, 10);
[Lb, D] = multi_edge_diffraction_rev1("bullington", x, z, tc.TestData.f, tc.TestData.flat);
Lu = multi_edge_diffraction_rev1("bullington_uc", x, z, tc.TestData.f, tc.TestData.flat);
tc.verifyEqual(Lu, J_approx(D.nu), 'AbsTol', 1e-9);
tc.verifyEqual(Lb - Lu, (1 - exp(-Lu / 6)) * (10 + 0.02 * 30), 'AbsTol', 1e-9);
% Reciprocal on a rough profile
x = (0:30:60000)';
g = 200 + 60 * sin(2 * pi * x / 7300) + 35 * sin(2 * pi * x / 2900 + 1) + 300 * exp(-((x - 21000) / 1500).^2);
z = g; z(1) = z(1) + 12; z(end) = z(end) + 3;
for m = ["deygout_isolated" "bullington_uc"]
    a = multi_edge_diffraction_rev1(m, x, z, 450, 8.5e6); b = multi_edge_diffraction_rev1(m, x, flipud(z), 450, 8.5e6);
    tc.verifyEqual(a, b, 'AbsTol', 1e-6, m);
end
end

function test_terminal_clutter_hook(tc)
% On a concealed Phase 2 row the clutter term adds exactly the P.2108 loss
% at the mobile terminal's height (transmitter in R1-R3, receiver in VA);
% the reversed call (terminals swapped, row.reversed = true) gives the same
% total; open rows get nothing; the constant control adds its constant; a
% clutter setting without cfg.row fails loud.
x = (0:30:30000)';
g = 200 + 40 * sin(2 * pi * x / 7300) + 120 * exp(-((x - 14000) / 1200).^2);
pfl = [numel(x) - 1; 30; g]; pflr = [numel(x) - 1; 30; flipud(g)];
c0 = params_exp(); c1 = c0; c1.terminal_clutter = "p2108_height_gain";
c2 = c0; c2.terminal_clutter = "constant"; c2.terminal_clutter_db = 7.5;
f = 1846;
for set_ = ["R2" "VA"]
    row = struct('set', set_, 'siting', "C", 'reversed', false);
    rowr = row; rowr.reversed = true;
    htx = 7.3; hrx = 2;
    if set_ == "VA", hm = hrx; else, hm = htx; end
    A = p2108_height_gain_rev1(f, hm, "trees_forest", "extend");
    tc.verifyGreaterThan(A, 0);
    d = itm_ref(pfl, htx, hrx, f, setfield(c1, 'row', row)) - itm_ref(pfl, htx, hrx, f, c0); %#ok<SFLD>
    tc.verifyEqual(d, A, 'AbsTol', 1e-9, set_);
    dr = itm_ref(pflr, hrx, htx, f, setfield(c1, 'row', rowr)) - itm_ref(pflr, hrx, htx, f, c0); %#ok<SFLD>
    tc.verifyEqual(dr, A, 'AbsTol', 1e-9, set_ + " reversed");
    d2 = itm_ref(pfl, htx, hrx, f, setfield(c2, 'row', row)) - itm_ref(pfl, htx, hrx, f, c0); %#ok<SFLD>
    tc.verifyEqual(d2, 7.5, 'AbsTol', 1e-9);
    cx = setfield(c1, 'row', row); cx.terminal_clutter = "nonsense"; %#ok<SFLD>
    tc.verifyError(@() itm_ref(pfl, htx, hrx, f, cx), 'itmexp:cfg');
end
row = struct('set', "R1", 'siting', "O", 'reversed', false);
tc.verifyEqual(itm_ref(pfl, 7.3, 2, f, setfield(c1, 'row', row)), itm_ref(pfl, 7.3, 2, f, c0)); %#ok<SFLD>
tc.verifyError(@() itm_ref(pfl, 7.3, 2, f, c1), 'itmexp:cfg');
% At defaults a row field changes nothing
tc.verifyEqual(itm_ref(pfl, 7.3, 2, f, setfield(c0, 'row', row)), itm_ref(pfl, 7.3, 2, f, c0)); %#ok<SFLD>
end
