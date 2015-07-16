#! /usr/bin/python

import datetime
import time

""" Global Variables (Constants)
"""
JAN61980    = 44244
JAN11901    = 15385
SEC_PER_DAY = 86400.0e0

def ydoy2mjd(year, doy, hour=0, minute=0, seconds=.0):
  ''' Modified Julian Date from Year and Day of Year
  '''
    try:
        iyear = int(year)
        idoy  = int(doy)
        ihour = int(hour)
        imin  = int(minute)
        fsec  = float(seconds)
    except:
        raise RuntimeError('Invalid date.')

    if idoy < 1 or idoy > 366:
        raise RuntimeError('Invalid date.')

    if ihour < 0 or ihour > 23 or imin < 0 or imin > 59 or fsec < 0 or fsec > 60:
        raise RuntimeError('Invalid date.')

    ## compute the Modified Julian Date
    mjd  = ((iyear - 1901)/4)*1461 + ((iyear - 1901)%4)*365 + idoy - 1 + JAN11901;
    fmjd = ((fsec/60.0 + iminute)/60.0 + ihour)/24.0;

    return mjd, fmjd
