function R = pe2d_tests_rev2(root)
%PE2D_TESTS_REV2 Validation of pe2d_rev2 (B37 D37a; experiments/batches/B37.md section 2).
%   R = PE2D_TESTS_REV2(root) runs:
%     T1-T6 the B36 tests (pe2d_tests_rev1) with pe2d_rev2 in place of
%        pe2d_rev1, repairs off: same limits.
%     T7 impedance flat ground (Epsilon 25, Sigma 0.02 S/m, the evaluator's
%        settings_rev1 values): 2D two-ray with the Fresnel coefficient for
%        horizontal polarization, F = 1 + G sqrt(R1/R2) exp(i k (R2 - R1));
%        230 and 910 MHz; transmitter 2 and 20 m; 1 and 20 km; receivers
%        2 to 20 m. Pass: |error| <= 0.2 dB where |F_exact| > -20 dB.
%     T8 10 degree plane, two-ray of the tilted plane (as T6). Pass: "wide"
%        within 0.3 dB; "narrow"'s error reported.
%     T9 range average: flat conducting ground, AvgFine; reference the mean
%        of the two-ray power at the same window positions. Pass: within
%        0.1 dB, and at least 40 samples in the window.
%     T10 roughness limit: RoughSigma 1e-12 equals no roughness to 1e-9 dB
%        (RoughSigma 0 skips the branch, so a tiny value is used; the
%        Miller-Brown-Vegh factor is then 1 to rounding).
%   A0 (bit parity with pe2d_rev1 on the B36 rows) and A1 (convergence)
%   run in d37a_run_rev1. Fails loud on any failure.
arguments
    root (1,1) string
end
itm_exp_paths_rev1(); St = settings_rev1();
R = struct(); c = 299.792458; fails = strings(0, 1);

% ---- T1-T6: rev1's tests through rev2 (a temporary copy with the call renamed)
src = fileread(fullfile(root, 'experiments', 'batches', 'pe2d_tests_rev1.m'));
src = strrep(src, 'pe2d_rev1(', 'pe2d_rev2(');
src = strrep(src, 'function R = pe2d_tests_rev1(root)', 'function R = pe2d_tests_rev1_via_rev2(root)');
td = tempname; mkdir(td); fid = fopen(fullfile(td, 'pe2d_tests_rev1_via_rev2.m'), 'w'); fwrite(fid, src); fclose(fid);
addpath(td); c0 = onCleanup(@() rmpath(td));
try
    R.T1_T6 = pe2d_tests_rev1_via_rev2(root);
catch ME
    fprintf('T1-T6 via rev2: %s\n', ME.message); fails(end + 1) = "T1-T6";
end

% ---- T7: impedance flat ground against two-ray with the Fresnel coefficient
e7 = [];
for f = [230 910]
    lam = c / f; k = 2 * pi / lam; n2 = St.epsilon + 1i * 60 * lam * St.sigma;
    for h1 = [2 20]
        for d = [1000 20000]
            h2 = 2:1:20;
            npt = round(d / 10);
            pfl = [npt; d / npt; zeros(npt + 1, 1)];
            o = pe2d_rev2(f, h1, pfl, 0, h2, FlatZ=true, WindowLambda=0, Ground="impedance", ...
                Epsilon=St.epsilon, Sigma=St.sigma);
            R1 = sqrt(d^2 + (h2 - h1).^2); R2 = sqrt(d^2 + (h2 + h1).^2);
            g = (h1 + h2) ./ R2; cg2 = 1 - g.^2;
            G = (g - sqrt(n2 - cg2)) ./ (g + sqrt(n2 - cg2));
            Fx = 1 + G .* sqrt(R1 ./ R2) .* exp(1i * k * (R2 - R1));
            sel = abs(Fx) > 10^(-20 / 20);
            ea = max(abs(20 * log10(abs(o.F)) - 20 * log10(abs(Fx))));    % all heights, for the record
            if any(sel)
                e = max(abs(20 * log10(abs(o.F(sel))) - 20 * log10(abs(Fx(sel)))));
                e7(end + 1) = e; %#ok<AGROW>
                fprintf('T7 impedance %d MHz, h1 %d m, %d km: max error %.3f dB on %d heights (limit 0.2); all heights %.3f dB\n', f, h1, d / 1000, e, nnz(sel), ea);
            else
                fprintf('T7 impedance %d MHz, h1 %d m, %d km: no height above -20 dB (case uninformative); all heights %.3f dB\n', f, h1, d / 1000, ea);
            end
        end
    end
end
R.T7_err_db = e7;
if ~all(e7 <= 0.2), fails(end + 1) = "T7"; end

% ---- T8: 10 degree plane
f = 410; lam = c / f; k = 2 * pi / lam;
d = 4000; sl = tand(10); h1 = 20; h2 = 1:0.5:40;
pfl = [400; d / 400; sl * (0:400)' * (d / 400)];
ca = 1 / sqrt(1 + sl^2);
dp = d / ca; a1 = h1 * ca; a2 = h2 * ca;
R1 = sqrt(dp^2 + (a2 - a1).^2); R2 = sqrt(dp^2 + (a2 + a1).^2);
Fx = 1 - sqrt(R1 ./ R2) .* exp(1i * k * (R2 - R1));
sel = abs(Fx) > 10^(-10 / 20);
on = pe2d_rev2(f, h1, pfl, 0, h2, WindowLambda=0, Propagator="narrow");
ow = pe2d_rev2(f, h1, pfl, 0, h2, WindowLambda=0, Propagator="wide");
en = max(abs(20 * log10(abs(on.F(sel))) - 20 * log10(abs(Fx(sel)))));
ew = max(abs(20 * log10(abs(ow.F(sel))) - 20 * log10(abs(Fx(sel)))));
R.T8_narrow_db = en; R.T8_wide_db = ew;
fprintf('T8 10 deg plane: narrow %.3f dB, wide %.3f dB (limit 0.3 for wide)\n', en, ew);
if ~(ew <= 0.3), fails(end + 1) = "T8"; end

% ---- T9: range average over flat conducting ground
f = 910; lam = c / f; k = 2 * pi / lam;
d = 3000; h1 = 10; h2 = [3 7 15];
pfl = [100; 30; zeros(101, 1)];
o = pe2d_rev2(f, h1, pfl, 0, h2, FlatZ=true, WindowLambda=20, AvgFine=true);
% window positions, rebuilt as pe2d_rev2 builds them for this geometry
xw = d - 20 * lam; m = ceil((d - xw) / (lam / 2) - 1e-9);
xr = xw + (1:m)' * (d - xw) / m;
if numel(xr) ~= o.nwin, error('itmexp:pe2d', 'T9 window rebuild: %d positions, PE %d.', numel(xr), o.nwin); end
P2 = zeros(numel(xr), numel(h2));
for q = 1:numel(xr)
    R1 = sqrt(xr(q)^2 + (h2 - h1).^2); R2 = sqrt(xr(q)^2 + (h2 + h1).^2);
    P2(q, :) = abs(1 - sqrt(R1 ./ R2) .* exp(1i * k * (R2 - R1))).^2;
end
Ax = -10 * log10(mean(P2, 1));
e9 = max(abs(o.A_db - Ax));
R.T9_err_db = e9; R.T9_nwin = o.nwin;
fprintf('T9 range average: max error %.3f dB, %d samples (limits 0.1 dB, 40)\n', e9, o.nwin);
if ~(e9 <= 0.1 && o.nwin >= 40), fails(end + 1) = "T9"; end

% ---- T10: roughness limit
f = 410; d = 5000; pfl = [500; 10; zeros(501, 1)]; h2 = [2 5 10];
a = pe2d_rev2(f, 10, pfl, 0, h2, FlatZ=true, WindowLambda=0, Ground="impedance", Epsilon=St.epsilon, Sigma=St.sigma);
b = pe2d_rev2(f, 10, pfl, 0, h2, FlatZ=true, WindowLambda=0, Ground="impedance", Epsilon=St.epsilon, Sigma=St.sigma, ...
    RoughSigma=1e-12, SinGraze=0.004);
e10 = max(abs(a.A_db - b.A_db));
R.T10_db = e10;
fprintf('T10 roughness limit: %.3g dB (limit 1e-9)\n', e10);
if ~(e10 <= 1e-9), fails(end + 1) = "T10"; end

R.fails = fails; R.pass = isempty(fails);
if ~R.pass, error('itmexp:pe2d', 'PE rev 2 validation failed: %s.', strjoin(fails, ', ')); end
fprintf('PE rev 2 validation: all pass\n');
end
