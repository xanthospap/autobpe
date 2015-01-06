#! /usr/bin/python

""" @package orbits
  Various functions to download GNSS orbits

  Created         : Sep 2014
  Last Update     : Oct 2014
                  : Nov 2014

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

def getorb (year,doy,ac='cod',save_dir='',translate=False,no_glo=False,force_type='x',force_remove=False,check_for_z=False):
  """ @brief Wrapper for getorb_ using year and doy
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
  return getorb_ (dt,ac,save_dir,translate,no_glo,force_type,force_remove,check_for_z)

def getorb_ (date_,ac='cod',save_dir='',translate=False,no_glo=False,force_type='x',force_remove=False,check_for_z=False):
  """ @brief Download an orbit file or orbit files

    @details This script will download both GPS and GLONASS orbit file or files,
             in sp3 format, depending on the analysis center (e.g. for code only
             one file will be downloaded but for igs AC two files are going to be 
             downloaded for gps and glonass respectively). The files to download 
             are in order of preference:<br>
              1. Final<br>
              2. Rapid<br>
              3. Ultra-Rapid<br>
            Whichever is found first is downloaded. If the user only wants a specific
            orbit type (e.g. final) then the \c force_type parameter should be set
            accordingly. If the file to download already exists, then the script
            will not re-download the file; it will report a successeful exit status
            though, except if the \c force_remove parameter is set to \c True. In
            this case, the script will first delete the already available file and
            try to re-download it. To also search for the uncompressed file, set the
            check_for_z parameter to True.
            Special Case: if ac='igs' and no_glo=False and force_type='u'
            only the glonass orbit file will be downloaded, because it is a merged file
            (has both gps and glonass)

    @param  date_        a datetime object for which the orbit file(s) is requested
    @param  ac           a 3-digit (string) identifier for the AC. Valid ac paramters 
                         are:<br>
                         igs,<br>
                         cod<br>
    @param  save_dir     the directory where the downloaded files will reside
    @param  translate    if set to True, all downloaded files will be given their
                         final names (e.g. igsWWWWD.sp3.Z, iglWWWWD.sp3.Z, codWWWWD.sp3.Z)
    @param  no_glo       do not download any glonass file (this is valid only for igs; cod's
                         sp3 files include by default the glonass orbits)
    @param  force_type   only try to download a specific product type:
                           'f' for final,
                           'r' for rapid (for glonass this defaults to ultra-rapid)
                           'u' for ultra-rapid
    @param  force_remove if a file alredy exists, with the same name as the one to
                         be downloaded, then this file will be deleted before the
                         new file is downloaded.
    @param check_for_z   if set to true, then the script will search also for a file
                         named the same as the one to be downloaded but uncompressed.
                         If this file exists, then the file is not redownloaded (e.g.
                         file to download is igsWWWWD.sp3.Z, the script will search
                         --prior to downloading-- for a file named as igsWWWWD.sp3.Z
                         or a file named igsWWWWD.sp3; if any of the two is available,
                         the file is not re-downloaded but the status is ok)
    @retval list         [Exit_Code,ftp_filename,saved_filename,solution_type]

    Exit Code | Status
    ----------|-----------------------
         0    | all ok
        -1    | connection error
        -2    | date error
        -3    | invalid directory
        -4    | invalid analysis center
        >0    | some file is missing
  """

  ## check if the analysis center is valid
  ac_info = bpepy.products.centers.acinfo (ac)
  if ac_info[0] != 0:
    print >> sys.stderr, 'ERROR! Unresolved AC'
    return -4

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

  ## set parameters
  if save_dir == '' or save_dir == './':
    SAVE_DIR = ''
  else:
    if save_dir.endswith ('/'):
      save_dir = save_dir[:-1]
    if os.path.isdir (save_dir):
      SAVE_DIR = save_dir
    else:
      print >> sys.stderr, 'ERROR: directory not found "%s"' % save_dir
      return -3
  ## call function to download orbit file
  if ac == 'cod':
    status = getorb_cod (date,SAVE_DIR,translate,force_type,force_remove,check_for_z)
  elif ac == 'igs':
    if ac=='igs' and no_glo==False and force_type=='u':
      status = getorb_igs_glonass (date,SAVE_DIR,translate,force_type,force_remove,check_for_z)
    elif ac=='igs' and no_glo==False and force_type=='r':
      status = [1,'','','']
    # special case : if we download rapid or ultra-rapid glonass, no need for gps
    elif ac=='igs' and no_glo==False and force_type=='x':
      status2 = getorb_igs_glonass (date,SAVE_DIR,translate,force_type,force_remove,check_for_z)
      if status2[0]==0 and status2[3]=='ultra-rapid':
        return status2
      else:
        status = getorb_igs (date,SAVE_DIR,translate,force_type,force_remove,check_for_z)
        status[0] = status[0]+status2[0]
        status[1] = status[1],status2[1]
        status[2] = status[2],status2[2]
        status[3] = status[3],status2[3]
    else:
      status = getorb_igs (date,SAVE_DIR,translate,force_type,force_remove,check_for_z)
      if not no_glo:
        status2 = getorb_igs_glonass (date,SAVE_DIR,translate,force_type,force_remove,check_for_z)
        status[0] = status[0]+status2[0]
        status[1] = status[1],status2[1]
        status[2] = status[2],status2[2]
        status[3] = status[3],status2[3]
  else:
    status = [1,'','','']

  return status
  #sys.exit (int (status[0]))

def getorb_igs_glonass (date,save_dir='',translate=False,force_type='x',force_remove=False,check_for_z=False):
  """ Download an igs glonass orbit file (sp3)

    Download orbit file from IGS, only for GLONASS satellites. The 
    script will search for (a) a final solution, or (b) an ultra-rapid
    solution and it will download the first available option.

    @param  date         a datetime object for which the orbit file(s) is requested
    @param  save_dir     the directory where the downloaded files will reside (string)
    @param  translate    translate file to match the global naming convention, i.e.
                         iglWWWWD.sp3.Z (string, 'yes' or 'no')
    @param  force_type   only try to download a specific product type:
                           'f' for final,
                           'r' for rapid (for glonass this is not available)
                           'u' for ultra-rapid
    @param  force_remove if a file alredy exists, with the same name as the one to
                         be downloaded, then this file will be deleted before the
                         new file is downloaded.
    @param check_for_z   if set to true, then the script will search also for a file
                         named the same as the one to be downloaded but uncompressed.
                         If this file exists, then the file is not redownloaded (e.g.
                         file to download is igsWWWWD.sp3.Z, the script will search
                         --prior to downloading-- for a file named as igsWWWWD.sp3.Z
                         or a file named igsWWWWD.sp3; if any of the two is available,
                         the file is not re-downloaded but the status is ok)
    @retval list         [Exit_Code,ftp_filename,saved_filename,solution_type]

    Exit Code | Status
    ----------|-----------------------
         0    | all ok
        -1    | connection error
         1    | nothing downloaded
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
  if force_type == 'r':
    #print >> sys.stderr, 'Warning! No rapid orbit available for glonass products; defaulting to ultra-rapid'
    return [1,'','','']

  ## ------------------------------------------------------------------------ ##
  ## if the user only wants a specific product type                           ##
  ## ------------------------------------------------------------------------ ##
  if force_type == 'f':  ## only final
    dc = 0
    for host in HOSTS:
      DIRN  = bpepy.products.centers.GLONASS_PRODUCT_AREA[dc] + SGW
      FILE  = 'igl' + SGW + SDOW + '.sp3.Z'
      if save_dir == '':
        DFILE = FILE
      else:
        DFILE = save_dir + '/' + FILE
      if os.path.isfile (DFILE):
        if force_remove : 
          os.unlink (DFILE)
        else : 
          DOWNLOADED = 'yes'
          ##print >> sys.stderr, 'File',dfile,'already available; skipping download'
          return [0,FILE,DFILE,'final']
      if check_for_z == True:
        p = re.compile ('.Z$')
        dfile = p.sub( '', DFILE)
        if os.path.isfile (dfile):
          DOWNLOADED = 'yes'
          ##print >> sys.stderr, 'File',dfile,'already available; skipping download'
          return [0,FILE,dfile,'final']
      status = bpepy.utils.ftpget (host+'/'+DIRN,[FILE],[DFILE])
      if status == 0:
        DOWNLOADED = 'yes'
      else:
        DOWNLOADED = 'no'
        try: os.unlink (DFILE)
        except: pass
      dc = dc + 1
      if DOWNLOADED == 'yes':
        SOLUTION_TYPE = 'final'
        FTP_FILENAME  = FILE
        SV_FILENAME   = DFILE
        return [0,FILE,DFILE,'final']
    if DOWNLOADED == 'no': return [1,'','','']
  elif force_type == 'u':  ## only ultra-rapid
    dc = 0
    for host in HOSTS:
      for hour in ['18','12','06','00']:
        FILE  = 'igv' + SGW + SDOW + '_' + hour + '.sp3.Z'
        if save_dir == '':
          DFILE = FILE
        else:
          DFILE = save_dir + '/' + FILE
        if translate == True :
          #DFILE = DFILE.replace ('igv','igl')
          DFILE = DFILE.replace ('_'+hour,'')
        DIRN  = bpepy.products.centers.GLONASS_PRODUCT_AREA[dc] + SGW
        if os.path.isfile (DFILE):
          if force_remove : 
            os.unlink (DFILE)
          else : 
            DOWNLOADED = 'yes'
            print >> sys.stderr, 'File',dfile,'already available; skipping download'
            return [0,FILE,DFILE,'ultra-rapid']
        if check_for_z == True:
          p = re.compile ('.Z$')
          dfile = p.sub( '', DFILE)
          if os.path.isfile (dfile):
            DOWNLOADED = 'yes'
            print >> sys.stderr, 'File',dfile,'already available; skipping download'
            return [0,FILE,dfile,'ultra-rapid']
        status = bpepy.utils.ftpget (host+'/'+DIRN,[FILE],[DFILE])
        if status == 0:
          DOWNLOADED = 'yes'
        else:
          DOWNLOADED = 'no'
          try: os.unlink (DFILE)
          except: pass
        if DOWNLOADED == 'yes':
          SOLUTION_TYPE = 'ultra-rapid (' + hour + ')'
          FTP_FILENAME = FILE
          SV_FILENAME  = DFILE
          return [0,FILE,DFILE,'ultra-rapid']
      dc = dc + 1
    if DOWNLOADED == 'no': return [1,'','','']

  ## ------------------------------------------------------------------------ ##
  ## Normal download; no specific product type asked for                      ##
  ## ------------------------------------------------------------------------ ##

  ## Final Solution
  dc = 0
  for host in HOSTS:
    DIRN  = bpepy.products.centers.GLONASS_PRODUCT_AREA[dc] + SGW
    FILE  = 'igl' + SGW + SDOW + '.sp3.Z'
    if save_dir == '':
      DFILE = FILE
    else:
      DFILE = save_dir + '/' + FILE
    if os.path.isfile (DFILE):
      if force_remove : 
        os.unlink (DFILE)
      else : 
        DOWNLOADED = 'yes'
        ##print >> sys.stderr, 'File',dfile,'already available; skipping download'
        return [0,FILE,DFILE,'final']
    if check_for_z == True:
      p = re.compile ('.Z$')
      dfile = p.sub( '', DFILE)
      if os.path.isfile (dfile):
        DOWNLOADED = 'yes'
        ##print >> sys.stderr, 'File',dfile,'already available; skipping download'
        return [0,FILE,dfile,'final']
    status = bpepy.utils.ftpget (host+'/'+DIRN,[FILE],[DFILE])
    if status == 0:
      DOWNLOADED = 'yes'
    else:
      DOWNLOADED = 'no'
      try: os.unlink (DFILE)
      except: pass
    dc = dc + 1
    if DOWNLOADED == 'yes':
      SOLUTION_TYPE = 'final'
      FTP_FILENAME  = FILE
      SV_FILENAME   = DFILE
      return [0,FILE,DFILE,'final']
  ## ----------------------------------------------
  ## Rapid Solution
  ## ----------------------------------------------
  ##if DOWNLOADED == 'no':
  ##  FILE  = 'igr' + SGW + SDOW + '.sp3.Z'
  ##  if save_dir == '':
  ##    DFILE = FILE
  ##  else:
  ##    DFILE = save_dir + '/' + FILE
  ##  if translate == True :
  ##    DFILE = DFILE.replace ('igr','igs')
  ##  # retrieve the file
  ##  try:
  ##    f.retrbinary ('RETR %s' % FILE, open (DFILE, 'wb').write)
  ##    DOWNLOADED = 'yes'
  ##    SOLUTION_TYPE = 'rapid'
  ##    FTP_FILENAME = FILE
  ##    SV_FILENAME  = DFILE
  ##  except :
  ##    print >> sys.stderr, 'ERROR: cannot read file "%s"' % FILE
  ##    DOWNLOADED = 'no'
  ##    try: os.unlink (DFILE)
  ##    except: pass

  ## Ultra Rapid Solution
  if DOWNLOADED == 'no':
    dc = 0
    for host in HOSTS:
      for hour in ['18','12','06','00']:
        FILE  = 'igv' + SGW + SDOW + '_' + hour + '.sp3.Z'
        if save_dir == '':
          DFILE = FILE
        else:
          DFILE = save_dir + '/' + FILE
        if translate == True :
          #DFILE = DFILE.replace ('igv','igl')
          DFILE = DFILE.replace ('_'+hour,'')
        DIRN  = bpepy.products.centers.GLONASS_PRODUCT_AREA[dc] + SGW
        if os.path.isfile (DFILE):
          if force_remove : 
            os.unlink (DFILE)
          else : 
            DOWNLOADED = 'yes'
            ##print >> sys.stderr, 'File',dfile,'already available; skipping download'
            return [0,FILE,DFILE,'ultra-rapid']
        if check_for_z == True:
          p = re.compile ('.Z$')
          dfile = p.sub( '', DFILE)
          if os.path.isfile (dfile):
            DOWNLOADED = 'yes'
            ##print >> sys.stderr, 'File',dfile,'already available; skipping download'
            return [0,FILE,dfile,'ultra-rapid']
        status = bpepy.utils.ftpget (host+'/'+DIRN,[FILE],[DFILE])
        if status == 0:
          DOWNLOADED = 'yes'
        else:
          DOWNLOADED = 'no'
          try: os.unlink (DFILE)
          except: pass
        if DOWNLOADED == 'yes':
          SOLUTION_TYPE = 'ultra-rapid (' + hour + ')'
          FTP_FILENAME = FILE
          SV_FILENAME  = DFILE
          return [0,FILE,DFILE,'ultra-rapid']
      dc = dc + 1

  ## No more solutions available; check the status
  if DOWNLOADED == 'no':
    print >> sys.stderr, 'ERROR: no orbit file found'
    return [1,'','','']
  else:
    return [0,FTP_FILENAME,SV_FILENAME,SOLUTION_TYPE]

def getorb_igs (date,save_dir='',translate=False,force_type='x',force_remove=False,check_for_z=False):
  """ Download an igs gps orbit file (sp3)

    Download orbit file from IGS, only for GPS satellites. The script will 
    search for (a) a final solution, (b) a rapid solution, or (c) an 
    ultra-rapid solution and it will download the first available option.

    @param  date         a datetime object for which the orbit file(s) is requested
    @param  save_dir     the directory where the downloaded files will reside (string)
    @param  translate    translate file to match the global naming convention, i.e.
                         igsWWWWD.sp3.Z (string, yes or no)
    @param  force_type   only try to download a specific product type:
                           'f' for final,
                           'r' for rapid,
                           'u' for ultra-rapid
    @param  force_remove if a file alredy exists, with the same name as the one to
                         be downloaded, then this file will be deleted before the
                         new file is downloaded.
    @param check_for_z   if set to true, then the script will search also for a file
                         named the same as the one to be downloaded but uncompressed.
                         If this file exists, then the file is not redownloaded (e.g.
                         file to download is igsWWWWD.sp3.Z, the script will search
                         --prior to downloading-- for a file named as igsWWWWD.sp3.Z
                         or a file named igsWWWWD.sp3; if any of the two is available,
                         the file is not re-downloaded but the status is ok)
    @retval list         [Exit_Code,ftp_filename,saved_filename,solution_type]

    Exit Code | Status
    ----------|-----------------------
         0    | all ok
        -1    | connection error
         1    | nothing downloaded
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
  if force_type == 'f':  ## only final
    dc = 0
    for host in HOSTS:
      DIRN  = bpepy.products.centers.PRODUCT_AREA[dc] + SGW
      FILE  = 'igs' + SGW + SDOW + '.sp3.Z'
      if save_dir == '':
        DFILE = FILE
      else:
        DFILE = save_dir + '/' + FILE
      if os.path.isfile (DFILE):
        if force_remove : 
          os.unlink (DFILE)
        else : 
          DOWNLOADED = 'yes'
          ##print >> sys.stderr, 'File',dfile,'already available; skipping download'
          return [0,FILE,DFILE,'final']
      if check_for_z == True:
        p = re.compile ('.Z$')
        dfile = p.sub( '', DFILE)
        if os.path.isfile (dfile):
          DOWNLOADED = 'yes'
          ##print >> sys.stderr, 'File',dfile,'already available; skipping download'
          return [0,FILE,dfile,'final']
      status = bpepy.utils.ftpget (host+'/'+DIRN,[FILE],[DFILE])
      if status == 0:
        DOWNLOADED = 'yes'
        SOLUTION_TYPE = 'final'
        FTP_FILENAME  = FILE
        SV_FILENAME   = DFILE
        return [0,FILE,DFILE,'final']
      else:
        DOWNLOADED = 'no'
        try: os.unlink (DFILE)
        except: pass
      dc = dc + 1
    if DOWNLOADED == 'no': return [1,'','','']
  elif force_type == 'r':  ## only rapid
    dc = 0
    for host in HOSTS:
      DIRN  = bpepy.products.centers.PRODUCT_AREA[dc] + SGW
      FILE  = 'igr' + SGW + SDOW + '.sp3.Z'
      if save_dir == '':
        DFILE = FILE
      else:
        DFILE = save_dir + '/' + FILE
      #if translate == True :
      #  DFILE = DFILE.replace ('igr','igs')
      if os.path.isfile (DFILE):
        if force_remove : 
          os.unlink (DFILE)
        else : 
          DOWNLOADED = 'yes'
          ##print >> sys.stderr, 'File',dfile,'already available; skipping download'
          return [0,FILE,DFILE,'rapid']
      if check_for_z == True:
        p = re.compile ('.Z$')
        dfile = p.sub( '', DFILE)
        if os.path.isfile (dfile):
          DOWNLOADED = 'yes'
          ##print >> sys.stderr, 'File',dfile,'already available; skipping download'
          return [0,FILE,dfile,'rapid']
      status = bpepy.utils.ftpget (host+'/'+DIRN,[FILE],[DFILE])
      if status == 0:
        DOWNLOADED = 'yes'
        SOLUTION_TYPE = 'rapid'
        FTP_FILENAME  = FILE
        SV_FILENAME   = DFILE
        return [0,FILE,DFILE,'rapid']
      else:
        DOWNLOADED = 'no'
        try: os.unlink (DFILE)
        except: pass
      dc = dc + 1
    if DOWNLOADED == 'no': return [1,'','',''] 
  elif force_type == 'u':  ## only ultra-rapid
    dc = 0
    for host in HOSTS:
      for hour in ['18','12','06','00']:
        FILE  = 'igu' + SGW + SDOW + '_' + hour + '.sp3.Z'
        if save_dir == '':
          DFILE = FILE
        else:
          DFILE = save_dir + '/' + FILE
        if translate == True :
          #DFILE = DFILE.replace ('igu','igs')
          DFILE = DFILE.replace ('_'+hour,'')
        DIRN  = bpepy.products.centers.PRODUCT_AREA[dc] + SGW
        if os.path.isfile (DFILE):
          if force_remove : 
            os.unlink (DFILE)
          else : 
            DOWNLOADED = 'yes'
            ##print >> sys.stderr, 'File',dfile,'already available; skipping download'
            return [0,FILE,DFILE,'ultra-rapid']
        if check_for_z == True:
          p = re.compile ('.Z$')
          dfile = p.sub( '', DFILE)
          if os.path.isfile (dfile):
            DOWNLOADED = 'yes'
            ##print >> sys.stderr, 'File',dfile,'already available; skipping download'
            return [0,FILE,dfile,'ultra-rapid']
        status = bpepy.utils.ftpget (host+'/'+DIRN,[FILE],[DFILE])
        if status == 0:
          DOWNLOADED = 'yes'
          SOLUTION_TYPE = 'ultra-rapid (' + hour + ')'
          FTP_FILENAME = FILE
          SV_FILENAME  = DFILE
          return [0,FILE,DFILE,'ultra-rapid']
        else:
          DOWNLOADED = 'no'
          try: os.unlink (DFILE)
          except: pass
      dc = dc + 1
    if DOWNLOADED == 'no': return [1,'','','']

  ## ------------------------------------------------------------------------ ##
  ## Normal download; no specific product type asked for                      ##
  ## ------------------------------------------------------------------------ ##

  ## Final Solution
  dc = 0
  for host in HOSTS:
    DIRN  = bpepy.products.centers.PRODUCT_AREA[dc] + SGW
    FILE  = 'igs' + SGW + SDOW + '.sp3.Z'
    if save_dir == '':
      DFILE = FILE
    else:
      DFILE = save_dir + '/' + FILE
    #print >> sys.stderr, 'Searching for:',DFILE
    if os.path.isfile (DFILE):
      if force_remove : 
        os.unlink (DFILE)
      else : 
        DOWNLOADED = 'yes'
        ##print >> sys.stderr, 'File',dfile,'already available; skipping download'
        return [0,FILE,DFILE,'final']
    #print >> sys.stderr, 'Check for uncompressed is:',check_for_z
    if check_for_z == True:
      p = re.compile ('.Z$')
      dfile = p.sub( '', DFILE)
      #print >> sys.stderr, 'Checking for',dfile
      if os.path.isfile (dfile):
        DOWNLOADED = 'yes'
        ##print >> sys.stderr, 'File',dfile,'already available; skipping download'
        return [0,FILE,dfile,'final']
    status = bpepy.utils.ftpget (host+'/'+DIRN,[FILE],[DFILE])
    if status == 0:
      DOWNLOADED = 'yes'
      SOLUTION_TYPE = 'final'
      FTP_FILENAME  = FILE
      SV_FILENAME   = DFILE
      return [0,FILE,DFILE,'final']
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
      FILE  = 'igr' + SGW + SDOW + '.sp3.Z'
      if save_dir == '':
        DFILE = FILE
      else:
        DFILE = save_dir + '/' + FILE
      #if translate == True :
      #  DFILE = DFILE.replace ('igr','igs')
      if os.path.isfile (DFILE):
        if force_remove : 
          os.unlink (DFILE)
        else : 
          DOWNLOADED = 'yes'
          ##print >> sys.stderr, 'File',dfile,'already available; skipping download'
          return [0,FILE,DFILE,'rapid']
      if check_for_z == True:
        p = re.compile ('.Z$')
        dfile = p.sub( '', DFILE)
        if os.path.isfile (dfile):
          DOWNLOADED = 'yes'
          ##print >> sys.stderr, 'File',dfile,'already available; skipping download'
          return [0,FILE,dfile,'rapid']
      status = bpepy.utils.ftpget (host+'/'+DIRN,[FILE],[DFILE])
      if status == 0:
        DOWNLOADED = 'yes'
        SOLUTION_TYPE = 'rapid'
        FTP_FILENAME  = FILE
        SV_FILENAME   = DFILE
        return [0,FILE,DFILE,'rapid']
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
        FILE  = 'igu' + SGW + SDOW + '_' + hour + '.sp3.Z'
        if save_dir == '':
          DFILE = FILE
        else:
          DFILE = save_dir + '/' + FILE
        if translate == True :
          #DFILE = DFILE.replace ('igu','igs')
          DFILE = DFILE.replace ('_'+hour,'')
        DIRN  = bpepy.products.centers.PRODUCT_AREA[dc] + SGW
        if os.path.isfile (DFILE):
          if force_remove : 
            os.unlink (DFILE)
          else : 
            DOWNLOADED = 'yes'
            ##print >> sys.stderr, 'File',dfile,'already available; skipping download'
            return [0,FILE,DFILE,'ultra-rapid']
        if check_for_z == True:
          p = re.compile ('.Z$')
          dfile = p.sub( '', DFILE)
          if os.path.isfile (dfile):
            DOWNLOADED = 'yes'
            ##print >> sys.stderr, 'File',dfile,'already available; skipping download'
            return [0,FILE,dfile,'ultra-rapid']
        status = bpepy.utils.ftpget (host+'/'+DIRN,[FILE],[DFILE])
        if status == 0:
          DOWNLOADED = 'yes'
          SOLUTION_TYPE = 'ultra-rapid (' + hour + ')'
          FTP_FILENAME = FILE
          SV_FILENAME  = DFILE
          return [0,FILE,DFILE,'ultra-rapid']
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

def getorb_cod (date,save_dir='',translate=False,force_type='x',force_remove=False,check_for_z=False,use_repro_2013='no'):
  """ Download a CODE orbit file (gps+glonass)

  Download orbit file from CODE AC. The script will search for (a) a
  final solution, (b) a rapid solution, or (c) an ultra-rapid solution
  and it will download the first available option.

    @param  date           a datetime object for which the orbit file is requested
    @param  save_dir       the directory where the downloaded files will reside (string)
    @param  translate      translate file to match the global naming convention, i.e.
                           codWWWWD.sp3.Z (string, yes or no)
    @param  use_repro_2013 use results from CODE's 2013 reprocessing campaign
    @param  force_type     only try to download a specific product type:
                             'f' for final,
                             'r' for rapid,
                             'u' for ultra-rapid
    @param  force_remove   if a file alredy exists, with the same name as the one to
                           be downloaded, then this file will be deleted before the
                           new file is downloaded.
    @param check_for_z     if set to true, then the script will search also for a file
                           named the same as the one to be downloaded but uncompressed.
                           If this file exists, then the file is not redownloaded (e.g.
                           file to download is igsWWWWD.sp3.Z, the script will search
                           --prior to downloading-- for a file named as igsWWWWD.sp3.Z
                           or a file named igsWWWWD.sp3; if any of the two is available,
                           the file is not re-downloaded but the status is ok)
    @retval list           [Exit_Code,ftp_filename,saved_filename,solution_type]

    Exit Code | Status
    ----------|-----------------------
         0    | all ok
        -1    | connection error
         1    | nothing downloaded
  """

  ## variables
  HOST = 'ftp.unibe.ch'
  DOWNLOADED    = 'no'
  SOLUTION_TYPE = ''
  FTP_FILENAME  = ''
  SV_FILENAME   = ''

  ## resolve date
  exit_status,SYR,MONTH,DOM,DOY,SGW,SDOW = bpepy.gpstime.resolvedt (date)
  
  ## standard names
  FINAL_ = 'cod'+SGW+SDOW+'.sp3.Z'
  RAPID_ = 'cor'+SGW+SDOW+'.sp3'
  ULTRA_ = 'cou'+SGW+SDOW+'.sp3'

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
    FILE  = identifier + SGW + SDOW + '.EPH.Z'
    if save_dir == '':
      DFILE = FILE
    else:
      DFILE = save_dir + '/' + FILE
    if translate == True:
      ##DFILE = (DFILE.replace ('.EPH','.SP3')).lower ()
      ##DFILE = (DFILE.replace ('.z','.Z'))
      DFILE = FINAL_
    if os.path.isfile (DFILE):
      if force_remove : 
        os.unlink (DFILE)
      else : 
        DOWNLOADED = 'yes'
        ##print >> sys.stderr, 'File',dfile,'already available; skipping download'
        return [0,FILE,DFILE,'final']
    if check_for_z == True:
      p = re.compile ('.Z$')
      dfile = p.sub( '', DFILE)
      if os.path.isfile (dfile):
        DOWNLOADED = 'yes'
        ##print >> sys.stderr, 'File',dfile,'already available; skipping download'
        return [0,FILE,dfile,'final']
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
      return [1,'','','']
  elif force_type == 'r':  ## only rapid
    if use_repro_2013 == 'yes':
      # print >> sys.stderr, 'ERROR: No rapid files available for REPRO2013'
      DOWNLOADED = 'no'
    else:
      FILE  = 'COD' + SGW + SDOW + '.EPH_R'
      if save_dir == '':
        DFILE = FILE
      else:
        DFILE = save_dir + '/' + FILE
      if translate == True:
        ##DFILE = (DFILE.replace ('.EPH_R','.SP3')).lower ()
        ##DFILE = (DFILE.replace ('.z','.Z'))
        DFILE = RAPID_
      if os.path.isfile (DFILE):
        if force_remove : 
          os.unlink (DFILE)
        else : 
          DOWNLOADED = 'yes'
          ##print >> sys.stderr, 'File',dfile,'already available; skipping download'
          return [0,FILE,DFILE,'rapid']
      #if check_for_z == True:
      #  p = re.compile ('.Z$')
      #  dfile = p.sub( '', DFILE)
      #  if os.path.isfile (dfile):
      #    DOWNLOADED = 'yes'
      #    return [0,FILE,dfile,'rapid']
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
        return [1,'','','']
  elif force_type == 'u':  ## only ultra-rapid
    if use_repro_2013 == 'yes':
      # print >> sys.stderr, 'ERROR: No ultra-rapid files available for REPRO2013'
      DOWNLOADED = 'no'
    else:
      delta_days = (date - datetime.datetime.today ()).days
      DIRN = 'aiub/CODE/'
      if delta_days < 1:
        FILE = 'COD' + '.EPH_U'
      elif delta_days < 2:
        FILE = 'COD' + SGW + SDOW + '.EPH_P1'
      elif delta_days < 3:
        FILE = 'COD' + SGW + SDOW + '.EPH_P2'
      elif delta_days < 5:
        FILE = 'COD' + SGW + SDOW + '.EPH_5D'
      else:
        DOWNLOADED = 'no'
        return [1,'','','']
      if translate == True:
        ##DFILE = ('COD' + SGW + SDOW + '.SP3').lower ()
        DFILE = ULTRA_
      if save_dir == '':
        DFILE = DFILE
      else:
        DFILE = save_dir + '/' + DFILE
      if os.path.isfile (DFILE):
        if force_remove : 
          os.unlink (DFILE)
        else : 
          DOWNLOADED = 'yes'
          ##print >> sys.stderr, 'File',dfile,'already available; skipping download'
          return [0,FILE,DFILE,'ultra-rapid']
      #if check_for_z == True:
      #  p = re.compile ('.Z$')
      #  dfile = p.sub( '', DFILE)
      #  if os.path.isfile (dfile):
      #    DOWNLOADED = 'yes'
      #    return [0,FILE,dfile,'ultra-rapid']
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
        return [1,'','','']

  ## ------------------------------------------------------------------------ ##
  ## Normal download; no specific product type asked for                      ##
  ## ------------------------------------------------------------------------ ##

  ## Final Solution
  identifier = 'COD'
  if use_repro_2013 == 'yes':
    DIRN = 'aiub/REPRO_2013/CODE/' + SYR + '/'
    identifier = 'CO2'
  else:
    DIRN = 'aiub/CODE/' + SYR + '/'
  FILE  = identifier + SGW + SDOW + '.EPH.Z'
  if save_dir == '':
    DFILE = FILE
  else:
    DFILE = save_dir + '/' + FILE
  if translate == True:
    ##DFILE = (DFILE.replace ('.EPH','.SP3')).lower ()
    ##DFILE = (DFILE.replace ('.z','.Z'))
    DFILE = FINAL_
  if os.path.isfile (DFILE):
    if force_remove : 
      os.unlink (DFILE)
    else : 
      DOWNLOADED = 'yes'
      ##print >> sys.stderr, 'File',dfile,'already available; skipping download'
      return [0,FILE,DFILE,'final']
  if check_for_z == True:
    p = re.compile ('.Z$')
    dfile = p.sub( '', DFILE)
    if os.path.isfile (dfile):
      DOWNLOADED = 'yes'
      ##print >> sys.stderr, 'File',dfile,'already available; skipping download'
      return [0,FILE,dfile,'final']
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
      FILE  = 'COD' + SGW + SDOW + '.EPH_R'
      if save_dir == '':
        DFILE = FILE
      else:
        DFILE = save_dir + '/' + FILE
      if translate == True:
        ##DFILE = (DFILE.replace ('.EPH_R','.SP3')).lower ()
        ##DFILE = (DFILE.replace ('.z','.Z'))
        DFILE = RAPID_
      if os.path.isfile (DFILE):
        if force_remove : 
          os.unlink (DFILE)
        else : 
          DOWNLOADED = 'yes'
          ##print >> sys.stderr, 'File',dfile,'already available; skipping download'
          return [0,FILE,DFILE,'rapid']
      #if check_for_z == True:
      #  p = re.compile ('.Z$')
      #  dfile = p.sub( '', DFILE)
      #  if os.path.isfile (dfile):
      #    DOWNLOADED = 'yes'
      #    return [0,FILE,dfile,'rapid']
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
        FILE = 'COD' + '.EPH_U'
      elif delta_days < 2:
        FILE = 'COD' + SGW + SDOW + '.EPH_P1'
      elif delta_days < 3:
        FILE = 'COD' + SGW + SDOW + '.EPH_P2'
      elif delta_days < 5:
        FILE = 'COD' + SGW + SDOW + '.EPH_5D'
      else:
        DOWNLOADED = 'no'
        return [1,'','','']
      if translate == True:
        ##DFILE = ('COD' + SGW + SDOW + '.SP3').lower ()
        DFILE = ULTRA_
      if save_dir == '':
        DFILE = DFILE
      else:
        DFILE = save_dir + '/' + DFILE
      if os.path.isfile (DFILE):
        if force_remove : 
          os.unlink (DFILE)
        else : 
          DOWNLOADED = 'yes'
          ##print >> sys.stderr, 'File',dfile,'already available; skipping download'
          return [0,FILE,DFILE,'ultra-rapid']
      #if check_for_z == True:
      #  p = re.compile ('.Z$')
      #  dfile = p.sub( '', DFILE)
      #  if os.path.isfile (dfile):
      #    DOWNLOADED = 'yes'
      #    return [0,FILE,dfile,'ultra-rapid']
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
