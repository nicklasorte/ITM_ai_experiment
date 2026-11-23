function L_bs = p452_troposcatter_rev1(d_km, theta_mrad, f_ghz, N_0, p_pct, G_sum_dbi)
%P452_TROPOSCATTER_REV1 ITU-R P.452-18 troposcatter basic transmission loss (dB).
%   L_bs = P452_TROPOSCATTER_REV1(d_km, theta_mrad, f_ghz, N_0, p_pct, G_sum_dbi)
%   evaluates ITU-R P.452-18 section 4.3, eq. (45):
%
%     L_bs = 190 + L_f + 20 log10(d) + 0.573 theta - 0.15 N_0 + L_c + A_g
%            - 10.1 [-log10(p/50)]^0.7
%     L_f  = 25 log10(f) - 2.5 [log10(f/2)]^2                       eq. (45a)
%     L_c  = 0.051 exp(0.055 (G_t + G_r))                            eq. (45b)
%     A_g  = [gamma_o + gamma_w(rho = 3 g/m^3)] d                    eq. (9)
%
%   d_km        great-circle path length (km)
%   theta_mrad  path angular distance (mrad), theta_e + theta_t + theta_r
%   f_ghz       frequency (GHz); P.452-18 covers about 0.1 to 50 GHz
%   N_0         path-centre sea-level surface refractivity (N-units)
%   p_pct       time percentage, 0.001 to 50 (P.452-18 section 4.3, note 2:
%               not valid above 50 %)
%   G_sum_dbi   G_t + G_r toward the horizon (dBi). The measurement records
%               in this repo don't carry antenna gains; callers pass 0
%               (TODO: gains from the ITS long-term records, if published).
%
%   Gaseous absorption uses gaseous_p676_rev1 at 15 deg C and 1013.25 hPa,
%   the sea-level values of the ITU-R P.835 reference atmosphere, as the
%   ITU-R reference implementation of P.452 does.
arguments
    d_km (1,1) double {mustBePositive, mustBeFinite}
    theta_mrad (1,1) double {mustBeReal, mustBeFinite}
    f_ghz (1,1) double {mustBePositive, mustBeFinite}
    N_0 (1,1) double {mustBePositive, mustBeFinite}
    p_pct (1,1) double {mustBeInRange(p_pct, 0.001, 50)}
    G_sum_dbi (1,1) double {mustBeReal, mustBeFinite} = 0
end
L_f = 25 * log10(f_ghz) - 2.5 * (log10(f_ghz / 2))^2;            % eq. (45a)
L_c = 0.051 * exp(0.055 * G_sum_dbi);                             % eq. (45b)
gamma = gaseous_p676_rev1(f_ghz, 3, 288.15, 1013.25);            % eq. (9), rho = 3 g/m^3
A_g = sum(gamma) * d_km;
L_bs = 190 + L_f + 20 * log10(d_km) + 0.573 * theta_mrad - 0.15 * N_0 + L_c + A_g ...
    - 10.1 * (-log10(p_pct / 50))^0.7;                           % eq. (45)
end
