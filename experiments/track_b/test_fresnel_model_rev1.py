import unittest
import numpy as np
from fresnel_model_rev1 import predict
class Test(unittest.TestCase):
    def setUp(self):
        self.x=np.linspace(0,10000,101); self.z=np.zeros(101); self.f=4.4e9
    def p(self,z=None,**kw): return predict(self.x,self.z if z is None else z,30,30,self.f,**kw)
    def test_clear(self):
        p=self.p(); self.assertEqual(p['terrain_db'],p['fs_db'])
    def test_grazing(self):
        z=self.z.copy(); z[50]=30; p=self.p(z); self.assertAlmostEqual(p['terrain_db']-p['fs_db'],6.03285,places=4)
    def test_transparent(self):
        p=self.p(cover_height=np.full(101,40),opacity=0); self.assertEqual(p['terrain_db'],p['environment_db'])
    def test_opaque(self):
        H=self.z.copy(); H[50]=40; p=self.p(cover_height=H,opacity=1); self.assertAlmostEqual(p['environment_db'],self.p(H)['terrain_db'])
    def test_reversal(self):
        z=self.z.copy(); z[20]=40; H=self.z.copy(); H[65]=60
        a=predict(self.x,z,10,30,self.f,cover_height=H,opacity=.8,gamma=1e-7); b=predict(self.x,z[::-1],30,10,self.f,cover_height=H[::-1],opacity=.8,gamma=1e-7); self.assertAlmostEqual(a['environment_db'],b['environment_db']); np.testing.assert_allclose(a['vertical_overlap'],b['vertical_overlap'][::-1])
    def test_invalid(self):
        with self.assertRaises(ValueError): self.p(cover_height=np.full(101,-1))
        with self.assertRaises(ValueError): self.p(opacity=2)
    def test_overlap(self):
        p=self.p(cover_height=np.full(101,100)); self.assertTrue(np.all((p['vertical_overlap']>=0)&(p['vertical_overlap']<=1)))
    def test_zero_height(self):
        p=self.p(opacity=1); self.assertEqual(p['terrain_db'],p['environment_db'])
if __name__=='__main__': unittest.main()
