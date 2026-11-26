import unittest
from architecture_generator_rev1 import SLOTS
from architecture_screen_rev2 import evaluate

class HardenedTests(unittest.TestCase):
    def setUp(self):
        self.slots={k:v[0] for k,v in SLOTS.items()}
    def test_wrong_slot(self):
        self.slots["core"]="P15"
        with self.assertRaises(ValueError): evaluate(self.slots)
    def test_injected_status(self):
        self.slots["status"]="approved"
        with self.assertRaises(ValueError): evaluate(self.slots)
    def test_availability_string(self):
        with self.assertRaises(ValueError): evaluate(self.slots,"terrain")
    def test_no_approval(self):
        result=evaluate(self.slots)
        for k in ("implementation_ready","architecture_complete","ranking_allowed"):
            self.assertFalse(result[k])
