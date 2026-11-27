import unittest,tempfile,hashlib
from pathlib import Path
import numpy as np
from cover_adapter_rev1 import load_runs,features
class Test(unittest.TestCase):
 def test_runs(self):
    with tempfile.TemporaryDirectory() as d:
      p=Path(d)/'a'; h=Path(d)/'h'; p.write_text('path_id,i_first,i_last,nlcd2001\nA,1,2,41\nA,3,3,24\n'); h.write_text(hashlib.sha256(p.read_bytes()).hexdigest()); np.testing.assert_equal(load_runs(p,h,'A',3,'nlcd2001'),[41,41,24]); self.assertRaises(ValueError,load_runs,p,h,'A',4,'nlcd2001'); h.write_text('bad'); self.assertRaises(ValueError,load_runs,p,h,'A',3,'nlcd2001')
 def test_features(self):
    x=np.arange(101)*100.; z=np.zeros(101); z[50]=35; lc=np.full(101,71); lc[50]=41; lc[20]=24; ev=np.zeros(101); ev[50]=120
    a=features(x,z,30,30,4.4e9,lc,ev); self.assertEqual(a['edge_nlcd'],41); self.assertEqual(a['edge_tree_fraction'],1); self.assertGreater(a['known_tree_opaque_sensitivity_db'],a['terrain_db']); self.assertEqual(a['urban_height_status'],'unavailable'); ev[50]=-9999; b=features(x,z,30,30,4.4e9,lc,ev); self.assertGreater(b['unknown_tree_height_fraction'],0); self.assertEqual(b['terrain_db'],b['known_tree_opaque_sensitivity_db'])
if __name__=='__main__': unittest.main()
