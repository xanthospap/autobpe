#! /usr/bin/python

import ftplib
import os

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
                  name of the saved file, the second element is the name
                  of the file on web

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
        raise RuntimeError('Failed to change dir in ftp ['+host+'] -> '+dirn)

    if not saveas:
        saveas = filen
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
        raise RuntimeError('Failed to download file: ' + host + dirn + filen)

    ftp.quit()
    localfile.close()

    return saveas, '%s%s%s'%(host,dirn,filen)