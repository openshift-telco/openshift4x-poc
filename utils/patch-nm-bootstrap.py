#!/bin/env python3

import json 
fname = ["ocp4poc/bootstrap.ign-bkup", "utils/nm-patch.json", "ocp4poc/bootstrap.ign-with-patch"]
d1 = json.load(open(fname[0],"r"))
d2 = json.load(open(fname[1],"r"))

d1["systemd"]["units"] += d2["systemd"]["units"]

json.dump(d1,open(fname[2],"w"))
