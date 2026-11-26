"""B31 step 1(a): parse the text layer of OT Report 75-74 Tables 7 to 11.

One of two independent digitizations (the other is a visual transcription).
Reads `pdftotext -layout` output per page, cleans common scan errors
(S->5, l/i/I->1, O/o->0, ','->'.' inside numbers), and keeps a path row only
when it yields exactly 18 loss values in order (VHF then UHF; 10, 3, 0.3 m;
10, 50, 90 %). Rows with fewer or more values are written as unaligned for
resolution against the page image.

Usage: python3 -I experiments/batches/d31_parse_text_rev1.py <pdf> <out_dir>
Needs pdftotext (poppler).
"""
import csv
import re
import subprocess
import sys

PAGES = {40: 7, 41: 7, 54: 8, 55: 8, 56: 8, 57: 9, 58: 9, 70: 10, 71: 10, 72: 11, 73: 11}
COLS = [(b, a, p) for b in ("VHF", "UHF") for a in ("10", "3", "0.3") for p in ("10", "50", "90")]
FIX = str.maketrans({"S": "5", "s": "5", "l": "1", "i": "1", "I": "1", "O": "0", "o": "0", ",": "."})
VAL = re.compile(r"(>?)((?:1\d\d|[5-9]\d)\.\d)(\*?)")
ROW = re.compile(r"^\s*(?:(\d{1,2})\s+(\d{1,2})|(\d{1,2}))\s+(\d\s*[.,]\s*\d{1,2})\s+(.*)$")


def page_text(pdf, p):
    return subprocess.run(["pdftotext", "-f", str(p), "-l", str(p), "-layout", pdf, "-"],
                          capture_output=True, text=True, check=True).stdout


def main(pdf, out):
    good, bad = [], []
    for p, t in PAGES.items():
        rx = None
        for line in page_text(pdf, p).splitlines():
            m = ROW.match(line.translate(FIX))
            if not m:
                continue
            if m.group(1):
                tx, rx = int(m.group(1)), int(m.group(2))
            else:
                if rx is None:
                    continue
                tx = int(m.group(3))
            dist = float(re.sub(r"\s", "", m.group(4)))
            body = re.sub(r"\s", "", m.group(5))
            vals = VAL.findall(body)
            rec = {"table": t, "page": p, "tx": tx, "rx": rx, "dist_km": dist}
            if len(vals) == 18:
                for (b, a, q), (gt, v, star) in zip(COLS, vals):
                    good.append({**rec, "band": b, "ant_m": a, "pct": q, "value": v, "flag": gt + star})
            else:
                bad.append({**rec, "n_values": len(vals), "raw": line.strip()})
    with open(out + "/text_rev1.csv", "w", newline="") as f:
        w = csv.DictWriter(f, ["table", "page", "tx", "rx", "dist_km", "band", "ant_m", "pct", "value", "flag"])
        w.writeheader()
        w.writerows(good)
    with open(out + "/text_unaligned_rev1.csv", "w", newline="") as f:
        w = csv.DictWriter(f, ["table", "page", "tx", "rx", "dist_km", "n_values", "raw"])
        w.writeheader()
        w.writerows(bad)
    print("aligned rows: %d (%d cells); unaligned rows: %d" % (len(good) // 18, len(good), len(bad)))


if __name__ == "__main__":
    if len(sys.argv) != 3:
        sys.exit("usage: d31_parse_text_rev1.py <pdf> <out_dir>")
    main(sys.argv[1], sys.argv[2])
