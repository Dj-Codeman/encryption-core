version="Vx.xx"

import config
import sys

def relazy():
    old_stout = sys.stdout
    null = open('/dev/null', 'w')
    sys.stdout = null
    print("HELLOOOOOO OUTTTTTT THEREEEEEEEEEE")
    sys.stdout = old_stout