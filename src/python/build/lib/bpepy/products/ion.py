#! /usr/bin/python

""" Import Libraries
"""
import datetime
import os
import sys
import re
import bpepy.gpstime
import bpepy.products.centers
import bpepy.utils

'''
Download Bernese - formated ION files.
Product Area:

* http://www.aiub.unibe.ch/download/CODE
  COD.ION_U         Last update of CODE rapid ionosphere product
                    (1 day) complemented with ionosphere
                    predictions (2 days)
  CODwwwwd.ION_R    CODE rapid ionosphere product, Bernese format

* http://www.aiub.unibe.ch/download/CODE/YYYY
  CODwwwwd.ION.Z  CODE final ionosphere product, Bernese format

'''

def get_ion_final (year,doy,wwww,d,save_dir,translate,force_remove,check_for_z):
  ## variables
  HOST = 'ftp.unibe.ch'
  SYR = str (year)
  DIRN = 'aiub/CODE/' + SYR + '/'
  FILE = 'COD'+wwww+d+'.ION.Z'
  if save_dir == ''  or save_dir == './':
    DFILE = FILE
  else:
    DFILE = save_dir + '/' + FILE
  if os.path.isfile (DFILE):
    if force_remove : 
      os.unlink (DFILE)
    else : 
      return [0,FILE,DFILE,'final']
  if check_for_z == True:
    p = re.compile ('.Z$')
    dfile = p.sub( '', DFILE)
    if os.path.isfile (dfile):
      DOWNLOADED = 'yes'
      return [0,FILE,dfile,'final']
  status = bpepy.utils.ftpget (HOST+'/'+DIRN,[FILE],[DFILE])
  if status == 0:
    return [0,FILE,DFILE,'final']
  else:
    try: os.unlink (DFILE)
    except: pass
    return [1,'','','']

def get_ion_rapid (year,doy,wwww,d,save_dir,translate,force_remove,check_for_z):
  ## variables
  HOST = 'ftp.unibe.ch'
  SYR = str (year)
  DIRN = 'aiub/CODE/'
  FILE = 'COD'+wwww+d+'.ION_R'
  if save_dir == '' or save_dir == './':
    DFILE = FILE
  else:
    DFILE = save_dir + '/' + FILE
  if translate == True:
    p = re.compile ('COD[0-9]*.ION_R$')
    DFILE = p.sub( 'COR'+wwww+d+'.ION', DFILE)
  if os.path.isfile (DFILE):
    if force_remove : 
      os.unlink (DFILE)
    else : 
      return [0,FILE,DFILE,'rapid']
  if check_for_z == True:
    p = re.compile ('.Z$')
    dfile = p.sub( '', DFILE)
    if os.path.isfile (dfile):
      DOWNLOADED = 'yes'
      return [0,FILE,dfile,'rapid']
  status = bpepy.utils.ftpget (HOST+'/'+DIRN,[FILE],[DFILE])
  if status == 0:
    return [0,FILE,DFILE,'rapid']
  else:
    try: os.unlink (DFILE)
    except: pass
    return [1,'','','']

def get_ion_urapid (year,doy,wwww,d,save_dir,translate,force_remove,check_for_z):
  ## variables
  HOST = 'ftp.unibe.ch'
  SYR = str (year)
  DIRN = 'aiub/CODE/'
  FILE = 'COD.ION_U'
  if save_dir == '' or save_dir == './':
    DFILE = FILE
  else:
    DFILE = save_dir + '/' + FILE
  if translate == True:
    p = re.compile ('COD.ION_U$')
    DFILE = p.sub( 'COU'+wwww+d+'.ION', DFILE)
  if os.path.isfile (DFILE):
    if force_remove : 
      os.unlink (DFILE)
    else : 
      return [0,FILE,DFILE,'ultra-rapid']
  if check_for_z == True:
    p = re.compile ('.Z$')
    dfile = p.sub( '', DFILE)
    if os.path.isfile (dfile):
      DOWNLOADED = 'yes'
      return [0,FILE,dfile,'ultra-rapid']
  status = bpepy.utils.ftpget (HOST+'/'+DIRN,[FILE],[DFILE])
  if status == 0:
    return [0,FILE,DFILE,'ultra-rapid']
  else:
    try: os.unlink (DFILE)
    except: pass
    return [1,'','','']

def getion_ (date_,save_dir='',translate=False,force_type='x',force_remove=False,check_for_z=False):

  ## if given argument is date and not datetime, convert it to datetime
  if type (date_) is datetime.date:
    date = datetime.datetime.fromordinal (date_.toordinal ())
  else:
    date = date_

  ## check that the given day is not more than one day in the future
  if (date - datetime.datetime.today ()).days > 1:
    print >> sys.stderr, 'ERROR! Cannot download orbits for future date!'
    return -2

  ## try to resolve date
  exit_status,YEAR,MONTH,DOM,DOY,GW,DW = bpepy.gpstime.resolvedt (date)
  if exit_status != 0:
    print >> sys.stderr, 'ERROR: cannot resolve date "%s"' % str (date)
    return -2

  ## variables
  HOST = 'ftp.unibe.ch'
  DOWNLOADED    = 'no'
  SOLUTION_TYPE = ''
  FTP_FILENAME  = ''
  SV_FILENAME   = ''

  ## see that the product type is set correctly (if it is set)
  if force_type != 'x':
    if force_type != 'f' and force_type != 'r' and force_type != 'u':
      return [1,'','','']

  if force_type=='f':
    return get_ion_final (YEAR,DOY,GW,DW,save_dir,translate,force_remove,check_for_z)
  elif force_type=='r':
     return get_ion_rapid (YEAR,DOY,GW,DW,save_dir,translate,force_remove,check_for_z)
  elif force_type=='u':
     return get_ion_urapid (YEAR,DOY,GW,DW,save_dir,translate,force_remove,check_for_z)
  else:
    status = get_ion_final (YEAR,DOY,GW,DW,save_dir,translate,force_remove,check_for_z)
    if status[0]==0:
      return status
    status = get_ion_rapid (YEAR,DOY,GW,DW,save_dir,translate,force_remove,check_for_z)
    if status[0]==0:
      return status
    status = get_ion_urapid (YEAR,DOY,GW,DW,save_dir,translate,force_remove,check_for_z)
    if status[0]==0:
      return status
    return [1,'','','']

def getion (year,doy,save_dir='',translate=False,force_type='x',force_remove=False,check_for_z=False):
  status,dt = bpepy.gpstime.ydoy2datetime (year,doy)
  return getion_ (dt,save_dir,translate,force_type,force_remove,check_for_z)
