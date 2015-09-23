import os
import ftplib
import urllib2
import gzip
import shutil

## paramiko for ssh/scp
## from paramiko import SSHClient
## from scp import SCPClient

def grabHttpFile(url, files, saveas):
  ''' Download file(s) from an http webserver.

      :param url:    The server's address/hostname; do not append the
                     the filename to be downloaded.
      :param files:  A list of files to be downloaded from the
                     given url.
      :param saveas: (Optional) The name(s) of the corresponding saved files, 
                     i.e. how to (localy) save each file in the ``files`` list.

      :returns:      A list of tuples, containing (each) the web file and
                     the (absolute path of) the saved file.

  '''
  if len(files) != len(saveas):
    raise RuntimeError('Download file list and save file list not equal')

  return_list = []

  for i, j in zip(files, saveas):
    webfile = os.path.join(url, i) ## not my os but whatever!
    try:
      response = urllib2.urlopen(webfile)
    except:
      raise RuntimeError('Failed to download file: %s' %webfile)
    with open(j, 'w') as f: f.write(response.read())
    return_list.append([webfile, os.path.abspath(j)])

  return return_list

def grabFtpFile(host, dirn, filen, saveas=None, username=None, password=None):
  ''' Download a file from an ftp server.

      :param host:     The host ip/hostname (e.g. ``ftp.unibe.ch``).
      :param dirn:     The directory in the host server, where the file 
                       is located (e.g. ``/aiub/CODE/``).
      :param filen:    The name of the file to download (e.g. ``COD18650.EPH.Z``).
      :param saveas:   (Optional) How to save the file in localhost (e.g. ``copy.txt``); 
                       if not set, the name ``filen`` will be used.
      :param username: (Optional) The username to connect to the ftp site (if any).
      :param password: (Optional) The password to connect to the ftp site (if any).

      :returns: In sucess, a tuple is returned; first element is the
                name of the saved file (absolute path), the second element
                is the name of the file on web.

      .. note::
        #. The (input) parameters ``dirn``, ``filen`` and ``saveas`` can be lists,
           in case we need to download multiple files from a common host. if 
           ``dirn`` has only one element, it is supposed that all files to 
           download are placed in the same remote directory; else the size of 
           ``dirn`` must match that of ``filen`` (and maybe ``saveas``). If 
           ``saveas`` is a string or a list with only one element (if 
           ``len(filen) > 1``) then it is treated as a **directory**
           and not a filename, i.e. the file are going to be saved as:
           os.path.join(saveas, filen[0]), os.path.join(saveas, filen[1]), ...
        #. See the documentation API for a detailed table of valid ``stype``
                values.

   '''
  ftp = ftplib.FTP(host)

  ## connect ...
  if username:
    if not password:
      raise RuntimeError('Given username but no password; error at webutils.grabFtpFile')
    ftp.login(username, password)
  else:
    ftp.login()

  if type(filen) is list:
    if not saveas:
      saveas = filen
    else:
      if type(saveas) is list and len(saveas) == len(filen):
        pass
      elif type(saveas) == str or (type(saveas) is list and len(saveas) == 1):
        saveas = [ os.path.join(saveas, x) for x in filen ]
      else:
        raise RuntimeError('Invalid arguments for ftp download (EX1)')
    if type(dirn) is list:
      if len(dirn) != len(filen):
        print 'length of dirn=%1i length of filen=%1i' %(len(dirn),len(filen))
        raise RuntimeError('Invalid arguments for ftp download (EX2)')
    else:
      dirn = len(filen)*[dirn]
  else:
    filen = [ filen ]
    dirn  = [ dirn ]
    if not saveas:
      saveas = filen
    else:
      saveas = [ saveas ]
  ##  now we should have:
  ##+ three lists (filen, saveas, dirn), all with the same # of elements, or

  sucess_dwl = []
  sucess_rmt = []

  prev_dir = dirn[0]
  ftp.cwd(prev_dir)
  for src_f, dst_f, dir_f in zip(filen, saveas, dirn):
    with open(dst_f, 'wb') as buf:
      try:
        if prev_dir != dir_f:
          ftp.cwd('/')
          ftp.cwd(dir_f)
          prev_dir = dir_f
        ftp.retrbinary('RETR %s'%src_f, buf.write, 1024)
        sucess_dwl.append(os.path.abspath(dst_f))
        sucess_rmt.append(os.path.join(host, dir_f, src_f))
      except:
        ftp.quit()
        try: os.remove(dst_f)
        except: print 'Failed to remove file %s' %dst_f
        raise RuntimeError('Failed to download file: %s' %(host + dir_f + src_f))

  ftp.quit()

  ##  protect legacy code in case all input arguments are strings
  if type(filen) != list:
    return sucess_dwl[0], sucess_rmt[0]

  return sucess_dwl, sucess_rmt