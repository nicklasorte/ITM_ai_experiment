# How the framework works

Rev 1, 2026-11-21. Two views: the whole system, then one experiment in
detail. GitHub draws the diagrams from the Mermaid source below. The rules
behind each step are in [FRAMEWORK.md](../FRAMEWORK.md).

## The whole system

```mermaid
flowchart TB
    subgraph HUMAN["Human-owned (read-only to the agent)"]
        RAW["Raw public data<br/>ITS Phase 2 spot · ITS long-term"]
        BUILD["data/build_links_rev1<br/>links, profiles, splits"]
        BASE["Baseline predictions<br/>ITM 1.4 (matlab_itm @ 9bd6a4e)<br/>P.452 · P.2001 references"]
        EVAL["eval/<br/>run_eval · score · physics battery"]
        PROG["program.md · FRAMEWORK.md<br/>literature reviews"]
        RAW --> BUILD --> BASE
    end

    subgraph AGENT["Agent loop (runs in MATLAB R2025b on Nick's Mac)"]
        PICK["Pick hypothesis<br/>ranked swap, worst cell first"]
        EDIT["Edit itm_variant/<br/>itm_p2p_core_exp · params_exp"]
        RUN["run_eval_rev1(Tag=...)"]
        DEC{"Keep?"}
        KEEP["Merge to best"]
        REV["Revert branch"]
        LOG["experiments/LOG.md<br/>results/results.tsv"]
        PICK --> EDIT --> RUN --> DEC
        DEC -- "yes" --> KEEP --> LOG
        DEC -- "no" --> REV --> LOG
        LOG --> PICK
    end

    PROG --> PICK
    BASE --> RUN
    EVAL --> RUN

    subgraph GATE["Human gates"]
        REVIEW["Every 10 keeps:<br/>independent reviewer + Nick"]
        LOCK["Lockbox, once per candidate:<br/>ITS Phase 1 · low antenna · DBSG3"]
    end
    KEEP -. "10 kept" .-> REVIEW
    REVIEW -. "survivor" .-> LOCK
```

## One experiment

```mermaid
flowchart TB
    A["1. Read results.tsv and the last 20 log entries"] --> B["2. Choose the worst cell<br/>(site × band, or long-term band × distance)"]
    B --> C["3. Write the log entry first:<br/>physics rationale, public source,<br/>predicted effect per site"]
    C --> D["4. git switch -c exp/NNN from best<br/>(or a top-3 kept variant)"]
    D --> E["5. One change in itm_variant/<br/>switch in params_exp"]
    E --> F["6. Physics battery<br/>continuity · reciprocity · two-ray bound · finite"]
    F -- "fail" --> X["Fix or abandon<br/>(never weaken the battery)"]
    F -- "pass" --> G["7. Predict all links<br/>Phase 2 @ 50 % · long-term @ 1–99 %"]
    G --> H["8. Score (rounded to 0.1 dB)<br/>composite = mean of<br/>Phase 2 level · LT level · LT shape"]
    H --> I{"9. Accept?<br/>≥ 0.3 dB better<br/>no site worse > 0.5 dB<br/>censored violations ≤ +1 pt<br/>≥ 0.5 dB per new parameter"}
    I -- "yes" --> K["Merge to best"]
    I -- "no" --> R["Discard branch"]
    K --> L["10. Append result row, finish the log entry:<br/>did the prediction come true?"]
    R --> L
    X --> L
```

## Who owns what

| Area | Who edits it | Files |
| --- | --- | --- |
| Data and evaluator | Nick only | `data/`, `eval/` |
| Plan and instructions | Nick only | `FRAMEWORK.md`, `program.md`, `CLAUDE.md`, `docs/` |
| Model under test | Agent | `itm_variant/` |
| Record | Agent (append only) | `experiments/`, `results/` |
