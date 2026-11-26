"""Conservative architecture screening overlay; research only."""
from architecture_generator_rev1 import load, generate
import json

# Proposed requirements, not verified validity domains.
REQUIREMENTS = {
"N01":("terrain","boundary","refractivity"),"N02":("terrain","boundary","refractivity"),
"N03":("terrain_3d","boundary","refractivity_3d"),"N09":("surface_mesh","boundary","material"),
"N12":("terrain_3d","material","refractivity_3d"),
"P15":("material","polarization"),"P22":("material","polarization"),
"P17":("planar_ground","material","polarization"),
"P48":("vertical_gradient",),"P50":("constant_gradient",),"P61":("range_profile",),
"S13":("averaging_contract",),"S14":("joint_state_law",),"S20":("joint_state_law","averaging_contract"),
"A01":(),"A07":("error_estimator",),"A08":("verified_fidelity_reference",)}
BASE=frozenset(("terrain","material","polarization","boundary","vertical_gradient","constant_gradient","averaging_contract"))

def screen(candidate, available=BASE):
    s=candidate["slots"]
    if set(s)!={"core","ground","atmosphere","statistics","acceleration"}:
        raise ValueError("invalid slots")
    ids=tuple(s.values())
    if len(set(ids))!=len(ids) or any(i not in REQUIREMENTS for i in ids):
        raise ValueError("unknown or duplicate component")
    missing=sorted(set().union(*(set(REQUIREMENTS[i]) for i in ids))-set(available))
    issues=[]
    if s["ground"]=="P17":
        issues.append("Sommerfeld planar reference is not an additive terrain correction")
    if s["core"] in ("N01","N02","N03","N09") and s["ground"]=="P15":
        issues.append("Fresnel coefficient requires a boundary derivation; not additive reflection")
    if s["atmosphere"]=="P50":
        issues.append("curvature ownership and constant-gradient approximation require proof")
    if s["statistics"] in ("S14","S20"):
        issues.append("state distribution and conditional estimand require calibration")
    if s["acceleration"]=="A08":
        issues.append("fidelity switching requires independent overlap reference")
    # No numeric domain invented. No rank or readiness claim.
    return {**candidate,"missing_inputs":missing,"ownership_review":issues,
            "domain_status":"unverified","implementation_ready":False,
            "screen_status":"blocked" if candidate["status"]=="blocked" else
            "input_gap" if missing else "research_review_required"}

def main():
    registry,rules=load()
    for candidate in generate(registry,rules):
        print(json.dumps(screen(candidate),sort_keys=True))

if __name__=="__main__":
    main()
