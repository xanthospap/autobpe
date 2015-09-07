import ftplib
import urllib2
import os

def grabHttpFile(url, files, saveas):
  ''' Download file(s) from an http webserver.

      :param url:    The server's address; do not append the
                     the filename to be downloaded.
      :param files:  A list of files to be downloaded from the
                     given url.
      :param saveas: The name(s) of the corresponding saved files, i.e. how to
                     (localy) save each file in the ``files`` list.

      :returns:      A list of tuples, containing (each) the web file and
                     the (absolute path of) the saved file.
      
      The next code block will download the files 'http://my.server.org/foo/bar/file1.txt'
      and save it to '/home/lol/sf1.txt' and also download 'http://my.server.org/foo/bar/file2.txt'
      and save it to '$(PWD)/sf2.txt'.

      .. code-block:: python

         file_list  = ['file1.txt', 'file2.txt']
         saved_list = ['/home/lol/sf1.txt', 'sf2.txt']
         lst = grebHttpFile('http://my.server.org/foo/bar', file_list, saved_list)

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

def grabFtpFile(host,dirn,filen,saveas=None,username=None,password=None):
  ''' Download a file from an ftp server.

      :param host:   The host ip (e.g. ``ftp.unibe.ch``).
      :param dirn:   The directory in the host server, where the file 
                     is located (e.g. ``/aiub/CODE/``).
      :param filen:  The name of the file to download (e.g. ``COD18650.EPH.Z``).
      :param saveas: How to save the file in localhost (e.g. ``copy.txt``); 
                     if not set, the name ``filen`` will be used.
      :param username: The username to connect to the ftp site (if any).
      :param password: The password to connect to the ftp site (if any).

      :returns: In sucess, a tuple is returned; first element is the
                name of the saved file (absolute path), the second element
                is the name of the file on web.
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
      if os.path.isfile(localfile):
          os.remove(localfile)
    except:
      pass
    raise RuntimeError('Failed to download file: %s' %(host + dirn + filen))

  ftp.quit()
  localfile.close()

  return os.path.abspath(saveas), '%s%s%s'%(host,dirn,filen)