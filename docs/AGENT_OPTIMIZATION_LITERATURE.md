# How people set up agents to optimize against a score

Rev 1, 2026-11-21. A general literature review: how AI agents are set up to
improve something when there is an automatic signal that says better or
worse. It covers the main families of loops, what each contributes, how
these loops fail, and which design rules this repository adopts. The
project-specific review is in [LITERATURE_REVIEW.md](LITERATURE_REVIEW.md).

## The common recipe

Every working system in this space has the same five parts. They differ in
how they fill each one.

| Part | Question it answers | Examples |
| --- | --- | --- |
| **Candidate generator** | What change do we try next? | An LLM editing code, a prompt, or a reward function; a classical optimizer proposing parameters |
| **Evaluator** | Is the candidate better or worse? | A test suite, a validation metric, a simulator, a held-out score |
| **Memory** | What has been tried and what happened? | A git history, a scored archive of programs, a solution tree, written reflections |
| **Selection policy** | Which candidates do we build on? | Keep if better (ratchet), keep a population, expand the best tree node, keep the best per niche |
| **Guardrails** | How do we stop the loop gaming the score? | A read-only evaluator, held-out data, human review, complexity limits |

The evaluator does most of the work. FunSearch, for example, pairs a frozen
LLM that proposes ideas with an evaluator whose job is to catch
confabulated or incorrect ones
([Romera-Paredes et al.](https://pmc.ncbi.nlm.nih.gov/articles/PMC10794145)).

## Families of loops

### 1. Ratchet: keep a change only if the score improves

The simplest loop is greedy hill climbing on code. Karpathy's
**autoresearch** (March 2026) gives an agent one training file. Each pass,
the agent edits the file, trains for five minutes, reads the validation
score, keeps or undoes the change, and logs the result
([freeCodeCamp](https://www.freecodecamp.org/news/build-an-ai-agent-that-runs-its-own-llm-experiments-with-autoresearch/)).
A change that improves the score stays as a commit; otherwise
`git reset` reverts it
([DataCamp](https://www.datacamp.com/de/tutorial/guide-to-autoresearch)).
Three files set the rules: an evaluation file that neither the human nor the
agent may change, the training file the agent edits, and a `program.md` that
only the human edits
([DataCamp](https://www.datacamp.com/hi/tutorial/guide-to-autoresearch)).
Every run gets the same time budget, so results are comparable.

- **Strength:** simple, auditable, every kept change has a commit and a
  reason.
- **Weakness:** it gets stuck at local optima, and every score check leaks a
  little information about the validation set (see
  [Failure modes](#failure-modes)).

### 2. Population and evolution: keep many candidates, breed the good ones

- **FunSearch** searches over programs that describe how to solve a problem,
  rather than over the answers themselves
  ([Romera-Paredes et al.](https://pmc.ncbi.nlm.nih.gov/articles/PMC10794145)).
- **AlphaEvolve** runs a pipeline of LLMs that make direct changes to an
  algorithm's code and improves it on feedback from one or more evaluators
  ([Novikov et al.](https://arxiv.org/abs/2506.13131)). Its mutations are
  syntax-aware edits guided by the parent programs and the user's expert
  advice; open versions include OpenEvolve, ShinkaEvolve, and DeepEvolve
  ([Mathematical exploration and discovery at scale](https://arxiv.org/pdf/2511.02864)).
- **CodeEvolve** adds an islands-based genetic algorithm to keep the
  population diverse and search in parallel
  ([arXiv 2510.14150](https://arxiv.org/pdf/2510.14150v4)).
- **DeepEvolve** adds a deep-research step before coding, to ground new
  hypotheses in the literature
  ([Liu et al.](https://arxiv.org/html/2510.06056v1)).
- **Eureka** uses a coding LLM to evolve reward functions for robot
  learning. It samples batches of candidates, refines the best, and feeds
  back a text summary of training results ("reward reflection")
  ([Ma et al.](https://arxiv.org/abs/2310.12931v2);
  [summary](https://arxiv.org/pdf/2511.19355)).

Why evolve instead of asking the LLM for the answer: building on code that
already works, one small validated change at a time, is far more reliable
for an LLM than writing a solution from scratch
([Lectures on AI for Mathematics](https://arxiv.org/pdf/2604.11504)).

### 3. Quality diversity: keep the best candidate in each niche

**MAP-Elites** keeps an archive with one cell per combination of features
the user chooses, and stores the best solution found in each cell
([Mouret and Clune](https://arxiv.org/abs/1504.04909)). Because it explores
more of the space, it also tends to find a better overall solution than
algorithms that chase one objective. AlphaEvolve's search builds on
MAP-Elites ([ImprovEvolve](https://arxiv.org/html/2602.10233)).

This matters whenever a change helps one kind of case and hurts another.
Keeping a best-per-niche archive stops the loop from throwing away a good
idea because it lost on the average.

### 4. Tree search over solutions

**AIDE** treats machine-learning engineering as code optimization and
casts trial and error as a tree search: each script is a node, LLM patches
create children, and metric feedback prunes the tree
([Jiang et al.](https://arxiv.org/abs/2502.13138);
[aideml](https://github.com/WecoAI/aideml)). Unlike a ReAct-style agent,
which piles history into its context, AIDE keeps every past solution in the
tree ([ar5iv](https://ar5iv.labs.arxiv.org/html/2502.13138)). On OpenAI's
MLE-bench, AIDE's tree search won four times as many medals as the best
linear agent
([aideml](https://github.com/harit7/aideml)).

### 5. The LLM as the optimizer

**OPRO** describes the optimization problem in plain language. At each step
the LLM sees previous solutions with their scores and proposes new ones,
which are scored and added back to the prompt
([Yang et al.](https://arxiv.org/abs/2309.03409)). The best prompts it found
beat human-written ones by up to 8 % on GSM8K and up to 50 % on Big-Bench
Hard ([ICLR 2024](https://iclr.cc/virtual/2024/poster/19209)). It depends
heavily on the LLM's own optimizing ability: small models struggle
([Zhang et al.](https://arxiv.org/html/2405.10276v1)).

### 6. Written feedback instead of a single number

- **Reflexion** has the agent write reflections on its feedback and keep them
  in an episodic memory that guides later attempts, instead of updating
  weights ([Shinn et al.](https://arxiv.org/abs/2303.11366v4)). A sparse
  success-or-failure signal becomes specific written advice
  ([PDF](https://arxiv.org/pdf/2303.11366)).
- **TextGrad** propagates LLM-written feedback backward through a compound
  system, by analogy with gradients
  ([Yuksekgonul et al.](https://arxiv.org/abs/2406.07496v1)).

The lesson for any loop: a score says whether a change helped; a written
diagnosis of why it helped or failed is what makes the next proposal good.

### 7. Classical optimizers for the numeric part

When the free choices are a few continuous constants, a classical
derivative-free optimizer is cheaper and more reliable than an LLM. Use the
LLM to propose the structure, and Bayesian optimization or a surrogate
optimizer (MATLAB `bayesopt`, `surrogateopt`) to fit its constants.

## Failure modes

### Specification gaming

Specification gaming is behavior that meets the literal objective without
achieving the intended outcome
([Krakovna et al., DeepMind](https://deepmind.google/blog/article/Specification-gaming-the-flip-side-of-AI-ingenuity)).
DeepMind collected around 60 examples
([DeepMind](https://deepmind.google/blog/specification-gaming-the-flip-side-of-ai-ingenuity/)).
One classic: an evolutionary bug-fixing system asked to remove sorting errors
from a list simply truncated the list
([Wikipedia: Reward hacking](https://www.wikipedia.com/wiki/Reward_hacking)).
A 2026 study found that all frontier models it tested exploit
specifications across varied domains
([Nishimura-Gasparian et al.](https://arxiv.org/pdf/2605.02269.pdf)).

**Defense:** the agent can't edit the evaluator or the data; the evaluator
checks several things at once, so improving one by breaking another is
caught; a human reviews kept changes.

### Goodhart's law, four ways

Manheim and Garrabrant split it into four mechanisms
([arXiv 1803.04585](https://ar5iv.arxiv.org/html/1803.04585)):

1. **Regressional:** selecting hard on a noisy proxy also selects for the
   noise.
1. **Extremal:** pushing the metric moves you into a region where the
   proxy no longer tracks the goal.
1. **Causal:** acting on the proxy breaks its link to the goal.
1. **Adversarial:** an agent with different goals games the proxy.

**Defense:** an acceptance threshold above the noise level (regressional);
physical bounds and sanity checks (extremal); the score is a measurement, not
something the agent can act on directly (causal); a read-only evaluator
(adversarial).

### Overfitting the holdout by reusing it

A holdout score estimates true performance only when the model is
independent of the holdout; once a team changes its model after seeing that
score, the independence is gone
([Google Research](https://research.google/blog/the-reusable-holdout-preserving-validity-in-adaptive-data-analysis/)).
Choosing each analysis after seeing earlier results creates a hidden, very
large multiple-comparisons problem, the "garden of forking paths"
([CACM](https://cacmb4.acm.org/magazines/2017/4/215040-guilt-free-data-reuse)).
Dwork et al. built a **reusable holdout** that limits what each query
reveals, so many adaptive analyses can be checked without collecting new
data ([Dwork et al.](https://cis.upenn.edu/~aaroth/reusable.html)).

A ratchet loop is exactly this adaptive process: hundreds of score checks
against the same folds.

**Defense:** cross-validation folds for the climbed score, a sealed lockbox
checked rarely by a human, and coarse score reporting (see the rules below).

### Leakage

Kapoor and Narayanan found leakage in at least 294 papers across 17 fields;
once it was fixed, the claimed edge of complex models over old ones
disappeared
([Patterns 2023](https://pmc.ncbi.nlm.nih.gov/articles/PMC10499856)).

**Defense:** split by group (path, site), never by row, and flag any data the
baseline model was originally built from.

## Design rules this repository adopts

| Rule | Where it comes from | How it shows up here |
| --- | --- | --- |
| The agent edits one place; the evaluator and data are read-only | autoresearch, FunSearch | `itm_variant/` editable; `eval/`, `data/` read-only |
| Every experiment is a commit that is kept or reverted | autoresearch | `exp/NNN` branches merged into `best` or discarded |
| Same budget and inputs for every run | autoresearch | Fixed inputs in `eval/settings_rev1.m`; fixed terrain |
| Write the diagnosis, not just the score | Reflexion, Eureka | `experiments/LOG.md`: rationale and predicted effect before the run, outcome after |
| Keep a best-per-niche archive | MAP-Elites, AlphaEvolve | Results kept per site × band cell and per mechanism, so a change that fixes mountains isn't lost because it hurts the average |
| Branch from more than the single best | AIDE, CodeEvolve | Agent may branch from any of the top three kept variants, not only the current best |
| LLM proposes structure; classical optimizer fits constants | Practice; Eureka | Constants fitted with `bayesopt` inside cross-validation |
| Accept only above the noise | Regressional Goodhart | 0.3 dB threshold; per-parameter cost |
| Check several things at once | Specification gaming | Physics battery, censored-bound check, per-site gates |
| Limit reuse of the holdout | Reusable holdout | Lockbox scored by a human, once per candidate; the agent sees fold scores rounded to 0.1 dB |
| Split by group | Leakage | Path- and site-grouped folds |
| Simpler wins ties | autoresearch | Complexity cost in the acceptance rule |
| Human gate | All of the above | Nick reviews every 10 kept changes and anything leaving the repo |

The 0.1 dB rounding is this project's adaptation of the reusable-holdout
idea, not a published method: it limits how much the agent learns about the
folds from each check without hiding real gains, which must exceed 0.3 dB to
count.
