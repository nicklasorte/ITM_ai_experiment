function out = pe2d_rev2(f_mhz, h_tx_m, pfl, gamma_e, h_rx_m, opts)
%PE2D_REV2 2D split-step Fourier PE reference, B37 repairs (diagnostic, not a model candidate).
%   out = PE2D_REV2(f_mhz, h_tx_m, pfl, gamma_e, h_rx_m, ...) is pe2d_rev1
%   (see its help for the formulation, after F. J. Ryan, NOSC TR 1453,
%   1991) with three repairs registered in experiments/batches/B37.md
%   section 2. With every repair off (the defaults: Ground "pec",
%   AvgFine false, RoughSigma 0) it reproduces pe2d_rev1 bit for bit.
%
%   Repairs:
%     AvgFine true   R-avg. In the final WindowLambda wavelengths of range
%                    the range step is at most lambda/2 (and profile knots
%                    are still stepped on), and the power is averaged over
%                    every step in the window. pe2d_rev1 averaged over the
%                    last round(WindowLambda*lambda/dx) steps, which is one
%                    step when dx is longer than the window (B36 review).
%     Ground "impedance"  R-imp. Leontovich impedance boundary
%                    du/dz + alpha u = 0 at the ground, alpha = i k
%                    sqrt(n^2 - 1), n^2 = Epsilon + i 60 lambda Sigma
%                    (horizontal polarization, small grazing angles;
%                    exp(-i w t)), solved by the discrete mixed Fourier
%                    transform: G. D. Dockery and J. R. Kuttler, "An
%                    improved impedance-boundary algorithm for Fourier
%                    split-step solutions of the parabolic wave equation",
%                    IEEE Trans. Antennas Propag. 44(12), 1996. The
%                    auxiliary field w = D u (central difference plus
%                    alpha u) is zero at the ground and is marched with the
%                    same odd-extension FFT as the perfect conductor; the
%                    discrete mode rho^m, rho the root of rho^2 +
%                    2 alpha dz rho - 1 = 0 with |rho| < 1, spans the kernel
%                    of D and is marched with its own factor; u is rebuilt
%                    from w by the two stable one-sided recursions of the
%                    factored difference operator.
%     RoughSigma s, SinGraze g  R-rough (needs Ground "impedance"). The
%                    specular reflection coefficient of the smooth
%                    impedance boundary at grazing angle asin(g) is
%                    multiplied by the Miller, Brown and Vegh
%                    factor exp(-2 a^2) I_0(2 a^2), a = k s g (IEE Proc.
%                    131 H(2), 1984), and alpha is replaced by the
%                    impedance that gives that coefficient at that angle.
%                    The caller supplies s (B37: ITM's sigma_h) and g
%                    (B37: from ITM's effective heights).
%   Epsilon, Sigma: ground constants for "impedance" (no defaults; B37
%   passes the evaluator's settings_rev1 values).
%
%   Fails loud on bad inputs, an unsupported combination, or a non-finite
%   field.
arguments
    f_mhz (1,1) double {mustBePositive}
    h_tx_m (1,1) double {mustBePositive}
    pfl (:,1) double
    gamma_e (1,1) double {mustBeNonnegative}
    h_rx_m (1,:) double {mustBePositive}
    opts.Ground (1,1) string {mustBeMember(opts.Ground, ["pec" "impedance"])} = "pec"
    opts.Epsilon (1,1) double = NaN
    opts.Sigma (1,1) double = NaN
    opts.RoughSigma (1,1) double {mustBeNonnegative} = 0
    opts.SinGraze (1,1) double = NaN
    opts.AvgFine (1,1) logical = false
    opts.DzLambda (1,1) double {mustBePositive} = 0.25
    opts.DxMax (1,1) double = NaN
    opts.ThetaBeam (1,1) double {mustBePositive} = 20
    opts.Margin (1,1) double = NaN
    opts.AbsorbFrac (1,1) double = 0.5
    opts.AbsorbRate (1,1) double {mustBePositive} = 2e-2
    opts.WindowLambda (1,1) double {mustBeNonnegative} = 20
    opts.Knife (1,:) double = []
    opts.FlatZ (1,1) logical = false
    opts.Terrain (1,1) string {mustBeMember(opts.Terrain, ["shift" "staircase"])} = "shift"
    opts.Propagator (1,1) string {mustBeMember(opts.Propagator, ["narrow" "wide"])} = "narrow"
end
imp = opts.Ground == "impedance";
if imp && (isnan(opts.Epsilon) || isnan(opts.Sigma))
    error('itmexp:pe2d', 'Ground "impedance" needs Epsilon and Sigma.');
end
if imp && opts.Terrain ~= "shift"
    error('itmexp:pe2d', 'Ground "impedance" is implemented for Terrain "shift" only.');
end
if opts.RoughSigma > 0 && (~imp || isnan(opts.SinGraze) || opts.SinGraze <= 0)
    error('itmexp:pe2d', 'RoughSigma needs Ground "impedance" and a positive SinGraze.');
end
np = pfl(1); xi = pfl(2);
if np < 2 || np ~= fix(np) || numel(pfl) ~= np + 3 || xi <= 0
    error('itmexp:pe2d', 'Malformed profile.');
end
lambda = 299.792458 / f_mhz;
k = 2 * pi / lambda;
d = np * xi;
xg = (0:np)' * xi;
zt = pfl(3:end);
if opts.FlatZ, zt = zeros(size(zt)); end
zb = min(zt);
zt = zt - zb;
shift = opts.Terrain == "shift";
slope = diff(zt) / xi;
dslope = max(abs(diff(slope)));
if shift && ~isempty(dslope) && dslope > 1 / (4 * opts.DzLambda)
    error('itmexp:pe2d', 'Slope change %.2f too large for DzLambda %.3g (aliasing); use a finer grid.', dslope, opts.DzLambda);
end
z_s = zt(1) + h_tx_m;
z_r = zt(end) + h_rx_m;
margin = opts.Margin;
if isnan(margin), margin = max([1000, 3 * sqrt(lambda * d), 0.25 * gamma_e * d^2]); end
ztop = max([zt; z_s; z_r(:)]) + margin;
H = ztop / (1 - opts.AbsorbFrac);
dz = opts.DzLambda * lambda;
N = ceil(H / dz);
dxmax = opts.DxMax;
if isnan(dxmax), dxmax = min(xi, 30); end
nsub = ceil(xi / dxmax);
nstep = np * nsub;
dx = xi / nsub;

% ---- range steps: positions, step lengths, and slope-knot index at each position
if ~opts.AvgFine
    xs = (1:nstep)' * dx;
    hs = repmat(dx, nstep, 1);
    knot = zeros(nstep, 1);
    sk = (nsub:nsub:nstep - 1)';
    knot(sk) = sk / nsub;
    nwin = max(1, round(opts.WindowLambda * lambda / dx));
    nwin = min(nwin, nstep);
    inwin = false(nstep, 1); inwin(end - nwin + 1:end) = true;
else
    Lw = opts.WindowLambda * lambda;
    if Lw <= 0 || Lw >= d
        error('itmexp:pe2d', 'AvgFine needs 0 < WindowLambda*lambda < path length.');
    end
    xw = d - Lw;
    coarse = (1:nstep)' * dx;
    xa = coarse(coarse < xw - 1e-9 * dx);
    if isempty(xa), xa0 = 0; else, xa0 = xa(end); end
    kk = xg(xg > xa0 + 1e-9 * dx & xg < d - 1e-9 * dx);   % knots after the last coarse position
    bp = unique([xa0; xw; kk; d]);
    bp = bp(bp >= xa0 - 1e-12);
    xb = [];
    for q = 1:numel(bp) - 1
        a = bp(q); b = bp(q + 1);
        if b <= xw + 1e-9 * dx
            m = max(1, ceil((b - a) / dx - 1e-9));       % before the window: coarse
        else
            m = max(1, ceil((b - a) / (lambda / 2) - 1e-9));
        end
        xb = [xb; a + (1:m)' * (b - a) / m]; %#ok<AGROW>
    end
    xs = [xa; xb];
    hs = diff([0; xs]);
    knot = zeros(numel(xs), 1);
    for q = 1:numel(xs)
        j = round(xs(q) / xi);
        if abs(xs(q) - j * xi) < 1e-9 * xi && j >= 1 && j < np, knot(q) = j; end
    end
    inwin = xs > xw + 1e-9 * dx;
    nwin = nnz(inwin);
end
ns = numel(xs);

z = (1:N)' * dz;
M = 2 * (N + 1);
p = 2 * pi / (M * dz) * [0:M/2, -M/2+1:-1]';
W = 2 * sqrt(log(2) / 2) / (k * sind(opts.ThetaBeam));
if shift
    zg0 = 0;
else
    zg0 = ground_level(z, zt(1));
end
z_s = zg0 + h_tx_m;
u = exp(-((z - z_s) / W).^2) - exp(-((z - (2 * zg0 - z_s)) / W).^2);
u(z <= zg0) = 0;
if shift
    u = u .* exp(-1i * k * slope(1) * z);
end

% ---- impedance boundary constants
if imp
    n2 = opts.Epsilon + 1i * 60 * lambda * opts.Sigma;
    sq = sqrt(n2 - 1); if real(sq) < 0, sq = -sq; end
    alpha = 1i * k * sq;
    if opts.RoughSigma > 0
        g = opts.SinGraze;
        G = (1i * k * g - alpha) / (1i * k * g + alpha);                % the smooth boundary's coefficient at asin(g)
        a2 = 2 * (k * opts.RoughSigma * g)^2;
        G = G * exp(-a2) * besseli(0, a2);                              % Miller, Brown and Vegh
        alpha = 1i * k * g * (1 - G) / (1 + G);                         % impedance giving that coefficient at asin(g)
    end
    ad = alpha * dz;
    r1 = sqrt(1 + ad^2) - ad; r2 = -sqrt(1 + ad^2) - ad;
    if abs(r1) < abs(r2), rho = r1; else, rho = r2; end
    if ~(abs(rho) < 1), error('itmexp:pe2d', 'No decaying discrete mode (|rho| = %.3g).', abs(rho)); end
    zm = [0; z];                                    % u_0 ... u_N (u_{N+1} = 0)
    modev = rho .^ (0:N)';
    mu = (rho + 1 / rho - 2) / dz^2;                % second-difference eigenvalue of the mode
    u = [0; u];                                     % add u_0 (source and image cancel at the ground)
end

cache_h = NaN; prop = []; refr = []; w = []; mfac = [];
u_rx = zeros(nwin, numel(h_rx_m));
x_rx = zeros(nwin, 1);
jw = 0;
for s = 1:ns
    h = hs(s);
    if h ~= cache_h
        prop = propagator(p, k, h, opts.Propagator);
        w = absorber(z, ztop, opts.AbsorbRate, h);
        refr = exp(1i * k * h * gamma_e * z);
        if imp
            if opts.Propagator == "narrow"
                mfac = exp(1i * mu * h / (2 * k));
            else
                mfac = exp(1i * h * (sqrt(complex(k^2 + mu)) - k));
            end
            refr0 = [1; refr]; w0 = [1; w];
        end
        cache_h = h;
    end
    if ~imp
        v = [0; u; 0; -flipud(u)];
        v = ifft(prop .* fft(v));
        u = v(2:N+1) .* refr .* w;
    else
        [wv, C] = to_w(u, alpha, dz, rho);
        v = [0; wv; 0; -flipud(wv)];
        v = ifft(prop .* fft(v));
        wv = v(2:N+1);
        C = C * mfac;
        u = from_w(wv, dz, rho) + C * modev;
        u = u .* refr0 .* w0;
    end
    if shift && knot(s) > 0
        j = knot(s);
        if imp
            u = u .* exp(-1i * k * (slope(j + 1) - slope(j)) * zm);
        else
            u = u .* exp(-1i * k * (slope(j + 1) - slope(j)) * z);
        end
    elseif ~shift && ~opts.FlatZ
        tz = interp1(xg, zt, xs(s), 'linear');
        u(z < tz) = 0;
    end
    if ~isempty(opts.Knife) && abs(xs(s) - opts.Knife(1)) < h / 2
        if imp, u(zm < opts.Knife(2) - zb) = 0; else, u(z < opts.Knife(2) - zb) = 0; end
    end
    if inwin(s)
        jw = jw + 1;
        if shift
            zr = h_rx_m;
        else
            zr = ground_level(z, interp1(xg, zt, xs(s), 'linear')) + h_rx_m;
        end
        if imp
            u_rx(jw, :) = interp1(zm, u, zr, 'linear', 0);
        else
            u_rx(jw, :) = interp1(z, u, zr, 'linear', 0);
        end
        x_rx(jw) = xs(s);
    end
end
if any(~isfinite(u))
    error('itmexp:pe2d', 'Non-finite field.');
end
rise = (zt(end) + h_rx_m) - (zt(1) + h_tx_m);
uf = free_space_rays(k, dz, hs, inwin, W, rise, x_rx, margin, opts.AbsorbFrac, opts.AbsorbRate, d, opts.Propagator);
F = u_rx ./ uf;
out = struct('dz', dz, 'dx', dx, 'N', N, 'nstep', ns, 'H', H, 'nwin', nwin, ...
    'max_slope_deg', atand(max([0; abs(slope)])));
out.F = F(end, :);
out.A_point_db = -20 * log10(abs(F(end, :)));
out.A_db = -10 * log10(mean(abs(F).^2, 1));
if imp, out.alpha = alpha; out.rho = rho; end
if any(~isfinite(out.A_db))
    error('itmexp:pe2d', 'Non-finite attenuation (field null or free-space reference zero).');
end
end

function [wv, C] = to_w(u, alpha, dz, rho)
% u = [u_0; ...; u_N], u_{N+1} = 0. w_m = (u_{m+1} - u_{m-1})/(2 dz) + alpha u_m, m = 1..N.
N = numel(u) - 1;
ue = [u; 0];
wv = (ue(3:N+2) - ue(1:N)) / (2 * dz) + alpha * ue(2:N+1);
up = from_w(wv, dz, rho);
C = u(1) - up(1);                       % the rest of u is C rho^m (kernel of D)
end

function u = from_w(wv, dz, rho)
% Particular solution of (u_{m+1} - u_{m-1})/(2 dz) + alpha u_m = w_m with
% u_{N+1} = 0 and y_1 = 0, from (E - rho)(E - sig) u_{m-1} = 2 dz w_m,
% sig = -1/rho, y_m = u_m + u_{m-1}/rho: forward y_{m+1} = rho y_m +
% 2 dz w_m, then backward u_{m-1} = rho (y_m - u_m). Both recursions
% multiply by rho, |rho| < 1, so both are stable.
N = numel(wv);
y = zeros(N + 1, 1);                    % y_1 ... y_{N+1}
for m = 1:N
    y(m + 1) = rho * y(m) + 2 * dz * wv(m);
end
u = zeros(N + 2, 1);                    % u_0 ... u_{N+1}; u_{N+1} = 0
for m = N + 1:-1:1                      % u_{m-1} = rho (y_m - u_m)
    u(m) = rho * (y(m) - u(m + 1));
end
u = u(1:N + 1);
end

function P = propagator(p, k, dx, kind)
if kind == "narrow"
    P = exp(-1i * p.^2 * dx / (2 * k));
else
    kz = sqrt(complex(k^2 - p.^2));
    P = exp(1i * dx * (kz - k));
    P(abs(p) > k) = exp(-dx * sqrt(p(abs(p) > k).^2 - k^2) - 1i * dx * k);
end
end

function zg = ground_level(z, tz)
i = find(z < tz, 1, 'last');
if isempty(i), zg = 0; else, zg = z(i); end
end

function w = absorber(z, za, rate, dx)
s = max(0, (z - za) / (max(z) - za));
w = exp(-dx * rate * s.^2);
end

function uf = free_space_rays(k, dz, hs, inwin, W, rise, x_rx, margin, absfrac, rate, d, kind)
% Free-space PE run with the same range steps, sampled along the direct rays in the window.
half = (max(abs(rise)) + margin) / (1 - absfrac);
N = 2 * ceil(half / dz);
z = ((1:N)' - N / 2) * dz;
p = 2 * pi / (N * dz) * [0:N/2, -N/2+1:-1]';
za = half * (1 - absfrac);
sa = max(0, (abs(z) - za) / (max(abs(z)) - za));
u = exp(-(z / W).^2);
uf = zeros(nnz(inwin), numel(rise));
cache_h = NaN; j = 0;
for s = 1:numel(hs)
    if hs(s) ~= cache_h
        prop = propagator(p, k, hs(s), kind);
        w = exp(-hs(s) * rate * sa.^2);
        cache_h = hs(s);
    end
    u = ifft(prop .* fft(u)) .* w;
    if inwin(s)
        j = j + 1;
        uf(j, :) = interp1(z, u, rise * x_rx(j) / d, 'linear', 0);
    end
end
end
