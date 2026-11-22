function A_h = p2108_height_gain_rev1(f_mhz, h_m, clutter, frange)
%P2108_HEIGHT_GAIN_REV1 Terminal clutter loss, ITU-R P.2108-1 section 3.1 (dB).
%   A_h = P2108_HEIGHT_GAIN_REV1(f_mhz, h_m, clutter, frange) returns the
%   height gain terminal correction of ITU-R P.2108-1 (09/2021) section
%   3.1, an end loss added to basic transmission loss for a terminal
%   below the representative clutter height.
%
%   Inputs:
%     f_mhz    frequency (MHz)
%     h_m      antenna height above ground (m), > 0
%     clutter  "water_sea" | "open_rural" | "suburban" | "urban" |
%              "trees_forest" | "dense_urban" (Table 3)
%     frange   "recommendation" | "extend"
%              "recommendation": error outside 0.03-3 GHz, the range of
%                section 3.1 (Table 1).
%              "extend": no upper frequency limit. Eq. (2a) is a single
%                knife edge over the clutter (P.526-16 eq. (31)), which has
%                no frequency limit of its own; the 3 GHz limit is the
%                range over which section 3.1 was validated. Using it above
%                3 GHz is a design choice (batch B07), flagged in the plan.
%                The 0.03 GHz lower limit still applies.
%
%   Equations (P.2108-1 section 3.1; constants as in the Recommendation):
%     h >= R: A_h = 0
%     (2a) A_h = J(nu) - 6.03, J from P.526 (eq. (1) of P.2108-1), zero for nu <= -0.78
%     (2b) A_h = -K_h2 log10(h / R)
%     (2c) nu = K_nu sqrt(h_dif theta_clut)
%     (2d) h_dif = R - h
%     (2e) theta_clut = atan(h_dif / w_s), in degrees
%     (2f) K_h2 = 21.8 + 6.2 log10(f), f in GHz
%     (2g) K_nu = 0.342 sqrt(f), f in GHz
%   Table 3: R = 10 m (water/sea, open/rural, suburban), 15 m (urban,
%   trees/forest), 20 m (dense urban); eq. (2b) for water/sea and
%   open/rural, eq. (2a) for the others. w_s = 27 m, the default street
%   width of Table 2. Checked against the NTIA/ITS reference
%   implementation (github.com/NTIA/p2108) and its published test vectors
%   (github.com/NTIA/p2108-test-data) in itm_variant/tests.
arguments
    f_mhz (1,1) double
    h_m (1,1) double
    clutter (1,1) string
    frange (1,1) string = "recommendation"
end
f = f_mhz / 1000;
if ~(f >= 0.03)
    error('itmexp:p2108', 'P.2108 section 3.1 needs f >= 0.03 GHz; got %g GHz.', f);
end
switch frange
    case "recommendation"
        if f > 3
            error('itmexp:p2108', 'P.2108 section 3.1 is for 0.03-3 GHz; got %g GHz.', f);
        end
    case "extend"
    otherwise
        error('itmexp:p2108', 'Unknown frequency range rule "%s".', frange);
end
if ~(h_m > 0)
    error('itmexp:p2108', 'Antenna height must be positive.');
end
w_s = 27;                                          % Table 2 default street width (m)
switch clutter
    case {"water_sea", "open_rural"}, R = 10; use_2b = true;    % Table 3
    case "suburban",                  R = 10; use_2b = false;
    case {"urban", "trees_forest"},   R = 15; use_2b = false;
    case "dense_urban",               R = 20; use_2b = false;
    otherwise
        error('itmexp:p2108', 'Unknown clutter type "%s".', clutter);
end
if h_m >= R
    A_h = 0;
    return
end
h_dif = R - h_m;                                   % eq. (2d)
theta = atan(h_dif / w_s) * 180 / pi;              % eq. (2e), degrees
if use_2b
    K_h2 = 21.8 + 6.2 * log10(f);                  % eq. (2f)
    A_h = -K_h2 * log10(h_m / R);                  % eq. (2b)
else
    nu = 0.342 * sqrt(f) * sqrt(h_dif * theta);    % eq. (2g), (2c)
    if nu <= -0.78
        J = 0;
    else
        J = 6.9 + 20 * log10(sqrt((nu - 0.1)^2 + 1) + nu - 0.1);   % P.526 J(nu)
    end
    A_h = J - 6.03;                                % eq. (2a)
end
end
