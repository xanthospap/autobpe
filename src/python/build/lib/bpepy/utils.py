  #! /usr/bin/python

""" @package utils

    @brief   Various utility functions.

    @date    September, 2014

    <b><center><hr>
    National Technical University of Athens <br>
    Dionysos Satellite Observatory <br>
    Higher Geodesy Laboratory <br>
    </center></b>
"""

""" Import Libraries
"""
import urllib
import urllib2
import ftplib

def ftpget (dir_,dfile,sfile_=''):
  """ Download a file(s) from an ftp server.

    @details Download a file (or list of files) from an ftp website.

    @param  dir_     string, the directory of the website (e.g. ggosatm.hg.tuwien.ac.at/DELAY/GRID)
    @param  dfile    list, name of the file(s) to download
    @param  sfile_   list, how to save each file in the dfile list. If empty, the files
                     will be saved as in the dfile list.
    @retval integer  an integer denoting the Exit Code

    Exit Codes | Returned Integer Value
    -----------|-----------------------
     0         | all ok
    -2         | argument error
    -1         | connection error
    >0         | file is missing

  """

  if sfile_ == '':
    sfile = dfile
  else:
    sfile = sfile_

  if len (dfile) != len (sfile):
    return -2

  HOST = dir_[0:dir_.find ('/')]
  DIR  = dir_[dir_.find ('/'):]
  if DIR.endswith ('/'):
    DIR = DIR[:-1]

  ## connect to host
  try:
    #print 'Connecting to host',HOST
    f = ftplib.FTP (HOST)
  except :
    #print >> sys.stderr, 'ERROR: cannot reach "%s"' % host
    return -1

  ## anonymous login
  try:
    #print 'Anonymous login'
    f.login ()
  except:
    #print >> sys.stderr, 'ERROR: cannot login anonymously'
    f.quit ()
    return -1

  ## change directory
  try:
    #print 'Changing to directory',DIR
    f.cwd (DIR)
  except :
    #print >> sys.stderr, 'ERROR: cannot CD to "%s"' % DIR
    f.quit ()
    return -1

  ## retrieve the file(s)
  for d,s in zip (dfile,sfile):
    try:
      #print 'Retrieving file',d
      f.retrbinary ('RETR %s' % d, open (s,'wb').write)
    except :
      #print >> sys.stderr, 'ERROR: cannot download file "%s"' % d
      for sf in sfile:
        try:
          os.unlink (sf)
        except:
          pass
      f.quit ()
      return 1

  f.quit ()
  return 0

def httpget (url,dfile,sfile_=''):
  """ Download a file(s) from a http server.

    @details Download a file (or list of files) from a http website.

    @param  url     string, the url of the website
    @param  dfile   list, name of the file(s) to download
    @param  sfile_  list, how to save each file in the dfile list. If empty, the files
                    will be saved as in the dfile list.
    @retval integer an integer denoting the Exit Code

    Exit Codes | Returned Integer Value
    -----------|-----------------------
     0         | all ok
    -2         | argument error
    -1         | connection error
    >0         | file is missing

  """

  if sfile_ == '':
    sfile = dfile
  else:
    sfile = sfile_

  if len (dfile) != len (sfile):
    return -2

  if url.endswith ('/'):
    url = url[:-1]

  iterator = 1
  for wfl,sfl in zip (dfile,sfile):
    file_to_download = url + '/' + wfl
    file_to_save     = sfl
    try:
      f = urllib2.urlopen (file_to_download)
      with open (file_to_save, "wb") as sf:
        sf.write (f.read())
    except:
      return iterator
    iterator = iterator + 1

  return 0;
