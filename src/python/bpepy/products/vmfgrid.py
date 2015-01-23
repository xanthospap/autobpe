 #! /usr/bin/python

""" @package vmfgrid
  Various functions to download Vienna Mapping Functions (VMF1) grid files

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
import bpepy.gpstime
import bpepy.utils
import os

def getvmf1 (year,doy,save_dir='',use_next_day='no',hour=''):
  status,dt = bpepy.gpstime.ydoy2datetime (year,doy)
  ## return getvmf1_ (dt,save_dir,use_next_day,hour)
  status = getvmf1_ (dt,save_dir,use_next_day,hour)
  ## print 'status is',status
  return status

def getvmf1_ (date_,save_dir='',use_next_day='no',hour=''):
  """ Download VMF1 grid file(s)

    Download VMF1 grid file(s) for a given date. Note that the script will
    download a forecast VMF1 grid, if a normal one is not found.

    @param  date_        the date for which the grid file(s) are needed (datetime or date object)
    @param  save_dir     directory where downloaded files will reside (string)
    @param  use_next_day download first file of next day (hour 00) (string, yes or no)
    @param  hour         if specified, the script will only download a grid file for the specified day.
                         String or integer in the range [0,24)
    @retval integer      an integer denoting the status (see Exit Codes)

    Exit Codes:
        :  0 all ok
        : -1 connection error
        : -2 date error
        : -3 invalid directory
        : -4 invalid hour
        : >0 some file is missing
  """

  ## if given argument is date and not datetime, convert it to datetime
  if type (date_) is datetime.date:
    date = datetime.datetime.fromordinal (date_.toordinal ())
  else:
    date = date_

  ## try to resolve date
  exit_status,YEAR,MONTH,DOM,DOY,GW,DW = bpepy.gpstime.resolvedt (date)
  if exit_status != 0:
    print >> sys.stderr, 'ERROR: cannot resolve date "%s"' % str (date)
    return -2

  ## set parameters
  if save_dir == '' or save_dir == './':
    SAVE_DIR = ''
  else:
    if save_dir.endswith ('/'):
      SAVE_DIR = save_dir
    else:
      SAVE_DIR = save_dir + '/'
    if os.path.isdir (save_dir):
      SAVE_DIR = save_dir
    else:
      print >> sys.stderr, 'ERROR: directory not found "%s"' % save_dir
      return -3

  ## check if we want an individual hour file
  DOWNLOADED = 'NO'
  if hour != '':
    try:
      ihour = int (hour)
    except:
      print >> sys.stderr, 'ERROR: Hour must be an integer in the range [0-24) (given:"%s")' %hour
      return -4
    dhour = (ihour // 6) * 6
    HOUR  = "%02i" %dhour
    dfile = YEAR + '/VMFG_' + YEAR + MONTH + DOM + '.H' + HOUR
    sfile = SAVE_DIR + dfile
    status = bpepy.utils.httpget ("http://ggosatm.hg.tuwien.ac.at/DELAY/GRID/VMFG",[dfile],[sfile])
    if status == 0:
      return 0
    else:
      status = bpepy.utils.httpget ("http://ggosatm.hg.tuwien.ac.at/DELAY/GRID/VMFG_FC",[dfile],[sfile])
      if status == 0:
        return 0
      else:
        return 1

  ## downloaded files list
  downloaded  = []
  description = []

  ## downloading all files for day
  DOWNLOADED = 'NO'
  files_to_download = []
  files_missing = []
  urls = []
  hours = [0,6,12,18]
  for h in hours:
    HOUR = "%02i" %h
    urls.append ("http://ggosatm.hg.tuwien.ac.at/DELAY/GRID/VMFG/"+YEAR)
    files_to_download.append ('VMFG_' + YEAR + MONTH + DOM + '.H' + HOUR)
    files_missing.append (0)
  if use_next_day == 'yes':
    next_day = date + datetime.timedelta (days=1)
    NYEAR  = next_day.year
    NMONTH = next_day.month
    NDOM   = next_day.day
    NYEAR  = "%04i" %NYEAR
    NMONTH = "%02i" %NMONTH
    NDOM   = "%02i" %NDOM
    urls.append ("http://ggosatm.hg.tuwien.ac.at/DELAY/GRID/VMFG/"+NYEAR)
    files_to_download.append ('VMFG_' + NYEAR + NMONTH + NDOM + '.H00')
    files_missing.append (0)
  iterator = 0
  for f,m,u in zip (files_to_download,files_missing,urls):
    sfile = SAVE_DIR + f
    status = bpepy.utils.httpget (u,[f],[sfile])
    if status != 0:
      files_missing[iterator] = 1
    else:
      downloaded.append (sfile)
      description.append ('final')
    iterator = iterator + 1
  urls = [u.replace('VMFG', 'VMFG_FC') for u in urls]
  iterator = 0
  for f,m,u in zip (files_to_download,files_missing,urls):
    if m == 1:
      sfile = SAVE_DIR + f
      status = bpepy.utils.httpget (u,[f],[sfile])
      if status == 0:
        files_missing[iterator] = 0
        downloaded.append (sfile)
        description.append ('prediction')
    iterator = iterator + 1
  if sum (files_missing) != 0:
    print >> sys.stderr, 'ERROR: Could not download all VMF grid files'
    for f,m in zip (files_to_download,files_missing):
      sfile = SAVE_DIR + f
      try:
        os.unlink (sfile)
      except:
        pass
    return 1
  else:
    for f,d in zip (downloaded,description):
      print f,d,
    return 0
