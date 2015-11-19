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
                      : 1 -> error

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
import datetime
import MySQLdb
import traceback
import argparse

## Global variables / default values
USE_MARKER_NR = True
SUCCESS=0
FAILURE=1
EXIT_STATUS=SUCCESS

parser = argparse.ArgumentParser(description='Validate rinex/stations.')

##  database host name
parser.add_argument('--db-host',
                    action='store',
                    required=False,
                    default='147.102.110.73',
                    help='The hostname/ip of the MySQL server hosting the database.',
                    metavar='DB_HOST',
                    dest='DB_HOST')
##  database user name
parser.add_argument('--db-user',
                    action='store',
                    required=False,
                    default='hypatia',
                    help='The user asking permission to query the database.',
                    metavar='DB_USER',
                    dest='DB_USER')
##  database password
parser.add_argument('--db-pass',
                    action='store',
                    required=False,
                    default='ypat;ia',
                    help='The password to connect to the database.',
                    metavar='DB_PASS',
                    dest='DB_PASS')
##  database name 
parser.add_argument('--db-name',
                    action='store',
                    required=False,
                    default='procsta',
                    help='The name of the database to query.',
                    metavar='DB_NAME',
                    dest='DB_NAME')
##  The year (4-digit)
parser.add_argument('-y', '--year',
                    action='store',
                    required=True,
                    help='The year as a four-digit integer.',
                    metavar='YEAR',
                    dest='year')
##  The day of year (doy) 
parser.add_argument('-d', '--doy',
                    action='store',
                    required=True,
                    help='The day of year (doy) as integer.',
                    metavar='DOY',
                    dest='doy')
##  The .FIX file, i.e. the list of reference files 
parser.add_argument('-f', '--fix-file',
                    action='store',
                    required=True,
                    help='The .FIX file, i.e. the file holding the names of the'
                    'reference stations.',
                    metavar='FIX_FILE',
                    dest='fix_file')
##  The name of the network 
parser.add_argument('-n', '--network',
                    action='store',
                    required=True,
                    help='The name of the network.',
                    metavar='NETWORK',
                    dest='network')
##  The path to RINEX files 
parser.add_argument('-p', '--rinex-path',
                    action='store',
                    required=True,
                    help='The path to the rinex file to validate.',
                    metavar='PTH2RNX',
                    dest='pth2rnx') 
##  The session
parser.add_argument('-s', '--session',
                    action='store',
                    required=False,
                    default='0',
                    help='The session.',
                    metavar='SESSION',
                    dest='session') 
##  File with stations to exclude
parser.add_argument('-e', '--exclude-file',
                    action='store',
                    required=False,
                    help='A file with stations to be ecluded.',
                    metavar='EXCLUDE_FILE',
                    dest='exclude_file') 

##  Parse command line arguments
args = parser.parse_args()

##  list of stations to be excluded
if args.exclude_file is not None:
    with open( args.exclude_file, 'r' ) as f: exclude_lines = f.readlines()
else:
    exclude_lines = []

## validate cmd arguments
if not os.path.isfile( args.fix_file ):
    print >>sys.stderr, 'Invalid Reference fix file: %s'%( args.fix_file )
    sys.exit(1)
if not os.path.isdir( args.pth2rnx ):
    print >>sys.stderr, 'Invalid path to RINEX: %s'%( args.pth2rnx )
    sys.exit(1)
if len( args.session ) != 1:
    print >>sys.stderr, 'Invalid session identifier: %s'%( args.session )
    sys.exit(1)

## read all lines from the .FIX file
with open( args.fix_file, 'r' ) as f: lines = f.readlines()

## Resolve the input date
try:
    dt = datetime.datetime.strptime('%s-%s'%(int(args.year),int(args.doy)),
                                    '%Y-%j')
except:
    print >>sys.stderr, 'Invalid date: year = %s doy = %s'%(args.year, args.doy)
    sys.exit(1)

## Month as 3-char, e.g. Jan (sMon)
## Month as 2-char, e.g. 01 (iMon)
## Day of month as 2-char, e.g. 05 (DoM)
## Day of year a 3-char, e.g. 157 (DoY)
Year, Cent, sMon, iMon, DoM, DoY = dt.strftime('%Y-%y-%b-%m-%d-%j').split('-')

## try connecting to the database server
try:
    db  = MySQLdb.connect(host   = args.DB_HOST, 
                          user   = args.DB_USER, 
                          passwd = args.DB_PASS, 
                          db     = args.DB_NAME)
    cur = db.cursor()

    QUERY='SELECT stacode.mark_name_DSO, stacode.mark_name_OFF, stacode.mark_numb_OFF, stacode.station_name FROM stacode JOIN station ON stacode.stacode_id=station.stacode_id JOIN  sta2nets ON sta2nets.station_id=station.station_id JOIN network ON network.network_id=sta2nets.network_id WHERE network.network_name="%s";'%( args.network )

    cur.execute( QUERY )
    SENTENCE = cur.fetchall()
    '''
    the answer should be a list of tuples, where each station of the network
    reports its name(DSO), name(official), number(official) full_name(?), e.g.
    ('pdel', 'pdel', '31906M004', '')
    '''
    print '%-15s %-16s %-9s %-9s %-8s'\
        %("RINEX", "MARKER NAME", "AVAILABLE", "REFERENCE", "EXCLUDED")
    for tpl in SENTENCE:
        rnx_file      = os.path.join(args.pth2rnx, 
                      tpl[0] + ('%s%s.%sd.Z'%(DoY, args.session, Cent)) )
        marker_name   = tpl[1]
        marker_number = tpl[2]
        rnx_exists    = 'No' ##  initial guess ...
        rnx_is_ref    = 'No' ##  initial guess ...
        rnx_is_excl   = 'No' ##  initial guess ...

        if USE_MARKER_NR:
            used_name = '%s %s'%(marker_name, marker_number)
        else:
            used_name = '%s' %(marker_name)

        if len(marker_name) != 4:
            print >> sys.stderr, 'ERROR ! Invalid marker number %s for station %s'%(marker_name, tpl[0])
            raise RuntimeError('')

        if os.path.isfile( rnx_file ): rnx_exists = 'Yes'
        
        if filter( lambda x: re.search(r'^%s\s+'%(used_name.upper()), x), lines):
            rnx_is_ref = 'Yes'

        if filter( lambda x: re.search(r'^%s\s*'%(used_name.upper().strip()), x), exclude_lines):
            rnx_is_excl = 'Yes'
      
        print '%-15s %-16s %-9s %-9s %-8s'%(os.path.basename(rnx_file), used_name.upper(), rnx_exists, rnx_is_ref, rnx_is_excl)

except:
    try: db.close()
    except: pass
    print >> sys.stderr, '***ERROR ! Cannot connect/query database server.'
    EXIT_STATUS = FAILURE

sys.exit( EXIT_STATUS )
