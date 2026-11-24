function [L_db, D] = multi_edge_diffraction_rev1(method, x_m, z_m, f_mhz, a_e_m)
%MULTI_EDGE_DIFFRACTION_REV1 Knife-edge diffraction loss over a terrain profile (dB).
%   L_db = MULTI_EDGE_DIFFRACTION_REV1(method, x_m, z_m, f_mhz, a_e_m)
%   returns the diffraction loss, relative to free space, of the path
%   described by the profile, evaluated at the path's own geometry.
%
%   Inputs:
%     method   "epstein_peterson" | "ep_isolated" | "p526_double_edge" | "string_ep" |
%              "deygout" | "p526_cascaded" | "p526_cascaded_isolated" |
%              "deygout_isolated" | "bullington" | "bullington_uc" |
%              "p526_cylinders_knife" | "p526_cascaded_isolated_one" |
%              "p526_cascaded_isolated_tree3" | "p526_cascaded_isolated_rival"
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
%     "ep_isolated"  As "epstein_peterson", but the two horizon obstacles
%         count as two edges only if they are isolated in the sense of
%         ITU-R P.526-16 section 2.5: every profile point between them
%         clears the line joining their tops by at least 0.6 of the first
%         Fresnel zone radius (P.526-16 eq. (2), r1 = sqrt(lambda d1 d2 / d)).
%         Otherwise they are one obstacle sampled twice (for example a
%         ridge top that falls between two profile samples) and the loss is
%         J of the highest-nu point over the whole path. Added in batch B02:
%         on such a top, plain Epstein-Peterson sees two near-grazing edges
%         and drops about 10 dB of the single steep edge's loss.
%     "p526_double_edge"  ITU-R P.526-16 section 4.3, double isolated
%         edges: L = L1 + L2 + Lc, eq. (40), with Lc =
%         10 log10[(a + b)(b + c) / (b (a + b + c))], eq. (39), applied only
%         where the Recommendation says it is valid (each of L1 and L2
%         above about 15 dB); otherwise L1 + L2. Edges and the isolation
%         test as in "ep_isolated".
%     "string_ep"  Obstructions found with the stretched string of ITU-R
%         P.526-16 section 4.4, eq. (44): from each string point, the next
%         is the sample of highest elevation on the effective Earth. String
%         points on consecutive samples form one obstruction (the
%         Recommendation's rule for sample spacings of 250 m or less).
%         Neighboring obstructions are merged unless the valley between
%         them opens to at least 0.6 of the first Fresnel zone radius
%         somewhere (the planner's reading of the isolation criterion in
%         section 2.5, with eq. (2) for the radius; a design choice, B05).
%         Each obstruction is one knife edge at its vertex, the
%         intersection of the rays from the neighboring obstructions (or
%         terminals) over its two ends, and the losses are summed as in
%         Epstein-Peterson. The cylinder, sub-path, and C_N terms of
%         section 4.4 are not included (their equations weren't verified).
%         On a smooth Earth the string touches consecutive samples, so the
%         result is the single Bullington-point knife edge (tested).
%     "deygout"  Principal edge over the whole path, plus one secondary edge
%         on each side of it; losses summed. Deygout, IEEE Trans. Antennas
%         Propag. 14(4), 1966; NTIA TR-26-580 section 3.3.3 (three major
%         edges). Edge selection as in ITU-R P.526-11 section 4.4.2.
%     "p526_cascaded"  The same three edges with the empirical correction
%         L = J(nu_p) + T [J(nu_t) + J(nu_r) + C], C = 10.0 + 0.04 D (D in
%         km), T = 1.0 - exp(-J(nu_p)/6.0): ITU-R P.526-11 section 4.4.2,
%         eq. (50a), (50b), (51), (52).
%     "p526_cascaded_isolated"  "p526_cascaded" with each secondary edge
%         weighted by how isolated it is from the principal edge (batch
%         B06). On each side of the principal edge p, a candidate point k
%         gets the weight w_k = min(1, c_k / (0.6 r1)), where c_k is the
%         depth of the deepest point between k and p below k (heights
%         measured from the line joining the antennas, Earth bulge
%         included) and r1 is the first Fresnel zone radius at that deepest
%         point on the sub-path from k to p (ITU-R P.526-16 eq. (2)). 0.6 of
%         the first Fresnel zone is the clearance that makes two obstacles
%         isolated in ITU-R P.526-16 section 2.5; the linear ramp from 0 to
%         that clearance is a design choice with no new constant. The
%         secondary edge on each side is the point of largest w_k J(nu_k),
%         with nu_k as in "deygout", and contributes w_k J(nu_k). A point on
%         the principal obstacle's own flank, or the neighboring sample of
%         a top that falls between two samples, has no valley before p, so
%         its weight is 0: this removes the 6 dB that plain Deygout adds on
%         each side of every edge (the reason for eq. (52)'s T) and the
%         split-top sampling artifact (B02), and the loss of a second ridge
%         grows from zero as its valley opens. At most three edges are
%         counted, as in the Recommendation. On a smooth Earth the weights
%         are 0 and the loss is J(nu_p) + T C.
%     "deygout_isolated"  The edges and weights of "p526_cascaded_isolated"
%         summed as in Deygout (1966): L = J(nu_p) + w_t J(nu_t) + w_r
%         J(nu_r), without the empirical correction C = 10 + 0.04 D and
%         the factor T of P.526-11 eq. (50a)-(52) (batch B07: with a
%         terminal clutter term present, C would be a second allowance for
%         the same real-terrain excess).
%     "bullington_uc"  "bullington" without the correction of eq. (57):
%         L = L_uc, eq. (52) or (56) (batch B07, same reason).
%     "p526_cylinders_knife"  ITU-R P.526-16 (11/2025) section 4.4,
%         multiple isolated cylinders, with zero-radius cylinders (T(m,n)
%         = 0, the knife-edge limit the Recommendation states below eq.
%         (36)); batch B09. Stretched string by eq. (44); consecutive string
%         samples (spacing <= 250 m) form one obstruction with points w, x,
%         y, z (Fig. 14); vertex by Attachment 1 eq. (107)-(115); cylinder
%         height h by eq. (116); d1, d2 = s1, s2 the inter-vertex distances;
%         nu by eq. (33); L'_i = J(nu_i), eq. (31). Sub-path losses L" on
%         every line-of-sight section (w..x of the first cylinder, y..z of
%         each) by Attachment 2 eq. (124)-(129), and on the whole path when
%         the string has no obstruction. Spreading correction
%         -20 log10 C_N, eq. (46)-(48). Total eq. (45). No empirical
%         correction such as P.526-11's C. The rounded form (T(m,n) with R
%         from Attachment 1 eq. (117)-(123)) isn't implemented: the sign of
%         the Earth-curvature term in eq. (122) as printed gives a negative
%         radius on a smooth Earth, so it waits for a check against
%         independent reference code (TODO).
%     "p526_cascaded_isolated_one"  "p526_cascaded_isolated" with one
%         secondary edge in total, the larger of the two weighted secondary
%         losses: L = J(nu_p) + T [max(w_t J(nu_t), w_r J(nu_r)) + C]
%         (batch B18, candidate 1801). With two tied ridges the loss is
%         the same whichever is principal (the secondary parameter of each,
%         seen from the other, is equal), so the step at a switch of
%         principal edge shrinks to the difference of two secondary
%         losses. Design choice with no new constant; P.526-11 counts one
%         secondary edge on each side.
%     "p526_cascaded_isolated_tree3"  Three edges whenever three exist
%         (batch B18, candidate 1802): the principal edge, the stronger
%         weighted secondary edge s1 of the two sides, then the strongest
%         of the other side's secondary edge and the edges of the two
%         sub-paths s1 splits its side into (Deygout's recursion, IEEE
%         Trans. Antennas Propag. 14(4), 1966, to depth two on one side).
%         Sub-path candidates are weighted by their isolation from both
%         ends of their sub-path (the smaller weight). L = J(nu_p) + T
%         [L_s1 + L_3 + C]. Design choice with no new constant.
%     "p526_cascaded_isolated_rival"  Diagnostic, not a loss model: the
%         "p526_cascaded_isolated" loss with the principal edge moved to the
%         runner-up ridge, the highest full-path nu among points fully
%         isolated from the principal edge (weight 1). D.nu = [nu_p nu_2].
%         With no runner-up, the normal loss and nu_2 = -Inf. Used for the
%         report-only info.edge_switch (B18).
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

    case {"ep_isolated", "p526_double_edge"}
        [i1, i2, blocked] = horizon_points(x_m, z_m, a_e_m);
        two = blocked && i1 < i2 && isolated(i1, i2, x_m, z_m, lambda, a_e_m);
        if ~two
            [nu, p] = principal(1, n, x_m, z_m, lambda, a_e_m);
            L_db = knife_J(nu);
            D.edges = p; D.nu = nu; D.isolated = false;
        else
            nu1 = nu_point(i1, 1, i2, x_m, z_m, lambda, a_e_m);
            nu2 = nu_point(i2, i1, n, x_m, z_m, lambda, a_e_m);
            L1 = knife_J(nu1); L2 = knife_J(nu2);
            L_db = L1 + L2;
            if method == "p526_double_edge" && L1 > 15 && L2 > 15
                a = x_m(i1); b = x_m(i2) - x_m(i1); c = x_m(n) - x_m(i2);
                L_db = L_db + 10 * log10((a + b) * (b + c) / (b * (a + b + c)));   % P.526-16 eq. (39), (40)
            end
            D.edges = [i1 i2]; D.nu = [nu1 nu2]; D.isolated = true;
        end

    case "string_ep"
        [L_db, D.edges, D.nu] = string_ep(x_m, z_m, lambda, a_e_m);

    case {"p526_cascaded_isolated", "deygout_isolated"}
        [nu_p, p] = principal(1, n, x_m, z_m, lambda, a_e_m);
        if nu_p > -0.78
            Jp = knife_J(nu_p);
            [L_t, t, nu_t, w_t] = isolated_secondary(1, p, p, x_m, z_m, lambda, a_e_m);
            [L_r, r, nu_r, w_r] = isolated_secondary(p, n, p, x_m, z_m, lambda, a_e_m);
            if method == "deygout_isolated"
                L_db = Jp + L_t + L_r;                       % Deygout 1966, weighted secondary edges
            else
                C = 10.0 + 0.04 * (x_m(n) / 1000);           % P.526-11 eq. (51), D in km
                T = 1.0 - exp(-Jp / 6.0);                    % P.526-11 eq. (52)
                L_db = Jp + T * (L_t + L_r + C);             % eq. (50a) with weighted secondary edges
                % Report only (B20, D20b): the eq. (50a) terms. No effect on L_db.
                D.terms = struct('J_p', Jp, 'T', T, 'L_t', L_t, 'L_r', L_r, 'C', C);
            end
            D.edges = [t p r]; D.nu = [nu_t nu_p nu_r]; D.weight = [w_t 1 w_r];
        else
            L_db = 0;                                        % P.526-11 eq. (50b)
            D.edges = p; D.nu = nu_p; D.weight = 1;
        end

    case "p526_cascaded_isolated_one"
        [nu_p, p] = principal(1, n, x_m, z_m, lambda, a_e_m);
        if nu_p > -0.78
            Jp = knife_J(nu_p);
            [L_t, t, nu_t, w_t] = isolated_secondary(1, p, p, x_m, z_m, lambda, a_e_m);
            [L_r, r, nu_r, w_r] = isolated_secondary(p, n, p, x_m, z_m, lambda, a_e_m);
            C = 10.0 + 0.04 * (x_m(n) / 1000);               % P.526-11 eq. (51), D in km
            T = 1.0 - exp(-Jp / 6.0);                        % P.526-11 eq. (52)
            if L_t >= L_r
                L_db = Jp + T * (L_t + C);
                D.edges = [t p]; D.nu = [nu_t nu_p]; D.weight = [w_t 1];
            else
                L_db = Jp + T * (L_r + C);
                D.edges = [p r]; D.nu = [nu_p nu_r]; D.weight = [1 w_r];
            end
        else
            L_db = 0;                                        % P.526-11 eq. (50b)
            D.edges = p; D.nu = nu_p; D.weight = 1;
        end

    case "p526_cascaded_isolated_tree3"
        [nu_p, p] = principal(1, n, x_m, z_m, lambda, a_e_m);
        if nu_p > -0.78
            Jp = knife_J(nu_p);
            [L_t, t, nu_t, w_t] = isolated_secondary(1, p, p, x_m, z_m, lambda, a_e_m);
            [L_r, r, nu_r, w_r] = isolated_secondary(p, n, p, x_m, z_m, lambda, a_e_m);
            if L_t >= L_r
                L_1 = L_t; s1 = t; e1 = [nu_t w_t]; L_o = L_r; o = r; eo = [nu_r w_r];
                sub = [1 s1; s1 p];
            else
                L_1 = L_r; s1 = r; e1 = [nu_r w_r]; L_o = L_t; o = t; eo = [nu_t w_t];
                sub = [p s1; s1 n];
            end
            L_3 = L_o; k3 = o; e3 = eo;
            if L_1 > 0
                for q = 1:2
                    [Lq, kq, nuq, wq] = isolated_between(sub(q, 1), sub(q, 2), x_m, z_m, lambda, a_e_m);
                    if Lq > L_3
                        L_3 = Lq; k3 = kq; e3 = [nuq wq];
                    end
                end
            end
            C = 10.0 + 0.04 * (x_m(n) / 1000);               % P.526-11 eq. (51), D in km
            T = 1.0 - exp(-Jp / 6.0);                        % P.526-11 eq. (52)
            L_db = Jp + T * (L_1 + L_3 + C);
            D.edges = [p s1 k3]; D.nu = [nu_p e1(1) e3(1)]; D.weight = [1 e1(2) e3(2)];
        else
            L_db = 0;                                        % P.526-11 eq. (50b)
            D.edges = p; D.nu = nu_p; D.weight = 1;
        end

    case "p526_cascaded_isolated_rival"
        [nu_p, p] = principal(1, n, x_m, z_m, lambda, a_e_m);
        [nu_2, p2] = rival_ridge(p, x_m, z_m, lambda, a_e_m);
        if isfinite(nu_2)
            L_db = cascaded_isolated_at(p2, nu_2, x_m, z_m, lambda, a_e_m);
        else
            L_db = cascaded_isolated_at(p, nu_p, x_m, z_m, lambda, a_e_m);
        end
        D.edges = [p p2]; D.nu = [nu_p nu_2];

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

    case {"bullington", "bullington_uc"}
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
        if method == "bullington_uc"
            L_db = L_uc;                                                     % eq. (52) or (56) alone (B07)
        else
            L_db = L_uc + (1 - exp(-L_uc / 6)) * (10 + 0.02 * (d / 1000));   % eq. (57), d in km
        end

    case "p526_cylinders_knife"
        [L_db, D.edges, D.nu, D.CN_db] = p526_cylinders(x_m, z_m, lambda, a_e_m);

    otherwise
        error('itmexp:multiedge', 'Unknown diffraction method "%s".', method);
end
if ~isfinite(L_db) || ~isreal(L_db)
    error('itmexp:multiedge', 'Non-finite %s loss.', method);
end
end

function L = cascaded_isolated_at(p, nu_p, x, z, lambda, a_e)
% "p526_cascaded_isolated" with the principal edge fixed at p
n = numel(x);
if nu_p > -0.78
    Jp = knife_J(nu_p);
    L_t = isolated_secondary(1, p, p, x, z, lambda, a_e);
    L_r = isolated_secondary(p, n, p, x, z, lambda, a_e);
    C = 10.0 + 0.04 * (x(n) / 1000);                 % P.526-11 eq. (51), D in km
    T = 1.0 - exp(-Jp / 6.0);                        % P.526-11 eq. (52)
    L = Jp + T * (L_t + L_r + C);
else
    L = 0;
end
end

function [nu2, p2] = rival_ridge(p, x, z, lambda, a_e)
% Highest full-path nu (P.526-11 eq. (49)) among points with isolation
% weight 1 from the principal edge p. -Inf and p when there is none.
n = numel(x);
nu2 = -Inf; p2 = p;
w = zeros(n, 1);
if p > 2
    k = (p - 1:-1:2)';
    w(k) = iso_weights(k, p, x, z, lambda, a_e);
end
if p < n - 1
    k = (p + 1:n - 1)';
    w(k) = iso_weights(k, p, x, z, lambda, a_e);
end
k = find(w >= 1);
if isempty(k), return, end
d = x(n);
h = z(k) + x(k) .* (d - x(k)) / (2 * a_e) - (z(1) * (d - x(k)) + z(n) * x(k)) / d;
nu = h .* sqrt(2 * d ./ (lambda * x(k) .* (d - x(k))));
[nu2, j] = max(nu);
p2 = k(j);
end

function w = iso_weights(k, p, x, z, lambda, a_e)
% Isolation weights of candidates k (ordered outward from p) relative to
% edge p: the w_k of isolated_secondary (P.526-16 section 2.5, eq. (2)),
% with heights from the line joining the antennas, Earth bulge included.
n = numel(x);
H = z(k) + x(k) .* (x(n) - x(k)) / (2 * a_e) - (z(1) * (x(n) - x(k)) + z(n) * x(k)) / x(n);
xk = x(k);
m = numel(H);
run_min = cummin(H);
at_min = cummax((H == run_min) .* (1:m)');
c = [0; H(2:end) - run_min(1:end - 1)];
iv = [1; at_min(1:end - 1)];
d1 = abs(xk - xk(iv)); d2 = abs(xk(iv) - x(p));
r1 = sqrt(lambda * d1 .* d2 ./ max(d1 + d2, eps));   % P.526-16 eq. (2)
w = zeros(m, 1);
ok = c > 0 & r1 > 0;
w(ok) = min(1, c(ok) ./ (0.6 * r1(ok)));             % 0.6 F1: P.526-16 section 2.5
end

function [L, k_best, nu_best, w_best] = isolated_between(a, b, x, z, lambda, a_e)
% Strongest weighted edge strictly between edges a and b, with nu on the
% sub-path a..b (P.526-11 eq. (49)) and the isolation weight the smaller
% of the weights from a and from b
L = 0; k_best = a; nu_best = -Inf; w_best = 0;
if b - a < 3
    return
end
k = (a + 1:b - 1)';
d_an = x(k) - x(a); d_nb = x(b) - x(k); d_ab = x(b) - x(a);
h = z(k) + d_an .* d_nb / (2 * a_e) - (z(a) * d_nb + z(b) * d_an) / d_ab;
nu = h .* sqrt(2 * d_ab ./ (lambda * d_an .* d_nb));
w_a = iso_weights(k, a, x, z, lambda, a_e);
w_b = flipud(iso_weights(flipud(k), b, x, z, lambda, a_e));
w = min(w_a, w_b);
J = zeros(numel(k), 1);
on = nu > -0.78;
J(on) = 6.9 + 20 * log10(sqrt((nu(on) - 0.1).^2 + 1) + nu(on) - 0.1);   % P.526-16 eq. (31)
[L, j] = max(w .* J);
if L > 0
    k_best = k(j); nu_best = nu(j); w_best = w(j);
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

function [L, k_best, nu_best, w_best] = isolated_secondary(a, b, p, x, z, lambda, a_e)
% Secondary edge between ends a and b (one of them the principal edge p),
% weighted by its isolation from p. See "p526_cascaded_isolated" in the header.
L = 0; k_best = p; nu_best = -Inf; w_best = 0;
if b - a < 3
    return
end
n = numel(x);
k = (a + 1:b - 1)';
% Deygout diffraction parameter on the sub-path a..b, P.526-11 eq. (49), (49a)
d_an = x(k) - x(a); d_nb = x(b) - x(k); d_ab = x(b) - x(a);
h = z(k) + d_an .* d_nb / (2 * a_e) - (z(a) * d_nb + z(b) * d_an) / d_ab;
nu = h .* sqrt(2 * d_ab ./ (lambda * d_an .* d_nb));
% Height above the line joining the antennas, Earth bulge included
H = z(k) + x(k) .* (x(n) - x(k)) / (2 * a_e) - (z(1) * (x(n) - x(k)) + z(n) * x(k)) / x(n);
% Order the candidates outward from p, so entry j has p's nearer neighbors before it
if p == b
    H = flipud(H); nu = flipud(nu); xk = flipud(x(k));
else
    xk = x(k);
end
m = numel(H);
run_min = cummin(H);
at_min = cummax((H == run_min) .* (1:m)');           % index of the running minimum
% Deepest point strictly between candidate j and p: running minimum up to j - 1
c = [0; H(2:end) - run_min(1:end - 1)];
iv = [1; at_min(1:end - 1)];
d1 = abs(xk - xk(iv)); d2 = abs(xk(iv) - x(p));
r1 = sqrt(lambda * d1 .* d2 ./ max(d1 + d2, eps));   % P.526-16 eq. (2)
w = zeros(m, 1);
ok = c > 0 & r1 > 0;
w(ok) = min(1, c(ok) ./ (0.6 * r1(ok)));             % 0.6 F1: P.526-16 section 2.5
J = zeros(m, 1);
on = nu > -0.78;
J(on) = 6.9 + 20 * log10(sqrt((nu(on) - 0.1).^2 + 1) + nu(on) - 0.1);   % P.526-16 eq. (31)
[L, j] = max(w .* J);
if L > 0
    nu_best = nu(j); w_best = w(j);
    if p == b, k_best = k(m + 1 - j); else, k_best = k(j); end
end
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

function tf = isolated(i1, i2, x, z, lambda, a_e)
% ITU-R P.526-16 section 2.5: path clearance between the obstacles of at
% least 0.6 of the first Fresnel zone radius (eq. (2)) on the sub-path from
% edge i1 to edge i2. Adjacent samples have nothing between them to show a
% clearance, so they don't count as isolated.
if i2 - i1 < 2
    tf = false;
    return
end
k = (i1 + 1:i2 - 1)';
d_a = x(k) - x(i1); d_b = x(i2) - x(k); d_ab = x(i2) - x(i1);
ray = (z(i1) * d_b + z(i2) * d_a) / d_ab;
clearance = ray - (z(k) + d_a .* d_b / (2 * a_e));
r1 = sqrt(lambda * d_a .* d_b / d_ab);
tf = all(clearance >= 0.6 * r1);
end

function [L, obs, nus] = string_ep(x, z, lambda, a_e)
% Epstein-Peterson over stretched-string obstructions (see the header).
n = numel(x);
% Stretched string, P.526-16 eq. (44)
pts = 1; s = 1;
while s < n
    i = (s + 1:n)';
    dsi = x(i) - x(s);
    [~, j] = max((z(i) - z(s)) ./ dsi - dsi / (2 * a_e));
    s = i(j);
    pts(end + 1) = s; %#ok<AGROW>
end
mid = pts(2:end - 1);
if isempty(mid)
    % Clear path: sub-path clearance loss of the highest-nu point
    [nus, obs] = principal(1, n, x, z, lambda, a_e);
    L = knife_J(nus);
    return
end
% Consecutive samples form one obstruction: rows [first last]
brk = [true, diff(mid) > 1];
first = mid(brk);
last = mid([brk(2:end), true]);
% Merge neighbors whose valley doesn't open to 0.6 of the first Fresnel zone
k = 1;
while k < numel(first)
    if valley_open(last(k), first(k + 1), x, z, lambda, a_e)
        k = k + 1;
    else
        last(k) = last(k + 1);
        first(k + 1) = []; last(k + 1) = [];
    end
end
m = numel(first);
L = 0; nus = zeros(1, m);
for k = 1:m
    if k == 1, w = 1; else, w = last(k - 1); end
    if k == m, q = n; else, q = first(k + 1); end
    D = x(q) - x(w);
    hgt = @(p) z(p) + (x(p) - x(w)) * (x(q) - x(p)) / (2 * a_e) ...
        - (z(w) * (x(q) - x(p)) + z(q) * (x(p) - x(w))) / D;
    if first(k) == last(k)
        sv = x(first(k)) - x(w);
        hv = hgt(first(k));
    else
        a = hgt(first(k)) / (x(first(k)) - x(w));      % ray from w over the near end
        b = hgt(last(k)) / (x(q) - x(last(k)));        % ray from q over the far end
        sv = D * b / (a + b);
        hv = a * sv;
    end
    nus(k) = hv * sqrt(2 * D / (lambda * sv * (D - sv)));
    L = L + knife_J(nus(k));
end
obs = [first(:), last(:)];
end

function tf = valley_open(i1, i2, x, z, lambda, a_e)
% True when some point between i1 and i2 lies at least 0.6 of the first
% Fresnel zone radius (P.526-16 eq. (2)) below the line joining them.
if i2 - i1 < 2
    tf = false;
    return
end
k = (i1 + 1:i2 - 1)';
d_a = x(k) - x(i1); d_b = x(i2) - x(k); d_ab = x(i2) - x(i1);
clearance = (z(i1) * d_b + z(i2) * d_a) / d_ab - (z(k) + d_a .* d_b / (2 * a_e));
tf = any(clearance >= 0.6 * sqrt(lambda * d_a .* d_b / d_ab));
end

function [L, verts, nus, CN_db] = p526_cylinders(x, z, lambda, a_e)
% ITU-R P.526-16 section 4.4 with zero-radius cylinders. x, z: distance and
% height above sea level of each sample, the first and last being the
% antennas (section 4.4, second paragraph). Self-consistent units (m).
n = numel(x);
% Stretched string, eq. (44): each string point has the highest elevation
% above the local horizontal seen from the previous string point.
pts = 1; s = 1;
while s < n
    i = (s + 1:n)';
    dsi = x(i) - x(s);
    [~, j] = max((z(i) - z(s)) ./ dsi - dsi / (2 * a_e));
    s = i(j);
    pts(end + 1) = s; %#ok<AGROW>
end
mid = pts(2:end - 1);
if isempty(mid)
    % No obstruction: line of sight with sub-path diffraction over the
    % whole path (Attachment 2, section 1, last paragraph)
    L = subpath_loss(1, n, x, z, lambda, a_e);
    verts = []; nus = []; CN_db = 0;
    return
end
if any(diff(x) > 250)
    error('itmexp:multiedge', ['p526_cylinders_knife groups consecutive string samples, ' ...
        'which section 4.4 allows only for spacings of 250 m or less.']);
end
% Obstructions: runs of consecutive string samples (section 4.4)
brk = [true, diff(mid) > 1];
xs = mid(brk);                          % point x of each obstruction
ys = mid([brk(2:end), true]);           % point y
N = numel(xs);
ws = [1, ys(1:end - 1)];                % w: previous string point or terminal (Fig. 14)
zs = [xs(2:end), n];                    % z: next string point or terminal
dv = zeros(1, N); hv = zeros(1, N);
for k = 1:N
    w = ws(k); xx = xs(k); y = ys(k); zz = zs(k);
    d_wx = x(xx) - x(w); d_yz = x(zz) - x(y); d_wz = x(zz) - x(w); d_xy = x(y) - x(xx);
    if xx == y
        d_wv = d_wx;                                                        % eq. (111)
        hv(k) = z(xx);                                                      % eq. (114)
    else
        a_w = (z(xx) - z(w)) / d_wx - d_wx / (2 * a_e);                     % eq. (108)
        a_z = (z(y) - z(zz)) / d_yz - d_yz / (2 * a_e);                     % eq. (109)
        a_ee = d_wz / a_e;                                                  % eq. (110)
        th = a_w + a_z + a_ee;                                              % eq. (107)
        if th * a_e >= d_xy
            d_wv = ((a_z + a_ee / 2) * d_wz + z(zz) - z(w)) / th;           % eq. (112a)
        else
            d_wv = (d_wx + (x(y) - x(w))) / 2;                              % eq. (112b)
        end
        hv(k) = d_wv * a_w + z(w) + d_wv^2 / (2 * a_e);                     % eq. (115)
    end
    dv(k) = x(w) + d_wv;                                                    % vertex distance from the transmitter
end
% Inter-vertex distances s1, s2 (Fig. 13): to the previous and next vertex or terminal
vpos = [x(1), dv, x(n)];
s1 = vpos(2:end - 1) - vpos(1:end - 2);
s2 = vpos(3:end) - vpos(2:end - 1);
if any(s1 <= 0) || any(s2 <= 0)
    error('itmexp:multiedge', 'p526_cylinders_knife: vertices out of order.');
end
L = 0; nus = zeros(1, N);
for k = 1:N
    w = ws(k); zz = zs(k);
    d_wv = dv(k) - x(w); d_wz = x(zz) - x(w); d_vz = d_wz - d_wv;           % eq. (113)
    h = hv(k) + d_wv * d_vz / (2 * a_e) - (z(w) * d_vz + z(zz) * d_wv) / d_wz;   % eq. (116)
    nus(k) = h * sqrt(2 * (s1(k) + s2(k)) / (lambda * s1(k) * s2(k)));      % eq. (33), self-consistent units
    L = L + knife_J(nus(k));                                                % L'_i, eq. (32) with T = 0
end
% Sub-path losses, eq. (45): w..x of the first cylinder and y..z of every cylinder
L = L + subpath_loss(ws(1), xs(1), x, z, lambda, a_e);
for k = 1:N
    L = L + subpath_loss(ys(k), zs(k), x, z, lambda, a_e);
end
% Spreading correction, eq. (46)-(48); (s1)_i = (s2)_(i-1) for cascaded cylinders
Pa = s1(1) * prod(s2) * (s1(1) + sum(s2));                                  % eq. (47)
Pb = s1(1) * s2(N) * prod(s1 + s2);                                         % eq. (48)
CN_db = -10 * log10(Pa / Pb);                                               % -20 log10 C_N, C_N = (Pa/Pb)^0.5
L = L + CN_db;
verts = dv;
end

function L = subpath_loss(u, v, x, z, lambda, a_e)
% Sub-path diffraction loss on a line-of-sight section u..v, ITU-R P.526-16
% Attachment 2 to Annex 1, eq. (124)-(129) and eq. (31).
p = u + 1;
while p < v && z(p) > z(p + 1)
    p = p + 1;
end
q = v - 1;
while q > u && z(q) > z(q - 1)
    q = q - 1;
end
if p >= q
    L = 0;                                  % p = q: no sub-path obstruction (p > q can't hold one either)
    return
end
i = (p:q)';
d_uv = x(v) - x(u); d_ui = x(i) - x(u); d_iv = x(v) - x(i);
h_r = (z(u) * d_iv + z(v) * d_ui) / d_uv;                                  % eq. (127)
h_t = z(i) + d_ui .* d_iv / (2 * a_e);                                     % eq. (128)
F1 = sqrt(lambda * d_ui .* d_iv / d_uv);                                   % eq. (126)
C_F = min((h_r - h_t) ./ F1);                                              % eq. (124), (125)
L = knife_J(-C_F * sqrt(2));                                               % eq. (129), (31)
end

