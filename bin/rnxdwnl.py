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
import sys, os, re
import shutil
import datetime
import subprocess
import glob
import MySQLdb
import traceback
import argparse

## Global variables / default values

# a dictionary to hold start time (hours) for every session character
ses_identifiers = {
   0:'a',  1:'b',  2:'c',  3:'d',  4:'e', 5:'f',  6:'g',
   7:'h',  8:'i',  9:'j', 10:'k', 11:'l', 12:'m', 13:'n',
  14:'o', 15:'p', 16:'q', 17:'r', 18:'s', 19:'t', 20:'u',
  21:'v', 22:'w', 23:'x'
}

def vprint( message, min_verb_level, std_buf=None ):
    if std_buf is None : std_buf = sys.stdout
    if args.verbosity >= min_verb_level: print >> std_buf, message

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
      raise ValueError('ERROR. Cannot execute command: [%s].'%command)
  if returncode:
      raise ValueError('ERROR. Command failed: [%s].'%command)

def UnixUncompress(inputf, outputf=None):
    ''' Uncompress the UNIX-compressed file 'inputf' to 'outputf'
        Return the uncompressed file-name
    '''
    if not outputf:
        sys_command = 'uncompress -f %s'%inputf
        dotZfile    = '%s'%inputf[:-2]
    else:
        sys_command = 'uncompress -f -c %s > %s'%(inputf, outputf)
        dotZfile    = '%s'%outputf

    try:
        p = subprocess.Popen(sys_command, shell=True,
            stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        output, err = p.communicate()
        returncode  = p.returncode
    except:
        raise ValueError('ERROR. Cannot uncompress file: %s'%inputf)

    if returncode:
        raise ValueError('ERROR. Cannot uncompress file: %s'%inputf)

    return dotZfile

def UnixCompress(inputf, outputf=None):
    ''' Compress the file inputf to outputf using UNIX-compress.
      The function will return the name of the compressed file.
    '''
    sys_command = 'compress -f %s'%inputf
    dotZfile    = '%s.Z'%inputf

    if outputf:
        sys_command += '; mv %s.Z %s'%(inputf, outputf)
        dotZfile    = '%s'%outputf

    try:
        p = subprocess.Popen(sys_command, shell=True,
            stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        output, err = p.communicate()
        returncode  = p.returncode
    except:
        raise ValueError('ERROR. Cannot compress file: %s'%inputf)

    if returncode:
        raise ValueError('ERROR. Cannot compress file: %s'%inputf)

    return dotZfile

def getRinexMarkerName(filename):
    ''' Given a rinex filename, this function will search the
      header to find and return the marker name.
      In case of error, an exception in thrown.
      If the file is (UNIX) compressed, i.e. ends with '.Z'
      then it is going to be de-compressed
    '''
    ufilename = filename

    if filename[-2:] == '.Z': ufilename = UnixUncompress(filename)

    with open(ufilename, 'r') as fin:
        for line in fin.readlines():
            if line.strip()[60:71] == 'MARKER NAME':
                return line[0:4], ufilename
    return '', ufilename

def subMarkerName( filename, marker_name ):
    marker_in_rinex, rinex_filename = getRinexMarkerName( filename )
    if marker_in_rinex == '':
        print >> sys.stderr, '[ERROR] Cannot find \'MARKER NAME\' in Rinex file \'%s\''%(rinex_filename)
    if marker_in_rinex != marker_name :
        vprint('[DEBUG] Changing marker name from \'%s\' to \'%s\' for \'%s\''%(marker_in_rinex, marker_name, rinex_filename), 1)
        with open(rinex_filename, 'r') as fin:
            with open(rinex_filename+'.tmp', 'w') as fout:
                for line in fin.readlines():
                    if re.match('^%s.*\sMARKER NAME\s*$'%marker_in_rinex, line):
                        print >> fout,'%s                                                        MARKER NAME'%(marker_name)
                    else:
                        print >> fout, line.rstrip('\n')
        shutil.move( rinex_filename+'.tmp', rinex_filename )

    return rinex_filename

def setDownloadCommand(infolist, dtime, hour=None, odir=None, toUpperCase=False):
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
    raise ValueError('ERROR. Invalid info list: [%s]'%str(infolist))

  year, doy, month, dom = dtime.strftime('%Y-%j-%b-%d').split('-')

  ## depending on protocol, use scp or wget
  if infolist[5] == 'ssh':
    command_ = 'scp'
    if infolist[4] == 'NTUA': command_ += " -P2754"
  else:
    command_ = 'wget'
    if infolist[4]  == 'TREECOMP' or infolist[4] == 'TREECOMP2': 
        command_ += ' --no-passive-ftp'
    if infolist[9]  != '': command_ += (' --user=' + infolist[9])
    if infolist[10] != '': command_ += (' --password=' + infolist[10])

  ## depending on protocol, set the server id
  if infolist[5] == 'ssh':
    host_ = infolist[9] + '@' + infolist[6]
  elif infolist[5] == 'ftp':
    host_ = 'ftp://' + infolist[6]
  elif infolist[5] == 'http':
    host_ = 'http://' + infolist[6]
  elif infolist[5] == 'https':
    host_ = 'https://' + infolist[6]
  else:
    raise ValueError('ERROR. Invalid server protocol: [%s]'%infolist[5])
  # remove last "/" in host (if any)
  if host_[-1] == '/' : host_ = host_[:-1]

  ## compile the path to the file
  path_ = infolist[7]
  
  ## special case for uranus network
  if infolist[4] == 'TREECOMP' or infolist[4] == 'TREECOMP2' :
    try:
      ## path_ += infolist[3] + '/' + year[2:2] + '/' + dom + '/'
      path_ = path_.replace('_FULL_STA_NAME_',infolist[3])
      path_ = path_.replace('_MMMM_',month)
      path_ = path_.replace('_DOM_',dom)
    except:
      raise ValueError('ERROR. Failed to make URANUS path: [%s]'%(infolist))
  if path_[0] == '/': path_ = path_[1:]

  ## set the filename (to download)
  session_identifier = '0'
  if hour != None:
    print '[WARNING] Using hour-dependent info!'
    if not hour in ses_identifiers :
      raise ValueError('ERROR. Invalid hour of day: %s'%hour)
    else:
      session_identifier = ses_identifiers[hour];
  filename_ = infolist[2] + doy + session_identifier + '.' + year[2:] + 'd.Z'
  if filename_[0] == '/': filename_ = filename_[1:]

  ## set the filename (to save)
  savef_ = filename_;
  if toUpperCase:
    savef_ = savef_.upper()
  if odir != '':
    if odir[-1] == '/': odir = odir[:-1]
    savef_ = odir + '/' + savef_

  ## return the command as string
  if infolist[5] == "ssh": ## scp -> saved file at the end (no -O switch)
    return (command_ + ' ' + os.path.join(host_, path_, filename_) + ' ' + savef_), savef_
  else:
    return (command_ + ' -O ' + savef_ + ' ' + os.path.join(host_, path_, filename_)), savef_

##  set the cmd parser
parser = argparse.ArgumentParser(
        description='Download RINEX files for any station/network included in'
        'a given database.',
        epilog     ='Ntua - 2015'
        )
##  input station list
parser.add_argument('-s', '--stations',
    nargs    = '*',
    action   = 'store',
    required = False,
    help     = 'A whitespace seperated list of stations to download. The given names'
    'are checked against the \"4-char ID\" in the database.',
    metavar  = 'STATION_LIST',
    dest     = 'stations',
    default  = []
    )
##  input network names
parser.add_argument('-n', '--networks',
    nargs    = '*',
    action   = 'store',
    required = False,
    help     = 'A whitespace seperated list of networks to download. The given names'
    'are checked against the \"??\" in the database.',
    metavar  = 'NETWORK_LIST',
    dest     = 'networks',
    default  = []
    )
##  year
parser.add_argument('-y', '--year',
    action   = 'store',
    required = True,
    type     = int,
    help     = 'The year for which you want the station (integer).',
    metavar  = 'YEAR',
    dest     = 'year'
    )
##  day of year (doy)
parser.add_argument('-d', '--doy',
    action   = 'store',
    required = True,
    type     = int,
    help     = 'The day of year for which you want the station (integer).',
    metavar  = 'DOY',
    dest     = 'doy'
    )
##  download path
parser.add_argument('-p', '--path',
    action   = 'store',
    required = False,
    help     = 'The directory where the downloaded files shall be placed.',
    metavar  = 'OUTPUT_DIR',
    dest     = 'output_dir',
    default  = os.getcwd()
    )
##  verbosity level
parser.add_argument('-v', '--verbosity',
    action   = 'store',
    required = False,
    type     = int,
    help     = 'Output verbosity level; if set to null (default value) no message'
    'is written on screen. If the level is set to 2, all messages appear on'
    'stdout.',
    metavar  = 'VERBOSITY',
    dest     = 'verbosity',
    default  = 0
    )
##  rename marker
parser.add_argument('-r', '--marker-rename',
    action   = 'store_true',
    help     = 'If this flag is set, then every downloaded rinex will be instpected'
    'for the \'MARKER NAME\' field. If it is different from the DSO name, then'
    'it will be altered.',
    dest     = 'rename_markers'
    )
## force remove any previous rinex that match the one (to be) downloaded 
parser.add_argument('--force-remove',
    action   = 'store_true',
    help     = 'If this flag is set, then before every download the script will'
    'search for a matching RINEX file in the given path; e.g. for station \'DYNG\''
    'it will search for \'dyngddds0.yyd.Z\', \'dyngddds0.yyd\', \'dyngddds0.yyo\''
    ' and if found, they will be removed.',
    dest     = 'force_remove'
    )
##  Database host-name/ip
parser.add_argument('--db-host',
    action   = 'store',
    required = True,
    help     = 'The host of the database to query.',
    metavar  = 'DB_HOST',
    dest     = 'db_host',
    default  = ''
    )
##  Database user 
parser.add_argument('--db-user',
    action   = 'store',
    required = True,
    help     = 'The username for the database to query.',
    metavar  = 'DB_USER',
    dest     = 'db_user',
    default  = ''
    )
##  Database password
parser.add_argument('--db-pass',
    action   = 'store',
    required = True,
    help     = 'The password for the database to query.',
    metavar  = 'DB_PASS',
    dest     = 'db_pass',
    default  = ''
    )
##  Database name 
parser.add_argument('--db-name',
    action   = 'store',
    required = True,
    help     = 'The name of the database to query.',
    metavar  = 'DB_NAME',
    dest     = 'db_name',
    default  = ''
    )

##  Parse command line arguments
args = parser.parse_args()

## Resolve the input date
try:
    dt = datetime.datetime.strptime( '%s-%s'%(args.year, args.doy), '%Y-%j' )
except:
    print >> sys.stderr, 'ERROR. Invalid date: year [%4i] doy = [%3i]'\
        %( args.year, args.doy )
    sys.exit(1)

## Month as 3-char, e.g. Jan (sMon)
## Month as 2-char, e.g. 01 (iMon)
## Day of month as 2-char, e.g. 05 (DoM)
## Day of year a 3-char, e.g. 157 (DoY)
Year, Cent, sMon, iMon, DoM, DoY = dt.strftime('%Y-%y-%b-%m-%d-%j').split('-')

##  This list is going to hold station-specific info, for every station to
##+ be downloaded
station_info = []

  ## try connecting to the database server
try:
    db  = MySQLdb.connect(
            host   = args.db_host, 
            user   = args.db_user, 
            passwd = args.db_pass, 
            db     = args.db_name
        )

    cur = db.cursor()

    ## ok, connected to db; now start quering for each station
    for s in args.stations :
        QUERY='SELECT station.station_id, station.mark_name_DSO, stacode.mark_name_OFF, stacode.station_name, ftprnx.dc_name, ftprnx.protocol, ftprnx.url_domain, ftprnx.pth2rnx30s, ftprnx.pth2rnx01s, ftprnx.ftp_usname, ftprnx.ftp_passwd, network.network_name FROM station JOIN stacode ON station.stacode_id=stacode.stacode_id JOIN dataperiod ON station.station_id=dataperiod.station_id JOIN ftprnx ON dataperiod.ftprnx_id=ftprnx.ftprnx_id JOIN  sta2nets ON sta2nets.station_id=station.station_id JOIN network ON network.network_id=sta2nets.network_id WHERE station.mark_name_DSO="%s" AND dataperiod.periodstart<"%s" AND dataperiod.periodstop>"%s";'%(s,dt.strftime('%Y-%m-%d'),dt.strftime('%Y-%m-%d'))
        
        cur.execute( QUERY )

        try:
            SENTENCE = cur.fetchall()
            # answer must only have one raw
            if len(SENTENCE) > 1:
                ## station belongs to more than one networks; see bug #13
                vprint('[DEBUG] station \"%s\" belongs to more than one networks.'%s, 2, sys.stdout )
                add_sta = True
                ref_line = SENTENCE[0]
                for line in SENTENCE[1:]:
                    for idx, field in enumerate( ref_line[0:10] ):
                        if field != line[idx]:
                            add_sta = False
                            vprint('[WARNING] Station \"%s\" belongs to more than one networks but independent fields don\'t match!'%s, 1, sys.stderr)
                            vprint('[WARNING] Station \"%s\" will be skipped'%s, 1, sys.stderr)
                if add_sta is True :
                    vprint('[DEBUG] station \"%s\" added to download list.'%s, 2, sys.stdout)
                    station_info.append( SENTENCE[0] )
            elif len(SENTENCE) == 0:
                vprint('[WARNING] Cannot match station \"%s\" in the database.'%s, 1, sys.stderr)
            else:
                station_info.append( SENTENCE[0] )
        except:
            vprint('[WARNING] No matching station name in database for \"%s\".'%s, 1, sys.stderr)

    # ok, now start asking for networks
    for w in args.networks :
        QUERY='SELECT station.station_id, station.mark_name_DSO, stacode.mark_name_OFF, stacode.station_name, ftprnx.dc_name, ftprnx.protocol, ftprnx.url_domain, ftprnx.pth2rnx30s, ftprnx.pth2rnx01s, ftprnx.ftp_usname, ftprnx.ftp_passwd, network.network_name FROM station JOIN stacode ON station.stacode_id=stacode.stacode_id JOIN dataperiod ON station.station_id=dataperiod.station_id JOIN ftprnx ON dataperiod.ftprnx_id=ftprnx.ftprnx_id JOIN  sta2nets ON sta2nets.station_id=station.station_id JOIN network ON network.network_id=sta2nets.network_id WHERE network.network_name="%s" AND dataperiod.periodstart<"%s" AND dataperiod.periodstop>"%s";'%(w,dt.strftime('%Y-%m-%d'),dt.strftime('%Y-%m-%d'))
        
        cur.execute( QUERY )
        
        try:
            SENTENCE = cur.fetchall()
            for row in SENTENCE: station_info.append( row )
        except:
            vprint('[WARNING] No matching station name in database for \"%s\".'%s, 1, sys.stderr)

except:
    # try:    db.close()
    # except: pass
    vprint('[ERROR] Cannot connect to database server.', 0, sys.stderr )
    exc_type, exc_value, exc_traceback = sys.exc_info ()
    lines = traceback.format_exception (exc_type, exc_value, exc_traceback)
    error_mes =  ''.join('!!#' + line for line in lines)
    vprint ( error_mes, 0, sys.stderr )
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
        cmd, svfl = setDownloadCommand( row, dt, None, args.output_dir, False )
        commands.append( cmd )
        svfiles.append( svfl )
    except ValueError as e:
        print >> sys.stderr, e.message

    ## Now, execute each command in the commands array to actually download
    ## the data.
    for cmd, sf in zip( commands, svfiles ):
        ## replace variables (_YYYY_, _DDD_ )
        cmd = cmd.replace('_YYYY_', Year)
        cmd = cmd.replace('_DDD_', DoY)
        cmd = cmd.replace('_YY_', Cent)

    ## Execute the command
    ## WAIT !! do not download the file if it already exists AND has
    ## size > 0. Or just delete!
    rinex_already_exists = False
    possible_duplicates = [ 
                sf, 
                sf.replace('.Z', ''  ), 
                sf.replace('d.Z', 'd'),
                sf.replace('d.Z', 'o')
                ]
    for pd in possible_duplicates : 
        if os.path.isfile( pd ) and os.path.getsize( pd ):
            if args.force_remove:
                vprint ('[DEBUG] Removing rinex file \'%s\'.'%pd, 1, sys.stdout)
                os.remove( pd )
            else:
                vprint('[DEBUG] File \"%s\" already exists. Skipping download.'%sf, 1, sys.stdout)
                rinex_already_exists = True
                sf = pd
            break
    
    if not rinex_already_exists :
        vprint('[DEBUG] Command = \"%s\", station = \"%s\"'%(cmd, sf), 2, sys.stdout)
        try:
            executeShellCmd( cmd )
        except ValueError as e:
            vprint('[ERROR] Failed to download file \"%s\"'%sf, 1, sys.stderr)

    ## check for empty file
    if os.path.isfile( sf ) and not os.path.getsize( sf ):
        vprint('[DEBUG] Removing empty file \"%s\"'%sf, 2, sys.stderr)
        os.remove( sf )
        
    if os.path.isfile( sf ):
        ## if needed, check/repair the marker name
        if args.rename_markers: subMarkerName( sf, row[1].upper() )

sys.exit(0)
