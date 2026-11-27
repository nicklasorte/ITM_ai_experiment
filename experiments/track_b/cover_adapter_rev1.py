"""Offline profile alignment; no GIS or fitting in prediction loop."""
import csv, hashlib
from pathlib import Path
import numpy as np
from fresnel_model_rev1 import predict

def load_runs(file, hashfile, path_id, n, column):
    raw=Path(file).read_bytes()
    if hashlib.sha256(raw).hexdigest()!=Path(hashfile).read_text().strip():
        raise ValueError('hash mismatch')
    out=np.empty(n,dtype=int); cursor=1
    for row in csv.DictReader(raw.decode('utf-8-sig').splitlines()):
        if row['path_id']!=path_id: continue
        a,b=int(row['i_first']),int(row['i_last'])
        if a!=cursor or b<a or b>n: raise ValueError('invalid run coverage')
        out[a-1:b]=int(row[column]); cursor=b+1
    if cursor!=n+1: raise ValueError('incomplete profile')
    return out

def features(x,z,tx,rx,f,nlcd,evh,gamma=0.):
    x=np.asarray(x,float); z=np.asarray(z,float)
    lc=np.asarray(nlcd); ev=np.asarray(evh)
    if lc.shape!=x.shape or ev.shape!=x.shape: raise ValueError('unaligned profile')
    tree=np.isin(lc,[41,42,43,90]); urban=np.isin(lc,[21,22,23,24])
    valid=np.isin(lc,[11,12,21,22,23,24,31,41,42,43,52,71,81,82,90,95])
    h=np.full(x.shape,np.nan); known=tree & (ev>=101)&(ev<=199)
    h[known]=ev[known]-100
    # Only known tree heights enter this sensitivity arm; unknowns stay explicit.
    base=predict(x,z,tx,rx,f,gamma=gamma)
    p=predict(x,z,tx,rx,f,cover_height=np.where(known,h,0),opacity=1,gamma=gamma)
    s=x[1:-1]; w=(x[2:]-x[:-2])/2
    r=np.sqrt(299792458/f*s*(x[-1]-s)/x[-1]); j=base['terrain_edge']; near=np.abs(s-x[j])<=r[j-1]
    def fraction(mask,weights):
        return float(np.sum(mask*weights)/np.sum(weights)) if np.sum(weights)>0 else None
    return dict(status='partial_environment',terrain_db=float(base['terrain_db']),known_tree_opaque_sensitivity_db=float(p['environment_db']),edge_index=j,edge_nlcd=int(lc[j]),edge_evh=int(ev[j]),tree_fraction=fraction(tree[1:-1],w),urban_fraction=fraction(urban[1:-1],w),edge_tree_fraction=fraction(tree[1:-1],w*near),edge_urban_fraction=fraction(urban[1:-1],w*near),known_tree_overlap=fraction(p['vertical_overlap'],w),unknown_class_fraction=fraction(~valid[1:-1],w),unknown_tree_height_fraction=fraction((tree&~known)[1:-1],w),urban_height_status='unavailable')
