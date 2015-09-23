#! /usr/bin/python

'''
|===========================================|
|** Higher Geodesy Laboratory             **|
|** Dionysos Satellite Observatory        **|
|** National Tecnical University of Athens**|
|===========================================|

filename              : rnx_dnwl.py
version               : v-0.5
created               : JUN-2015

usage                 : Python routine to help the downloading of RINEX files.
                        This routine will connect to a database and return all
                        information needed to download a RINEX file

exit code(s)          : 0 -> success
                      : 1 -> error (command line arguments)
                      : 2 -> database server error

description           :

notes                 :

TODO                  :
bugs & fixes          :
last update           :

report any bugs to    :
                      : Xanthos Papanikolaou xanthos@mail.ntua.gr
                      : Demitris Anastasiou  danast@mail.ntua.gr
'''

## Import libraries
import sys
import os
import datetime
import subprocess
import getopt
import glob
import MySQLdb
import traceback

## Debug Mode
DDEBUG_MODE = True

## help function
def help (i):
    print ""
    print ""
    sys.exit(i)

## Global variables / default values
HOST_NAME   = '147.102.110.73'
USER_NAME   = 'bpe2'
PASSWORD    = 'webadmin'
DB_NAME     = 'procsta'
stations    = []
networks    = []
rename_marker = False
year        = 0
doy         = 0
outputdir   = ''
touppercase = False
uncompressZ = False
forceRemove = False

# a dictionary to hold start time (hours) for every session character
ses_identifiers = {
   0:'a',  1:'b',  2:'c',  3:'d',  4:'e', 5:'f',  6:'g',
   7:'h',  8:'i',  9:'j', 10:'k', 11:'l', 12:'m', 13:'n',
  14:'o', 15:'p', 16:'q', 17:'r', 18:'s', 19:'t', 20:'u',
  21:'v', 22:'w', 23:'x'
}

def executeShellCmd(command):
  ''' This function will execute a shell-like command
  '''
  
  try:
    p = subprocess.Popen(command, shell=True,
                         stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    output, err = p.communicate()
    returncode  = p.returncode
  # print >> sys.stderr, output
  # print >> sys.stderr, err
  except:
    raise ValueError('ERROR. Cannot execute command: ['+command+'].')
  if returncode:
    raise ValueError('ERROR. Command failed: ['+command+'].')

def UnixUncompress(inputf, outputf = '0'):
  ''' Uncompress the UNIX-compressed file inputf to outputf
  '''

  if outputf == '0':
    sys_command = 'uncompress -f ' + inputf
  else:
    sys_command = 'uncompress -f -c ' + inputf + ' > ' + outputf

  try:
    p = subprocess.Popen(sys_command, shell=True,
            stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    output, err = p.communicate()
    returncode = p.returncode
  except:
    raise ValueError('ERROR. Cannot uncompress file:'+inputf)
  if returncode:
    raise ValueError('ERROR. Cannot uncompress file:'+inputf)

def UnixCompress(inputf, outputf = '0'):
  ''' Compress the file inputf to outputf using UNIX-compress
  '''

  sys_command = 'compress -f' + inputf
  if (outputf != inputf) + '.Z' and (outputf != '0') :
    sys_command += '; mv ' + inputf + '.Z ' + outputf

  try:
    p = subprocess.Popen(sys_command, shell=True,
            stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    output, err = p.communicate()
    returncode = p.returncode
  except:
    raise ValueError('ERROR. Cannot compress file:'+inputf)
  if returncode:
    raise ValueError('ERROR. Cannot compress file:'+inputf)

def getRinexMarkerName(filename):
  ''' Given a rinex filename, this function will search the
      header to find and return the marker name.
      In case of error, an exception in thrown.
      If the file is (UNIX) compressed, i.e. ends with '.Z'
      then it is going to be de-compressed
  '''
  ufilename = filename

  if filename[-2:] == '.Z':
    ufilename = filename[0:len(filename)-2]
    UnixUncompress(filename,ufilename)

  with open(ufilename,'r') as fin:
    for line in fin.readlines():
      if line.strip()[60:] == 'MARKER NAME':
        return line[0:4]

  fin.close()
  raise ValueError('ERROR. No MARKER NAME in Rinex file:'+ufilename)

def setDownloadCommand(infolist,year='',doy='',month='',dom='',hour='',
        odir='',toUpperCase=False):
  ''' Given a list (of information) as returned by the database query (for one
        station), this function will examine the fields and compile the
        download command and the file to be saved. I.e the return type is
        [download_command, saved_file], both string elements.
        The saved file is included in the command (as argument in the '-O' switch,
        but it is also returned as the second element of the list for ease of use.

        Input params :
        year = 4-digit year (string)
        doy  = 3-digit day of year (string)
        month= 3-digit month (string), e.g. 'Jan'
        dom  = 2-digit day of month
        hour = 2-digit hour of day
        odir = path to where the file is to be saved (string) e.g. /home/bpe/foo/bar
        toUpperCase = truncate the saved file to uppercase characters

        The input array, must have the following fields:
        [0]  station_id (long int)
        [1]  station_name_DSO (4-char)
        [2]  station_name_OFF (4-char), i.e. official name
        [3]  station_name (long name/location), useful for URANUS network
        [4]  server_name (string)
        [5]  server_protocol (char), e.g. ftp, http, ssh
        [6]  server_domain
        [7]  path_to_30sec_rnx
        [8]  path_to_01sec_rnx
        [9]  username
        [10] password
        [11] network
        e.g. (29L, 'akyr', 'akyr', '', 'NTUA', 'ssh', '147.102.110.69', '/media/WD/data/COMET/_YYYY_/_DDD_/', '/media/WD/data/COMET/_YYYY_/_DDD_/', 'gpsdata', 'gevdais;ia')
    '''
  ## validate the number of fields
  if len(infolist) != 12:
    raise ValueError('ERROR. Invalid info list:'+infolist)

  ## depending on protocol, use scp or wget
  if infolist[5] == "ssh":
    command_ = "scp"
    if infolist[4] == "NTUA": command_ += " -P2754"
  else:
    command_ = "wget"
    if infolist[9]  != '': command_ += (' --user=' + infolist[9])
    if infolist[10] != '': command_ += (' --password=' + infolist[10])

  ## depending on protocol, set the server id
  if infolist[5] == "ssh":
    host_ = infolist[9] + '@' + infolist[6]
  elif infolist[5] == "ftp":
    host_ = 'ftp://' + infolist[6]
  elif infolist[5] == "http":
    host_ = 'http://' + infolist[6]
  elif infolist[5] == "https":
    host_ = 'https://' + infolist[6]
  else:
    raise ValueError('ERROR. Invalid server protocol:'+infolist[5])
  # remove last "/" in host (if any)
  if host_[-1] == '/' : host_ = host_[:-1]

  ## compile the path to the file
  path_ = infolist[7]
  if path_[0]  != '/' : path_ = '/' + path_
  if path_[-1] != '/' : path_ = path_ + '/'
  ## special case for uranus network
  if infolist[11] == 'uranus':
    try:
      ## path_ += infolist[3] + '/' + year[2:2] + '/' + dom + '/'
      path_ = path_.replace('_FULL_STA_NAME_',infolist[3])
      path_ = path_.replace('_MMMM_',month)
      path_ = path_.replace('_DOM_',dom)
    except:
      raise ValueError('ERROR. Failed to make URANUS path:'
         +infolist+' at '+year+'-'+month+'-'+dom)

  ## set the filename (to download)
  session_identifier = '0'
  if hour != '':
    if not hour in ses_identifiers :
      raise ValueError('ERROR. Invalid hour of day:', hour)
    else:
      session_identifier = ses_identifiers[hour];
  filename_ = infolist[2] + doy + session_identifier + '.' + year[2:] + 'd.Z'

  ## set the filename (to save)
  savef_ = filename_;
  if toUpperCase:
    savef_ = savef_.upper()
  if odir != '':
    if odir[-1] == '/': odir = odir[:-1]
    savef_ = odir + '/' + savef_

  ## return the command as string
  if infolist[5] == "ssh": ## scp -> saved file at the end (no -O switch)
    return (command_ + ' ' + host_ + path_ + filename_ + ' ' + savef_), savef_
  else:
    return (command_ + ' -O' + savef_ + ' ' + host_ + path_ + filename_), savef_

## Resolve command line arguments
def main (argv):

  if len(argv) < 1: help(1)

  try:
    opts, args = getopt.getopt(argv,'hs:n:ry:d:p:uzf',[
      'help','stations=','networks=','rename-marker','year=','doy=',
      'path=','uppercase','uncompress','fore-remove'])

  except getopt.GetoptError: help(1)

  for opt, arg in opts:
    if opt in ('-h', '--help'):
      help(0)
    elif opt in ('-s', '--stations'):
      station_list = arg.split(',')
      global stations
      stations += station_list
    elif opt in ('-n', '--networks'):
      network_list = arg.split(',')
      global networks
      networks += network_list
    elif opt in ('-r', '--rename-marker'):
      global rename_marker
      rename_marker = True
    elif opt in ('-f', '--force-remove'):
      global forceRemove
      forceRemove = True
    elif opt in ('-y', '--year'):
      global year
      year = arg
      #try:
      #  year = int(arg)
      #  except:
      #    print >> sys.stderr, 'Invalid year: %s'%arg
      #    sys.exit(1)
    elif opt in ('-d', '--doy'):
      global doy
      doy = arg
      #try:
      #  doy = int(arg)
      #except:
      #  print >> sys.stderr, 'Invalid day of year: %s', %arg
      #  sys.exit(1)
    elif opt in ('-u', '--uppercase'):
      global touppercase
      touppercase = True
    elif opt in ('-p', '--path'):
      global outputdir
      outputdir = arg
      if not os.path.exists(outputdir):
        print >> sys.stderr, 'ERROR. Directory does not exist: %s'%arg
        sys.exit(2)
    elif opt in ('-z', '--uncompress'):
      global uncompressZ
      uncompressZ = True
    else:
      print >> sys.stderr, 'Invalid command line argument: %s'%opt

## Start main
if __name__ == "__main__":
  main( sys.argv[1:] )

  ## Resolve the input date
  try:
    dt = datetime.datetime.strptime('%s-%s'%(int(year),int(doy)),'%Y-%j')
  except:
    print >> sys.stderr, 'Invalid date: year = %s doy = %s'%(year, doy)
    sys.exit(1)

  ## Month as 3-char, e.g. Jan (sMon)
  ## Month as 2-char, e.g. 01 (iMon)
  ## Day of month as 2-char, e.g. 05 (DoM)
  ## Day of year a 3-char, e.g. 157 (DoY)
  Year, sMon, iMon, DoM, DoY = dt.strftime('%Y-%b-%m-%d-%j').split('-')

  ##  This list is going to hold station-specific info, for every station to
  ##+ be downloaded
  station_info = []

  ## try connecting to the database server
  try:
    db  = MySQLdb.connect(host=HOST_NAME, user=USER_NAME, passwd=PASSWORD, db=DB_NAME)
    cur = db.cursor()

    ## ok, connected to db; now start quering for each station
    for s in stations:
      QUERY='SELECT station.station_id, station.mark_name_DSO, stacode.mark_name_OFF, stacode.station_name, ftprnx.dc_name, ftprnx.protocol, ftprnx.url_domain, ftprnx.pth2rnx30s, ftprnx.pth2rnx01s, ftprnx.ftp_usname, ftprnx.ftp_passwd, network.network_name FROM station JOIN stacode ON station.stacode_id=stacode.stacode_id JOIN dataperiod ON station.station_id=dataperiod.station_id JOIN ftprnx ON dataperiod.ftprnx_id=ftprnx.ftprnx_id JOIN  sta2nets ON sta2nets.station_id=station.station_id JOIN network ON network.network_id=sta2nets.network_id WHERE station.mark_name_DSO="%s" AND dataperiod.periodstart<"%s" AND dataperiod.periodstop>"%s";'%(s,dt.strftime('%Y-%m-%d'),dt.strftime('%Y-%m-%d'))
      cur.execute(QUERY)
      try:
        SENTENCE = cur.fetchall()
        # answer must only have one raw
        if len(SENTENCE) > 1:
          print >> sys.stderr, 'ERROR. More than one records matching for station %s'%s
        elif len(SENTENCE) < 1:
          print >> sys.stderr, 'ERROR. Cannot match station %s in the database.'%s
        else:
          station_info.append(SENTENCE[0])
      except:
        print >> sys.stderr, 'No matching station name in database for %s'%s

    # ok, now start asking for networks
    for w in networks:
      QUERY='SELECT station.station_id, station.mark_name_DSO, stacode.mark_name_OFF, stacode.station_name, ftprnx.dc_name, ftprnx.protocol, ftprnx.url_domain, ftprnx.pth2rnx30s, ftprnx.pth2rnx01s, ftprnx.ftp_usname, ftprnx.ftp_passwd, network.network_name FROM station JOIN stacode ON station.stacode_id=stacode.stacode_id JOIN dataperiod ON station.station_id=dataperiod.station_id JOIN ftprnx ON dataperiod.ftprnx_id=ftprnx.ftprnx_id JOIN  sta2nets ON sta2nets.station_id=station.station_id JOIN network ON network.network_id=sta2nets.network_id WHERE network.network_name="%s" AND dataperiod.periodstart<"%s" AND dataperiod.periodstop>"%s";'%(w,dt.strftime('%Y-%m-%d'),dt.strftime('%Y-%m-%d'))
      cur.execute(QUERY)
      try:
        SENTENCE = cur.fetchall()
        for row in SENTENCE: station_info.append(row)
      except:
        print >> sys.stderr, 'No matching station name in database for : %s'%s

  except:
    try: db.close()
    except: pass
    print >> sys.stderr, '***ERROR ! Cannot connect to database server.'
    exc_type, exc_value, exc_traceback = sys.exc_info ()
    lines = traceback.format_exception (exc_type, exc_value, exc_traceback)
    print ''.join('!!#' + line for line in lines)
    sys.exit(2)

  ## Goodbye database
  db.close()

  ##  All station specific information are stacked in the station_info array
  ##  get the command to be executed for each (including variables, e.g. _YYYY_)
  ##  and the list of the corresponding files to be saved.
  commands = []
  svfiles  = []
  for row in station_info:
    try:
      cmd, svfl = setDownloadCommand(row,
                Year,
                DoY,
                sMon,
                DoM,
                '',
                outputdir,
                touppercase)
      commands.append(cmd)
      svfiles.append(svfl)
    except ValueError as e:
      print >> sys.stderr, e.message

  ## Now, execute each command in the commands array to actually download
  ## the data.
  for cmd, sf in zip(commands,svfiles):
    ## replace variables (_YYYY_, _DDD_ )
    cmd = cmd.replace('_YYYY_', Year)
    cmd = cmd.replace('_DDD_', DoY);

    ## Execute the command
    ## WAIT !! do not download the file if it already exists AND has
    ## size > 0. Or just delete!
    if os.path.isfile(sf) and os.path.getsize(sf):
      if forceRemove:
        os.remove(sf)
      else:
         print '## File %s already exists. Skipping download.'%sf
    else:
      ## print 'Command = [',cmd,']'
      try:
        executeShellCmd(cmd)
      except ValueError as e:
        print >> sys.stderr, 'ERROR. Failed to download file: %s'%sf

    ## check for empty file
    if os.path.isfile(sf) and not os.path.getsize(sf):
      print >> sys.stderr, '## Removing empty file: %s'%sf
      os.remove(sf)

#    ## If specified, uncompress the downloaded files
#    if uncompressZ:
#        for fl in svfiles:
#            if os.path.isfile(fl) and (fl[-2:] == '.Z') :
#                try:
#                    UnixUncompress(fl)
#                except:
#                    print >> sys.stderr, 'ERROR. Failed to uncompress file:',fl

  ## db.close()
  sys.exit(0)
