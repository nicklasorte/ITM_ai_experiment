function L = spherical_earth_diffraction_rev1(d_km, hte_m, hre_m, ae_km, f_ghz, pol)
%SPHERICAL_EARTH_DIFFRACTION_REV1 Spherical-earth diffraction loss L_dsph (dB).
%   L = spherical_earth_diffraction_rev1(d_km, hte_m, hre_m, ae_km, f_ghz, pol)
%   ITU-R P.452-18 section 4.2.2, eq. (23)-(37), over land (omega = 0, so
%   eq. (29) reduces to the land term with epsilon_r = 22 and sigma = 0.003
%   S/m). The same procedure as ITU-R P.526-16 section 3.2.
%     d_km   path length (km)
%     hte_m  transmitter height above the smooth surface (m)
%     hre_m  receiver height above the smooth surface (m)
%     ae_km  effective earth radius (km)
%     f_ghz  frequency (GHz)
%     pol    0 horizontal, 1 vertical (ITM convention)
%   Batch B25 (post-B20 plan N02). Checked against matlab_itu_p452's
%   spherical_earth, which matches the ITU-R reference code to 1e-9 dB.

if ~(isscalar(d_km) && d_km > 0 && isfinite(d_km))
    error('itmexp:sph', 'Path length must be positive and finite (%g km).', d_km);
end
if ~(hte_m > 0 && hre_m > 0 && isfinite(hte_m) && isfinite(hre_m))
    error('itmexp:sph', 'Heights above the smooth surface must be positive (%g, %g m).', hte_m, hre_m);
end
if ~(ae_km > 0 && f_ghz > 0) || (pol ~= 0 && pol ~= 1)
    error('itmexp:sph', 'Bad radius, frequency or polarization.');
end
lambda = 0.2998 / f_ghz;                                                         % m
dlos = sqrt(2 * ae_km) * (sqrt(0.001 * hte_m) + sqrt(0.001 * hre_m));            % eq. (23)
if d_km >= dlos
    L = first_term(d_km, hte_m, hre_m, ae_km, f_ghz, pol);                       % eq. (29)
else
    c = (hte_m - hre_m) / (hte_m + hre_m);                                       % eq. (25d)
    m = 250 * d_km^2 / (ae_km * (hte_m + hre_m));                                % eq. (25e)
    b = 2 * sqrt((m + 1) / (3 * m)) * cos(pi / 3 + acos(1.5 * c * sqrt(3 * m / (m + 1)^3)) / 3);  % eq. (25c)
    dse1 = d_km / 2 * (1 + b);                                                   % eq. (25a)
    dse2 = d_km - dse1;                                                          % eq. (25b)
    hse = ((hte_m - 500 * dse1^2 / ae_km) * dse2 + (hre_m - 500 * dse2^2 / ae_km) * dse1) / d_km;  % eq. (24)
    hreq = 17.456 * sqrt(dse1 * dse2 * lambda / d_km);                           % eq. (26)
    if hse > hreq
        L = 0;
    else
        aem = 500 * (d_km / (sqrt(hte_m) + sqrt(hre_m)))^2;                      % eq. (27)
        Ldft = first_term(d_km, hte_m, hre_m, aem, f_ghz, pol);
        if Ldft < 0
            L = 0;                                                               % eq. (28)
        else
            L = (1 - hse / hreq) * Ldft;                                         % eq. (28)
        end
    end
end
if ~isfinite(L) || ~isreal(L)
    error('itmexp:sph', 'Non-finite spherical-earth diffraction loss.');
end
end

function L = first_term(d, hte, hre, a, f, pol)
% Eq. (30)-(37), land constants of eq. (29).
epsr = 22; sigma = 0.003;                                                        % eq. (29)
K = 0.036 * (a * f)^(-1/3) * ((epsr - 1)^2 + (18 * sigma / f)^2)^(-1/4);         % eq. (30a)
if pol == 1
    K = K * (epsr^2 + (18 * sigma / f)^2)^(1/2);                                 % eq. (30b)
end
beta = (1 + 1.6 * K^2 + 0.67 * K^4) / (1 + 4.5 * K^2 + 1.53 * K^4);              % eq. (31)
X = 21.88 * beta * (f / a^2)^(1/3) * d;                                          % eq. (32)
Yt = 0.9575 * beta * (f^2 / a)^(1/3) * hte;                                      % eq. (33a)
Yr = 0.9575 * beta * (f^2 / a)^(1/3) * hre;                                      % eq. (33b)
if X >= 1.6
    Fx = 11 + 10 * log10(X) - 17.6 * X;                                          % eq. (34)
else
    Fx = -20 * log10(X) - 5.6488 * X^1.425;                                      % eq. (34)
end
gfloor = 2 + 20 * log10(K);                                                      % eq. (35)
L = -Fx - max(gain(beta * Yt), gfloor) - max(gain(beta * Yr), gfloor);           % eq. (37)
end

function G = gain(B)
% Eq. (36a), (36b)
if B > 2
    G = 17.6 * (B - 1.1)^0.5 - 5 * log10(B - 1.1) - 8;
else
    G = 20 * log10(B + 0.1 * B^3);
end
end
