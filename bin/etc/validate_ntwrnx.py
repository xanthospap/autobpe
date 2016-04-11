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
import glob
import json

## Global variables / default values
USE_MARKER_NR = True
SUCCESS=0
FAILURE=1
EXIT_STATUS=SUCCESS

##  get marker name from RINEX
def get_marker_name(rinex):
    with open(rinex, 'r') as fin:
        for line in fin.readlines():
            if line.strip()[60:71] == 'MARKER NAME':
                return line[0:4].rstrip()
    return ''

def get_marker_number(rinex):
    with open(rinex, 'r') as fin:
        for line in fin.readlines():
            if line.strip()[60:73] == 'MARKER NUMBER':
                return line[0:20].rstrip()
    return ''

parser = argparse.ArgumentParser(description='Validate rinex/stations.')

##  database host name
parser.add_argument('--db-host',
        action    = 'store',
        required  = True,
        default   = '',
        help      = 'The hostname/ip of the MySQL server hosting the database.',
        metavar   = 'DB_HOST',
        dest      = 'db_host')

##  database user name
parser.add_argument('--db-user',
        action   = 'store',
        required = True,
        default  = '',
        help     = 'The user asking permission to query the database.',
        metavar  = 'DB_USER',
        dest     = 'db_user')

##  database password
parser.add_argument('--db-pass',
        action   = 'store',
        required = True,
        default  = '',
        help     = 'The password to connect to the database.',
        metavar  = 'DB_PASS',
        dest     = 'db_pass')

##  database name 
parser.add_argument('--db-name',
        action   = 'store',
        required = True,
        default  = '',
        help     = 'The name of the database to query.',
        metavar  = 'DB_NAME',
        dest     = 'db_name')

##  The year (4-digit)
parser.add_argument('-y', '--year',
        action   = 'store',
        required = True,
        help     = 'The year as a four-digit integer.',
        metavar  = 'YEAR',
        dest     = 'year')

##  The day of year (doy) 
parser.add_argument('-d', '--doy',
        action   = 'store',
        required = True,
        help     = 'The day of year (doy) as integer.',
        metavar  = 'DOY',
        dest     = 'doy')

##  The .FIX file, i.e. the list of reference files 
parser.add_argument('-f', '--fix-file',
        action   = 'store',
        required = True,
        help     = 'The .FIX file, i.e. the file holding the names of the'
        'reference stations.',
        metavar  = 'FIX_FILE',
        dest     = 'fix_file')

##  The name of the network 
parser.add_argument('-n', '--network',
        action   = 'store',
        required = True,
        help     = 'The name of the network.',
        metavar  = 'NETWORK',
        dest     = 'network')

##  The path to RINEX files 
parser.add_argument('-p', '--rinex-path',
        action   = 'store',
        required = True,
        help     = 'The path to the rinex file to validate.',
        metavar  = 'PTH2RNX',
        dest     = 'pth2rnx') 

##  The session
parser.add_argument('-s', '--session',
        action   = 'store',
        required = False,
        default  = '0',
        help     = 'The session.',
        metavar  = 'SESSION',
        dest     = 'session') 

##  Skip the database query
parser.add_argument('--skip-database',
        action   = 'store_true',
        help     = 'Skip the database query.',
        dest     = 'skip_database')

##  File with stations to exclude
parser.add_argument('-e', '--exclude-file',
        action   = 'store',
        required = False,
        help     = 'A file with stations to be ecluded.',
        metavar  = 'EXCLUDE_FILE',
        dest     = 'exclude_file')

##  also output an html table
parser.add_argument('--html',
        action   = 'store_true',
        help     = 'Also output an html table, named \"validate_rnx.html\".',
        dest     = 'make_html')

##  also output in json format
parser.add_argument('--json',
        action   = 'store_true',
        help     = 'Also output info in json format, named \"validate_rnx.json\".',
        dest     = 'make_json')

##  Parse command line arguments
args = parser.parse_args()

##  list of stations to be excluded
if args.exclude_file is not None:
    with open(args.exclude_file, 'r') as f: exclude_lines = f.readlines()
else:
    exclude_lines = []

## validate cmd arguments
if not os.path.isfile(args.fix_file):
    print >>sys.stderr, '[ERROR] Invalid Reference fix file: %s'%(args.fix_file)
    sys.exit(1)
if not os.path.isdir(args.pth2rnx):
    print >>sys.stderr, '[ERROR] Invalid path to RINEX: %s'%(args.pth2rnx)
    sys.exit(1)
if len(args.session) != 1:
    print >>sys.stderr, '[ERROR] Invalid session identifier: %s'%(args.session)
    sys.exit(1)

## read all lines from the .FIX file
with open(args.fix_file, 'r') as f: lines = f.readlines()

## Resolve the input date
try:
    dt = datetime.datetime.strptime('%s-%s'%(int(args.year),int(args.doy)),
                                    '%Y-%j')
except:
    print >>sys.stderr, '[ERROR] Invalid date: year = %s doy = %s'%(args.year, args.doy)
    sys.exit(1)

## Month as 3-char, e.g. Jan (sMon)
## Month as 2-char, e.g. 01 (iMon)
## Day of month as 2-char, e.g. 05 (DoM)
## Day of year a 3-char, e.g. 157 (DoY)
Year, Cent, sMon, iMon, DoM, DoY = dt.strftime('%Y-%y-%b-%m-%d-%j').split('-')

## if we are writing html ...
if args.make_html:
    htmlout = open('validate_rnx.html', 'w')
    print >>htmlout, "<table style=\"width:100%\">"

## if we are wrinting json ...
if args.make_json:
    jsonout   = open('validate_rnx.json', 'w')
    json_list = []

##  Skip database
if args.skip_database :
    ## get a list of all RINEX file in the rinex folder (args.pth2rnx)
    generic_rinex='????%s0.%s[oO]'%(DoY, Cent)
    rinex_list = [ os.path.abspath(x) for x in glob.glob( os.path.join(args.pth2rnx, generic_rinex) ) ]
    if len(rinex_list) == 0:
        print >> sys.stderr, '[ERROR] No RINEX files found in \"%s\".'%(args.pth2rnx)
        sys.exit( 1 )
    print '%-15s %-16s %-9s %-9s %-8s'\
        %("RINEX", "MARKER NAME", "AVAILABLE", "REFERENCE", "EXCLUDED")
    if args.make_html:
        print >>htmlout, "<tr><th>RINEX</th><th>MARKER NAME</th><th>AVAILABLE</th><th>REFERENCE</th><th>EXCLUDED</th></tr>"
    for rnx in rinex_list :
        rnx_name = os.path.basename(rnx)
        rnx_path = os.path.dirname(rnx)
        RNX_FILE = os.path.join(rnx_path, rnx_name.upper())
        rnx_file = os.path.join(rnx_path, rnx_name.lower())
        if RNX_FILE != rnx : shutil.move(rnx, RNX_FILE)
        marker_name   = get_marker_name(RNX_FILE)
        marker_number = get_marker_number(RNX_FILE)
        if marker_name == '':
            print >> sys.stderr, '[ERROR] Failed to read RINEX marker name for \"%s\"'%(RNX_FILE)
            sys.exit(1)
        used_name  = '%s %s'%(marker_name, marker_number)
        rnx_is_ref = 'No'
        rnx_is_excl= 'No'
        rnx_exists = 'Yes'
        if filter( lambda x: re.search(r'^%s\s+'%(used_name.upper()), x), lines):
            rnx_is_ref = 'Yes'
        if filter( lambda x: re.search(r'^%s\s*'%(used_name.upper().strip()), x), exclude_lines):
            rnx_is_excl = 'Yes'
            ## Rename to lower so that it doesn't get used !
            shutil.move( RNX_FILE, rnx_file )
            RNX_FILE    = rnx_file
        print '%-15s %-16s %-9s %-9s %-8s'%(os.path.basename(RNX_FILE), used_name.upper(), rnx_exists, rnx_is_ref, rnx_is_excl)
        if args.make_html:
            print >>htmlout, "<tr><td>%s</td><td>%s</td><td>%s</td><td>%s</td><td>%s</td></tr>"%(os.path.basename(RNX_FILE), used_name.upper(), rnx_exists, rnx_is_ref, rnx_is_excl)

        if args.make_json:
            json_list.append( {"rinex": os.path.basename(RNX_FILE), "station": used_name.upper().strip(), "available": rnx_exists, "reference": rnx_is_ref, "exclude": rnx_is_excl} )

    sys.exit( 0 )

## try connecting to the database server
try:
    db  = MySQLdb.connect(host   = args.db_host, 
                          user   = args.db_user, 
                          passwd = args.db_pass, 
                          db     = args.db_name)
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
    if args.make_html:
        print >>htmlout, "<tr><th>RINEX</th><th>MARKER NAME</th><th>AVAILABLE</th><th>REFERENCE</th><th>EXCLUDED</th></tr>"
    for tpl in SENTENCE:
        ## Rinex can be:
        ## Hatanaka & UNIX compressed,
        ## Hatanaka and not UNIX compressed
        ## plain, uncompressed RINEX
        rnx_fn_a      = tpl[0] + ('%s%s.%sd.Z'%(DoY, args.session, Cent))
        rnx_fn_b      = tpl[0] + ('%s%s.%sd'%(DoY, args.session, Cent))
        rnx_fn_c      = tpl[0] + ('%s%s.%so'%(DoY, args.session, Cent))
        possible_rinex= [ os.path.join(args.pth2rnx, x) 
                        for x in [rnx_fn_a, rnx_fn_b, rnx_fn_c] ]
        #rnx_file      = os.path.join(args.pth2rnx, rnx_filename)
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
            print >> sys.stderr, '[ERROR] Invalid marker number %s for station %s'%(marker_name, tpl[0])
            raise RuntimeError('')

        rnx_file = ''
        for rnx in possible_rinex:
            if os.path.isfile( rnx ):
                rnx_file   = rnx
                rnx_exists = 'Yes'
        
        if filter( lambda x: re.search(r'^%s\s+'%(used_name.upper()), x), lines):
            rnx_is_ref = 'Yes'

        if filter( lambda x: re.search(r'^%s\s*'%(used_name.upper().strip()), x), exclude_lines):
            rnx_is_excl = 'Yes'
      
        print '%-15s %-16s %-9s %-9s %-8s'%(os.path.basename(rnx_file), used_name.upper(), rnx_exists, rnx_is_ref, rnx_is_excl)
        if args.make_html:
            print >>htmlout, "<tr><td>%s</td><td>%s</td><td>%s</td><td>%s</td><td>%s</td></tr>"%(os.path.basename(rnx_file), used_name.upper(), rnx_exists, rnx_is_ref, rnx_is_excl)

        if args.make_json:
            json_list.append( {"rinex": os.path.basename(rnx_file), "station": used_name.upper().strip(), "available": rnx_exists, "reference": rnx_is_ref, "exclude": rnx_is_excl} )

except:
    traceback.print_exc()
    try: db.close()
    except: pass
    print >> sys.stderr, '[ERROR] Cannot connect/query database server.'
    EXIT_STATUS = FAILURE

if args.make_html:
    print >>htmlout, "</table>"

if args.make_json: json.dump(json_list, jsonout)

sys.exit(EXIT_STATUS)
