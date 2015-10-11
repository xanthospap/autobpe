#! /usr/bin/python

import os
import sys
import datetime
import getopt
import bernutils.webutils
import gzip
import json

## help function
def help (i):
    print ""
    print ""
    sys.exit(i)

## global
EXIT_SUCCESS = 0
EXIT_FAILURE = 1
HOST         = 'http://ggosatm.hg.tuwien.ac.at'
OUT_DIR      = ''
year         = None
doy          = None
hour         = None
JSON_OUT     = None

## Resolve command line arguments
def main (argv):

    if len(argv) < 1:
        help(1)

    try:
      opts, args = getopt.getopt(argv,'hy:d:r:o:j:',[
        'help','year=','doy=','hour=','outdir=','json='])
    except getopt.GetoptError:
        help(1)

    for opt, arg in opts:
        if opt in ('-h', 'help'):
            help(0)
        elif opt in ('-y', '--year'):
            global year
            year = arg
        elif opt in ('-d', '--doy'):
            global doy
            doy = arg
        elif opt in ('-r', '--hour'):
            global hour
            hour = arg
        elif opt in ('-o', '--outdir'):
            global OUT_DIR
            OUT_DIR = arg
        elif opt in ('-j', '--json'):
            global JSON_OUT
            JSON_OUT = arg
        else:
            print >> sys.stderr, "Invalid command line argument:",opt

## Start main
if __name__ == "__main__":
    main( sys.argv[1:] )

## year and doy must be set and valid
if not year:
    print >> sys.stderr, 'ERROR. Year must be set and valid !'
    sys.exit(EXIT_FAILURE)
if not doy:
    print >> sys.stderr, 'ERROR. Doy must be set and valid !'
    sys.exit(EXIT_FAILURE)
try:
    iyear = int(year)
    idoy  = int(doy)
    if hour is not None:
        # hour can be float so that int(hour) would fail !
        ihour = int(float(hour))
except:
    print >> sys.stderr, 'ERROR. Invalid date argument(s) ![1]'
    sys.exit(EXIT_FAILURE)

# output directory must exist !
if OUT_DIR != '':
    if OUT_DIR[-1] == '/': OUT_DIR = OUT_DIR[:-1]
    if not os.path.isdir(OUT_DIR):
        print >> sys.stderr, 'ERROR. Invalid/non-existent directory given:',OUT_DIR
        sys.exit(EXIT_FAILURE)

## make year, doy and hour a valid datetime instance
if not hour:
    date_string = '%04i %03i 0 0 0' %(iyear,idoy)
else:
    date_string = '%04i %03i %02i 0 0' %(iyear,idoy,ihour)

try:
    dt = datetime.datetime.strptime(date_string,'%Y %j %H %M %S')
except:
    print >> sys.stderr, 'ERROR. Invalid date argument(s) ![2]'
    sys.exit(EXIT_FAILURE)

## difference in (days) from today
today  = datetime.date.today()
daydif = today - dt.date()

# date requested older than today (use normal folders)
if daydif.days >= 1:
    DIRN = ( '/DELAY/GRID/VMFG/%04i' %iyear )
else: # else, use prediction folder
    DIRN = ( '/DELAY/GRID/VMFG_FC/%04i' %iyear )

# make a list with the file(s) we want
request_list     = []
generic_filename = 'VMFG_%04i%s%s.H' %(iyear,dt.strftime('%m'),dt.strftime('%d'))
if not hour:
    for i in [0,6,12,18]:
        request_list.append(generic_filename+('%02i'%i))
else:
    i = divmod(ihour,6)[0] * 6
    request_list.append(generic_filename+('%02i'%i))

# WARNING pre-2008, all files are zipped into filename.gz
if iyear <= 2008:
    for i, f in enumerate(request_list):
        request_list[i] = (f + '.gz')

# try downloading the file(s)
URL = ('%s%s' %(HOST,DIRN))
saveas_list = list(request_list)
if OUT_DIR != '':
    for i, f in enumerate(saveas_list):
        saveas_list[i] = os.path.join(OUT_DIR,f)
try:
    retlist = bernutils.webutils.grabHttpFile(URL,request_list,saveas_list)
except Exception, e:
    ## TODO should delete files if this step fails
    print >> sys.stderr, 'ERROR.',str(e)
    sys.exit(EXIT_FAILURE)

# WARNING pre-2008, all files are zipped into filename.gz
if iyear <= 2008:
    for i, f in enumerate(retlist):
        gzfilename = f[1]
        if gzfilename[-3:] == '.gz':
            new_saveas = gzfilename[:-3]
            with open(new_saveas,'w') as fn:
                fn.write(gzip.open(gzfilename).read())
            f[1] = new_saveas
            os.remove(gzfilename)

# print results
if JSON_OUT:
    with open(JSON_OUT, 'w') as jout:
      print>>jout,"\"%s\":["%("vmf1")
      for idx, i in enumerate(retlist):
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
          print>>jout,"%s %s"%(json.dumps(jdict), end),

for i in retlist: print 'Downloaded',i[0],'to',i[1]

# exit with sucess
sys.exit(EXIT_SUCCESS)
