#!/usr/bin/env python3
import subprocess
import getpass
import sys
import math

#--- set your preferences below: padding between windows, margin(s)
padding = 10; left_margin = 70; top_margin = 30
#---

get = lambda cmd: subprocess.check_output(["/bin/bash", "-c", cmd]).decode("utf-8")
def get_res():
    xr = get("xrandr").split(); pos = xr.index("current")
    return [int(xr[pos+1]), int(xr[pos+3].replace(",", "") )]

# find windows of the application, identified by their pid
pids = [p.split()[0] for p in get("ps -e").splitlines() if sys.argv[1] in p]
w_list = sum([[w.split()[0] for w in get("wmctrl -lp").splitlines() if p in w] for p in pids], [])
# calculate the columns/rows, depending on the number of windows
cols = math.ceil(math.sqrt(len(w_list))); rows = cols
# define (calculate) the area to divide
res = get_res()
area_h = res[0] - left_margin; area_v = res[1] - top_margin
# create a list of calculated coordinates
x_coords = [int(left_margin+area_h/cols*n) for n in range(cols)]
y_coords = [int(top_margin+area_v/rows*n) for n in range(rows)]
coords = sum([[(cx, cy) for cx in x_coords] for cy in y_coords], [])
# calculate the corresponding window size, given the padding, margins, columns and rows
if cols != 0:
    w_size = [str(int(area_h/cols - padding)), str(int(area_v/rows - padding))]
# remove possibly maximization, move the windows
for n, w in enumerate(w_list):
    data = (",").join([str(item) for item in coords[n]])+","+(",").join(w_size)
    cmd1 = "wmctrl -ir "+w+" -b remove,maximized_horz"
    cmd2 = "wmctrl -ir "+w+" -b remove,maximized_vert"
    cmd3 = "wmctrl -ir "+w+" -e 0,"+data
    for cmd in [cmd1, cmd2, cmd3]:
        subprocess.call(["/bin/bash", "-c", cmd])
