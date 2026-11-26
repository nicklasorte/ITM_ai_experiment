function T = d34_perturb_rev1(root)
%D34_PERTURB_REV1 B34 D34c: stock ITM loss as the profile spacing alone moves by -20 to +20 ULP (diagnostic).
%   T = D34_PERTURB_REV1(root) takes the two pairs D34c traced (Hunter
%   Liggett T4-R4, Table 10; Graham T3-R3, Table 9), their fresh profiles
%   from profiles_lossless_rev1.mat, and runs stock ITM (itm_p2p_rev1) at
%   both bands and both receivers (3 m, 10 m; transmitter 0.5 m) with the
%   spacing offset by k ULP, k = -20..20, elevations unchanged. Writes
%   experiments/D34c-profile-roundtrip/perturbations_rev1.csv with the
%   exact spacing as hex and the loss with 17 significant digits.
arguments
    root (1,1) string
end
itm_exp_paths_rev1();
S = settings_rev1();
out = fullfile(root, 'experiments', 'D34c-profile-roundtrip');
M = load(fullfile(out, 'profiles_lossless_rev1.mat'));
Pr = readtable(fullfile(root, 'experiments', 'D32-ot7574-heights', 'predictions_rev1.csv'), 'TextType', 'string');
keys = string({M.profiles.geom_key});
pairs = {"Hunter|T4|R4", 10; "Graham|T3|R3", 9};
rows = {};
for a = 1:size(pairs, 1)
    g = pairs{a, 1}; tb = pairs{a, 2};
    pf = M.profiles(keys == g).pfl;
    for band = ["VHF" "UHF"]
        for h = [3 10]
            q = Pr(Pr.geom_key == g & Pr.table == tb & Pr.band == band & Pr.rx_ant_m == h, :);
            if height(q) ~= 1
                error('itmexp:d34c', 'Expected one B32 row for %s %s %g m.', g, band, h);
            end
            for u = -20:20
                p2 = pf; p2(2) = pf(2) + u * eps(pf(2));
                L = itm_p2p_rev1(0.5, h, p2, q.f_mhz, 50, confidence=S.confidence, climate=q.climate, ...
                    N_0=q.N_0, polarization=1, epsilon=q.epsilon, sigma=q.sigma, mdvar=S.mdvar, validity="off");
                rows(end + 1, :) = {g, tb, band, h, u, string(num2hex(p2(2))), string(sprintf('%.17g', L))}; %#ok<AGROW>
            end
        end
    end
end
T = cell2table(rows, 'VariableNames', {'geom_key', 'table', 'band', 'rx_ant_m', 'spacing_offset_ulp', ...
    'spacing_hex', 'stock_L_db'});
writetable(T, fullfile(out, 'perturbations_rev1.csv'));
fprintf('Wrote perturbations_rev1.csv (%d rows)\n', height(T));
end
