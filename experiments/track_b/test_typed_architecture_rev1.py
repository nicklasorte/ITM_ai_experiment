import unittest
from typed_architecture_rev1 import generate,validate

class GraphTests(unittest.TestCase):
    def setUp(self):
        self.g=next(generate())
    def check(self,nodes,edges,goal="conditional"):
        return validate(nodes,edges,goal)
    def test_generated(self):
        a=list(generate())
        self.assertEqual(len(a),20)
        self.assertTrue(all(x["status"]=="structural_research_only" and not x["implementation_ready"] for x in a))
    def test_cycle(self):
        with self.assertRaises(ValueError): self.check(self.g["nodes"],self.g["edges"]+[("receiver","source")])
    def test_duplicate(self):
        with self.assertRaises(ValueError): self.check(self.g["nodes"]+["scene"],self.g["edges"])
    def test_unknown(self):
        with self.assertRaises(ValueError): self.check(self.g["nodes"]+["fake"],self.g["edges"])
    def test_missing_edge(self):
        self.assertEqual(self.check(self.g["nodes"],[e for e in self.g["edges"] if e!=("N01","receiver")])["status"],"blocked")
    def test_reference_injection(self):
        self.assertEqual(self.check(self.g["nodes"],self.g["edges"]+[("sommerfeld","N01")])["status"],"blocked")
    def test_duplicate_owner(self):
        self.assertEqual(self.check(self.g["nodes"]+["N02"],self.g["edges"])["status"],"blocked")
    def test_missing_state(self):
        self.assertEqual(self.check(self.g["nodes"],self.g["edges"],"cdf")["status"],"blocked")
