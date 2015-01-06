 #! /usr/bin/python

""" @package dcb
  Various functions to download GNSS differential Code Bias files (DCB)

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
import sys
import bpepy.utils

def getdcb (date_, save_dir=''):
  """ Download DCB file(s) from AIUB (CODE).

    Download DCB file(s) from AIUB (CODE). Files to be downloaded are (in this order):
       1. P1C1 (P1C1MMYY.DCB.Z)
       2. P1P2 (P1P2MMYY.DCB.Z)
       3. P2C2 (P2C2MMYY_RINEX.DCB.Z)
    If any of these files is missing, the function will return an
    integer (>0) denoting the missing file(s) using a binary combination:
    returned_value = (P1C1 is missing?) * 2**0 + 
                     (P1P2 is missing?) * 2**1 +
                     (P2C2 is missing?) * 2**2
    If the given date is more than one day in the future, the function will
    exit with error (date error). If the given date is less than 30 days
    away (in past) the normal file(s) will be downloaded (in the corresponding
    year folder). Else, the running 30-day solution will be used. All downloaded
    files will be saved in the save_dir given, or if this argument is not given
    in the working directory.

    @param  date_    the date for which the DCB file(s) are needed (datetime or date object)
    @param  save_dir directory where downloaded files will reside (string)
    @retval integer  an integer denoting the status (see Exit Codes and Description)

  Exit Codes:
        :  0 all ok
        : -1 connection error
        : -2 date error
        : -3 invalid directory
        : >0 some file is missing
  """

  ## if given argument is date and not datetime, convert it to datetime
  if type (date_) is datetime.date:
    date = datetime.datetime.fromordinal (date_.toordinal ())
  else:
    date = date_

  ## check that the given day is not more than one day in the future
  if (date - datetime.datetime.today ()).days > 1:
    print >> sys.stderr, 'ERROR! Cannot download DCB for future date!'
    return -2

  ## try to resolve date
  exit_status,YEAR,SMON,SDOM,DOY,GW,DW = bpepy.gpstime.resolvedt (date)
  if exit_status != 0:
    print >> sys.stderr, 'ERROR: cannot resolve date "%s"' % str (date)
    return -2

  ## set parameters
  if save_dir == '':
    SAVE_DIR = ''
  else:
    if save_dir.endswith ('/'):
      save_dir = save_dir[:-1]
    if os.path.isdir (save_dir):
      SAVE_DIR = save_dir
    else:
      print >> sys.stderr, 'ERROR: directory not found "%s"' % save_dir
      return -3

  ## 2-digit year
  if int (YEAR) >= 2000:
    SY2D = "%02i" % (YEAR-2000)
  else:
    SY2D = "%02i" % (YEAR-1900)

  ## Decide what file to download.
  # If the day requested is less than 30 days away,
  # the file is 30-DAY running solution
  today = datetime.datetime.today ();
  delta = today - date;
  if delta.days > 30:
    DIRN = '/aiub/CODE/' + YEAR
    FILE_LIST = ['P1C1'+SY2D+SMON+'.DCB.Z', 'P1P2'+SY2D+SMON+'.DCB.Z','P2C2'+SY2D+SMON+'_RINEX.DCB.Z']
  else:
    DIRN = '/aiub/CODE'
    FILE_LIST = ['P1C1_RINEX.DCB', 'P1P2_ALL.DCB', 'P2C2_RINEX.DCB']

  ## retrieve the file(s)
  host = 'ftp.unibe.ch'
  FILE_COUNTER = 0
  STATUS = 0
  for FILE in FILE_LIST:
    if SAVE_DIR == '':
      DFILE = FILE
    else:
      DFILE = SAVE_DIR + '/' + FILE
    status = bpepy.utils.ftpget (host+'/'+DIRN,[FILE],[DFILE])
    if status != 0:
      STATUS = STATUS + math.pow (2, FILE_COUNTER)
    FILE_COUNTER = FILE_COUNTER + 1

  ## return the status
  return STATUS
