import unittest
from architecture_generator_rev1 import load,generate
from architecture_screen_rev1 import screen,BASE

class ScreenTests(unittest.TestCase):
    def test_all(self):
        r,q=load()
        a=[screen(c) for c in generate(r,q)]
        self.assertEqual(len(a),405)
        self.assertTrue(all(not c["implementation_ready"] for c in a))
        self.assertTrue(all(c["domain_status"]=="unverified" for c in a))
    def test_missing(self):
        r,q=load()
        c=next(generate(r,q))
        self.assertTrue(screen(c,[])["missing_inputs"])
        self.assertFalse(screen(c,BASE)["implementation_ready"])
    def test_invalid(self):
        with self.assertRaises(ValueError):
            screen({"slots":{}})
    def test_block(self):
        r,q=load()
        c=next(generate(r,q))
        c["status"]="blocked"
        self.assertEqual(screen(c)["screen_status"],"blocked")

if __name__=="__main__":
    unittest.main()
