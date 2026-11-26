"""Typed research graph; structural checks are not physics approval."""
from dataclasses import dataclass
from itertools import product

@dataclass(frozen=True)
class Node:
    role: str
    deps: tuple
    owns: tuple = ()

CATALOG = {
    "scene":Node("input",()),
    "source":Node("source",("scene",)),
    "gradient":Node("medium",("scene",)),
    "profile":Node("medium",("scene",)),
    "curvature":Node("transform",("gradient",),("curvature",)),
    "physical_geometry":Node("transform",("scene",),("curvature",)),
    "impedance":Node("boundary",("scene",)),
    "fresnel":Node("boundary",("scene",)),
    "N01":Node("solver",("source",),("surface_field",)),
    "N02":Node("solver",("source",),("surface_field",)),
    "N03":Node("solver",("source",),("surface_field",)),
    "N09":Node("solver",("source",),("surface_field",)),
    "N12":Node("solver",("source",),("surface_field",)),
    "receiver":Node("receiver",()),
    "conditional":Node("output",("receiver",)),
    "joint_state":Node("state",("scene",)),
    "ensemble":Node("ensemble",("joint_state","conditional")),
    "cdf":Node("output",("ensemble",)),
    "mesh":Node("numerical",()),
    "sommerfeld":Node("reference",("scene",)),
    "free_space":Node("reference",("scene",)),
}
# Provisional research contracts; not verified capability claims.
BOUNDARY={"N01":{"impedance"},"N02":{"impedance"},"N03":{"impedance"},
          "N09":{"impedance"},"N12":{"fresnel"}}
EXTRA={"N03":("terrain_3d","medium_3d"),
       "N09":("surface_mesh","green_function"),
       "N12":("terrain_3d","ray_amplitude","shadow_policy")}
def validate(nodes, edges, goal="conditional"):
    nodes=tuple(nodes)
    if any(not isinstance(n,str) or n not in CATALOG for n in nodes):
        raise ValueError("unknown node")
    if len(set(nodes))!=len(nodes): raise ValueError("duplicate node")
    ns=set(nodes)
    if goal not in ("conditional","cdf"): raise ValueError("unknown goal")
    edges=tuple(tuple(e) for e in edges)
    if any(len(e)!=2 or any(n not in ns for n in e) for e in edges):
        raise ValueError("invalid edge")
    if len(set(edges))!=len(edges): raise ValueError("duplicate edge")
    es=set(edges)
    incoming={n:{a for a,b in es if b==n} for n in ns}
    remaining=set(ns)
    while remaining:
        ready={n for n in remaining if not incoming[n]&remaining}
        if not ready: raise ValueError("dependency cycle")
        remaining-=ready
    errors=[]
    roles={r:{n for n in ns if CATALOG[n].role==r} for r in
           ("solver","boundary","medium","transform","reference")}
    for r in ("solver","boundary","medium","transform"):
        if len(roles[r])!=1: errors.append("require_one:"+r)
    for n in sorted(ns):
        for dep in CATALOG[n].deps:
            if (dep,n) not in es: errors.append("missing_dependency:"+dep+":"+n)
    owners={}
    for n in sorted(ns):
        for m in CATALOG[n].owns:
            if m in owners: errors.append("duplicate_owner:"+m)
            owners[m]=n
    need={"scene","source","receiver","conditional","free_space","sommerfeld"}
    if goal=="cdf": need|={"joint_state","ensemble","cdf"}
    elif ns&{"joint_state","ensemble","cdf"}: errors.append("unexpected_statistics")
    for n in sorted(need-ns): errors.append("missing_node:"+n)
    allowed={(d,n) for n in ns for d in CATALOG[n].deps}
    for solver in roles["solver"]:
        if not roles["boundary"]<=BOUNDARY[solver]: errors.append("boundary_mismatch")
        for d in roles["boundary"]|roles["medium"]|roles["transform"]:
            allowed.add((d,solver))
            if (d,solver) not in es: errors.append("missing_solver_input:"+d)
        allowed.add((solver,"receiver"))
        if (solver,"receiver") not in es: errors.append("missing_receiver_link")
        if "mesh" in ns: allowed.add(("mesh",solver))
    if "curvature" in ns and "profile" in ns: errors.append("curvature_profile_overlap")
    for a,b in sorted(es-allowed): errors.append("unexpected_edge:"+a+":"+b)
    return {"status":"blocked" if errors else "structural_research_only",
            "errors":errors,"unverified_requirements":sorted({x for s in roles["solver"] for x in EXTRA.get(s,())}),
            "implementation_ready":False,"ranking_allowed":False}

def generate():
    for solver,medium,goal in product(BOUNDARY,("gradient","profile"),("conditional","cdf")):
        boundary=next(iter(BOUNDARY[solver]))
        transform="curvature" if medium=="gradient" else "physical_geometry"
        nodes={"scene","source",medium,transform,boundary,solver,"receiver","conditional","free_space","sommerfeld"}
        if goal=="cdf": nodes|={"joint_state","ensemble","cdf"}
        edges={(d,n) for n in nodes for d in CATALOG[n].deps}
        edges|={(d,solver) for d in (medium,transform,boundary)}
        edges.add((solver,"receiver"))
        yield {"nodes":sorted(nodes),"edges":sorted(edges),"goal":goal,
               **validate(sorted(nodes),sorted(edges),goal)}
