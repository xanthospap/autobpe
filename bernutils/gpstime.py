import datetime
import time

""" Global Variables (Constants)
"""
JAN61980    = 44244
JAN11901    = 15385
SEC_PER_DAY = 86400.0e0

month_day = [
  [0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334, 365],
  [0, 31, 60, 91, 121, 152, 182, 213, 244, 274, 305, 335, 366]
]

def mjd2pydt(mjd,fmjd=.0):
  ''' Convert a date given in Modified Julian Date format, to
      a Python ``datetime`` object. The input MJD can be split
      in any convinient way between the parameters ``mjd`` and
      ``fmjd``. Or ``fmjd`` can be ignored and the date passed
      in ``mjd``.

      :param mjd:  The Modified Julian Date; can be either ``float`` 
                   or ``integer``
      :param fmjd: In case the MJD is plit in two parts, this is
                   the second part of the input MJD. E.g. if
                   MJD = 57222.75, then, for increased accuracy,
                   one can use ``mjd = 57222`` and ``fmjd = .75``.

      :returns:    A Python ``datetime`` object, representing the input
                   (MJD) date.

    '''
  jd   = mjd + fmjd
  i, d = divmod(jd, 1)
  mjd  = int(i) ## just to be sure !
  fmjd = float(d)

  days_fr_jan1_1901 = mjd - JAN11901
  num_four_yrs      = int(days_fr_jan1_1901/1461)
  years_so_far      = 1901 + 4*num_four_yrs
  days_left         = days_fr_jan1_1901 - 1461*num_four_yrs
  delta_yrs         = int(days_left/365 - days_left/1460)

  year   = years_so_far + delta_yrs
  yday   = days_left - 365*delta_yrs + 1
  hour   = int(fmjd*24.0)
  minute = int(fmjd*1440.0 - hour*60.0)
  second = int(fmjd*86400.0 - hour*3600.0 - minute*60.0)
  leap   = int(year%4 == 0)
  guess  = int(yday*0.032)
  more   = int(( yday - month_day[leap][guess+1] ) > 0)
  month  = guess + more + 1
  mday   = yday - month_day[leap][guess+more]

  return datetime.datetime(year, month, mday, hour, minute, second)

def pydt2ydoy(datetm):
  ''' Transform a Python ``datetime`` instance to year and 
      day of year.

      :returns: A tuple consisting of ``[year, day_of_year, hour, minute, second]``.

  '''
  try:
    iyear = int(datetm.strftime('%Y'))
    idoy  = int(datetm.strftime('%j'))
  except:
    raise RuntimeError('Invalid date.')

  if type(datetm) is datetime.date:
    ihour = 0
    imin  = 0
    isec  = 0
  elif type(datetm) is datetime.datetime:
    ihour = datetm.hour
    imin  = datetm.minute
    isec  = datetm.second
  else:
    raise RuntimeError('Non-datetime object passed as input -> gpstime.pydt2ydoy')

  return iyear, idoy, ihour, imin, isec

def pydt2gps(datetm):
  ''' Transform a Python ``datetime`` instance to 
      gps week and seconds of week.
  '''
  try:
      year, doy, hour, min, sec = pydt2ydoy(datetm)
  except:
      raise
  return ydoy2gps(year,doy,hour,min,sec)

def ydoy2gps(year, doy, hour=0, minute=0, seconds=.0):
  ''' Transform a tuple of ``year`` and day of year (i.e. ``doy``)
      to gps week and seconds of week.

      :returns: A tuple consisting of ``[gps_week, sec_of_week]``.

  '''
  try:
    [mjd, fmjd] = ydoy2mjd(year,doy,hour,minute,seconds)
  except:
    raise

  gps_week = (mjd - JAN61980) / 7
  sec_of_week = ((mjd - JAN61980) - gps_week*7 + fmjd ) * SEC_PER_DAY

  return gps_week, sec_of_week

def ydoy2mjd(year, doy, hour=0, minute=0, seconds=.0):
  ''' Transform a tuple of ``year`` and day of year (i.e. ``doy``)
      to Modified Julian Date and fraction of day.
      Optional arguments include ``hour``, ``minute`` and ``second``.

      :returns: A tuple consisting of ``[mjd, fmjd]``, where ``mjd`` is the
                (integer) Modified Julian Date and ``fmjd`` is the fraction
                of day (float).

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
  fmjd = ((fsec/60.0 + imin)/60.0 + ihour)/24.0;

  return mjd, fmjd

def ydoy2pydt(year, doy, hour=0, minute=0, seconds=0):
  ''' Transform a date, given as ``year`` and day of year 
      (i.e. ``doy``) to a valid Python datetime instance.
      Optional arguments include ``hour``, ``minute`` and ``second``,
      all integers.

      :returns: A ``datetime`` instance.

  '''
  try:
    iyear = int(year)
    idoy  = int(doy)
    ihour = int(hour)
    imin  = int(minute)
    isec  = int(seconds)
  except:
    raise RuntimeError('Invalid date.')

  date_string = '%4i %03i %02i %02i %02i' %(iyear, idoy, ihour, imin, isec)

  return datetime.strptime(date_string, '%Y %j %H %M %S')
