import os
import ftplib
import urllib2
import gzip
import shutil

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

  if url[-1] == '/': url = url[:-1]

  return_list = []

  for i, j in zip(files,saveas):
    webfile = url + ('/%s' %(i))
    try:
      response = urllib2.urlopen(webfile)
    except:
      raise RuntimeError('Failed to download file: %s' %webfile)
    with open(j, 'w') as f:
      f.write(response.read())
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

      .. note:: See the documentation API for a detailed table of valid ``stype``
                values.

   '''
  if host[-1] == '/' : host = host[:-1]
  if dirn[0]  != '/' : dirn = '/' + dirn
  if dirn[-1] != '/' : dirn += '/'
  if filen[0] == '/' : filen = filen[:-1]

  ftp = ftplib.FTP(host)

  if username:
    if not password:
      raise RuntimeError('Given username but no password; error at webutils.grabFtpFile')
    ftp.login(username, password)
  else:
    ftp.login()

  try:
    ftp.cwd(dirn)
  except:
    raise RuntimeError('Failed to change dir in ftp [%s] -> [%s]' %(host,dirn))

  if not saveas: saveas = filen

  localfile = open(saveas, 'wb')
 
  try:
    ftp.retrbinary('RETR %s' %filen, localfile.write, 1024)
  except:
    ftp.quit()
    ## remove corrupt file
    try:
      localfile.close()
      if os.path.isfile(saveas):
        os.remove(saveas)
    except:
      pass
    raise RuntimeError('Failed to download file: %s' %(host + dirn + filen))

  ftp.quit()
  localfile.close()

  return os.path.abspath(saveas), '%s%s%s'%(host, dirn, filen)

# one go (de)compress of files
def de_compress_file(source_file):
    ''' compress or decompress a file (in one go);
        depending on the filename extension, ".gz" is appended to or deleted
        from the filename
    '''
    if source_file[-3:] == ".gz" or source_file[-2:] == ".Z":
        dst = source_file[:source_file.index(".", -4)]
        with gzip.open(source_file, 'rb') as input_file, \
                open(source_file[:-3], 'wb') as output_file:
            shutil.copyfileobj(input_file, output_file)
    else:
        with open(source_file, 'rb') as input_file, \
                gzip.open('.'.join((source_file, 'gz')), 'wb') as output_file:
            shutil.copyfileobj(input_file, output_file)

    return 0