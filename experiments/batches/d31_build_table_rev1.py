"""B31 step 1 (final): build the digitized OT 75-74 table with each cell's check.

Base: visual_rev1.csv. Each path's check is recorded:
- text_cells: text-layer row aligned and every cell agreed;
- text_sequence: text-layer values agreed in order (unaligned row);
- second_visual: confirmed by an independent second visual read (paths the
  text layer couldn't confirm; v1 and v2 agreed on every cell);
plus three cells resolved by the planner against the page image
(RESOLVED below). Cells either reader called hard to read are marked
uncertain.

Usage: python3 -I experiments/batches/d31_build_table_rev1.py <work_dir> <out_csv>
"""
import sys

import pandas as pd

AREA = {7: ("Eglin", "Nov-Dec, year not printed (1972 inferred)"), 8: ("Graham", "Sep-Oct 1973"), 9: ("Graham", "Apr 1974"),
        10: ("Hunter Liggett", "Jan-Feb 1974"), 11: ("Hunter Liggett", "May-Jun 1974")}
F_MHZ = {"VHF": 172.5, "UHF": 410.5}          # report Appendix A: "tuned to nominal frequencies of 172.5 and 410.5 MHz"
RX_M = {"10": 10.0, "3": 3.0, "0.3": 0.35}    # report section 2: lowest antenna 0.35 m
RESOLVED = {  # (table, tx, rx, band, ant, pct): (value, flag, note)
    (7, 2, 3, "VHF", "0.3", "90"): ("152.7", "", "text layer dropped the leading digit; image shows 152.7"),
    (8, 1, 2, "UHF", "0.3", "90"): ("142.8", "", "last digit smudged; both visual reads give 8"),
    (11, 1, 1, "UHF", "3", "90"): ("150.5", "*", "faint asterisk visible on the image"),
}
UNCERTAIN = {(8, 1, 2, "UHF", "0.3", "90"), (10, 3, 3, "UHF", "3", "90"), (10, 8, 1, "UHF", "3", "90"),
             (10, 8, 1, "UHF", "0.3", "10"), (10, 8, 1, "UHF", "0.3", "50"), (10, 8, 1, "UHF", "0.3", "90"),
             (10, 7, 1, "UHF", "10", "90"), (11, 1, 1, "UHF", "3", "90"), (11, 1, 1, "UHF", "10", "90"),
             (11, 8, 4, "VHF", "0.3", "90"), (10, 4, 4, "UHF", "10", "50")}


def main(wd, out):
    V = pd.read_csv(wd + "/visual_rev1.csv", dtype=str, keep_default_na=False)
    D = pd.read_csv(wd + "/disagreements_rev1.csv", dtype=str, keep_default_na=False)
    V2 = pd.read_csv(wd + "/visual2_rev1.csv", dtype=str, keep_default_na=False)
    U = pd.read_csv(wd + "/text_unaligned_rev1.csv", dtype=str, keep_default_na=False)
    T = pd.read_csv(wd + "/text_rev1.csv", dtype=str, keep_default_na=False)
    for d in (V, D, V2, U, T):
        for c in ("table", "tx", "rx"):
            d[c] = d[c].astype(int)
    bad = set(zip(D.table, D.tx, D.rx))
    second = set(zip(V2.table, V2.tx, V2.rx))
    aligned = set(zip(T.table, T.tx, T.rx))
    seq = set(zip(U.table, U.tx, U.rx))
    rows = []
    for r in V.itertuples():
        k = (r.table, r.tx, r.rx)
        if k in second:
            check = "second_visual"
        elif k in aligned and k not in bad:
            check = "text_cells"
        elif k in seq and k not in bad:
            check = "text_sequence"
        else:
            sys.exit("B31 STOP: path %s has no second check" % (k,))
        ck = (r.table, r.tx, r.rx, r.band, r.ant_m, r.pct)
        value, flag, note = r.value, r.flag, ""
        if ck in RESOLVED:
            value, flag, note = RESOLVED[ck]
        area, period = AREA[r.table]
        rows.append({"table": r.table, "area": area, "period": period, "tx": r.tx, "rx": r.rx,
                     "dist_km": float(r.dist_km), "band": r.band, "f_mhz": F_MHZ[r.band],
                     "tx_ant_m": 0.35, "rx_ant_m": RX_M[r.ant_m], "pct": int(r.pct),
                     "loss_db": float(value) if value not in ("", "-") else None,
                     "lower_bound": ">" in flag, "questionable": "*" in flag,
                     "missing": value in ("", "-"), "check": check,
                     "uncertain": ck in UNCERTAIN, "note": note})
    out_df = pd.DataFrame(rows)
    out_df.to_csv(out, index=False)
    print(out_df.groupby(["table", "check"]).size().unstack(fill_value=0) // 18)
    print("cells %d; missing %d; lower bounds %d; questionable %d; uncertain %d" % (
        len(out_df), out_df.missing.sum(), out_df.lower_bound.sum(), out_df.questionable.sum(), out_df.uncertain.sum()))


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2])
