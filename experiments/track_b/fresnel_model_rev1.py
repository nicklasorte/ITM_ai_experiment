"""Experimental dominant-edge kernel; not a complete propagation model."""
import numpy as np
C = 299792458.0

def predict(x, terrain, tx_agl, rx_agl, f_hz, *, cover_height=None, opacity=0., gamma=0.):
    x=np.asarray(x,dtype=float); z=np.asarray(terrain,dtype=float)
    if x.ndim!=1 or x.size<3 or z.shape!=x.shape or not np.all(np.isfinite(x)) or not np.all(np.isfinite(z)) or x[0]!=0 or np.any(np.diff(x)<=0):
        raise ValueError('invalid profile')
    if not all(np.isfinite(a) for a in (tx_agl,rx_agl,f_hz,gamma)) or min(tx_agl,rx_agl,f_hz)<=0:
        raise ValueError('invalid scalar input')
    H=np.zeros_like(z) if cover_height is None else np.asarray(cover_height,dtype=float)
    a=np.broadcast_to(np.asarray(opacity,dtype=float),z.shape)
    if H.shape!=z.shape or not np.all(np.isfinite(H)) or np.any(H<0) or not np.all(np.isfinite(a)) or np.any((a<0)|(a>1)):
        raise ValueError('invalid environmental inputs')
    D=x[-1]; s=x[1:-1]; lam=C/f_hz
    r=np.sqrt(lam*s*(D-s)/D)
    ray=z[0]+tx_agl+(z[-1]+rx_agl-z[0]-tx_agl)*s/D
    h=z[1:-1]+gamma*s*(D-s)/2-ray
    v=np.sqrt(2)*h/r; ve=v+np.sqrt(2)*a[1:-1]*H[1:-1]/r
    def loss(v):
        return 0. if v<=-.78 else max(0.,6.9+20*np.log10(np.hypot(v-.1,1)+v-.1))
    j=int(np.argmax(v)); k=int(np.argmax(ve))
    q=np.maximum(0,np.minimum(h+H[1:-1],r)-np.maximum(h,-r))/(2*r)
    fs=20*np.log10(4*np.pi*D/lam)
    return dict(status='experimental',fs_db=fs,terrain_db=fs+loss(v[j]),environment_db=fs+loss(ve[k]),terrain_edge=j+1,environment_edge=k+1,terrain_v=v[j],environment_v=ve[k],vertical_overlap=q)
