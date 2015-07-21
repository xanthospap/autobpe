#! /usr/bin/python

import os
import datetime
import getopt

## help function
def help (i):
    print ""
    print ""
    sys.exit(i)

## global
HOST = 'http://ggosatm.hg.tuwien.ac.at'
year = None
doy  = None
hour = None

## Resolve command line arguments
def main (argv):

    if len(argv) < 1:
        help(1)

    try:
        opts, args = getopt.getopt(argv,'hy:d:r:',[
            'help','year=','doy=','hour='])
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
        else:
            print >> sys.stderr, "Invalid command line argument:",opt

## Start main
if __name__ == "__main__":
    main( sys.argv[1:] )

## year and doy must be set and valid
if not year:
    print >> sys.stderr, 'ERROR. Year must be set and valid !'
    sys.exit(1)
if not doy:
    print >> sys.stderr, 'ERROR. Doy must be set and valid !'
    sys.exit(1)
try:
    iyear = int(year)
    idoy  = int(doy)
    if hour:
        ihour = int(hour)
except:
    print >> sys.stderr, 'ERROR. Invalid date argument(s) !'
    sys.exit(1)

## make year, doy and hour a valid datetime instance
if not hour:
    date_string = '%04i %03i 0 0 0' %(iyear,idoy)
else:
    date_string = '%04i %03i %02i 0 0' %(iyear,idoy,ihour)

try:
    dt = datetime.datetime(date_string,'%Y %j %H %M %S')
except:
    print >> sys.stderr, 'ERROR. Invalid date argument(s) !'
    sys.exit(1)

## difference in (days) from today
today  = datetime.date.today()
daydif = today - dt.date()

# date requested older than today (use normal folders)
if daydif >= 1:
    DIRN = ( '/DELAY/GRID/VMFG/%04i' %iyear )
else: # else, use prediction folder
    DIRN = ( '/DELAY/GRID/VMFG_FC/%04i' %iyear )

# make a list with the file(s) we want
request_list     = []
generic_filename = 'VMFG_%04i%s%s.H' %(iyear,dt.strftime('%m'),dt.strftime('%d'))
if not hour:
    for i in [0,6,12,18]:
        request_list.append(generic_filename+('%02i'%i)
else:
    i = divmod(i,6)[0] * 6
    request_list.append(generic_filename+('%02i'%i)