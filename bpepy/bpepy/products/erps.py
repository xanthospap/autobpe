#! /usr/bin/python

""" @package erps
  Various functions to download Earth Rotation Parameters files.

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
import os
import sys
import re
import bpepy.gpstime
import bpepy.products.centers
import bpepy.utils

def geterp (year,doy,ac='cod',save_dir='',translate=False,force_type='x',force_remove=False,check_for_z=False):
  """ @brief Wrapper for geterp_ using year and doy
  print 'In script getorb with:'
  print 'year=',year
  print 'doy=',doy
  print 'ac=',ac
  print 'save_dir=',save_dir
  print 'translate=',translate
  print 'no_glo=',no_glo
  print 'force_type=',force_type
  print 'force_remove=',force_remove
  """
  status,dt = bpepy.gpstime.ydoy2datetime (year,doy)
  return geterp_ (dt,ac,save_dir,translate,force_type,force_remove,check_for_z)

def geterp_ (date_,ac='cod',save_dir='',translate=False,force_type='x',force_remove=False,check_for_z=False):
  """ Download Earth Rotation Parameters file

    This function will download an Earth Rotation Parameters file (.erp)
    for a given date. The file to download can be in order of preference:
      1. Final
      2. Rapid
      3. Ultra-Rapid
    Whichever is found first is downloaded.

    @param  date_    a datetime object for which the orbit file(s) is requested
    @param  ac       a 3-digit (string) identifier for the AC
    @param  save_dir the directory where the downloaded files will reside
    @retval list     [Exit_Code,ftp_filename,saved_filename,solution_type]

    Exit Codes:
        :  0 all ok
        : -1 connection error
        : -2 date error
        : -3 invalid directory
        : -4 invalid analysis center
        : >0 some file is missing
  """

  ## check if the analysis center is valid
  ac_info = bpepy.products.centers.acinfo (ac)
  if ac_info[0] != 0:
    print >> sys.stderr, 'ERROR! Unresolved AC (',ac,')'
    return -4

  ## if given argument is date and not datetime, convert it to datetime
  if type (date_) is datetime.date:
    date = datetime.datetime.fromordinal (date_.toordinal ())
  else:
    date = date_

  ## check that the given day is not more than one day in the future
  if (date - datetime.datetime.today ()).days > 1:
    print >> sys.stderr, 'ERROR! Cannot download erp for future date!'
    return -2

  ## try to resolve date
  exit_status,YEAR,MONTH,DOM,DOY,GW,DW = bpepy.gpstime.resolvedt (date)
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

  if translate == True: Trans='yes'
  else: Trans='no'

  ## call function to download erp file
  if ac == 'cod':
    status = geterp_cod (date,SAVE_DIR,Trans,force_type,force_remove,check_for_z)
  elif ac == 'igs':
    status = geterp_igs (date,SAVE_DIR,Trans,force_type,force_remove,check_for_z)
  else:
    status = [1,'','','']

  return status
  #sys.exit (int (status[0]))

def geterp_igs (date,save_dir='',translate='no',force_type='x',force_remove=False,check_for_z=False):
  """ Download an erp file from igs AC

    Download erp file from IGS. The script will 
    search for (a) a final solution, (b) a rapid solution, or (c) an 
    ultra-rapid solution and it will download the first available option.

    @param  date         a datetime object for which the orbit file(s) is requested
    @param  save_dir     the directory where the downloaded files will reside (string)
    @param  translate    translate file to match the global naming convention, i.e.
                         igsWWWWD.erp.Z (string, yes or no)
    @param  force_type   only try to download a specific product type:
                           'f' for final,
                           'r' for rapid
                           'u' for ultra-rapid
    @retval list         [Exit_Code,ftp_filename,saved_filename,solution_type]

    Exit Codes :
        :  0 all ok
        : -1 connection error
        :  1 nothing downloaded
  """

  ## variables
  DOWNLOADED    = 'no'
  SOLUTION_TYPE = ''
  FTP_FILENAME  = ''
  SV_FILENAME   = ''
  HOSTS         = bpepy.products.centers.IGS_HOSTS;

  ## resolve date
  exit_status,SYR,MONTH,DOM,DOY,SGW,SDOW = bpepy.gpstime.resolvedt (date)

  ## see that the product type is set correctly (if it is set)
  if force_type != 'x':
    if force_type != 'f' and force_type != 'r' and force_type != 'u':
      return [1,'','','']

  ## ------------------------------------------------------------------------ ##
  ## if the user only wants a specific product type                           ##
  ## ------------------------------------------------------------------------ ##
  if force_type == 'f':
    ## Final Solution
    dc = 0
    for host in HOSTS:
      DIRN  = bpepy.products.centers.PRODUCT_AREA[dc] + SGW
      FILE  = 'igs' + SGW + '7' + '.erp.Z'
      if save_dir == '':
        DFILE = FILE
      else:
        DFILE = save_dir + '/' + FILE
      if translate == 'yes' :
        DFILE = DFILE.replace (SGW + '7',SGW + SDOW)
      if os.path.isfile (DFILE):
        if force_remove:
          os.unlink (DFILE)
        else : 
          DOWNLOADED = 'yes'
          SOLUTION_TYPE = 'final'
          FTP_FILENAME  = FILE
          SV_FILENAME   = DFILE
          return [0,FTP_FILENAME,SV_FILENAME,SOLUTION_TYPE]
      if check_for_z == True:
        p = re.compile ('.Z$')
        dfile = p.sub( '', DFILE)
        if os.path.isfile (dfile):
          DOWNLOADED = 'yes'
          SOLUTION_TYPE = 'final'
          FTP_FILENAME  = FILE
          SV_FILENAME   = DFILE
          return [0,FTP_FILENAME,SV_FILENAME,SOLUTION_TYPE]
      status = bpepy.utils.ftpget (host+'/'+DIRN,[FILE],[DFILE])
      if status == 0:
        DOWNLOADED = 'yes'
        SOLUTION_TYPE = 'final'
        FTP_FILENAME  = FILE
        SV_FILENAME   = DFILE
        return [0,FTP_FILENAME,SV_FILENAME,SOLUTION_TYPE]
      else:
        DOWNLOADED = 'no'
        try: os.unlink (DFILE)
        except: pass
      dc = dc + 1
  elif force_type == 'r':
    dc = 0
    for host in HOSTS:
      DIRN  = bpepy.products.centers.PRODUCT_AREA[dc] + SGW
      FILE  = 'igr' + SGW + SDOW + '.erp.Z'
      if save_dir == '':
        DFILE = FILE
      else:
        DFILE = save_dir + '/' + FILE
      #if translate == 'yes' :
      #  DFILE = DFILE.replace ('igr','igs')
      if os.path.isfile (DFILE):
        if force_remove:
          os.unlink (DFILE)
        else : 
          DOWNLOADED = 'yes'
          SOLUTION_TYPE = 'rapid'
          FTP_FILENAME  = FILE
          SV_FILENAME   = DFILE
          return [0,FTP_FILENAME,SV_FILENAME,SOLUTION_TYPE]
      if check_for_z == True:
        p = re.compile ('.Z$')
        dfile = p.sub( '', DFILE)
        if os.path.isfile (dfile):
          DOWNLOADED = 'yes'
          SOLUTION_TYPE = 'rapid'
          FTP_FILENAME  = FILE
          SV_FILENAME   = DFILE
          return [0,FTP_FILENAME,SV_FILENAME,SOLUTION_TYPE]
      status = bpepy.utils.ftpget (host+'/'+DIRN,[FILE],[DFILE])
      if status == 0:
        DOWNLOADED = 'yes'
        SOLUTION_TYPE = 'rapid'
        FTP_FILENAME  = FILE
        SV_FILENAME   = DFILE
        break
      else:
        DOWNLOADED = 'no'
        try: os.unlink (DFILE)
        except: pass
      dc = dc + 1
  elif force_type == 'u':
    dc = 0
    for host in HOSTS:
      for hour in ['18','12','06','00']:
        FILE  = 'igu' + SGW + SDOW + '_' + hour + '.erp.Z'
        if save_dir == '':
          DFILE = FILE
        else:
          DFILE = save_dir + '/' + FILE
        if translate == 'yes' :
          #DFILE = DFILE.replace ('igu','igs')
          DFILE = DFILE.replace ('_'+hour,'')
        DIRN  = bpepy.products.centers.PRODUCT_AREA[dc] + SGW
        if os.path.isfile (DFILE):
          if force_remove:
            os.unlink (DFILE)
          else : 
            DOWNLOADED = 'yes'
            SOLUTION_TYPE = 'ultra-rapid'
            FTP_FILENAME  = FILE
            SV_FILENAME   = DFILE
            return [0,FTP_FILENAME,SV_FILENAME,SOLUTION_TYPE]
        if check_for_z == True:
          p = re.compile ('.Z$')
          dfile = p.sub( '', DFILE)
          if os.path.isfile (dfile):
            DOWNLOADED = 'yes'
            SOLUTION_TYPE = 'ultra-rapid'
            FTP_FILENAME  = FILE
            SV_FILENAME   = DFILE
            return [0,FTP_FILENAME,SV_FILENAME,SOLUTION_TYPE]
        status = bpepy.utils.ftpget (host+'/'+DIRN,[FILE],[DFILE])
        if status == 0:
          DOWNLOADED = 'yes'
          SOLUTION_TYPE = 'ultra-rapid'
          FTP_FILENAME = FILE
          SV_FILENAME  = DFILE
          break
        else:
          DOWNLOADED = 'no'
          try: os.unlink (DFILE)
          except: pass
      dc = dc + 1

  ## Final Solution
  dc = 0
  for host in HOSTS:
    DIRN  = bpepy.products.centers.PRODUCT_AREA[dc] + SGW
    FILE  = 'igs' + SGW + '7' + '.erp.Z'
    if save_dir == '':
      DFILE = FILE
    else:
      DFILE = save_dir + '/' + FILE
    if translate == 'yes' :
      DFILE = DFILE.replace (SGW + '7',SGW + SDOW)
    if os.path.isfile (DFILE):
      if force_remove:
        os.unlink (DFILE)
      else : 
        DOWNLOADED = 'yes'
        SOLUTION_TYPE = 'final'
        FTP_FILENAME  = FILE
        SV_FILENAME   = DFILE
        return [0,FTP_FILENAME,SV_FILENAME,SOLUTION_TYPE]
    if check_for_z == True:
      p = re.compile ('.Z$')
      dfile = p.sub( '', DFILE)
      if os.path.isfile (dfile):
        DOWNLOADED = 'yes'
        SOLUTION_TYPE = 'final'
        FTP_FILENAME  = FILE
        SV_FILENAME   = DFILE
        return [0,FTP_FILENAME,SV_FILENAME,SOLUTION_TYPE]
    status = bpepy.utils.ftpget (host+'/'+DIRN,[FILE],[DFILE])
    if status == 0:
      DOWNLOADED = 'yes'
      SOLUTION_TYPE = 'final'
      FTP_FILENAME  = FILE
      SV_FILENAME   = DFILE
      break
    else:
      DOWNLOADED = 'no'
      try: os.unlink (DFILE)
      except: pass
    dc = dc + 1

  ## Rapid Solution
  if DOWNLOADED == 'no':
    dc = 0
    for host in HOSTS:
      DIRN  = bpepy.products.centers.PRODUCT_AREA[dc] + SGW
      FILE  = 'igr' + SGW + SDOW + '.erp.Z'
      if save_dir == '':
        DFILE = FILE
      else:
        DFILE = save_dir + '/' + FILE
      #if translate == 'yes' :
      #  DFILE = DFILE.replace ('igr','igs')
      if os.path.isfile (DFILE):
        if force_remove:
          os.unlink (DFILE)
        else : 
          DOWNLOADED = 'yes'
          SOLUTION_TYPE = 'rapid'
          FTP_FILENAME  = FILE
          SV_FILENAME   = DFILE
          return [0,FTP_FILENAME,SV_FILENAME,SOLUTION_TYPE]
      if check_for_z == True:
        p = re.compile ('.Z$')
        dfile = p.sub( '', DFILE)
        if os.path.isfile (dfile):
          DOWNLOADED = 'yes'
          SOLUTION_TYPE = 'rapid'
          FTP_FILENAME  = FILE
          SV_FILENAME   = DFILE
          return [0,FTP_FILENAME,SV_FILENAME,SOLUTION_TYPE]
      status = bpepy.utils.ftpget (host+'/'+DIRN,[FILE],[DFILE])
      if status == 0:
        DOWNLOADED = 'yes'
        SOLUTION_TYPE = 'rapid'
        FTP_FILENAME  = FILE
        SV_FILENAME   = DFILE
        break
      else:
        DOWNLOADED = 'no'
        try: os.unlink (DFILE)
        except: pass
      dc = dc + 1

  ## Ultra Rapid Solution
  if DOWNLOADED == 'no':
    dc = 0
    for host in HOSTS:
      for hour in ['18','12','06','00']:
        FILE  = 'igu' + SGW + SDOW + '_' + hour + '.erp.Z'
        if save_dir == '':
          DFILE = FILE
        else:
          DFILE = save_dir + '/' + FILE
        if translate == 'yes' :
          #DFILE = DFILE.replace ('igu','igs')
          DFILE = DFILE.replace ('_'+hour,'')
        DIRN  = bpepy.products.centers.PRODUCT_AREA[dc] + SGW
        if os.path.isfile (DFILE):
          if force_remove:
            os.unlink (DFILE)
          else : 
            DOWNLOADED = 'yes'
            SOLUTION_TYPE = 'ultra-rapid'
            FTP_FILENAME  = FILE
            SV_FILENAME   = DFILE
            return [0,FTP_FILENAME,SV_FILENAME,SOLUTION_TYPE]
        if check_for_z == True:
          p = re.compile ('.Z$')
          dfile = p.sub( '', DFILE)
          if os.path.isfile (dfile):
            DOWNLOADED = 'yes'
            SOLUTION_TYPE = 'ultra-rapid'
            FTP_FILENAME  = FILE
            SV_FILENAME   = DFILE
            return [0,FTP_FILENAME,SV_FILENAME,SOLUTION_TYPE]
        status = bpepy.utils.ftpget (host+'/'+DIRN,[FILE],[DFILE])
        if status == 0:
          DOWNLOADED = 'yes'
          SOLUTION_TYPE = 'ultra-rapid'
          FTP_FILENAME = FILE
          SV_FILENAME  = DFILE
          break
        else:
          DOWNLOADED = 'no'
          try: os.unlink (DFILE)
          except: pass
      dc = dc + 1

  ## No more solutions available; check the status
  if DOWNLOADED == 'no':
    # print >> sys.stderr, 'ERROR: no orbit file found'
    return [1,'','','']
  else:
    return [0,FTP_FILENAME,SV_FILENAME,SOLUTION_TYPE]

def geterp_cod (date,save_dir='',translate='no',force_type='x',force_remove=False,check_for_z=False,use_repro_2013='no'):
  """ Download erp file from CODE AC.

    Download erp file from CODE AC. The script will search for (a) a
    final solution, (b) a rapid solution, or (c) an ultra-rapid solution
    and it will download the first available option.

    @param  date           a datetime object for which the erp file is requested
    @param  save_dir       the directory where the downloaded file will reside (string)
    @param  translate      translate file to match the global naming convention, i.e.
                           codWWWWD.erp.Z (string, yes or no)
    @param  use_repro_2013 use results from CODE's 2013 reprocessing campaign
    @retval list           [Exit_Code,ftp_filename,saved_filename,solution_type]

    Exit Codes :
        :  0 all ok
        : -1 connection error
        :  1 nothing downloaded
  """

  ## variables
  HOST = 'ftp.unibe.ch'
  DOWNLOADED    = 'no'
  SOLUTION_TYPE = ''
  FTP_FILENAME  = ''
  SV_FILENAME   = ''

  ## resolve date
  exit_status,SYR,MONTH,DOM,DOY,SGW,SDOW = bpepy.gpstime.resolvedt (date)

  ## see that the product type is set correctly (if it is set)
  if force_type != 'x':
    if force_type != 'f' and force_type != 'r' and force_type != 'u':
      return [1,'','','']

  ## ------------------------------------------------------------------------ ##
  ## if the user only wants a specific product type                           ##
  ## ------------------------------------------------------------------------ ##
  if force_type == 'f':  ## only final
    identifier = 'COD'
    if use_repro_2013 == 'yes':
      DIRN = 'aiub/REPRO_2013/CODE/' + SYR + '/'
      identifier = 'CO2'
    else:
      DIRN = 'aiub/CODE/' + SYR + '/'
    FILE  = identifier + SGW + '7' + '.ERP.Z'
    if save_dir == '':
      DFILE = FILE
    else:
      DFILE = save_dir + '/' + FILE
    if translate == 'yes':
      DFILE = DFILE.replace (SGW+'7',SGW+SDOW)
    #  DFILE = (DFILE.replace (SGW+'7',SGW+SDOW)).lower ()
    #  DFILE = DFILE.replace('.z','.Z')
    if os.path.isfile (DFILE):
      if force_remove:
        os.unlink (DFILE)
      else : 
        DOWNLOADED = 'yes'
        SOLUTION_TYPE = 'final'
        if identifier == 'CO2':
          SOLUTION_TYPE = SOLUTION_TYPE + ' (repro 2013)'
        FTP_FILENAME  = FILE
        SV_FILENAME   = DFILE
        return [0,FTP_FILENAME,SV_FILENAME,SOLUTION_TYPE]
    if check_for_z == True:
      p = re.compile ('.Z$')
      dfile = p.sub( '', DFILE)
      if os.path.isfile (dfile):
        DOWNLOADED = 'yes'
        SOLUTION_TYPE = 'final'
        if identifier == 'CO2':
          SOLUTION_TYPE = SOLUTION_TYPE + ' (repro 2013)'
        FTP_FILENAME  = FILE
        SV_FILENAME   = DFILE
        return [0,FTP_FILENAME,SV_FILENAME,SOLUTION_TYPE]
    status = bpepy.utils.ftpget (HOST+'/'+DIRN,[FILE],[DFILE])
    if status == 0:
      DOWNLOADED = 'yes'
      SOLUTION_TYPE = 'final'
      if identifier == 'CO2':
        SOLUTION_TYPE = SOLUTION_TYPE + ' (repro 2013)'
      FTP_FILENAME  = FILE
      SV_FILENAME   = DFILE
      return [0,FTP_FILENAME,SV_FILENAME,SOLUTION_TYPE]
    else:
      DOWNLOADED = 'no'
      try: os.unlink (DFILE)
      except: pass
      return [1,'','','']
  elif force_type == 'r':  ## only rapid
    if use_repro_2013 == 'yes':
      # print >> sys.stderr, 'ERROR: No rapid files available for REPRO2013'
      DOWNLOADED = 'no'
      identifier = 'COD'
    else:
      FILE  = 'COD' + SGW + SDOW + '.ERP_R'
      DIRN = 'aiub/CODE/' #+ SYR + '/'
      if translate == 'yes':
        DFILE = 'COR' + SGW + SDOW + '.ERP'
      #  DFILE = DFILE.replace ('.ERP_R','.ERP')
      #  DFILE = DFILE.replace ('COD','COR')
      #  DFILE = (DFILE.replace ('.ERP_R','.ERP')).lower ()
      else:
        DFILE = FILE
      if save_dir == '':
        DFILE = FILE
      else:
        DFILE = save_dir + '/' + FILE
      if os.path.isfile (DFILE):
        if force_remove:
          os.unlink (DFILE)
        else : 
          DOWNLOADED = 'yes'
          SOLUTION_TYPE = 'rapid'
          FTP_FILENAME  = FILE
          SV_FILENAME   = DFILE
          return [0,FTP_FILENAME,SV_FILENAME,SOLUTION_TYPE]
      if check_for_z == True:
        p = re.compile ('.Z$')
        dfile = p.sub( '', DFILE)
        if os.path.isfile (dfile):
          DOWNLOADED = 'yes'
          SOLUTION_TYPE = 'rapid'
          FTP_FILENAME  = FILE
          SV_FILENAME   = DFILE
          return [0,FTP_FILENAME,SV_FILENAME,SOLUTION_TYPE]
      status = bpepy.utils.ftpget (HOST+'/'+DIRN,[FILE],[DFILE])
      if status == 0:
        DOWNLOADED = 'yes'
        SOLUTION_TYPE = 'rapid'
        FTP_FILENAME  = FILE
        SV_FILENAME   = DFILE
        return [0,FTP_FILENAME,SV_FILENAME,SOLUTION_TYPE]
      else:
        DOWNLOADED = 'no'
        try: os.unlink (DFILE)
        except: pass
        return [1,'','','']
  elif force_type == 'u':  ## only ultra-rapid
    if use_repro_2013 == 'yes':
      # print >> sys.stderr, 'ERROR: No ultra-rapid files available for REPRO2013'
      DOWNLOADED = 'no'
    else:
      delta_days = (date - datetime.datetime.today ()).days
      DIRN = 'aiub/CODE/'
      if delta_days < 1:
        FILE = 'COD' + '.ERP_U'
      elif delta_days < 2:
        FILE = 'COD' + SGW + SDOW + '.ERP_P1'
      elif delta_days < 3:
        FILE = 'COD' + SGW + SDOW + '.ERP_P2'
      elif delta_days < 5:
        FILE = 'COD' + SGW + SDOW + '.ERP_5D'
      else:
        DOWNLOADED = 'no'
        return [1,'','','']
      if translate == 'yes':
        DFILE = 'COU' + SGW + SDOW + '.ERP'
      else:
        DFILE = FILE
      if save_dir == '':
        DFILE = DFILE
      else:
        DFILE = save_dir + '/' + DFILE
      if os.path.isfile (DFILE):
        if force_remove:
          os.unlink (DFILE)
        else : 
          DOWNLOADED = 'yes'
          SOLUTION_TYPE = 'ultra-rapid'
          FTP_FILENAME  = FILE
          SV_FILENAME   = DFILE
          return [0,FTP_FILENAME,SV_FILENAME,SOLUTION_TYPE]
      if check_for_z == True:
        p = re.compile ('.Z$')
        dfile = p.sub( '', DFILE)
        if os.path.isfile (dfile):
          DOWNLOADED = 'yes'
          SOLUTION_TYPE = 'ultra-rapid'
          FTP_FILENAME  = FILE
          SV_FILENAME   = DFILE
          return [0,FTP_FILENAME,SV_FILENAME,SOLUTION_TYPE]
      status = bpepy.utils.ftpget (HOST+'/'+DIRN,[FILE],[DFILE])
      if status == 0:
        DOWNLOADED = 'yes'
        SOLUTION_TYPE = 'ultra-rapid'
        FTP_FILENAME  = FILE
        SV_FILENAME   = DFILE
        return [0,FTP_FILENAME,SV_FILENAME,SOLUTION_TYPE]
      else:
        DOWNLOADED = 'no'
        try: os.unlink (DFILE)
        except: pass
        return [1,'','','']

  ## Final Solution
  identifier = 'COD'
  if use_repro_2013 == 'yes':
    DIRN = 'aiub/REPRO_2013/CODE/' + SYR + '/'
    identifier = 'CO2'
  else:
    DIRN = 'aiub/CODE/' + SYR + '/'
  FILE  = identifier + SGW + '7' + '.ERP.Z'
  if save_dir == '':
    DFILE = FILE
  else:
    DFILE = save_dir + '/' + FILE
  if translate == 'yes':
    DFILE = DFILE.replace (SGW+'7',SGW+SDOW)
  else:
    DFILE = FILE
  if os.path.isfile (DFILE):
    if force_remove:
      os.unlink (DFILE)
    else : 
      DOWNLOADED = 'yes'
      SOLUTION_TYPE = 'final'
      if identifier == 'CO2':
        SOLUTION_TYPE = SOLUTION_TYPE + ' (repro 2013)'
      FTP_FILENAME  = FILE
      SV_FILENAME   = DFILE
      return [0,FTP_FILENAME,SV_FILENAME,SOLUTION_TYPE]
  if check_for_z == True:
    p = re.compile ('.Z$')
    dfile = p.sub( '', DFILE)
    if os.path.isfile (dfile):
      DOWNLOADED = 'yes'
      SOLUTION_TYPE = 'final'
      if identifier == 'CO2':
        SOLUTION_TYPE = SOLUTION_TYPE + ' (repro 2013)'
      FTP_FILENAME  = FILE
      SV_FILENAME   = DFILE
      return [0,FTP_FILENAME,SV_FILENAME,SOLUTION_TYPE]
  status = bpepy.utils.ftpget (HOST+'/'+DIRN,[FILE],[DFILE])
  if status == 0:
    DOWNLOADED = 'yes'
    SOLUTION_TYPE = 'final'
    if identifier == 'CO2':
      SOLUTION_TYPE = SOLUTION_TYPE + ' (repro 2013)'
    FTP_FILENAME  = FILE
    SV_FILENAME   = DFILE
  else:
    DOWNLOADED = 'no'
    try: os.unlink (DFILE)
    except: pass

  ## Rapid Solution
  if DOWNLOADED == 'no':
    if use_repro_2013 == 'yes':
      # print >> sys.stderr, 'ERROR: No rapid files available for REPRO2013'
      DOWNLOADED = 'no'
    else:
      FILE  = 'COD' + SGW + SDOW + '.ERP_R'
      DIRN = 'aiub/CODE/'
      if translate == 'yes':
        #DFILE = DFILE.replace ('.ERP_R','.ERP')
        #DFILE = DFILE.replace ('COD','COR')
        DFILE = 'COR' + GPSW + SDOW + '.ERP'
      else:
        DFILE=FILE
      if save_dir == '':
        DFILE = FILE
      else:
        DFILE = save_dir + '/' + FILE
      if os.path.isfile (DFILE):
        if force_remove:
          os.unlink (DFILE)
        else : 
          DOWNLOADED = 'yes'
          SOLUTION_TYPE = 'rapid'
          FTP_FILENAME  = FILE
          SV_FILENAME   = DFILE
          return [0,FTP_FILENAME,SV_FILENAME,SOLUTION_TYPE]
      if check_for_z == True:
        p = re.compile ('.Z$')
        dfile = p.sub( '', DFILE)
        if os.path.isfile (dfile):
          DOWNLOADED = 'yes'
          SOLUTION_TYPE = 'rapid'
          FTP_FILENAME  = FILE
          SV_FILENAME   = DFILE
          return [0,FTP_FILENAME,SV_FILENAME,SOLUTION_TYPE]
      status = bpepy.utils.ftpget (HOST+'/'+DIRN,[FILE],[DFILE])
      if status == 0:
        DOWNLOADED = 'yes'
        SOLUTION_TYPE = 'rapid'
        FTP_FILENAME  = FILE
        SV_FILENAME   = DFILE
      else:
        DOWNLOADED = 'no'
        try: os.unlink (DFILE)
        except: pass

  ## Ultra Rapid Solution
  if DOWNLOADED == 'no':
    if use_repro_2013 == 'yes':
      # print >> sys.stderr, 'ERROR: No ultra-rapid files available for REPRO2013'
      DOWNLOADED = 'no'
    else:
      delta_days = (date - datetime.datetime.today ()).days
      DIRN = 'aiub/CODE/'
      if delta_days < 1:
        FILE = 'COD' + '.ERP_U'
      elif delta_days < 2:
        FILE = 'COD' + SGW + SDOW + '.ERP_P1'
      elif delta_days < 3:
        FILE = 'COD' + SGW + SDOW + '.ERP_P2'
      elif delta_days < 5:
        FILE = 'COD' + SGW + SDOW + '.ERP_5D'
      else:
        DOWNLOADED = 'no'
        return [1,'','','']
      if translate == 'yes':
        DFILE = 'COU' + SGW + SDOW + '.ERP'
      else:
        DFILE=FILE
      #if translate == 'yes':
      #  DFILE = ('COD' + SGW + SDOW + '.ERP').lower ()
      if save_dir == '':
        DFILE = DFILE
      else:
        DFILE = save_dir + '/' + FILE
      if os.path.isfile (DFILE):
        if force_remove:
          os.unlink (DFILE)
        else : 
          DOWNLOADED = 'yes'
          SOLUTION_TYPE = 'ultra-rapid'
          FTP_FILENAME  = FILE
          SV_FILENAME   = DFILE
          return [0,FTP_FILENAME,SV_FILENAME,SOLUTION_TYPE]
      if check_for_z == True:
        p = re.compile ('.Z$')
        dfile = p.sub( '', DFILE)
        if os.path.isfile (dfile):
          DOWNLOADED = 'yes'
          SOLUTION_TYPE = 'ultra-rapid'
          FTP_FILENAME  = FILE
          SV_FILENAME   = DFILE
          return [0,FTP_FILENAME,SV_FILENAME,SOLUTION_TYPE]
      status = bpepy.utils.ftpget (HOST+'/'+DIRN,[FILE],[DFILE])
      if status == 0:
        DOWNLOADED = 'yes'
        SOLUTION_TYPE = 'ultra-rapid'
        FTP_FILENAME  = FILE
        SV_FILENAME   = DFILE
      else:
        DOWNLOADED = 'no'
        try: os.unlink (DFILE)
        except: pass

  ## No more solutions available; check the status
  if DOWNLOADED == 'no':
    # print >> sys.stderr, 'ERROR: no orbit file found'
    return [1,'','','']
  else:
    return [0,FTP_FILENAME,SV_FILENAME,SOLUTION_TYPE]
