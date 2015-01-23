#! /usr/bin/python

""" @package geopy
  @brief Various geodetic functions

  Created         : Sep 2014
  Last Update     : Oct 2014

  List of Changes :

  National Technical University of Athens
  Dionysos Satellite Observatory
  Higher Geodesy Laboratory
"""

""" Import Libraries
"""
import math
import time

## SemiMajor Axis for ITRF
a_itrf = 6378137.0;
## Flattening for ITRF
f_itrf = 1.0e00/298.25722210088;

def xyz2flh (x_,y_,z_):
  """ Cartesian to Geodetic coordinate transformation

    Transform from geocentric rectangular to geodetic coordinates. This routine is
    closely based on the GCONV2H subroutine by Fukushima.

    @param  x_   x-coordinate in meters (string or float)
    @param  y_   y-coordinate in meters (string or float)
    @param  z_   z-coordinate in meters (string or float)
    @retval list [latitude (rad),longtitude (rad),height (m)]

    In case of error, the array [-999,-999,-999] is returned
  """

  try:
    x = float (x_)
    y = float (y_)
    z = float (z_)
  except:
    return -999,-999,-999

  ## Set SemiMajor Axis and Flattening for ITRF
  a = a_itrf;
  f = f_itrf;

  ## Functions of ellipsoid parameters
  aeps2 = a*a*1e-32;
  e2    = (2.0e0-f)*f;
  e4t   = e2*e2*1.5e0;
  ep2   = 1.0e0-e2;
  ep    = math.sqrt (ep2);
  aep   = a*ep;

  ## Compute Coefficients of (Modified) Quartic Equation
  # Remark: Coefficients are rescaled by dividing by 'a'
  # Compute distance from polar axis squared
  p2 = (x*x+y*y);

  ## Compute longitude lambda
  if p2: lon = math.atan2 (y,x);
  else: lon=.0;

  ## Ensure that Z-coordinate is unsigned
  absz = math.fabs (z);

  ## Continue unless at the poles
  if p2 > aeps2:
    ## Compute distance from polar axis
    p = math.sqrt (p2);
    ## Normalize
    s0 = absz/a;
    pn = p/a;
    zp = ep*s0;
    ## Prepare Newton correction factors
    c0  = ep*pn;
    c02 = c0*c0;
    c03 = c02*c0;
    s02 = s0*s0;
    s03 = s02*s0;
    a02 = c02+s02;
    a0  = math.sqrt (a02);
    a03 = a02*a0;
    d0  = zp*a03 + e2*s03;
    f0  = pn*a03 - e2*c03;
    ## Prepare Halley correction factor
    b0 = e4t*s02*c02*pn*(a0-ep);
    s1 = d0*f0 - b0*s0;
    cp = ep*(f0*f0-b0*c0);
    ## Evaluate latitude and height
    lat = math.atan (s1/cp);
    s12 = s1*s1;
    cp2 = cp*cp;
    hgt = (p*cp+absz*s1-a*math.sqrt(ep2*s12+cp2))/math.sqrt(s12+cp2);
  else:
    ## Special case: pole
    lat = math.pi / 2e0;
    hgt = absz - aep;
  ## Restore sign of latitude
  if z < 0.:
    lat = -lat;
  ## Finished
  return lat, lon, hgt

def rad2hdeg (a_):
  """ Radians to hexicondal degrees

    Transform radians to hexicondal degrees. In case of error,
    the array [-999,-999,-999] is returned.

    @param  a_   angle in radians (string or float)
    @retval list [degrees,minutes,seconds]
  """

  try:
    a = float (a_)
  except:
    return -999,-999,-999

  ## transform to decimal degrees
  adeg = math.degrees (a)

  ## transform to degrees, minutes, seconds
  mnt,sec = divmod (adeg*3600,60)
  deg,mnt = divmod (mnt,60)

  return deg,mnt,sec

