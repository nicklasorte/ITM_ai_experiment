function out = p617_troposcatter_rev1(d_km, f_mhz, theta_t_mrad, theta_r_mrad, h_t_km, h_r_km, h_s_km, N_0, dN, ka_km, p_pct, G_sum_dbi, h_b_km)
%P617_TROPOSCATTER_REV1 ITU-R P.617-6 troposcatter loss distribution (section 4.1).
%   out = P617_TROPOSCATTER_REV1(d_km, f_mhz, theta_t_mrad, theta_r_mrad,
%   h_t_km, h_r_km, h_s_km, N_0, dN, ka_km, p_pct, G_sum_dbi, h_b_km)
%   evaluates ITU-R P.617-6 section 4.1, read from the published PDF
%   (09/2025, pages 5-6):
%
%     theta   = theta_e + theta_t + theta_r                     mrad   eq. (1)
%     theta_e = d * 10^3 / (k a)                                mrad   eq. (2)
%     L_c     = 0.07 exp[0.055 (G_t + G_r)]                     dB     eq. (3)
%     L_bs(p) = F + 22 log10 f + 17.5 log10(theta^2 + 7 theta + 4)
%               + 17 log10 d + L_c - Y_p                        dB     eq. (4)
%     F       = 0.18 N_0 exp(-h_s / h_b) - 0.23 dN              dB     eq. (5)
%     Y_p     =  0.035 N_0 exp(-h_0 / h_b) (-log(p / 50))^0.67          p < 50
%               -0.035 N_0 exp(-h_0 / h_b) (-log[(100 - p) / 50])^0.67  p >= 50
%                                                                      eq. (6)
%     h_0     = h_t + (d sin(beta) / sin(theta / 1000))
%               * [ (1/2) d sin(beta) / (k a sin(theta / 1000)) + sin(theta_t / 1000) ]
%                                                                      eq. (7a)
%     beta    = d / (2 k a) + theta_r / 1000 + (h_r - h_t) / d          eq. (7b)
%
%   Interpretations, recorded in batch B14: "log" in eq. (6) is read as
%   log10, the ITU-R convention; "sin theta_t / 1 000" in eq. (7a) is read as
%   sin(theta_t / 1000), with theta_t in mrad.
%
%   Inputs (scalars except p_pct):
%     d_km           great-circle path length (km)
%     f_mhz          frequency (MHz)
%     theta_t_mrad, theta_r_mrad  horizon angles at the transmitter and
%                    receiver (mrad)
%     h_t_km, h_r_km altitudes of the antennas above sea level (km)
%     h_s_km         height of the Earth's surface above sea level (km)
%     N_0            sea-level surface refractivity (N-units)
%     dN             refractivity lapse rate through the lowest 1 km
%                    (N-units/km)
%     ka_km          effective Earth radius k a (km). P.617-6 says k = 4/3
%                    unless a more accurate value is known.
%     p_pct          time percentages (any size), 0 < p < 100
%     G_sum_dbi      G_t + G_r (dBi)
%     h_b_km         scale height (km); P.617-6 gives 7.35 km as the global
%                    mean reference value
%
%   Output struct: theta (mrad), h_0 (km), beta (rad), F, L_c, Y_p (size of
%   p_pct) and L_bs (size of p_pct), all in dB where not stated.
arguments
    d_km (1,1) double {mustBePositive, mustBeFinite}
    f_mhz (1,1) double {mustBePositive, mustBeFinite}
    theta_t_mrad (1,1) double {mustBeReal, mustBeFinite}
    theta_r_mrad (1,1) double {mustBeReal, mustBeFinite}
    h_t_km (1,1) double {mustBeReal, mustBeFinite}
    h_r_km (1,1) double {mustBeReal, mustBeFinite}
    h_s_km (1,1) double {mustBeReal, mustBeFinite}
    N_0 (1,1) double {mustBePositive, mustBeFinite}
    dN (1,1) double {mustBeReal, mustBeFinite}
    ka_km (1,1) double {mustBePositive, mustBeFinite}
    p_pct double {mustBeGreaterThan(p_pct, 0), mustBeLessThan(p_pct, 100)}
    G_sum_dbi (1,1) double {mustBeReal, mustBeFinite} = 0
    h_b_km (1,1) double {mustBePositive, mustBeFinite} = 7.35   % P.617-6 section 4.1, global mean reference value
end
theta = d_km * 1e3 / ka_km + theta_t_mrad + theta_r_mrad;                     % eqs. (1), (2)
if theta <= 0
    error('p617:geometry', 'Scatter angle %.3g mrad is not positive; the path isn''t transhorizon.', theta);
end
L_c = 0.07 * exp(0.055 * G_sum_dbi);                                           % eq. (3)
F = 0.18 * N_0 * exp(-h_s_km / h_b_km) - 0.23 * dN;                            % eq. (5)
beta = d_km / (2 * ka_km) + theta_r_mrad / 1000 + (h_r_km - h_t_km) / d_km;  % eq. (7b)
s = sin(theta / 1000);
h_0 = h_t_km + (d_km * sin(beta) / s) * (0.5 * d_km * sin(beta) / (ka_km * s) + sin(theta_t_mrad / 1000));   % eq. (7a)
amp = 0.035 * N_0 * exp(-h_0 / h_b_km);
Y_p = zeros(size(p_pct));
lo = p_pct < 50;
Y_p(lo) = amp * (-log10(p_pct(lo) / 50)).^0.67;                                % eq. (6), p < 50
Y_p(~lo) = -amp * (-log10((100 - p_pct(~lo)) / 50)).^0.67;                     % eq. (6), p >= 50
L_bs = F + 22 * log10(f_mhz) + 17.5 * log10(theta^2 + 7 * theta + 4) + 17 * log10(d_km) + L_c - Y_p;   % eq. (4)
out = struct('theta', theta, 'h_0', h_0, 'beta', beta, 'F', F, 'L_c', L_c, 'Y_p', Y_p, 'L_bs', L_bs);
end
