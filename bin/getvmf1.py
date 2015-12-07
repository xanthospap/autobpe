#! /usr/bin/python

import os, sys
import datetime
import argparse
import gzip
import json
import bernutils.webutils

## global
EXIT_SUCCESS = 0
EXIT_FAILURE = 1
HOST         = 'http://ggosatm.hg.tuwien.ac.at'

def vprint( message, min_verb_level, std_buf=None ):
    if std_buf is None : std_buf = sys.stdout
    if args.verbosity >= min_verb_level: print >> std_buf, message

##  set the cmd parser
parser = argparse.ArgumentParser(
        description='Download VMF1 grid files for a given date.',
        epilog     ='Ntua - 2015'
        )
##  year
parser.add_argument('-y', '--year',
    action   = 'store',
    required = True,
    type     = int,
    help     = 'The year (integer).',
    metavar  = 'YEAR',
    dest     = 'year'
    )
##  day of year (doy)
parser.add_argument('-d', '--doy',
    action   = 'store',
    required = True,
    type     = int,
    help     = 'The day of year (integer).',
    metavar  = 'DOY',
    dest     = 'doy'
    )
##  hour of day
parser.add_argument('--hour',
    action   = 'store',
    required = False,
    type     = int,
    help     = 'The hour of day (integer in range [0-23]).',
    metavar  = 'HOUR',
    dest     = 'hour',
    default  = None
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
## json output file 
parser.add_argument('-j', '--json',
    action   = 'store',
    required = False,
    help     = 'Output file (summary) in json format.',
    metavar  = 'JSON_OUT',
    dest     = 'json_out',
    default  = ''
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

##  Parse command line arguments
args = parser.parse_args()

# output directory must exist !
if not os.path.isdir( args.output_dir ):
    print >> sys.stderr, '[ERROR] Invalid/non-existent directory given: \"%s\".'%(args.output_dir)
    sys.exit( EXIT_FAILURE )

## make year, doy and hour a valid datetime instance
try:
    if args.hour is not None:
        # hour can be float so that int(hour) would fail !
        ihour       = int( float(args.hour) )
        date_string = '%04i %03i %02i 0 0' %(args.year,args.doy,ihour)
        dt          = datetime.datetime.strptime(date_string,'%Y %j %H %M %S')
    else:
        date_string = '%04i %03i 0 0 0' %(args.year,args.doy)
        dt          = datetime.datetime.strptime(date_string,'%Y %j %H %M %S')
except:
    print >> sys.stderr, '[ERROR] Invalid date argument(s) !'
    sys.exit( EXIT_FAILURE )

## difference (in days) from today
today  = datetime.date.today()
daydif = today - dt.date()

# date requested older than today (use normal folders)
if daydif.days >= 1:
    DIRN = ( '/DELAY/GRID/VMFG/%04i' %args.year )
    vprint('[DEBUG] Delta days = %+3i'%(daydif.days), 1)
    vprint('[DEBUG] Using standard VMF dealy folder: \"%s\"'%DIRN, 1)
else: # else, use prediction folder
    DIRN = ( '/DELAY/GRID/VMFG_FC/%04i' %args.year )
    vprint('[DEBUG] Using predicted VMF dealy folder: \"%s\"'%DIRN, 1)

# make a list with the file(s) we want, i.e. request_list
generic_filename = 'VMFG_%04i%s%s.H' %(args.year,
                    dt.strftime('%m'),
                    dt.strftime('%d'))
if not args.hour:
    request_list = [ generic_filename+('%02i'%i) for i in [0, 6, 12, 18] ]
else:
    i = divmod(ihour,6)[0] * 6
    request_list = [ generic_filename+('%02i'%i) ]

# WARNING pre-2008, all files are zipped into filename.gz
if args.year <= 2008:
    for i, f in enumerate(request_list):
        request_list[i] = (f + '.gz')

# try downloading the file(s)
status      = EXIT_SUCCESS
URL         = ( '%s%s' %(HOST,DIRN) )
saveas_list = [ os.path.join(args.output_dir, i) for i in request_list ]
try:
    retlist = bernutils.webutils.grabHttpFile(URL,request_list,saveas_list)
except Exception, e:
    ## try for prediction if delta days == 1
    if daydif.days == 1:
        try:
            NOR_DIRN      = ( '/DELAY/GRID/VMFG/%04i' %args.year )
            PRE_DIRN      = ( '/DELAY/GRID/VMFG_FC/%04i' %args.year )
            request_list2 = [ i.replace(NOR_DIRN, PRE_DIRN) for i in request_list ]
            vprint('[DEBUG] Final VMF1 grid not found! Trying for prediction', 1)
            retlist = bernutils.webutils.grabHttpFile(URL,request_list2,saveas_list)
            request_list  = request_list2
        except:
            #print >> sys.stderr, '[ERROR] %s'%(str(e))
            print >> sys.stderr, '[ERROR] Failed to download VMF1 grid file(s).'
            status = EXIT_FAILURE
    else:
        #print >> sys.stderr, '[ERROR] %s'%(str(e))
        print >> sys.stderr, '[ERROR] Failed to download VMF1 grid file(s).'
        status = EXIT_FAILURE

## TODO should delete files if this step fails
if status == EXIT_FAILURE: sys.exit( EXIT_FAILURE )

# WARNING pre-2008, all files are zipped into filename.gz
if args.year <= 2008:
   for i, f in enumerate( retlist ):
       gzfilename = f[1]
       if gzfilename[-3:] == '.gz':
           new_saveas = gzfilename[:-3]
           with open(new_saveas,'w') as fn:
               fn.write( gzip.open(gzfilename).read() )
           f[1] = new_saveas
           os.remove( gzfilename )

# print results
if args.json_out != '' :
   with open(args.json_out, 'w') as jout:
     print >> jout, "\"%s\":["%("vmf1")
     for idx, i in enumerate( retlist ):
         jdict = {
             'info'    : 'Vienna Mapping Function 1 Grid',
             'format'  : 'GRD (ascii grid file)',
             'satsys'  : '',
             'ac'      : 'tuwien',
             'type'    : '',
             'host'    : HOST,
             'filename': i[0]
           }
         if idx == len(retlist) - 1: end = ']'
         else: end = ','
         print >> jout, "%s %s"%(json.dumps(jdict), end),

if args.verbosity > 0 :
    for i in retlist: print '[DEBUG] Downloaded \"%s\" to \"%s\".'%(i[0],i[1])

# exit with sucess
sys.exit( EXIT_SUCCESS )
