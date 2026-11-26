# Height contrast exploratory replay
Source D32 blob b4efb50ef826637f34d1988d1243bb1fcaa196d3. Matched area, period, TX/RX, frequency, TX height; exactly two rows 3/10 m, all four quality flags false, finite losses. Primary retains flagged geometry because area-specific exclusions not verified; global R5/T7 exclusion sensitivity only. Metrics arrays [bias, RMSE] dB; m suffix common offset; obs mean measured contrast. Connector JS descriptive calculation, no new model run.
```json
{
  "sha": "b4efb50ef826637f34d1988d1243bb1fcaa196d3",
  "groups": 420,
  "all": {
    "707": [
      -1.7081967009768806,
      5.825798150059415
    ],
    "n": 340,
    "obs": 3.796176470588234,
    "stock": [
      0.08622253638073428,
      6.0156213448421925
    ],
    "stockm": [
      -11.604027979000096,
      17.114000116387693
    ],
    "707m": [
      -8.42502768796417,
      14.316225897570273
    ]
  },
  "sensitivity": {
    "707": [
      -1.5527107248638654,
      5.8178284214785245
    ],
    "n": 295,
    "obs": 3.709491525423724,
    "stock": [
      -0.010660669895811471,
      6.074882555201188
    ],
    "stockm": [
      -12.008851630988602,
      17.302017929356147
    ],
    "707m": [
      -8.665022998457319,
      14.621765132231488
    ]
  },
  "areas": [
    {
      "707": [
        -2.3294299289417597,
        5.914883141551444
      ],
      "area": "Hunter Liggett",
      "n": 124,
      "obs": 3.8032258064516102,
      "stock": [
        -1.3121777749668804,
        5.923108832477824
      ],
      "stockm": [
        -9.687358479125304,
        14.613877802243733
      ],
      "707m": [
        -7.128337724893139,
        12.385247382292926
      ]
    },
    {
      "707": [
        -1.702730861334316,
        5.917097622437009
      ],
      "area": "Eglin",
      "n": 76,
      "obs": 6.880263157894738,
      "stock": [
        0.1004885458847223,
        7.020178240804374
      ],
      "stockm": [
        -22.970825241698776,
        23.959732613988503
      ],
      "707m": [
        -19.203368719647045,
        20.57487682958556
      ]
    },
    {
      "707": [
        -1.1609287262996655,
        5.69486883362056
      ],
      "area": "Graham",
      "n": 140,
      "obs": 2.1157142857142843,
      "stock": [
        1.3170612641293133,
        5.482438457425412
      ],
      "stockm": [
        -7.131102450567061,
        14.508844484744067
      ],
      "707m": [
        -3.7224250951992297,
        11.492490749471552
      ]
    }
  ]
}
```
OT75-74 introduction https://www.its.ntia.gov/publications/download/OT-75-74.pdf describes forested Eglin and sparse vegetation Graham. Confounding precludes causal identification. Prior D32-D34 contrasts overlap; not a novel experiment. No D31 join, grouped bootstrap or independent review completed; no acceptance or tuning. Next reconcile exact geometry exclusions and earlier results. Self-review: repeated paths correlated, archive clamp and antenna normalization unresolved, differences of medians not median paired differences. No lockbox accessed.
