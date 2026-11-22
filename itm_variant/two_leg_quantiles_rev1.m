function Y = two_leg_quantiles_rev1(z, Y1fun, Y2fun)
%TWO_LEG_QUANTILES_REV1 Quantiles of the sum of two independent time deviates (research package H03; batch B12).
%   Y = TWO_LEG_QUANTILES_REV1(z, Y1fun, Y2fun) returns, for each normal
%   deviate in z, the Phi(z) quantile of Y1(Z1) + Y2(Z2), with Z1, Z2
%   independent standard normals and Y1fun, Y2fun increasing functions of
%   the deviate (each leg's ITM time-variability curve Y_T). This is the
%   two-leg convolution of NBS Technical Note 101 section 10.8 under
%   independence. Deterministic quadrature on a fixed deviate grid
%   (-7.5 to 7.5, 1201 points, normal weights); no random numbers.
Zg = linspace(-7.5, 7.5, 1201)';
w = exp(-Zg.^2 / 2); w = w / sum(w);
y1 = Y1fun(Zg); y2 = Y2fun(Zg);
if any(diff(y1) < -1e-9) || any(diff(y2) < -1e-9) || ~all(isfinite([y1; y2]))
    error('itmexp:twoleg', 'Leg time deviates must be finite and increasing.');
end
S = y1 + y2.';                      % all pairs
W = w * w.';
[s, k] = sort(S(:));
F = cumsum(W(k));
F = (F - W(k) / 2);                 % mid-point CDF, symmetric in the two tails
[F, iu] = unique(F);
s = s(iu);
p = 0.5 * erfc(-z / sqrt(2));       % Phi(z)
Y = interp1(F, s, p, 'linear', 'extrap');
Y = reshape(Y, size(z));
end
