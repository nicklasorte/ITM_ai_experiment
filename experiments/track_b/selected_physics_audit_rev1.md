# Selected component scientific audit rev1
Scope: individual path conditional complex transfer and loss; no aggregate. Source abstracts/excerpts checked; full derivation and implementation verification not complete. All domains remain unverified for release.
Convention exp(-i omega t), k0=omega/c, passive complex permittivity Im(epsilon)>=0.
|ID|Role|Governing concept / equation|Domain limitation and falsification|
|---|---|---|---|
|N01|forward scalar solver|2ik0 u_x+u_zz+k0^2(n^2-1)u=0|paraxial, scalar, forward; compare plane-wave phase exact kx and terrain reference|
|N02|forward scalar solver|u_x=ik0(sqrt(n^2+k0^-2 dzz)-1)u for range-invariant operator|factorization not exact for range-dependent operator; specify rational approximation and evanescent branch; test angular dispersion|
|N03|3D solver candidate|N01 transverse Laplacian becomes dyy+dzz in scalar paraxial limit|not full vector; test finite-width obstacle and cross-range convergence|
|N09|boundary integral solver|A j=b schematic surface integral discretization, not executable formula|choose formulation/Green function, material, resonance treatment; small canonical references; cost dense matrix|
|N12|ray solver|eikonal abs(grad S)^2=n^2 for isotropic medium|high-frequency smooth medium, caustic/shadow limitations; diffraction not implicit; test caustic and shadow|
|P15|interface coefficient|r_TE=(kz1-kz2)/(kz1+kz2) for equal permeability, consistent tangential E basis|planar homogeneous interface, outgoing/passive branch; TM convention must be specified; test normal incidence and PEC|
|P22|boundary operator|tangential E=Zs(H cross n) with n directed into exterior, convention to be checked against solver|local impedance approximation, not exact for all dielectric angles; test against half-space|
|P17|reference solver|Sommerfeld spectral integral for dipole above planar half-space; no universal multiplicative loss|planar layered geometry and source orientation, singularities/branch cuts; compare independent numerical integral|
|P48|environment parameter|n=1+10^-6 N, gradient dn/dz in m^-1|gradient alone lacks intercept and vertical extent; test linear profile|
|P50|coordinate transform|1/Re=1/a+dn/dz under near-horizontal constant gradient approximation|no arbitrary duct or singular/negative effective radius clamp; apply curvature once|
|P61|environment field|n(x,z) or n(x,y,z)|require interpolation, coordinates and range dependence; test layer interfaces|
|S13|output estimand|F(l|X)=Pr(L<=l|X)|not itself a stochastic generator; require averaging and conditional law|
|S14|state law|F(l|X)=integral F(l|X,Z)dP(Z|X)|joint state distribution and calibration; no independent marginal quantile addition|
|S20|computation|weighted empirical CDF sum w_i I(L_i<=l)|requires state law and solver; invalid probability mass retained; convergence across seeds|
|A01|analysis method|dimensionless groups via dimensional homogeneity|not a runtime accelerator by itself; verify similarity across all relevant groups|
|A07|numerical method|adaptive discretization driven by error estimator|estimator solver-specific; refine independently; compare resource-accuracy curve|
|A08|orchestration|fidelity selection under validated error budget|no unvalidated regime switching; overlap checks, null-aware error, abstention|
Sources checked: ITU-R P.453-14 https://www.itu.int/rec/R-REC-P.453/en ; P.834-9 catalog https://www.itu.int/rec/R-REC-P.834/en ; P.834-5 section 2 equation 3 https://www.itu.int/dms_pubrec/itu-r/rec/p/R-REC-P.834-5-200503-S%21%21PDF-E.pdf (historical edition); Kuttler and Dockery 1991 https://doi.org/10.1029/91RS00109 ; Guan et al 2018 https://doi.org/10.1155/2018/1878307 ; NTIA TR-00-379 https://its.ntia.gov/publications/download/TR-00-379.pdf ; Michalski and Mosig 2016 https://doi.org/10.1080/09205071.2015.1093964 . NTIA report uses opposite time convention; translate before adopting formulas. N03/N09/N12 and statistical/numerical methods are provisional mathematical classifications, not complete source audits.
## Red-team disposition
Original Cartesian design confuses roles: S13/S14/S20 are layers, A01 is analysis, P17 is a reference, and P50 is a transform rather than an atmospheric state. Do not rank 405 combinations as 405 complete models. Replace with typed architecture graphs; explicit source/receiver normalization, solver boundary, medium, conditional outputs, joint state law only when probabilistic output requested, numerical control and reference tests. Missing troposcatter, diffraction coverage and material variability are unresolved for long-range replacement. Independent reviewer unavailable. Self-red-team only. No solver execution or accuracy claims.
