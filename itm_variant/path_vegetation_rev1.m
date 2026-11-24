function [A_db, V] = path_vegetation_rev1(pfl, cls, h_m, f_mhz, a_e_m, use_end)
%PATH_VEGETATION_REV1 Excess loss of woodland along each terminal's ray (ITU-R P.833-10 eq. (1); B17).
%   [A_db, V] = PATH_VEGETATION_REV1(pfl, cls, h_m, f_mhz, a_e_m, use_end)
%   returns the vegetation loss (dB) to add to the reference attenuation,
%   and diagnostics V.
%
%   Inputs:
%     pfl      ITM profile [np; spacing_m; z_1 ... z_np+1] (transmitter first)
%     cls      NLCD 2001 class at each of the np+1 samples
%     h_m      [h_tx h_rx] antenna heights above ground (m)
%     f_mhz    frequency (MHz)
%     a_e_m    effective Earth radius (m)
%     use_end  [true true] to count the transmitter and receiver rays; an
%              end that already carries a terminal clutter term is false
%
%   Rays (geometry of P.833-10 Fig. 1, a terminal ray entering woodland):
%   - line of sight (no sample rises above the straight ray on the
%     effective Earth): the direct ray, the half nearer each terminal
%     going to that terminal;
%   - otherwise: each terminal's ray to its radio horizon, the sample of
%     largest elevation angle on the effective Earth (as ITM's FindHorizons).
%   A sample is inside the canopy when its class is woodland (NLCD 41, 42,
%   43 or 90: the "trees_forest" mapping fixed in B11,
%   landcover_lookup_rev1) and the ray passes less than R = 15 m above the
%   ground there (ITU-R P.2108-1 Table 3, trees/forest; the same R as the
%   terminal clutter term), with the Earth bulge in the ray's chord frame.
%   d (m) = number of such samples times the profile spacing.
%
%   Loss per ray, ITU-R P.833-10 section 2.1 eq. (1):
%     A_ev = A_m [1 - exp(-d gamma / A_m)]
%   with gamma (dB/m) and A_m (dB) from P.833-10 Table 1 (mixed forest,
%   St. Petersburg, 105.9-2117.5 MHz), interpolated linearly in log10 f
%   (gamma also in log10), and held at the end values outside the table
%   (the "hold" convention of the terminal clutter term). Polarization
%   isn't used: Table 1 is mostly slant polarization.
%   A_db is the sum over the counted rays. P.833-10 defines A_ev as excess
%   to all other mechanisms, so it adds to diffraction loss.
%
%   V: d_m (1x2), A_db (1x2), los (true for the direct ray), i_hzn (1x2).

if nargin < 6 || isempty(use_end)
    use_end = [true true];
end
np = fix(pfl(1)); xi = pfl(2);
g = pfl(3:np + 3); g = g(:);
cls = cls(:);
if numel(cls) ~= np + 1
    error('itmexp:vegetation', 'Land cover has %d samples; the profile has %d.', numel(cls), np + 1);
end
if ~(f_mhz > 0) || ~(a_e_m > 0) || numel(h_m) ~= 2
    error('itmexp:vegetation', 'Bad frequency, Earth radius or heights.');
end
R = 15;                                           % m, ITU-R P.2108-1 Table 3, trees/forest
wood = ismember(cls, [41 42 43 90]);
x = (0:np)' * xi; D = x(end);
zt = g(1) + h_m(1); zr = g(end) + h_m(2);
V = struct('d_m', [0 0], 'A_db', [0 0], 'los', true, 'i_hzn', [NaN NaN]);
A_db = 0;
if np < 2
    return
end
k = (2:np)';
th_t = (g(k) - zt) ./ x(k) - x(k) / (2 * a_e_m);
th_r = (g(k) - zr) ./ (D - x(k)) - (D - x(k)) / (2 * a_e_m);
[mt, it] = max(th_t); [~, ir] = max(th_r);
it = k(it); ir = k(ir);
th_los = (zr - zt) / D - D / (2 * a_e_m);
if mt <= th_los
    % direct ray: clearance above the effective ground in the full-path chord frame
    c = (zt * (D - x) + zr * x) / D - (g + x .* (D - x) / (2 * a_e_m));
    inside = wood & c > 0 & c < R;
    inside([1 end]) = false;
    near_t = x <= D / 2;
    n_in = [nnz(inside & near_t), nnz(inside & ~near_t)];
else
    V.los = false; V.i_hzn = [it ir];
    n_in = [count_leg(1, it, zt, g(it)), count_leg(ir, np + 1, g(ir), zr)];
end
[gam, A_m] = p833_table1(f_mhz);
V.d_m = n_in * xi;
V.A_db = A_m * (1 - exp(-V.d_m * gam / A_m));      % P.833-10 eq. (1)
V.A_db(~use_end) = 0;
A_db = sum(V.A_db);
if ~isfinite(A_db) || A_db < 0
    error('itmexp:vegetation', 'Vegetation loss is not finite and non-negative.');
end

    function n = count_leg(a, b, za, zb)
        % samples strictly between a and b that are woodland under the ray
        if b - a < 2
            n = 0;
            return
        end
        j = (a + 1:b - 1)';
        da = x(j) - x(a); db = x(b) - x(j); L = x(b) - x(a);
        cl = (za * db + zb * da) / L - (g(j) + da .* db / (2 * a_e_m));
        n = nnz(wood(j) & cl > 0 & cl < R);
    end
end

function [gam, A_m] = p833_table1(f_mhz)
% ITU-R P.833-10 Table 1 (mixed coniferous-deciduous forest, mean tree height 16 m)
F = [105.9 466.475 949.0 1852.2 2117.5];          % MHz
G = [0.04 0.12 0.17 0.30 0.34];                   % gamma, dB/m
M = [9.4 18.0 26.5 29.0 34.1];                    % A_m, dB
lf = min(max(log10(f_mhz), log10(F(1))), log10(F(end)));   % hold outside the table
gam = 10 ^ interp1(log10(F), log10(G), lf);
A_m = interp1(log10(F), M, lf);
end
