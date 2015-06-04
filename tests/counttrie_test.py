#! /usr/bin/env python
"""
Unit-test for run-tests
"""

import unittest
import counttrie.counttrie as ct

class TestCountTrie(unittest.TestCase):


    def test_counttrie(self):

        print "Creating tree"
        t = ct.CountTrie()
        t.add("AGAAT")
        t.add("AGAGG")
        t.add("AGAAG")
        t.add("CATAC")
        t.add("CGCAG")
        t.add("CGCAG")
        t.add("CGCAG")
        t.add("CGC")
        t.add("GCATG")
        t.add("TACAC")
        t.add("")
        t.add("")
        t.add("")
        t.remove("", False)
        t.add("A")
        t.add("CA")
        t.remove("CA")
        t.remove("CA")
        t.add("TACAT")
        t.add("TACATTTT")
        t.add("TACATTTTAA")
        t.remove("TACATTTTAA")
        #
        print "Printing sequences"
        l, c = t.get_sequences()
        for i in range(len(l)):
            print l[i] + "\t" + str(c[i])
        #
        print "Printing counts"
        print t.get_count("")
        print t.get_count("CGCAG")
        print t.get_count("A")
        print t.get_count("C")
        print t.size()
        print t.size(True)
        #
        print "Finding with 2 mismatches with indels for AGCAG"
        s = t.find("AGCAG", 2, True)
        for i in s:
            print i
        #
        print "Removing count range"
        t.remove_count_range(1,1)
        l, c = t.get_sequences()
        for i in range(len(l)):
            print l[i] + "\t" + str(c[i])



if __name__ == '__main__':
    unittest.main()
