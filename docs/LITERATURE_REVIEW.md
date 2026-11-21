# Literature review: harness design and replacement parts for ITM

Rev 1, 2026-11-21. This review supports [FRAMEWORK.md](../FRAMEWORK.md). Part 1
covers how to build an evaluation harness that an agent can hill climb without
fooling itself. Part 2 covers the ITM submodels this project will replace or
rewrite, and what P.452, P.2001, ITU-R P.526, and the wider literature offer
for each. Part 3 turns that into a ranked list of candidate changes.

Scope set by Nick on 2026-11-21:

- Terrain source doesn't change. Every model sees the same profile.
- Replacement parts come from ITU-R P.452, P.2001, P.526, or the
  literature, or are written here from the literature.
- Comparisons cover time variability as well as the 50 % value.
- Runs use MATLAB R2025b on Nick's Mac.

## Part 1: Harness design

### 1.1 Keep the judge apart from the contestant

Every system that reliably improves code with an LLM separates three things:
an evaluator the agent can't change, the code the agent changes, and the
instructions a human owns.

- [FunSearch](https://pmc.ncbi.nlm.nih.gov/articles/PMC10794145) pairs a
  frozen LLM that proposes programs with an evaluator that guards against
  confabulated or incorrect ideas.
- [AlphaEvolve](https://arxiv.org/abs/2506.13131) has LLMs make direct edits
  to an algorithm and keeps improving it on feedback from one or more
  evaluators. Open versions include OpenEvolve, ShinkaEvolve, and DeepEvolve
  ([Mathematical exploration and discovery at scale](https://arxiv.org/pdf/2511.02864)). DeepEvolve adds a
  research step before coding, which is what this review is
  ([Liu et al.](https://arxiv.org/html/2510.06056v1)).
- Karpathy's autoresearch (March 2026) is the smallest version: the agent
  edits one training file, runs it for a fixed time, reads a validation
  metric, and keeps or reverts the commit. The evaluation file is immutable
  and the human only edits `program.md`
  ([DataCamp guide](https://www.datacamp.com/tutorial/guide-to-autoresearch)).
  It also states the rule that a small gain bought with ugly complexity isn't
  worth keeping.

**What this harness does:** `eval/` and `data/` are read-only to the agent;
the agent edits `itm_variant/` only; `program.md` is human-owned; every
experiment is a git commit that is kept or reverted.

### 1.2 Leakage is the main way a tuned model fools you

[Kapoor and Narayanan (2023)](https://pmc.ncbi.nlm.nih.gov/articles/PMC10499856)
found data leakage in at least 294 papers across 17 fields, and in their case
studies the claimed advantage of complex models over older ones disappeared
once leakage was fixed. They propose model info sheets that walk through
eight leakage types. Three of them apply directly here:

- **No true test set.** Tuning and scoring on the same paths. Fix:
  group-wise held-out folds and a sealed lockbox.
- **Non-independence between train and test.** Rows on the same path share
  terrain and siting. Fix: never split a path, and hold out whole sites.
- **Using data the model was built from.** Canada's CRC notes that P.1812
  scores well on Ofcom's UK drive tests partly because it was developed on
  them ([Ethier and Châteauvert](https://arxiv.org/html/2405.10006v1)). The
  same trap exists here: ITM's time-variability curves were drawn from
  long-term measurements of the same era, and the NBS Technical Note 101
  graphs for long-term variability were
  [based on the data then available](https://its.ntia.gov/publications/download/TN101v1.pdf).
  The ITS long-term set used here overlaps that data, so **ITM's baseline
  time-variability score on it is likely optimistic**, and P.452 and P.2001
  were tested on SG3 databanks that share paths with it. The harness reports
  this as a known bias. It doesn't fix it.

### 1.3 Weight by path and site, and know the noise floor

- [Paul (2003)](https://its.ntia.gov/publications/download/2003%20ISART%2003-401%20Paul.pdf)
  warns that many of the 41,000 ITS measurements come from the same paths
  and are correlated.
- [Willis, Craig, and Thomas](https://its.ntia.gov/media/33514/wil_m-08.pdf)
  found that differences between candidate models were hidden by measurement
  error, that data aren't of equal weight, and that a model can end up
  matching the most numerous dataset.
- [Craig et al. (2008)](https://its.ntia.gov/media/33469/cra_k-08.pdf),
  testing diffraction variants on 5,316 links from 26 datasets, found that
  mean-error differences between datasets were larger than differences
  between models, so mean errors were probably dominated by measurement
  bias.

**What this harness does:** each path gets a total weight of 1; each
site × band cell counts equally; per-site bias is reported but the climbed
score is RMS; the agent stops on a cell within 1 dB of the measured noise
floor.

### 1.4 Score the whole time distribution, not only the median

The long-term data give measured quantiles of hourly-median attenuation at
0.01, 0.1, 1, 10, 50, 90, 99, 99.9, and 99.99 % of time
([ITS legacy data](https://its.ntia.gov/data/legacy-radio-propagation-data/)).
The source report covers nearly 800 paths from 40 MHz to 10 GHz and 10 to
1000 km ([Longley, Reasoner, and Fuller 1971, OT/TRER 16](https://www.ntia.gov/report/1971/measured-and-predicted-long-term-distributions-tropospheric-transmission-loss)).

A time-variability score needs two parts, because a model can get the median
wrong and the spread right, or the reverse:

- **Level error** at each quantile: predicted minus measured loss at p %.
- **Shape error**: `(L_p − L_50)` predicted minus measured, which removes the
  median error and tests only the spread.

The quantiles at 0.01 % and 99.99 % rest on few hours of data; the harness
scores 1, 10, 50, 90, and 99 % and reports the tails separately.

### 1.5 Handle censored measurements

About 12 % of Phase 2 results are below the receiver's sensitivity, so the
measured loss is only a lower bound. Dropping them biases the data toward
strong-signal paths. The harness keeps them out of the RMS but counts how
often a variant predicts less loss than the bound, which catches a change
that improves RMS by predicting optimistic loss on dead paths.

### 1.6 Reference parity

The baseline must reproduce exactly, every run. `matlab_itm` matches the NTIA
C++ to within 4 × 10⁻¹³ dB on 740 cases, so the experimental copy starts as a
bit-identical clone and the harness checks that the unmodified copy
reproduces the stored baseline before it scores anything.

## Part 2: Replacement parts

### 2.1 Diffraction

**What ITM does.** Between the radio horizons, ITM blends a double
knife-edge loss and a smooth-earth loss with a weight that depends on terrain
irregularity, and adds a terrain clutter term
([Paul 2003](https://its.ntia.gov/publications/download/2003%20ISART%2003-401%20Paul.pdf)).
It doesn't use the profile between the two horizons, so obstacles there are
invisible to it.

**What the field offers.**

| Method | How it works | Evidence | Source |
| --- | --- | --- | --- |
| Bullington | Replace all obstacles with one equivalent knife-edge at the intersection of the steepest rays from each end | In a five-method Brazilian comparison, Bullington gave the worst results ([UFU](https://repositorio.ufu.br/bitstream/123456789/18133/4/ComportamentoModelosCalculo.pdf)); on the SG3 database its spread was lower than P.1812's 3-edge method ([Craig et al.](https://its.ntia.gov/media/33469/cra_k-08.pdf)) | ITU-R P.526 §4.5.1 |
| Delta-Bullington | Bullington on the actual profile, minus Bullington on a smooth profile, plus spherical-earth loss; continuous from line of sight into diffraction | Used by P.452 (since rev 17) and P.2001 (Attachment A) | [P.526-16 §4.5.2](https://www.itu.int/dms_pubrec/itu-r/rec/p/R-REC-P.526-16-202511-I!!TOC-HTM-E.htm), [P.2001-6 Attachment A](https://www.itu.int/dms_pubrec/itu-r/rec/p/R-REC-P.2001-6-202509-I!!TOC-HTM-E.htm) |
| Epstein-Peterson | Add single knife-edge losses for each edge on the sub-path between its neighbors | Close to Giovaneli in the UFU comparison | [Kasampalis et al.](https://bura.brunel.ac.uk/bitstream/2438/34053/2/FullText.pdf) |
| Deygout | Main edge first, then sub-path edges recursively | Often pessimistic in the UFU comparison | [Vogler TR-83-124](https://its.ntia.gov/publications/details?pub=2125) |
| Giovaneli | A geometric correction to Deygout | Close to Vogler in several comparisons | [Kasampalis et al.](https://bura.brunel.ac.uk/bitstream/2438/34053/2/FullText.pdf) |
| Vogler | Rigorous multiple knife-edge integral, checked against measured data | Too slow for coverage runs | [Vogler TR-82-108](https://its.ntia.gov/publications/details?pub=2099) |
| Fast graphical algorithms (up to six edges) | Algorithms for Bullington, Epstein-Peterson, Deygout, and Giovaneli, compared with Vogler; many orders of magnitude faster | Includes a technique to pick the best method per path | [DeMinco, McKenna, Johnk, NTIA TR-26-580 (Oct 2025)](https://www.its.ntia.gov/publications/details?pub=4564) |
| Roughness-weighted edge loss (FCC PTP) | Edge loss `J(v) + R·(S(v) − J(v))`, with `S(v) = max(21.66 + 27.35v, 0)` and `R = 75/(ΔH + 75)`, ΔH from terrain within 10 km of the edge | Similar results across three variants on SG3 data | [Craig et al.](https://its.ntia.gov/media/33469/cra_k-08.pdf) |

Kasampalis et al. found ITM accurate in most mountainous paths but
underestimating field strength in some long fringe paths, where
multiple knife-edge methods were accurate
([BMSB 2015](https://bura.brunel.ac.uk/handle/2438/34053?mode=full)).

**Implication for us.** R2 (Colorado mountains) has 29.9 dB RMS under ITM.
Multi-edge diffraction on the actual profile is the most likely single fix.
Start with delta-Bullington (it is what P.452 and P.2001 use and it is
continuous with line of sight), then try Epstein-Peterson and Giovaneli as
the edge model, and the roughness-weighted edge loss as a way to keep ITM's
smooth-earth behavior on gentle terrain.

### 2.2 Effective antenna height

**What ITM does.** ITM fits a least-squares line to the terrain near each
terminal and measures the antenna height above that line. On rough or
sloping terrain this effective height can far exceed the structural height.

**Evidence.**

- Paul (2003): effective heights have a significant effect on ITM in every
  path class, errors are largest when effective height greatly exceeds
  structural height, and the best value is often between the two
  ([Paul 2003](https://its.ntia.gov/publications/download/2003%20ISART%2003-401%20Paul.pdf)).
- Montgomery (1969) compared several effective-height definitions (least
  squares fits to different sections of the profile) and several
  Rayleigh-roughness factors against field-strength data
  ([ERL TM 158](https://its.ntia.gov/publications/details?pub=3069)).

**Candidates.** A blend `h_e = h_s + α(h_e,ITM − h_s)` with α fitted; a cap
tied to terrain roughness under the antenna; Montgomery's alternative fit
windows. This is a small code change in `quick_pfl` with one or two
parameters.

### 2.3 Line of sight

**What ITM does.** A two-ray model built on effective heights, blended with
extrapolated diffraction loss, and a roughness-based reduction of the
reflected ray. When effective and structural heights are close, ITM and other
two-ray models agree; otherwise they diverge because they compute ground
reflection differently
([Paul 2003](https://its.ntia.gov/publications/download/2003%20ISART%2003-401%20Paul.pdf)).

**What P.452 and P.2001 do.** Free-space loss plus a multipath and focusing
correction for the time percentage, with sub-path diffraction taken from the
delta-Bullington term, so a partly obstructed line-of-sight path gets loss
from the actual obstacle.

**Implication for us.** 89 % of Phase 2 rows are line of sight under ITM, at
15.7 dB RMS. If delta-Bullington is adopted for diffraction, its sub-path
term is the natural line-of-sight replacement too, so the two swaps should be
tested together as well as separately.

### 2.4 Troposcatter and the mode switch

**What ITM does.** Troposcatter loss from the H0 frequency-gain curves and an
attenuation function of scattering angle; the model switches to troposcatter
when its loss falls below diffraction's.

**What P.452 and P.2001 do.** P.452 treats troposcatter as the background
interference level for longer paths, more than about 100–150 km
([P.452-16](https://www.itu.int/dms_pubrec/itu-r/rec/p/R-REC-P.452-16-201507-S!!PDF-E.pdf)).
P.2001 has a separate troposcatter sub-model with its own climate
classification, combined with the other sub-models (Attachment E)
([P.2001-6](https://www.itu.int/dms_pubrec/itu-r/rec/p/R-REC-P.2001-6-202509-I!!TOC-HTM-E.htm)).

**Implication for us.** On Phase 2, ITM selects troposcatter on 234 results,
all on paths of 75–120 km (116 of them in the R2 mountains), below the
100–150 km range where P.452 says troposcatter sets the background level.
ITM over-predicts loss there by 19.1 dB on average. Test two separate
changes: the P.452 or P.2001 troposcatter formula, and a mode-switch rule
that keeps obstructed paths of this length in diffraction.

### 2.5 Time variability

**What ITM does.** ITM splits variability into time, location, and situation
components ([Longley–Rice](https://en.wikipedia.org/wiki/Longley%E2%80%93Rice_model)).
Time variability uses climate-specific empirical curves of effective
distance, from Technical Note 101.

**What P.452 does.** P.452 predicts loss not exceeded for 0.001 % to 50 % of
time and is built for interference
([P.452-17](https://www.itu.int/dms_pubrec/itu-r/rec/p/R-REC-P.452-17-202109-S!!PDF-E.pdf)).
It has no fading side (above 50 %), so it can replace ITM only on the
enhancement side of the distribution.

**What P.2001 does.** P.2001 covers 0 % to 100 % of an average year with no
discontinuities, which makes it suitable for Monte Carlo
([P.2001-6](https://www.itu.int/dms_pubrec/itu-r/rec/p/R-REC-P.2001-6-202509-I%21%21PDF-E.pdf)).
It combines sub-models for normal propagation (diffraction with clear-air
fading and enhancement), anomalous propagation (ducting and layer
reflection), troposcatter, and sporadic-E
([P.2001-0 contents](https://www.itu.int/dms_pubrec/itu-r/rec/p/R-REC-P.2001-0-201202-S!!TOC-HTM-E.htm)).

**Candidates.**

- Replace ITM's time deviate with P.2001's clear-air fading and enhancement
  (Attachment B) on the ITM median.
- Replace the enhancement side only with P.452's ducting and layer-reflection
  model, keeping ITM's fading side.
- Refit ITM's climate curve constants on training folds of the long-term
  set, noting the in-sample caveat in §1.2.

## Part 3: Ranked candidates

Ranked by expected gain on the observed error and cost to build. "Source"
says where the code or formula comes from. The P.452 and P.2001 parts are
written fresh in `itm_variant/` from the ITU-R text, with Nick's existing
ports used only as numerical checks.

| Rank | Candidate | ITM function | Source | Target error | New parameters |
| --- | --- | --- | --- | --- | --- |
| 1 | Delta-Bullington diffraction on the actual profile | `diffraction_loss`, `knife_edge_diffraction` | P.526 §4.5, P.2001 Att. A | R2, diffraction mode | 0 |
| 2 | Effective-height blend | `quick_pfl` | Paul 2003; Montgomery 1969 | Line of sight, all sites | 1 |
| 3 | Troposcatter mode-switch guard for obstructed paths under about 150 km | `longley_rice` | This project, from the Phase 2 diagnosis | Troposcatter mode (+19 dB) | 0–1 |
| 4 | Delta-Bullington sub-path term for line of sight | `line_of_sight_loss` | P.452, P.2001 | Line of sight, 3–10 GHz | 0 |
| 5 | Multi-edge alternatives: Epstein-Peterson, Giovaneli, roughness-weighted edge | `knife_edge_diffraction` | TR-26-580; FCC PTP | R2 | 0–1 |
| 6 | P.2001 or P.452 troposcatter formula | `troposcatter_loss` | P.2001 Att. E; P.452 §4.3 | Long-term trans-horizon paths | 0 |
| 7 | P.2001 clear-air fading and enhancement on the ITM median | `variability` | P.2001 Att. B | Long-term shape error | 0 |
| 8 | Refit ITM time-variability constants | `variability`, `curve` | TN101 form, refit | Long-term shape error | 3–6 |

Write-up rule: name each part by its physics and its public source. Don't
attribute a change to an unpublished or restricted model.
