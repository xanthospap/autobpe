#! /usr/bin/python

import os, sys, argparse
import datetime
import bernutils.badnq

##  set the cmd parser
parser = argparse.ArgumentParser(
    description='Extract station coordinates from an ADDNEQ2 output file and '
    'write them to station-specific time-series files.',
    epilog ='Ntua - 2016'
    )

##  Name of the processed campaign
parser.add_argument('-a', '--addneq2-out',
    action   = 'store',
    required = True,
    help     = 'The filename of the ADDNEQ2 output file.',
    metavar  = 'ADDNEQ2.OUT',
    dest     = 'adnq_out'
    )

##  The directory where the (time-series) station specific directories are placed
parser.add_argument('-d', '--ts-dir',
    action   = 'store',
    required = True,
    help     = 'The directory where station-specific directories are placed',
    metavar  = 'PATH2TS',
    dest     = 'pth2ts'
    )

##  A file containing all stations to be extracted (form ADDNEQ2) and written
##+ to .cts files
parser.add_argument('-s', '--sta-file',
    action   = 'store',
    required = False,
    help     = 'A file containing a list of stations to be extracted.',
    metavar  = 'STA_FILE',
    dest     = 'sta_file'
    )

##  A description string to append to the records
parser.add_argument('-t', '--description',
    action   = 'store',
    required = False,
    help     = 'A description string to append to the records.',
    metavar  = 'DESCRIPTION',
    dest     = 'description'
    )

ERROR = 1
ALLOK = 0

##  Parse command line arguments
args = parser.parse_args()

if not os.path.isdir(args.pth2ts):
    print >> sys.stderr, '[ERROR] Cannot locate directory: \"{}\".'.format(args.pth2ts)
    sys.exit(ERROR)

if not os.path.isfile(args.adnq_out):
    print >> sys.stderr, '[ERROR] Cannot locate file \"{}\".'.format(args.adnq_out)
    sys.exit(ERROR)

##  get (a dictionary with) station info and reference epoch
##  Note that the station names (keys) may contain DOMES and may be capitalized
try:
    adnq = bernutils.badnq.AddneqFile(args.adnq_out)
    stad, refeph = adnq.get_station_coordinates()
    status = ALLOK
except:
    print >> sys.stderr, '[ERROR] Cannot extract coordinates from file \"{}\".'.format(args.adnq_out)
    status = ERROR

if status == ERROR : sys.exit(ERROR)

##  list of stations to be etracted from ADDNEQ file. Station names are extracted
##+ as 4-char id's.
sta_lst = []
if args.sta_file is not None:
    if not os.path.isfile(args.sta_file):
        print >> sys.stderr, '[ERROR] Cannot locate file: \"{}\".'.format(args.sta_file)
    try:
        with open(args.sta_file, 'r') as fin:
            for line in fin.readlines():
                if len(line) >=4 : sta_lst.append(line.strip()[0:4].lower())
    except:
        status = ERROR
        print >> sys.stderr, '[ERROR] Could not read file: \"{}\".'.format(args.sta_file)

if status == ERROR: sys.exit(ERROR)

##  If the user has specified a station selection file and it is empty, there
##+ is nothing left to do
if len(sta_lst) == 0 and args.sta_file is not None:
    print 'Station selection file \"{}\" is empty; nothing to do!'.format(args.sta_file)
    sys.exit(ALLOK)

##  If the station list is empty at this point, we probably want all stations
if len(sta_lst) == 0: sta_lst = [ x.strip()[0:4].lower() for x in stad ]

##  Ok, now write the coordinates for all stations in the sta_lst list
for key, val in stad.iteritems():
    if key.strip()[0:4].lower() in sta_lst:
        sta_id = key.strip()[0:4].lower()
        try:
            tsf = open(os.path.join(args.pth2ts, sta_id, (sta_id+'.cts')), 'a')
            print >> tsf, '{:} {:+15.5f} {:9.5f} {:+15.5f} {:9.5f} {:+15.5f} {:9.5f} {:+13.8f} {:9.5f} {:+13.8f} {:9.5f} {:12.5f} {:9.5f} {:} {:}'.format(refeph, val[0][1], val[0][3], val[1][1], val[1][3], val[2][1], val[2][3], val[4][1], val[4][3], val[5][1], val[5][3], val[3][1], val[3][3], datetime.datetime.now(), args.description)
            tsf.close()
        except:
            print >> sys.stderr, '[ERROR] Failed to update time-series records for station \"{}\"'.format(sta_id)
            status = ERROR
    if status == ERROR: sys.exit(ERROR)

sys.exit(ALLOK)
