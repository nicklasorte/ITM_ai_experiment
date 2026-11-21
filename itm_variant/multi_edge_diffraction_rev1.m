function [L_db, D] = multi_edge_diffraction_rev1(method, x_m, z_m, f_mhz, a_e_m)
%MULTI_EDGE_DIFFRACTION_REV1 Knife-edge diffraction loss over a terrain profile (dB).
%   L_db = MULTI_EDGE_DIFFRACTION_REV1(method, x_m, z_m, f_mhz, a_e_m)
%   returns the diffraction loss, relative to free space, of the path
%   described by the profile, evaluated at the path's own geometry.
%
%   Inputs:
%     method   "epstein_peterson" | "deygout" | "p526_cascaded" | "bullington"
%     x_m      distance of each profile point from the transmitter (m),
%              increasing, x_m(1) = 0, x_m(end) = path length
%     z_m      height above sea level (m): z_m(1) and z_m(end) are the
%              ANTENNA heights (ground plus mast); interior points are terrain
%     f_mhz    frequency (MHz)
%     a_e_m    effective Earth radius (m). The caller passes ITM's own value
%              (1/gamma_e), so the variant and ITM bend rays the same way.
%
%   Every method uses the same two building blocks:
%     nu  Diffraction parameter of point n between ends a and b, with the
%         Earth-curvature bulge: ITU-R P.526-11 section 4.4.2, eq. (49) and
%         (49a). Equivalent to ITU-R P.526-16 section 4.1, eq. (26).
%     J   Single knife-edge loss approximation, valid for nu > -0.78, else
%         0: ITU-R P.526-16 section 4.1, eq. (31).
%
%   Methods and sources:
%     "epstein_peterson"  Sum of knife-edge losses over successive edges,
%         each edge's height measured from the line joining the preceding
%         edge (or transmitter) to the following edge (or receiver).
%         Epstein and Peterson, Proc. IRE 41(5), 1953; as described in NTIA
%         TR-26-580 (DeMinco, McKenna, and Johnk, 2025), section 3.3.2.
%         Edges used here: the two radio-horizon obstacles (the terrain
%         points of highest elevation angle from each terminal), the same
%         two obstacles ITM's double knife edge represents. One shared
%         horizon gives a single edge. With no obstruction the loss is J of
%         the highest-nu point (sub-path clearance).
%     "deygout"  Principal edge over the whole path, plus one secondary edge
%         on each side of it; losses summed. Deygout, IEEE Trans. Antennas
%         Propag. 14(4), 1966; NTIA TR-26-580 section 3.3.3 (three major
%         edges). Edge selection as in ITU-R P.526-11 section 4.4.2.
%     "p526_cascaded"  The same three edges with the empirical correction
%         L = J(nu_p) + T [J(nu_t) + J(nu_r) + C], C = 10.0 + 0.04 D (D in
%         km), T = 1.0 - exp(-J(nu_p)/6.0): ITU-R P.526-11 section 4.4.2,
%         eq. (50a), (50b), (51), (52).
%     "bullington"  Single equivalent edge at the intersection of the two
%         horizon rays: ITU-R P.526-16 section 4.5.1, eq. (49)-(57),
%         including the correction [1 - exp(-L_uc/6)] (10 + 0.02 d).
%
%   D is a struct of diagnostics (edge indices and nu values).
%
%   No fitted constants. Every constant above is from the cited equation.

arguments
    method (1,1) string
    x_m (:,1) double
    z_m (:,1) double
    f_mhz (1,1) double
    a_e_m (1,1) double
end
n = numel(x_m);
if numel(z_m) ~= n || n < 2
    error('itmexp:multiedge', 'x_m and z_m must have the same length, at least 2.');
end
if ~all(isfinite(x_m)) || ~all(isfinite(z_m)) || any(diff(x_m) <= 0) || x_m(1) ~= 0
    error('itmexp:multiedge', 'Profile must be finite with x_m(1) = 0 and increasing distances.');
end
if ~(f_mhz > 0) || ~(a_e_m > 0)
    error('itmexp:multiedge', 'Frequency and effective Earth radius must be positive.');
end
lambda = 299.792458 / f_mhz;          % wavelength (m); speed of light, exact SI value
D = struct('method', method, 'edges', [], 'nu', []);

switch method
    case "epstein_peterson"
        [i1, i2, blocked] = horizon_points(x_m, z_m, a_e_m);
        if ~blocked || i1 > i2
            % No terrain horizon, or horizons that cross: one edge at the
            % highest-nu point
            [nu, p] = principal(1, n, x_m, z_m, lambda, a_e_m);
            L_db = knife_J(nu);
            D.edges = p; D.nu = nu;
        elseif i1 == i2
            nu = nu_point(i1, 1, n, x_m, z_m, lambda, a_e_m);
            L_db = knife_J(nu);
            D.edges = i1; D.nu = nu;
        else
            nu1 = nu_point(i1, 1, i2, x_m, z_m, lambda, a_e_m);
            nu2 = nu_point(i2, i1, n, x_m, z_m, lambda, a_e_m);
            L_db = knife_J(nu1) + knife_J(nu2);
            D.edges = [i1 i2]; D.nu = [nu1 nu2];
        end

    case {"deygout", "p526_cascaded"}
        [nu_p, p] = principal(1, n, x_m, z_m, lambda, a_e_m);
        if nu_p > -0.78
            [nu_t, t] = principal(1, p, x_m, z_m, lambda, a_e_m);
            [nu_r, r] = principal(p, n, x_m, z_m, lambda, a_e_m);
            Jp = knife_J(nu_p);
            if method == "deygout"
                L_db = Jp + knife_J(nu_t) + knife_J(nu_r);
            else
                C = 10.0 + 0.04 * (x_m(n) / 1000);           % P.526-11 eq. (51), D in km
                T = 1.0 - exp(-Jp / 6.0);                    % P.526-11 eq. (52)
                L_db = Jp + T * (knife_J(nu_t) + knife_J(nu_r) + C);   % eq. (50a)
            end
            D.edges = [t p r]; D.nu = [nu_t nu_p nu_r];
        else
            L_db = 0;                                        % P.526-11 eq. (50b)
            D.edges = p; D.nu = nu_p;
        end

    case "bullington"
        % ITU-R P.526-16 section 4.5.1. The Recommendation works in km and m
        % with C_e = 1/r_e; here all lengths are metres, so its
        % 500 C_e d_i (d - d_i) is d_i (d - d_i) / (2 a_e) and its
        % sqrt(0.002 d / (lambda d_i (d - d_i))) is sqrt(2 d / (lambda d_i (d - d_i))).
        d = x_m(n);
        if n < 3
            L_db = 0;
            return
        end
        i = (2:n - 1)';
        di = x_m(i);
        bulge = di .* (d - di) / (2 * a_e_m);
        h_ts = z_m(1); h_rs = z_m(n);
        S_tim = max((z_m(i) + bulge - h_ts) ./ di);                          % eq. (49)
        S_tr = (h_rs - h_ts) / d;                                            % eq. (50)
        if S_tim < S_tr
            nu = max((z_m(i) + bulge - (h_ts * (d - di) + h_rs * di) / d) ...
                .* sqrt(2 * d ./ (lambda * di .* (d - di))));                % eq. (51)
            D.nu = nu;
        else
            S_rim = max((z_m(i) + bulge - h_rs) ./ (d - di));                % eq. (53)
            d_b = (h_rs - h_ts + S_rim * d) / (S_tim + S_rim);               % eq. (54)
            nu = (h_ts + S_tim * d_b - (h_ts * (d - d_b) + h_rs * d_b) / d) ...
                * sqrt(2 * d / (lambda * d_b * (d - d_b)));                  % eq. (55)
            D.nu = nu; D.d_b_m = d_b;
        end
        L_uc = knife_J(nu);                                                  % eq. (52), (56)
        L_db = L_uc + (1 - exp(-L_uc / 6)) * (10 + 0.02 * (d / 1000));       % eq. (57), d in km

    otherwise
        error('itmexp:multiedge', 'Unknown diffraction method "%s".', method);
end
if ~isfinite(L_db) || ~isreal(L_db)
    error('itmexp:multiedge', 'Non-finite %s loss.', method);
end
end

function J = knife_J(nu)
% ITU-R P.526-16 eq. (31); zero for nu <= -0.78
if nu > -0.78
    J = 6.9 + 20 * log10(sqrt((nu - 0.1)^2 + 1) + nu - 0.1);
else
    J = 0;
end
end

function nu = nu_point(k, a, b, x, z, lambda, a_e)
% ITU-R P.526-11 eq. (49), (49a): point k between ends a and b
d_an = x(k) - x(a); d_nb = x(b) - x(k); d_ab = x(b) - x(a);
h = z(k) + d_an * d_nb / (2 * a_e) - (z(a) * d_nb + z(b) * d_an) / d_ab;
nu = h * sqrt(2 * d_ab / (lambda * d_an * d_nb));
end

function [nu, k] = principal(a, b, x, z, lambda, a_e)
% Highest-nu interior point between ends a and b (first one on a tie).
% With no interior point there is no edge: nu = -Inf, k = a.
if b - a < 2
    nu = -Inf; k = a;
    return
end
i = (a + 1:b - 1)';
d_an = x(i) - x(a); d_nb = x(b) - x(i); d_ab = x(b) - x(a);
h = z(i) + d_an .* d_nb / (2 * a_e) - (z(a) * d_nb + z(b) * d_an) / d_ab;
[nu, j] = max(h .* sqrt(2 * d_ab ./ (lambda * d_an .* d_nb)));
k = i(j);
end

function [i1, i2, blocked] = horizon_points(x, z, a_e)
% Terrain points of highest elevation angle from each terminal on the
% effective Earth (the radio horizons), as in ITM's FindHorizons. blocked is
% true when terrain rises above the direct ray from either terminal.
n = numel(x);
i1 = 1; i2 = n; blocked = false;
if n < 3
    return
end
d = x(n);
i = (2:n - 1)';
dt = x(i); dr = d - x(i);
[th_t, jt] = max((z(i) - z(1)) ./ dt - dt / (2 * a_e));
[th_r, jr] = max((z(i) - z(n)) ./ dr - dr / (2 * a_e));
direct_t = (z(n) - z(1)) / d - d / (2 * a_e);
direct_r = (z(1) - z(n)) / d - d / (2 * a_e);
if th_t > direct_t, i1 = i(jt); blocked = true; else, i1 = n; end
if th_r > direct_r, i2 = i(jr); blocked = true; else, i2 = 1; end
if blocked && (i1 == n || i2 == 1)
    % Only one side found a horizon (numerical edge case): use that point for both
    if i1 == n, i1 = i2; else, i2 = i1; end
end
end
