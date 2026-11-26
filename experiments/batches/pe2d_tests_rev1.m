function R = pe2d_tests_rev1(root)
%PE2D_TESTS_REV1 Validation of pe2d_rev1 against analytic references (B36 check 1).
%   R = PE2D_TESTS_REV1(root) runs:
%     T1 flat perfectly conducting ground, no refraction: two-ray field in
%        2D, F = 1 - sqrt(R1/R2) exp(i k (R2 - R1)), over a height scan;
%        pass if |dB error| < 0.5 where |F_exact| > -10 dB.
%     T2 single knife edge over a flat conducting ground: four-path
%        Kirchhoff diffraction (source and image to the edge top to
%        receiver and image, Dirichlet signs, Fresnel integral with the
%        e^{+ikr} convention); pass if |dB error| < 1.0 where
%        |F_exact| > -25 dB.
%     T3 smooth earth beyond the horizon: ITU-R P.452-18 section 4.2.2
%        (itm_variant/spherical_earth_diffraction_rev1, horizontal
%        polarization), with the same effective radius; pass if |error|
%        < 2.0 dB (the PE ground is a perfect conductor, P.452's is land).
%     T6 uniform 5.7 degree slope: two-ray field of the tilted plane; pass
%        if |dB error| < 0.5 where |F_exact| > -10 dB.
%     T4 absorber 0.5 at 2e-2 against 0.65 at 4e-2 on a gentle real Phase 2
%        profile (R1, steepest interval under 5 degrees);
%        pass if < 0.2 dB.
%     T5 grid halving (dz and dx) on the same profile; pass if < 0.5 dB.
%   Tolerances are planner choices. Fails loud on any failure.
arguments
    root (1,1) string
end
itm_exp_paths_rev1();
R = struct();
c = 299.792458;

% ---- T1: two-ray over flat conducting ground
f = 410; lam = c / f; k = 2 * pi / lam;
d = 5000; h1 = 20; h2 = 1:0.5:60;
pfl = [500; d / 500; zeros(501, 1)];
o = pe2d_rev1(f, h1, pfl, 0, h2, FlatZ=true, WindowLambda=0);
R1 = sqrt(d^2 + (h2 - h1).^2); R2 = sqrt(d^2 + (h2 + h1).^2);
Fx = 1 - sqrt(R1 ./ R2) .* exp(1i * k * (R2 - R1));
sel = abs(Fx) > 10^(-10 / 20);
e1 = max(abs(20 * log10(abs(o.F(sel))) - 20 * log10(abs(Fx(sel)))));
R.T1_max_err_db = e1;
fprintf('T1 two-ray: max error %.3f dB on %d heights (limit 0.5)\n', e1, nnz(sel));

% ---- T2: knife edge over flat conducting ground (four paths)
f = 410; lam = c / f; k = 2 * pi / lam;
d = 4000; d1 = 2000; Hk = 40; h1 = 10; h2 = 2:2:60;
pfl = [400; d / 400; zeros(401, 1)];
o = pe2d_rev1(f, h1, pfl, 0, h2, FlatZ=true, WindowLambda=0, Knife=[d1, Hk]);
Fx = zeros(size(h2));
for j = 1:numel(h2)
    Rd = sqrt(d^2 + (h2(j) - h1)^2);
    acc = 0;
    for a = [1 -1]
        for b = [1 -1]
            za = a * h1; zbb = b * h2(j);
            r = sqrt(d^2 + (zbb - za)^2);
            zl = za + (zbb - za) * d1 / d;                  % line of sight at the edge
            hh = Hk - zl;                                   % edge height above it
            nu = hh * sqrt(2 * d / (lam * d1 * (d - d1)));
            acc = acc + a * b * fresnel_factor(nu) * sqrt(Rd / r) * exp(1i * k * (r - Rd));
        end
    end
    Fx(j) = acc;
end
sel = abs(Fx) > 10^(-25 / 20);
e2 = max(abs(20 * log10(abs(o.F(sel))) - 20 * log10(abs(Fx(sel)))));
R.T2_max_err_db = e2;
fprintf('T2 knife edge: max error %.3f dB on %d heights (limit 1.0)\n', e2, nnz(sel));

% ---- T3: smooth earth beyond the horizon
gamma_e = 157e-9 * (1 - 0.04665 * exp(301 / 179.3));       % ITM's effective curvature at N_s = 301
ae_km = 1e-3 / gamma_e;
T3 = [];
for f = [230 910]
    d = 80e3; h1 = 20; h2 = 10;
    pfl = [2666; d / 2666; zeros(2667, 1)];
    o = pe2d_rev1(f, h1, pfl, gamma_e, h2, FlatZ=true, WindowLambda=20);
    Lref = spherical_earth_diffraction_rev1(d / 1000, h1, h2, ae_km, f / 1000, 0);
    T3(end + 1) = o.A_db - Lref; %#ok<AGROW>
    fprintf('T3 smooth earth %d MHz: PE %.2f dB, P.452 %.2f dB, error %+.2f dB (limit 2.0)\n', f, o.A_db, Lref, T3(end));
end
R.T3_err_db = T3;

% ---- T6: uniform slope (5.7 degrees): the shift map is exact there, so the
% field is the two-ray field of the tilted plane (distance along the
% plane, heights perpendicular to it)
f = 410; lam = c / f; k = 2 * pi / lam;
d = 4000; sl = 0.1; h1 = 20; h2 = 1:0.5:40;
pfl = [400; d / 400; sl * (0:400)' * (d / 400)];
o = pe2d_rev1(f, h1, pfl, 0, h2, WindowLambda=0);
ca = 1 / sqrt(1 + sl^2);
dp = d / ca; a1 = h1 * ca; a2 = h2 * ca;                   % along-plane distance, perpendicular heights
R1 = sqrt(dp^2 + (a2 - a1).^2); R2 = sqrt(dp^2 + (a2 + a1).^2);
Fx = 1 - sqrt(R1 ./ R2) .* exp(1i * k * (R2 - R1));
sel = abs(Fx) > 10^(-10 / 20);
e6 = max(abs(20 * log10(abs(o.F(sel))) - 20 * log10(abs(Fx(sel)))));
R.T6_max_err_db = e6;
fprintf('T6 tilted plane (%.1f deg): max error %.3f dB on %d heights (limit 0.5)\n', atand(sl), e6, nnz(sel));

% ---- T4, T5: a gentle real Phase 2 profile (R1, steepest interval under 5 degrees, longest such)
P = load_profiles_rev1(root);
best = 0; pr = [];
for q = P
    if startsWith(q.path_id, "P2_R1_") && endsWith(q.path_id, "_O")
        ms = max(abs(diff(q.h_m))) / q.spacing_m;
        if ms < tand(5) && q.d_km > best
            best = q.d_km; pr = q;
        end
    end
end
if isempty(pr), error('itmexp:pe2d', 'No gentle R1 profile found for T4/T5.'); end
pfl = [numel(pr.h_m) - 1; pr.spacing_m; pr.h_m(:)];
gamma_e = 157e-9 * (1 - 0.04665 * exp(pr.N_0 / 179.3));
f = 910; h2 = [1 3 9];
base = pe2d_rev1(f, 7.3, pfl, gamma_e, h2);
thick = pe2d_rev1(f, 7.3, pfl, gamma_e, h2, AbsorbFrac=0.65, AbsorbRate=4e-2);
fine = pe2d_rev1(f, 7.3, pfl, gamma_e, h2, DzLambda=0.125, DxMax=base.dx / 2);
e4 = max(abs(thick.A_db - base.A_db)); e5 = max(abs(fine.A_db - base.A_db));
R.T4_max_db = e4; R.T5_max_db = e5; R.T45_path = pr.path_id; R.T45_A_db = base.A_db;
fprintf('T4 absorber variant on %s (%.1f km, 910 MHz): max change %.3f dB (limit 0.2)\n', pr.path_id, pr.d_km, e4);
fprintf('T5 grid halved on %s: max change %.3f dB (limit 0.5); A = %s dB\n', pr.path_id, e5, mat2str(round(base.A_db, 2)));

fails = strings(0, 1);
if ~(e1 < 0.5), fails(end + 1) = "T1"; end
if ~(e2 < 1.0), fails(end + 1) = "T2"; end
if ~all(abs(T3) < 2.0), fails(end + 1) = "T3"; end
if ~(e4 < 0.2), fails(end + 1) = "T4"; end
if ~(e5 < 0.5), fails(end + 1) = "T5"; end
if ~(e6 < 0.5), fails(end + 1) = "T6"; end
R.pass = isempty(fails);
if ~R.pass
    error('itmexp:pe2d', 'PE validation failed: %s.', strjoin(fails, ', '));
end
fprintf('PE validation: all pass\n');
end

function F = fresnel_factor(nu)
% Knife-edge field relative to free space for edge clearance parameter nu,
% e^{+ikr} convention: F = ((1 - 1i)/2) * int_nu^inf exp(1i*pi*t^2/2) dt.
I0 = integral(@(t) exp(1i * pi * t.^2 / 2), 0, nu);        % int_0^nu
F = ((1 - 1i) / 2) * ((1 + 1i) / 2 - I0);                   % int_0^inf = (1 + 1i)/2
end
