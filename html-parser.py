#!/usr/bin/python

import re
import os
import sys

#myfile="tmp.html"
myfile = sys.argv[1]
f = open(myfile, "r")
txt=f.read()

pattern='<a target="_new"[^\>]+>\s+([0-9]+)</a>.*<a target="workspace"[^>]+>\s+([0-9]+)</a>\s+([0-9a-z-A-Z.]+)\s*-\s+([a-zA-Z/]+)'
m=re.search(pattern, txt, re.DOTALL)
if m :
    if not m.groups() :
        print("error on line")
    else:
        print m.groups()
else:
    print("No results found")
