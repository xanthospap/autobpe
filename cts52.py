#! /usr/bin/python

"""
Transform a .cts file of version 52 to version 50
Use as : cts52.py <xxxx.c.cts> <xxxx.g.cts>
Result written to stdout
"""

import bpepy.geopy
import bpepy.gpstime
import sys
import datetime

# check command line arguments
if len (sys.argv) != 3:
  print "Invalid Syntax!"
  print "Use as: cts52.py <xxxx.c.cts> <xxxx.g.cts>"
  sys.exit (1)

# check that input files can be opened
try:
  fin = open (sys.argv[1], 'r')
except:
  print "Error! Cannot open file", sys.argv[1]
  sys.exit (1)

try:
  fin = open (sys.argv[2], 'r')
except:
  print "Error! Cannot open file", sys.argv[2]
  sys.exit (1)

# open input files
fc = open (sys.argv[1], 'r')
fg = open (sys.argv[2], 'r')

# Read in lines, one-by-one in each file
cline = fc.readline ()
gline = fg.readline ()

# Process each pair of lines
while True:
  # keep reading until line is not commented out
  if cline[0] == '#':
    while cline[0] == '#':
      cline = fc.readline ()
  # keep reading until line is not commented out
  if gline[0] == '#':
    while gline[0] == '#':
      gline = fg.readline ()
  # split the lines (whitespace)
  cline_s = cline.split ()
  gline_s = gline.split ()
  # try and resolve the dates
  try:
    cdate = datetime.datetime (int (cline_s[0]), int (cline_s[2]), int (cline_s[3]), 12, 0)
    gdate = datetime.datetime (int (gline_s[0]), int (gline_s[2]), int (gline_s[3]), 12, 0)
  except:
    print 'Error! Unable to read in date from line'
    print cline,' or'
    print gline
    fc.close ()
    fg.close ()
    sys.exit (1)
  # check that the dates are the same
  if cdate != gdate:
    print 'Error! Unmatched dates at line:'
    print cline,' or'
    print gline
    fc.close ()
    fg.close ()
    sys.exit (1)
  # get cartesian coordinates
  try:
    x = float (cline_s[4])
    y = float (cline_s[5])
    z = float (cline_s[6])
  except:
    print 'Error! Invalid cartesian coordinates format:'
    print cline
    fc.close ()
    fg.close ()
    sys.exit (1)
  # transform cartesian to geodetic coordinates
  geodetic = bpepy.geopy.xyz2flh (x,y,z);
  # only proceed if transformation was successeful
  if geodetic[0] != -999:
    # transform radians to dms
    glat = bpepy.geopy.rad2hdeg (float (geodetic[0]))
    glon = bpepy.geopy.rad2hdeg (float (geodetic[1]))
    ghgt = float (geodetic[2]);
    glats= "%+03i %02i %15.10f" % (glat[0], glat[1], glat[2])
    glons= "%+03i %02i %15.10f" % (glon[0], glon[1], glon[2])
    ghgts= "%10.5f" % (ghgt)
    fys  = "%12.7f" % (bpepy.gpstime.decimalyear (cdate))
    # check that conversion was sucesseful
    if glat[0] != -999 and glon[0] != -999:
      # get the std. deviation values
      try:
        lat_std = "%09.5f" % (float (gline_s[7]));
        lon_std = "%09.5f" % (float (gline_s[8]));
        hgt_std = "%09.5f" % (float (gline_s[9]));
        # print a valid bern50 line
        # year(0) month(1) day(2) hour(3) doy(4) fractional_year(5)  n(6-8), e(9-11) u(12) sn(13) se(14) su(15)  #
        dstr = cdate.strftime ("%Y %m %d %H %j")
        print dstr, fys, glats, glons, ghgts, lat_std, lon_std, hgt_std
      except:
        print 'Error! Cannot extract std. deviation values'
        print gline
        fc.close ()
        fg.close ()
        sys.exit (1)
    else:
      print 'Unable to transform to DMS; geodetic:',geodetic
      print 'Initial line:',cline
      fc.close ()
      fg.close ()
      sys.exit (1)
  # read next pair of lines or break if EOF (in any of the two files)
  try:
    cline = fc.readline ()
    gline = fg.readline ()
    if not cline: break
    if not gline: break
  except:
    break

fc.close ()
fg.close ()
sys.exit (0)
