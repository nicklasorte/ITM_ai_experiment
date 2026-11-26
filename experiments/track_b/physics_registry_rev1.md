# Track B physics component registry — rev1

Snapshot 722022bb25b52cecf6edcf996d70a8c36f108669. Individual-path only. Candidate inventory, not validated implementations. Stable IDs from the prior inventory. Sources are research leads, not freshly verified citations. Equations are illustrative where supplied; TODO means not derived or verified. No implied compatibility from absence of a rule. Legacy experiment coverage not mapped; do not infer untested from unknown. P27/P28 have only a scalar synthetic smoke and open review findings. No code or score changes.

Machine-readable: [registry](physics_registry_rev1.csv), [compatibility rules](physics_compatibility_rev1.csv). Each rule applies to listed sets where physical ownership overlaps, not necessarily every Cartesian pair. Default relationship unknown; require review before composing. C01–C12 defined in [architecture proposal](../proposals/track_b_competing_architectures_rev1.md).

## foundation

| ID | Component | Equation or gap | Benchmark |
|---|---|---|---|
| P01 | Maxwell equations | curl E=i omega mu H; curl H=J-i omega epsilon_c E | C01/C02/C10 |
| P02 | Vector wave equation | TODO: derive or verify source-specific formulation | C01/C02/C10 |
| P03 | Scalar Helmholtz equation | laplacian E+k^2 E=0 (scalar homogeneous source-free) | C01/C02/C10 |
| P04 | Green functions | TODO: derive or verify source-specific formulation | C01/C02/C10 |
| P05 | Huygens-Fresnel principle | TODO: derive or verify source-specific formulation | C01/C02/C10 |
| P06 | Fermat principle | TODO: derive or verify source-specific formulation | C01/C02/C10 |
| P07 | Eikonal equation | \|grad S\|^2=n^2 | C01/C02/C10 |
| P08 | EM boundary conditions | TODO: derive or verify source-specific formulation | C01/C02/C10 |
| P09 | Poynting theorem | TODO: derive or verify source-specific formulation | C01/C02/C10 |
| P10 | Lorentz reciprocity | TODO: derive or verify source-specific formulation | C01/C02/C10 |

## surface

| ID | Component | Equation or gap | Benchmark |
|---|---|---|---|
| P11 | Spherical spreading | TODO: derive or verify source-specific formulation | C01/C02/C10 |
| P12 | Free-space transmission | Lfs=20 log10(4 pi d/lambda) | C01/C02/C10 |
| P13 | Coherent two-ray | H=H_direct+H_reflected | C01/C02/C10 |
| P14 | Multiple ground reflections | TODO: derive or verify source-specific formulation | C01/C02/C10 |
| P15 | Fresnel reflection | TODO: derive or verify source-specific formulation | C01/C02/C10 |
| P16 | Fresnel transmission | TODO: derive or verify source-specific formulation | C01/C02/C10 |
| P17 | Sommerfeld ground wave | TODO: derive or verify source-specific formulation | C01/C02/C10 |
| P18 | Norton surface wave | TODO: derive or verify source-specific formulation | C01/C02/C10 |
| P19 | Brewster angle | TODO: derive or verify source-specific formulation | C01/C02/C10 |
| P20 | Ground conductivity | TODO: derive or verify source-specific formulation | C01/C02/C10 |
| P21 | Complex permittivity | epsilon_c=epsilon+i sigma/omega (exp(-i omega t)) | C01/C02/C10 |
| P22 | Surface impedance | TODO: derive or verify source-specific formulation | C01/C02/C10 |
| P23 | Surface roughness attenuation | TODO: derive or verify source-specific formulation | C01/C02/C10 |
| P24 | Specular reflection | TODO: derive or verify source-specific formulation | C01/C02/C10 |
| P25 | Diffuse reflection | TODO: derive or verify source-specific formulation | C01/C02/C10 |
| P26 | Polarization-dependent reflection | TODO: derive or verify source-specific formulation | C01/C02/C10 |

## diffraction

| ID | Component | Equation or gap | Benchmark |
|---|---|---|---|
| P27 | Fresnel integrals | F(v)=0.5 erfc((1-i)v sqrt(pi)/2) | C03/C04/C06/C10 |
| P28 | Single knife edge | v=h sqrt(2(d1+d2)/(lambda d1 d2)) | C03/C04/C06/C10 |
| P29 | Multiple knife edges | TODO: derive or verify source-specific formulation | C03/C04/C06/C10 |
| P30 | Rounded obstacle | TODO: derive or verify source-specific formulation | C03/C04/C06/C10 |
| P31 | Spherical Earth diffraction | TODO: derive or verify source-specific formulation | C03/C04/C06/C10 |
| P32 | Creeping waves | TODO: derive or verify source-specific formulation | C03/C04/C06/C10 |
| P33 | GTD | TODO: derive or verify source-specific formulation | C03/C04/C06/C10 |
| P34 | UTD | TODO: derive or verify source-specific formulation | C03/C04/C06/C10 |
| P35 | PTD | TODO: derive or verify source-specific formulation | C03/C04/C06/C10 |
| P36 | Physical optics | TODO: derive or verify source-specific formulation | C03/C04/C06/C10 |
| P37 | Kirchhoff diffraction integral | TODO: derive or verify source-specific formulation | C03/C04/C06/C10 |
| P38 | Rayleigh-Sommerfeld diffraction | TODO: derive or verify source-specific formulation | C03/C04/C06/C10 |
| P39 | Fresnel-zone obstruction | TODO: derive or verify source-specific formulation | C03/C04/C06/C10 |
| P40 | Lateral diffraction | TODO: derive or verify source-specific formulation | C03/C04/C06/C10 |
| P41 | Finite-width obstacle | TODO: derive or verify source-specific formulation | C03/C04/C06/C10 |
| P42 | Terrain focusing | TODO: derive or verify source-specific formulation | C03/C04/C06/C10 |
| P43 | Terrain defocusing | TODO: derive or verify source-specific formulation | C03/C04/C06/C10 |
| P44 | Terrain backscatter | TODO: derive or verify source-specific formulation | C03/C04/C06/C10 |
| P45 | Terrain multipath | TODO: derive or verify source-specific formulation | C03/C04/C06/C10 |
| P46 | Caustics and uniform asymptotics | TODO: derive or verify source-specific formulation | C03/C04/C06/C10 |

## atmosphere

| ID | Component | Equation or gap | Benchmark |
|---|---|---|---|
| P47 | Refractive index | n=1+1e-6 N | C05/C10 |
| P48 | Vertical refractivity gradient | TODO: derive or verify source-specific formulation | C05/C10 |
| P49 | Horizontal refractivity gradient | TODO: derive or verify source-specific formulation | C05/C10 |
| P50 | Effective Earth radius | k_e=1/(1+a dn/dz) (constant gradient) | C05/C10 |
| P51 | Subrefraction | TODO: derive or verify source-specific formulation | C05/C10 |
| P52 | Superrefraction | TODO: derive or verify source-specific formulation | C05/C10 |
| P53 | Surface duct | TODO: derive or verify source-specific formulation | C05/C10 |
| P54 | Elevated duct | TODO: derive or verify source-specific formulation | C05/C10 |
| P55 | Evaporation duct | TODO: derive or verify source-specific formulation | C05/C10 |
| P56 | Atmospheric waveguide | TODO: derive or verify source-specific formulation | C05/C10 |
| P57 | Atmospheric layer reflection | TODO: derive or verify source-specific formulation | C05/C10 |
| P58 | Atmospheric focusing | TODO: derive or verify source-specific formulation | C05/C10 |
| P59 | Atmospheric turbulence | TODO: derive or verify source-specific formulation | C05/C10 |
| P60 | Tropospheric scintillation | TODO: derive or verify source-specific formulation | C05/C10 |
| P61 | Range-dependent refractivity | TODO: derive or verify source-specific formulation | C05/C10 |
| P62 | Normal modes | TODO: derive or verify source-specific formulation | C05/C10 |
| P63 | Coupled modes | TODO: derive or verify source-specific formulation | C05/C10 |
| P64 | Leaky modes | TODO: derive or verify source-specific formulation | C05/C10 |

## scatter

| ID | Component | Equation or gap | Benchmark |
|---|---|---|---|
| P65 | Tropospheric volume scattering | TODO: derive or verify source-specific formulation | C07/C09 |
| P66 | Rayleigh scattering | TODO: derive or verify source-specific formulation | C07/C09 |
| P67 | Mie scattering | TODO: derive or verify source-specific formulation | C07/C09 |
| P68 | Bistatic scattering | TODO: derive or verify source-specific formulation | C07/C09 |
| P69 | Forward scattering | TODO: derive or verify source-specific formulation | C07/C09 |
| P70 | Backscattering | TODO: derive or verify source-specific formulation | C07/C09 |
| P71 | Multiple scattering | TODO: derive or verify source-specific formulation | C07/C09 |
| P72 | Radiative transfer | s dot grad I=-kappa_ext I+integral K I dOmega+Q | C07/C09 |
| P73 | Kolmogorov spectrum | TODO: derive or verify source-specific formulation | C07/C09 |
| P74 | Von Karman spectrum | TODO: derive or verify source-specific formulation | C07/C09 |
| P75 | Born approximation | TODO: derive or verify source-specific formulation | C07/C09 |
| P76 | Rytov approximation | TODO: derive or verify source-specific formulation | C07/C09 |
| P77 | Small perturbation scattering | TODO: derive or verify source-specific formulation | C07/C09 |
| P78 | Kirchhoff rough surface | TODO: derive or verify source-specific formulation | C07/C09 |
| P79 | Polarized scattering | TODO: derive or verify source-specific formulation | C07/C09 |
| P80 | Coherent-incoherent decomposition | TODO: derive or verify source-specific formulation | C07/C09 |

## materials

| ID | Component | Equation or gap | Benchmark |
|---|---|---|---|
| P81 | Dielectric absorption | TODO: derive or verify source-specific formulation | C08 |
| P82 | Vegetation volume scattering | TODO: derive or verify source-specific formulation | C08 |
| P83 | Canopy penetration | TODO: derive or verify source-specific formulation | C08 |
| P84 | Tree trunk scattering | TODO: derive or verify source-specific formulation | C08 |
| P85 | Foliage moisture | TODO: derive or verify source-specific formulation | C08 |
| P86 | Vegetation lateral waves | TODO: derive or verify source-specific formulation | C08 |
| P87 | Above-canopy diffraction | TODO: derive or verify source-specific formulation | C08 |
| P88 | Effective medium | TODO: derive or verify source-specific formulation | C08 |
| P89 | Building penetration | TODO: derive or verify source-specific formulation | C08 |
| P90 | Building reflection | TODO: derive or verify source-specific formulation | C08 |
| P91 | Building edge diffraction | TODO: derive or verify source-specific formulation | C08 |
| P92 | Street canyon waveguide | TODO: derive or verify source-specific formulation | C08 |
| P93 | Material transmission matrices | TODO: derive or verify source-specific formulation | C08 |
| P94 | Multilayer dielectric | TODO: derive or verify source-specific formulation | C08 |
| P95 | Ground moisture | TODO: derive or verify source-specific formulation | C08 |
| P96 | Vegetation anisotropy | TODO: derive or verify source-specific formulation | C08 |

## additional

| ID | Component | Equation or gap | Benchmark |
|---|---|---|---|
| P97 | Oxygen absorption | A=integral gamma ds (dB) | mechanism-specific reference required |
| P98 | Water vapor absorption | A=integral gamma ds (dB) | mechanism-specific reference required |
| P99 | Rain attenuation | gamma_R=k R^alpha (source-dependent coefficients) | mechanism-specific reference required |
| P100 | Rain scattering | TODO: derive or verify source-specific formulation | mechanism-specific reference required |
| P101 | Cloud and fog attenuation | TODO: derive or verify source-specific formulation | mechanism-specific reference required |
| P102 | Ice and snow scattering | TODO: derive or verify source-specific formulation | mechanism-specific reference required |
| P103 | Ionospheric refraction | TODO: derive or verify source-specific formulation | mechanism-specific reference required |
| P104 | Sporadic E | TODO: derive or verify source-specific formulation | mechanism-specific reference required |
| P105 | Faraday rotation | TODO: derive or verify source-specific formulation | mechanism-specific reference required |
| P106 | Hydrometeor depolarization | TODO: derive or verify source-specific formulation | mechanism-specific reference required |

## solver

| ID | Component | Equation or gap | Benchmark |
|---|---|---|---|
| N01 | Narrow-angle PE | 2 i k0 u_x+u_zz+k0^2(n^2-1)u=0 | C10/C12 plus mechanism reference |
| N02 | Wide-angle PE | TODO: derive or verify source-specific formulation | C10/C12 plus mechanism reference |
| N03 | 3D PE | TODO: derive or verify source-specific formulation | C10/C12 plus mechanism reference |
| N04 | Two-way PE | TODO: derive or verify source-specific formulation | C10/C12 plus mechanism reference |
| N05 | Split-step Fourier | TODO: derive or verify source-specific formulation | C10/C12 plus mechanism reference |
| N06 | FDFD | TODO: derive or verify source-specific formulation | C10/C12 plus mechanism reference |
| N07 | FDTD | TODO: derive or verify source-specific formulation | C10/C12 plus mechanism reference |
| N08 | FEM | TODO: derive or verify source-specific formulation | C10/C12 plus mechanism reference |
| N09 | BEM | TODO: derive or verify source-specific formulation | C10/C12 plus mechanism reference |
| N10 | Method of moments | TODO: derive or verify source-specific formulation | C10/C12 plus mechanism reference |
| N11 | Fast multipole | TODO: derive or verify source-specific formulation | C10/C12 plus mechanism reference |
| N12 | Ray tracing | TODO: derive or verify source-specific formulation | C10/C12 plus mechanism reference |
| N13 | Gaussian beam tracing | TODO: derive or verify source-specific formulation | C10/C12 plus mechanism reference |
| N14 | Beam propagation | TODO: derive or verify source-specific formulation | C10/C12 plus mechanism reference |
| N15 | Angular spectrum | TODO: derive or verify source-specific formulation | C10/C12 plus mechanism reference |
| N16 | Normal-mode expansion | phi''+(k0^2 n^2-beta^2)phi=0 | C10/C12 plus mechanism reference |
| N17 | Spectral methods | TODO: derive or verify source-specific formulation | C10/C12 plus mechanism reference |
| N18 | Fast marching | TODO: derive or verify source-specific formulation | C10/C12 plus mechanism reference |
| N19 | Monte Carlo radiative transfer | TODO: derive or verify source-specific formulation | C10/C12 plus mechanism reference |
| N20 | Reduced basis | TODO: derive or verify source-specific formulation | C10/C12 plus mechanism reference |

## statistics

| ID | Component | Equation or gap | Benchmark |
|---|---|---|---|
| S01 | Random medium | TODO: derive or verify source-specific formulation | C10/C12 plus mechanism reference |
| S02 | Stochastic Helmholtz | TODO: derive or verify source-specific formulation | C10/C12 plus mechanism reference |
| S03 | Random refractivity | TODO: derive or verify source-specific formulation | C10/C12 plus mechanism reference |
| S04 | Random surface | TODO: derive or verify source-specific formulation | C10/C12 plus mechanism reference |
| S05 | Spatial covariance | TODO: derive or verify source-specific formulation | C10/C12 plus mechanism reference |
| S06 | Temporal autocorrelation | TODO: derive or verify source-specific formulation | C10/C12 plus mechanism reference |
| S07 | Phase decorrelation | TODO: derive or verify source-specific formulation | C10/C12 plus mechanism reference |
| S08 | Rayleigh fading | TODO: derive or verify source-specific formulation | C10/C12 plus mechanism reference |
| S09 | Rician fading | TODO: derive or verify source-specific formulation | C10/C12 plus mechanism reference |
| S10 | Nakagami fading | TODO: derive or verify source-specific formulation | C10/C12 plus mechanism reference |
| S11 | Coherent field sum | G=\|sum H_m\|^2 | C10/C12 plus mechanism reference |
| S12 | Incoherent power sum | G=sum E\|H_m\|^2 (incoherent) | C10/C12 plus mechanism reference |
| S13 | Conditional distributions | F_L(l\|X)=Pr(L<=l\|X) | C10/C12 plus mechanism reference |
| S14 | Joint environmental states | F_L(l)=integral F_L(l\|Z) dP(Z) | C10/C12 plus mechanism reference |
| S15 | Extreme value theory | TODO: derive or verify source-specific formulation | C10/C12 plus mechanism reference |
| S16 | Importance sampling | TODO: derive or verify source-specific formulation | C10/C12 plus mechanism reference |
| S17 | Polynomial chaos | TODO: derive or verify source-specific formulation | C10/C12 plus mechanism reference |
| S18 | Bayesian uncertainty | TODO: derive or verify source-specific formulation | C10/C12 plus mechanism reference |
| S19 | Multiscale homogenization | TODO: derive or verify source-specific formulation | C10/C12 plus mechanism reference |
| S20 | Ensemble wave propagation | TODO: derive or verify source-specific formulation | C10/C12 plus mechanism reference |

## acceleration

| ID | Component | Equation or gap | Benchmark |
|---|---|---|---|
| A01 | Dimensional analysis | TODO: derive or verify source-specific formulation | C10/C12 plus mechanism reference |
| A02 | Matched asymptotics | TODO: derive or verify source-specific formulation | C10/C12 plus mechanism reference |
| A03 | Uniform asymptotics | TODO: derive or verify source-specific formulation | C10/C12 plus mechanism reference |
| A04 | Pade approximation | TODO: derive or verify source-specific formulation | C10/C12 plus mechanism reference |
| A05 | POD | TODO: derive or verify source-specific formulation | C10/C12 plus mechanism reference |
| A06 | Reduced-order EM | TODO: derive or verify source-specific formulation | C10/C12 plus mechanism reference |
| A07 | Adaptive mesh | TODO: derive or verify source-specific formulation | C10/C12 plus mechanism reference |
| A08 | Adaptive fidelity | TODO: derive or verify source-specific formulation | C10/C12 plus mechanism reference |
| A09 | Multigrid | TODO: derive or verify source-specific formulation | C10/C12 plus mechanism reference |
| A10 | PINN | TODO: derive or verify source-specific formulation | C10/C12 plus mechanism reference |
| A11 | Fourier neural operator | TODO: derive or verify source-specific formulation | C10/C12 plus mechanism reference |
| A12 | DeepONet | TODO: derive or verify source-specific formulation | C10/C12 plus mechanism reference |
| A13 | Gaussian process surrogate | TODO: derive or verify source-specific formulation | C10/C12 plus mechanism reference |
| A14 | Multifidelity surrogate | TODO: derive or verify source-specific formulation | C10/C12 plus mechanism reference |
| A15 | Physics constrained symbolic regression | TODO: derive or verify source-specific formulation | C10/C12 plus mechanism reference |

## Compatibility rules

- R01: P11 P12 vs P13 N01 N12 — conditional: normalize once; no extra FSPL if solver returns absolute transfer
- R02: P13 P14 P15 P24 vs N01 N02 N03 N09 — alternative_or_partition: same reflected field cannot be added twice
- R03: P28 P29 P30 P31 P33 P34 P35 vs N01 N02 N03 N09 — alternative_or_partition: same diffraction field cannot be added twice
- R04: P50 vs P47 P48 P61 N01 — conditional: curvature and refractivity transformation once
- R05: P53 P54 P55 P56 vs N01 N02 N16 P62 — alternative_or_partition: duct field owned by one solver
- R06: P65 P72 P82 vs S01 S02 N19 — conditional: derive coherent/diffuse partition and averaging
- R07: P81 P83 P88 P89 vs N01 N08 N09 — conditional: material absorption/penetration once
- R08: P97 P98 P99 P101 vs N01 N12 P65 — conditional: integrate actual trajectory or medium once
- R09: S11 vs S12 — conditional: coherent groups then incoherent power only with justified averaging
- R10: S03 S04 S14 vs S13 S20 — complementary: joint states; distinguish epistemic and time variability
- R11: A10 A11 A12 A13 A14 vs N01 N02 N09 N12 — alternative: surrogate replaces teacher prediction, not added
- R12: P20 P21 P22 vs P15 P17 P18 — complementary: consistent constitutive parameters and boundary
- R13: P23 P25 P77 P78 vs P24 P14 — conditional: conserve coherent/diffuse partition
- R14: P103 P104 P105 vs P47 P61 — conditional: distinct ionospheric path and supported frequency/time law
- R15: N05 N11 N17 A07 A09 vs N01 N09 N10 — implementation: numerical technique not extra physical loss
- R16: S08 S09 S10 vs S20 S13 — alternative_or_partition: fading law requires validated unresolved residual; no double variability

## Review and use

Select a governing representation, material and atmosphere inputs, unresolved mechanisms, statistical contract and numerical implementation. Verify source edition/equation, domain, input units, reference normalization, independent benchmarks, computational cost and ownership before registering implementation. Apply mandatory code review after each implementation; current Fresnel review remains blocking. Cost and historical coverage are unknown pending audit; no invented ratings. Registry integrity checks: 161 unique IDs, all rule references resolve, 16 rules. Self-check only, no independent scientific review. Next: map legacy submodels and published references, then fill equation/domain/cost gaps in priority order.
