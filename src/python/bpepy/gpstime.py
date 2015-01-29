#! /usr/bin/python

""" @package gpstime
  @brief Various functions to manipulate Gps-related dates

  Created         : Sep 2014
  Last Update     : Oct 2014

  List of Changes :

  National Technical University of Athens
  Dionysos Satellite Observatory
  Higher Geodesy Laboratory
"""

""" Import Libraries
"""
import datetime
import time

""" Global Variables (Constants)
"""
C_JAN6 = 44244;
C_JAN1 = 15385;
C_SPD  = 86400.0;
C_FMJD = 0.2;

def yd2mjd (year, doy):
  """ Modified Julian Date from Year and Day of Year

    Compute Modified Julian Date from Year and Day of Year
    In case of error, the integer -999 is returned
    Modified Julian Date is returned as integer

    @param  year  The year (string, integer, float)
    @param  doy   The day of year (string, integer, float)
    @retval mjd   Modified Julian Date as integer
  """

  try:
    int (year)
    int (doy)
  except:
    return -999

  ## check doy limits
  if int (doy) < 1 or int (doy) > 366:
    return -999

  ## compute the Modified Julian Date
  mjd = ((int (year)-1901)/4)*1461 + ((int (year)-1901)%4)*365 + int (doy)- 1 + 15385

  return mjd

def yd2gpsweek (year, doy):
  """ Gps Week and Day of Week from Year and Day of Year

    Compute Gps Week and Day of Week from Year and Day of Year
    In case of error, the integer -999 is returned.
    Both Gps Week and DoW are returned as integers.
    
    @param  year  The year (string, integer, float)
    @param  doy   The day of year (string, integer, float)
    @retval list  [gpsweek,day_of_gps_week] as integers
  """

  try:
    int (year)
    int (doy)
  except:
    return -999, -999

  ## check doy limits
  if int (doy) < 1 or int (doy) > 366:
    return -999, -999

  ## compute Modified Julian Date
  mjd = yd2mjd (year, doy)
  if mjd < 0 :
    return -999, -999

  ## compute Gps Week
  gpsweek = (mjd - C_JAN6) / 7.0

  ## compute day of Gps week
  dow = mjd - C_JAN6 - int (gpsweek)*7.0 + C_FMJD

  ## return Gps Week as integers (not floats)
  return int (gpsweek), int (dow)

def yd2month (year, doy):
  """ Month and Day of Month from Year and Day of Year

    Compute Month and Day of Month from Year and Day of Year
    In case of error, the integer -999 is returned.
    Month and DoM are returned as integers.

    @param  year  The year (string, integer, float)
    @param  doy   The day of year (string, integer, float)
    @retval list  [month,day_of_month] as integers
  """

  try:
    int (year)
    int (doy)
  except:
    return -999, -999

  ## check doy limits
  if int (doy) < 1 or int (doy) > 366:
    return -999, -999

  iyear = int (year)
  idoy  = int (doy)
  mday  = [[0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334, 365],
         [0, 31, 60, 91, 121, 152, 182, 213, 244, 274, 305, 335, 366]]
  leap  = (iyear%4 == 0)
  guess = idoy * 0.032
  more  = (idoy - mday[leap][int(guess+1)] ) > 0
  month = guess + more + 1
  dom   = idoy - mday[leap][int(guess+more)]

  ## return month and DoM as integers (not floats)
  return int (month), int (dom)

def decimalyear (date):
  """ Datetime object to fractional year

    Transform a datetime object to fractional year

    @param  date  datetime object; date to resolve
    @retval float fractional year as float
  """

  ## returns seconds since epoch
  def sinceEpoch (date):
    return time.mktime (date.timetuple ())
  s = sinceEpoch

  year = date.year
  startOfThisYear = datetime.datetime (year=year, month=1, day=1)
  startOfNextYear = datetime.datetime (year=year+1, month=1, day=1)

  yearElapsed = s (date) - s (startOfThisYear)
  yearDuration = s (startOfNextYear) - s (startOfThisYear)
  fraction = yearElapsed/yearDuration

  return date.year + fraction

def datetime2ydoy (date_):
  """ Datetime object to YEAR and DOY

    Transform a datetime object to YEAR and DOY.
    Year is returned as a 4-digit string and doy as a
    3-digit string. In case of error, the list [-1,-1]
    is returned.

    @param  date_ datetime or date object; date to resolve
    @retval list  [year,doy] as integers
  """

  ## if given argument is date and not datetime, convert it to datetime
  if type (date_) is datetime.date:
    date = datetime.datetime.fromordinal (date_.toordinal ())
  else:
    date = date_

  ## try to extracy year and doy
  try:
    year = int (date.strftime ('%Y'));
    doy  = int (date.strftime ('%j'));
    return year,doy
  except:
    return -1,-1

def ydoy2datetime (year,doy):
  """ YEAR, DOY date to a datetime object

    Transform a YEAR, DOY date to a datetime object.
    The returned value is a list formated as:
    [Exit_Code, Date]. If the conversion was sucesseful,
    the Exit_Code equals 0.

    @param  year  The year (string or integer)
    @param  doy   The day of year (string or integer)
    @retval list  [status,date] where status=0 for a secesseful
                  conversion and date is the datetime object
  """

  ## try to resolve year and doy
  try:
    date_str = '%s-%s' % (str (year),str (doy))
  except:
    return 1,''

  ## try to set datetime object
  try:
    date = datetime.datetime.strptime (date_str,"%Y-%j")
  except:
    return 1,''

  ## all ok
  return 0,date

def resolvedt (date_):
  """ Decompose datetime object

    Resolve a datetime object and decompose it into parts.
    The function will return a string list formated as:
    [Exit_Code, year, month, dom, doy, gps_week, dow]
    If the Exit_Code is not zero, an error occured.

    @param  date_ datetime or date object; date to resolve
    @retval list  [status,year,month,dom,doy,gpsweek,dayofgpsweek]
                   integer, 6 * string
  """

  ## if given argument is date and not datetime, convert it to datetime
  if type (date_) is datetime.date:
    date = datetime.datetime.fromordinal (date_.toordinal ())
  else:
    date = date_

  ## try to resolve the datetime object
  try:
    year  = "%04i" % (date.year)
    month = "%02i" % (date.month)
    dom   = "%02i" % (date.day)
    doy   = date.strftime ("%j")
    a,b   = yd2gpsweek (year,doy)
    gw    = "%04i" % (a)
    dw    = "%01i" % (b)
    return 0,year,month,dom,doy,gw,dw
  except:
    return 1,0,0,0,0,0,0

def jd2gd (imjd,fmjd):
  """ Resolve a Modified Julian Date

    Resolve a two-part Modified Julian date, and transform it to
    a valid datetime instance. The function will return
    a list [Exit_Code, datetime.instnce]. If exit code
    is other than 0, an error has occured.

    @param mjd  the integer part of the Modified julian date
    @param fmjd the fractional part of the Modified julian date
    @retval     a list as [Exit_Code, datetime.instnce]
  """

  mjd  = int (imjd);
  fmjd = float(fmjd);

  if mjd < 50000 or (fmjd < 0 or fmjd > 1.):
    return 1,datetime.datetime.now()

  days_fr_jan1_1901 = mjd - C_JAN1;
  num_four_yrs = days_fr_jan1_1901/1461;
  years_so_far = 1901 + 4*num_four_yrs;
  days_left = days_fr_jan1_1901 - 1461*num_four_yrs;
  delta_yrs = days_left/365 - days_left/1460;

  year = years_so_far + delta_yrs;
  yday = days_left - 365*delta_yrs + 1;
  hour = int (fmjd*24.0);
  minute = int (fmjd*1440.0 - hour*60.0);
  second = fmjd*86400.0 - hour*3600.0 - minute*60.0;

  date_str = "%4i-%03i-%02i-%02i-%02i" % (year,yday,hour,minute,second)
  dt = datetime.datetime.strptime (date_str,"%Y-%j-%H-%M-%S")
  
  return 0,dt
