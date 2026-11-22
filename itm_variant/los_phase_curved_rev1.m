function [dphi, u, v, d1] = los_phase_curved_rev1(h1, h2, s, a_e, wn)
%LOS_PHASE_CURVED_REV1 Reflected-ray phase over a curved Earth (research package H02; batch B12).
%   [dphi, u, v, d1] = LOS_PHASE_CURVED_REV1(h1, h2, s, a_e, wn) returns
%   the two-ray phase difference wn * 2 u v / s (rad) for terminal heights
%   h1, h2 (m) over a smooth sphere of effective radius a_e (m) at
%   distance s (m), with wn = 2 pi / lambda in ITM's form (f_MHz / 47.7).
%   u, v are the heights above the plane tangent at the specular point and
%   d1 its distance from terminal 1, from ITU-R P.530-19 (09/2025) Annex 1
%   section 6.1.2.3, eq. (121)-(125), and the path difference of eq. (126).
%   The research package's H02 text equates u and v to place the point;
%   that holds only for equal heights, so P.530's specular point is used.
%   Limits: m < 1e-9 uses the flat-Earth point d1 = s h1 / (h1 + h2)
%   (the m -> 0 limit of eq. (123)); u <= 0 or v <= 0 (a terminal at or
%   below the tangent plane, beyond the smooth horizon) gives zero phase.
if ~(h1 > 0 && h2 > 0 && s > 0 && a_e > 0)
    dphi = 0; u = 0; v = 0; d1 = s / 2;
    return
end
c = (h1 - h2) / (h1 + h2);                                      % eq. (125)
m = s^2 / (4 * a_e * (h1 + h2));                                % eq. (124), metres throughout
if m < 1e-9
    b = c;
else
    arg = 1.5 * c * sqrt(3 * m / (m + 1)^3);
    arg = max(-1, min(1, arg));
    b = 2 * sqrt((m + 1) / (3 * m)) * cos(pi / 3 + acos(arg) / 3);   % eq. (123)
end
d1 = s * (1 + b) / 2;                                           % eq. (121)
d2 = s * (1 - b) / 2;                                           % eq. (122)
u = h1 - d1^2 / (2 * a_e);
v = h2 - d2^2 / (2 * a_e);
if u <= 0 || v <= 0
    dphi = 0;
else
    dphi = wn * 2 * u * v / s;                                  % eq. (126) as a phase
end
end
