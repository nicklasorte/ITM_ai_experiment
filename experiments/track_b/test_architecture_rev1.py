import unittest
from architecture_generator_rev1 import load, assess, generate

class ReviewTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.registry,cls.rules=load()
    def test_count(self):
        a=list(generate(self.registry,self.rules))
        self.assertEqual(len(a),405)
        self.assertEqual(len({tuple(x["slots"].values()) for x in a}),405)
        self.assertEqual(a,list(generate(self.registry,self.rules)))
        self.assertTrue(all(not x["implementation_ready"] for x in a))
    def test_invalid(self):
        for ids in ([],["P01","P01"],["bogus"]):
            with self.assertRaises(ValueError):
                assess(ids,self.registry,self.rules)
    def test_unknown(self):
        x=assess(["P01","P02"],self.registry,self.rules)
        self.assertEqual(x["findings"][0]["status"],"unknown")
        self.assertFalse(x["implementation_ready"])
    def test_alternative(self):
        x=assess(["A11","N01"],self.registry,self.rules)
        self.assertEqual(x["status"],"blocked")
    def test_conflict(self):
        rule=dict(rule_id="TEST",component_set_a="P01",component_set_b="P02",
                  relationship="conditional",condition="test")
        other=dict(rule,rule_id="TEST2",relationship="complementary")
        x=assess(["P01","P02"],self.registry,[rule,other])
        self.assertEqual(x["status"],"blocked")
    def test_order(self):
        self.assertEqual(assess(["P15","N01"],self.registry,self.rules),
                         assess(["N01","P15"],self.registry,self.rules))

if __name__=="__main__":
    unittest.main()
