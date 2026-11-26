"""Hardened screening entry point; reconstructs upstream findings."""
from architecture_generator_rev1 import SLOTS,load,assess
from architecture_screen_rev1 import screen,BASE

def evaluate(slots, available=BASE, root=None):
    if not isinstance(slots,dict) or set(slots)!=set(SLOTS):
        raise ValueError("invalid slot schema")
    for key,options in SLOTS.items():
        if not isinstance(slots[key],str) or slots[key] not in options:
            raise ValueError("invalid component for "+key)
    if isinstance(available,(str,bytes)):
        raise ValueError("availability must be a collection of input IDs")
    available=tuple(available)
    if any(not isinstance(x,str) or not x.strip() for x in available):
        raise ValueError("invalid input ID")
    registry,rules=load() if root is None else load(root)
    candidate={"slots":dict(slots),**assess(slots.values(),registry,rules)}
    result=screen(candidate,available)
    result["architecture_complete"]=False
    result["implementation_ready"]=False
    result["ranking_allowed"]=False
    return result
