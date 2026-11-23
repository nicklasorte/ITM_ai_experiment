function w = faddeeva_w_rev1(z)
%FADDEEVA_W_REV1 Faddeeva function w(z) = exp(-z^2) erfc(-iz), complex z.
%   w = FADDEEVA_W_REV1(z) works elementwise on any complex array.
%
%   Upper half-plane (Im z >= 0): the rational approximation of Weideman,
%   "Computation of the complex error function," SIAM J. Numer. Anal.
%   31(5), 1994, pp. 1497-1518, eq. (3.3)-(3.6), with N = 40 terms and the
%   paper's optimal L = sqrt(N/sqrt(2)). Lower half-plane: the reflection
%   identity w(z) = 2 exp(-z^2) - w(-z) (Abramowitz and Stegun 7.1.11).
%   N = 40 is the paper's choice for full double precision; against SciPy's
%   wofz (an independent implementation) the relative error is below
%   2e-14 on |Re z|, Im z <= 40 (B16 planner check, 2026-11-23).
%
%   Used by vogler_two_screen_rev1 (batch B16a) for the complex error
%   function that MATLAB's erfc doesn't provide.

persistent a L
if isempty(a)
    N = 40;
    M = 2 * N;
    k = (-M + 1:M - 1)';
    L = sqrt(N / sqrt(2));
    t = L * tan(k * pi / (2 * M));
    f = [0; exp(-t.^2) .* (L^2 + t.^2)];
    a = real(fft(fftshift(f))) / (2 * M);
    a = flipud(a(2:N + 1));
end
if ~isnumeric(z) || ~all(isfinite(z(:)))
    error('itmexp:faddeeva', 'z must be finite and numeric.');
end
w = zeros(size(z));
up = imag(z) >= 0;
w(up) = upper_half(z(up));
zl = z(~up);
w(~up) = 2 * exp(-zl.^2) - upper_half(-zl);

    function v = upper_half(zz)
        Z = (L + 1i * zz) ./ (L - 1i * zz);
        p = polyval(a, Z);
        v = 2 * p ./ (L - 1i * zz).^2 + (1 / sqrt(pi)) ./ (L - 1i * zz);
    end
end
