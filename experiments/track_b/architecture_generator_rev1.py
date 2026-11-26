"""Research candidate enumeration; never authorizes physical compatibility."""
import csv
import itertools
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parent
REL = {"conditional","alternative","alternative_or_partition","complementary","implementation"}
SLOTS = {
    "core": ("N01","N02","N03","N09","N12"),
    "ground": ("P15","P22","P17"),
    "atmosphere": ("P48","P50","P61"),
    "statistics": ("S13","S14","S20"),
    "acceleration": ("A01","A07","A08"),
}


def load(root=ROOT):
    with (root/"physics_registry_rev1.csv").open(newline="",encoding="utf-8") as f:
        rows=list(csv.DictReader(f))
    registry={}
    for row in rows:
        key=row["id"]
        if not key or key in registry or not row["validation_status"]:
            raise ValueError("invalid registry ID/status")
        registry[key]=row
    with (root/"physics_compatibility_rev1.csv").open(newline="",encoding="utf-8") as f:
        rules=list(csv.DictReader(f))
    seen=set()
    for rule in rules:
        a,b=map(lambda k:set(rule[k].split()),("component_set_a","component_set_b"))
        if (not rule["rule_id"] or rule["rule_id"] in seen or not a or not b
                or a&b or not (a|b)<=registry.keys()
                or rule["relationship"] not in REL or not rule["condition"].strip()):
            raise ValueError("invalid compatibility rule")
        seen.add(rule["rule_id"])
    return registry,rules


def assess(ids,registry,rules):
    ids=tuple(ids)
    if not ids or len(set(ids))!=len(ids) or not set(ids)<=registry.keys():
        raise ValueError("empty, duplicate or unknown component")
    findings=[]
    for a,b in itertools.combinations(sorted(ids),2):
        matches=[]
        for rule in rules:
            x,y=map(lambda k:set(rule[k].split()),("component_set_a","component_set_b"))
            if (a in x and b in y) or (b in x and a in y):
                matches.append(rule)
        kinds={m["relationship"] for m in matches}
        status=("blocked_alternative" if "alternative" in kinds else
                "conflicting_rules" if len(kinds)>1 else
                "unknown" if not kinds else "review_required")
        findings.append({"pair":[a,b],"status":status,
                         "rules":[m["rule_id"] for m in matches]})
    # Group rules are conservative flags, not pairwise physical proof.
    return {"status":"blocked" if any(f["status"] in
            {"blocked_alternative","conflicting_rules"} for f in findings)
            else "research_only",
            "implementation_ready":False,
            "metadata_unverified":list(sorted(ids)),
            "findings":findings}


def generate(registry,rules):
    for i,values in enumerate(itertools.product(*SLOTS.values()),1):
        yield {"id":f"TB-{i:04d}","slots":dict(zip(SLOTS,values)),
               **assess(values,registry,rules)}


def main():
    registry,rules=load()
    for candidate in generate(registry,rules):
        print(json.dumps(candidate,sort_keys=True))

if __name__=="__main__":
    main()
