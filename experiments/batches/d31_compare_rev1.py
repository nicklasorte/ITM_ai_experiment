"""B31 step 1: compare the two independent digitizations of OT 75-74 Tables 7 to 11.

Inputs (in <dir>): visual_rev1.csv (visual transcription, every cell),
text_rev1.csv (text layer, rows with all 18 values aligned) and
text_unaligned_rev1.csv (text-layer rows the parser couldn't align).

For aligned rows, every cell is compared (value and flag). For unaligned
rows, the text layer's values, in order, are compared with the visual row's
non-empty values in order (dashes and blanks skipped): this checks every
number, while positions come from the visual read. Distances are compared
for every path.

Usage: python3 -I experiments/batches/d31_compare_rev1.py <dir>
Writes <dir>/disagreements_rev1.csv and prints a summary.
"""
import csv
import re
import sys

import pandas as pd


def key(d):
    return list(zip(d.table, d.tx, d.rx))


def main(dd):
    V = pd.read_csv(dd + "/visual_rev1.csv", dtype=str, keep_default_na=False)
    T = pd.read_csv(dd + "/text_rev1.csv", dtype=str, keep_default_na=False)
    U = pd.read_csv(dd + "/text_unaligned_rev1.csv", dtype=str, keep_default_na=False)
    for d in (V, T, U):
        for c in ("table", "tx", "rx"):
            d[c] = d[c].astype(int)
    out = []
    order = [(b, a, p) for b in ("VHF", "UHF") for a in ("10", "3", "0.3") for p in ("10", "50", "90")]
    vrows = {k: g for k, g in V.groupby(["table", "tx", "rx"])}
    paths_v = set(vrows)
    paths_t = set(zip(T.table, T.tx, T.rx)) | set(zip(U.table, U.tx, U.rx))
    for k in sorted(paths_v - paths_t):
        out.append({"table": k[0], "tx": k[1], "rx": k[2], "kind": "path_missing_in_text"})
    for k in sorted(paths_t - paths_v):
        out.append({"table": k[0], "tx": k[1], "rx": k[2], "kind": "path_missing_in_visual"})
    n_cells = n_seq = 0
    for k, g in T.groupby(["table", "tx", "rx"]):
        if k not in vrows:
            continue
        v = vrows[k].set_index(["band", "ant_m", "pct"])
        t = g.set_index(["band", "ant_m", "pct"])
        if abs(float(v.dist_km.iloc[0]) - float(t.dist_km.iloc[0])) > 1e-9:
            out.append({"table": k[0], "tx": k[1], "rx": k[2], "kind": "distance",
                        "visual": v.dist_km.iloc[0], "text": t.dist_km.iloc[0]})
        for c in order:
            n_cells += 1
            vv, tv = v.loc[c, "value"], t.loc[c, "value"]
            vf, tf = v.loc[c, "flag"].replace("-", ""), t.loc[c, "flag"]
            if vv != tv or vf != tf:
                out.append({"table": k[0], "tx": k[1], "rx": k[2], "kind": "cell", "band": c[0], "ant_m": c[1],
                            "pct": c[2], "visual": vv + vf, "text": tv + tf})
    for _, r in U.iterrows():
        k = (r.table, r.tx, r.rx)
        if k not in vrows:
            continue
        v = vrows[k].set_index(["band", "ant_m", "pct"])
        if abs(float(v.dist_km.iloc[0]) - float(r.dist_km)) > 1e-9:
            out.append({"table": k[0], "tx": k[1], "rx": k[2], "kind": "distance",
                        "visual": v.dist_km.iloc[0], "text": r.dist_km})
        vis = [v.loc[c, "value"] for c in order if v.loc[c, "value"] != ""]
        body = re.sub(r"\s", "", r.raw.translate(str.maketrans({"S": "5", "s": "5", "l": "1", "i": "1", "I": "1",
                                                              "O": "0", "o": "0", ",": "."})))
        body = re.sub(r"^\d{1,2}(\d{1,2})?\d\.\d{1,2}", "", body)   # drop path numbers and distance
        txt = re.findall(r">?((?:1\d\d|[5-9]\d)\.\d)\*?", body)
        n_seq += 1
        if vis != txt:
            out.append({"table": k[0], "tx": k[1], "rx": k[2], "kind": "sequence",
                        "visual": " ".join(vis), "text": " ".join(txt)})
    cols = ["table", "tx", "rx", "kind", "band", "ant_m", "pct", "visual", "text"]
    with open(dd + "/disagreements_rev1.csv", "w", newline="") as f:
        w = csv.DictWriter(f, cols)
        w.writeheader()
        w.writerows(out)
    kinds = pd.Series([o["kind"] for o in out]).value_counts().to_dict() if out else {}
    print("visual paths %d; aligned cells compared %d; unaligned rows compared by sequence %d" % (
        len(paths_v), n_cells, n_seq))
    print("disagreements:", kinds)


if __name__ == "__main__":
    main(sys.argv[1])
