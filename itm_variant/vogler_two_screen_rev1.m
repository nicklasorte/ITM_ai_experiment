function [L_db, A, D] = vogler_two_screen_rev1(x_m, z_m, f_mhz, rel_tol)
%VOGLER_TWO_SCREEN_REV1 Coupled diffraction loss over one or two knife edges (dB).
%   [L_db, A, D] = VOGLER_TWO_SCREEN_REV1(x_m, z_m, f_mhz) returns the loss
%   relative to free space of the field diffracted over N = 1 or 2 ideal
%   knife edges, by Vogler's multiple knife-edge attenuation function:
%   L. E. Vogler, NTIA TR-83-124 sections 2-3, and "An attenuation
%   function for multiple knife-edge diffraction," Radio Science 17(6),
%   1982 (the same form):
%     A_N = (1/2^N) C_N exp(sigma_N) (2/sqrt(pi))^N I_N
%     I_N = int_{beta_1}^inf ... int_{beta_N}^inf exp(2 f - sum x_m^2) dx
%     f   = sum_{m=1}^{N-1} alpha_m (x_m - beta_m)(x_{m+1} - beta_{m+1})
%     alpha_m = sqrt(r_m r_{m+2} / ((r_m + r_{m+1})(r_{m+1} + r_{m+2})))
%     beta_m  = theta_m sqrt(i k r_m r_{m+1} / (2 (r_m + r_{m+1})))
%     sigma_N = sum beta_m^2,  C_1 = 1,
%     C_N = sqrt(r_2 ... r_N (r_1 + ... + r_{N+1}) /
%                ((r_1 + r_2)(r_2 + r_3) ... (r_N + r_{N+1})))
%   with r_m the distances between successive points (transmitter, edges,
%   receiver) and theta_m the bending angle at edge m (positive when the
%   edge obstructs). L_db = -20 log10 |A_N|.
%
%   x_m, z_m: the N + 2 points, transmitter first: horizontal distance from
%   the transmitter (m, increasing) and height (m) on a flat Earth. The
%   caller applies any Earth curvature first (for example the bulge
%   x (d - x) / (2 a_e) of ITU-R P.526-11 eq. (49a)). Paraxial geometry:
%   r_m are horizontal distances and angles are slopes.
%   rel_tol (optional, default 1e-10): relative tolerance of the integral.
%
%   Evaluation. Substituting x_m = beta_m + t_m cancels exp(sigma_N), and
%   the inner integral of N = 2 is closed in terms of the Faddeeva function
%   w (faddeeva_w_rev1):
%     A_1 = w(i beta_1) / 2
%     A_2 = C_2 / (2 sqrt(pi)) int_0^inf exp(-t^2 - 2 beta_1 t) w(i (beta_2 - alpha_1 t)) dt
%   The remaining integral is done with MATLAB's integral on [0, T], with T
%   where the integrand is below exp(-80) of its scale; where Re of
%   beta_2 - alpha_1 t is negative, w is reflected (A&S 7.1.11) inside the
%   exponent so nothing overflows.
%
%   D: alpha, beta, C, nu (edge-to-edge diffraction parameters, nu_m =
%   theta_m sqrt(2 r_m r_{m+1} / (lambda (r_m + r_{m+1})))), L_ep_db (the
%   sum of exact single-edge losses at those nu: independent edges,
%   Epstein-Peterson), and L_c_db = -20 log10 C_N (the spacing term; for
%   N = 2 it equals ITU-R P.526-16 eq. (39)).
%
%   Checks (itm_variant/tests/test_diffraction_rev1.m): the five two-edge
%   cases 21-25 of NTIA TR-26-580 Table 12 reproduce its Table 17 Vogler
%   values to 0.001 dB; N = 1 gives the exact Fresnel knife edge; reversal
%   is exact; at large nu, L_db tends to L_ep_db + L_c_db.
%   Batch B16a. No fitted constants.

if nargin < 4 || isempty(rel_tol)
    rel_tol = 1e-10;
end
x_m = x_m(:); z_m = z_m(:);
n = numel(x_m);
if numel(z_m) ~= n || ~any(n == [3 4])
    error('itmexp:vogler', 'Give 3 or 4 points (one or two edges); got %d.', n);
end
if ~all(isfinite([x_m; z_m])) || any(diff(x_m) <= 0)
    error('itmexp:vogler', 'Points must be finite with increasing distances.');
end
if ~(f_mhz > 0) || ~(rel_tol > 0)
    error('itmexp:vogler', 'Frequency and tolerance must be positive.');
end
lambda = 299.792458 / f_mhz;            % m; speed of light, exact SI value
k = 2 * pi / lambda;
r = diff(x_m);
s = diff(z_m) ./ r;                     % slope of each leg
N = n - 2;
theta = s(1:N) - s(2:N + 1);            % bending angle at each edge
beta = zeros(N, 1); nu = zeros(N, 1);
for m = 1:N
    beta(m) = theta(m) * sqrt(1i * k * r(m) * r(m + 1) / (2 * (r(m) + r(m + 1))));
    nu(m) = theta(m) * sqrt(2 * r(m) * r(m + 1) / (lambda * (r(m) + r(m + 1))));
end
if N == 1
    alpha = [];
    C = 1;
    A = faddeeva_w_rev1(1i * beta) / 2;
else
    alpha = sqrt(r(1) * r(3) / ((r(1) + r(2)) * (r(2) + r(3))));
    C = sqrt(r(2) * sum(r) / ((r(1) + r(2)) * (r(2) + r(3))));
    b1 = beta(1); b2 = beta(2);
    T = sqrt(80 / (1 - alpha^2)) + 2 * abs(real(b1)) + 2 * abs(real(b2)) / max(alpha, 1e-3);
    I = integral(@integrand, 0, T, 'RelTol', rel_tol, 'AbsTol', 1e-15);
    A = C / (2 * sqrt(pi)) * I;
end
if ~isfinite(A) || A == 0
    error('itmexp:vogler', 'Attenuation function is not finite or is zero.');
end
L_db = -20 * log10(abs(A));
L1 = zeros(N, 1);
for m = 1:N
    L1(m) = -20 * log10(abs(faddeeva_w_rev1(1i * beta(m)) / 2));
end
D = struct('alpha', alpha, 'beta', beta, 'C', C, 'nu', nu, 'theta', theta, ...
    'L_ep_db', sum(L1), 'L_c_db', -20 * log10(C));

    function g = integrand(t)
        zz = b2 - alpha * t;
        e = -t.^2 - 2 * b1 * t;
        g = zeros(size(t));
        pos = real(zz) >= 0;
        g(pos) = exp(e(pos)) .* faddeeva_w_rev1(1i * zz(pos));
        q = ~pos;
        % w(i zz) = 2 exp(zz^2) - w(-i zz), with exp(zz^2) folded into the exponent
        g(q) = 2 * exp(e(q) + zz(q).^2) - exp(e(q)) .* faddeeva_w_rev1(-1i * zz(q));
    end
end
