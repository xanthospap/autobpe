#! /usr/bin/python

'''
|===========================================|
|** Higher Geodesy Laboratory             **|
|** Dionysos Satellite Observatory        **|
|** National Tecnical University of Athens**|
|===========================================|

filename              : 
version               : v-0.5
created               : JUN-2015

usage                 : Python routine to 

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
import sys
import os
import getopt
import bernutils.berncrd

## ------------ DEBUGING FLAGS
DDEBUG = True

## Global variables
stations            = []
flags               = []
drop_marker_numbers = False
update_file         = ''
reference_file      = ''
include_unmatched   = False
delete_unmatched    = False

## help function
def help (i):
    print ""
    print ""
    sys.exit(i)

## Resolve command line arguments
def main (argv):

    if len(argv) < 1:
        help(1)

    try:
        opts, args = getopt.getopt(argv,'hs:u:r:f:',[
            'help','stations=','update=','reference=','no-marker-number',
            'flags=','include-unmatched','delete-unmatched'])
    except getopt.GetoptError:
        help(1)

    for opt, arg in opts:
        if opt in ('-h', 'help'):
            help(0)
        elif opt in ('-s', '--stations'):
            station_list = arg.split(',')
            global stations
            stations += station_list
        elif opt in ('-u', '--update'):
            global update_file
            update_file = arg
        elif opt in ('-r', '--reference'):
            global reference_file
            reference_file = arg
        elif opt in ('--no-marker-number'):
            global drop_marker_numbers
            drop_marker_numbers = True
        elif opt in ('-f', '--flags'):
            flag_list = arg.split(',')
            global flags
            flags += flag_list
        elif opt in ('--include-unmatched'):
            global include_unmatched
            include_unmatched = True
        elif opt in ('--delete-unmatched'):
            global delete_unmatched
            delete_unmatched = True
        else:
            print >> sys.stderr, "Invalid command line argument:",opt

## Start main
if __name__ == "__main__":
    main( sys.argv[1:] )

## File to update and reference file must be set!
if not os.path.isfile(update_file):
    print >> sys.stderr, 'ERROR. File does not exist:',update_file
    sys.exit (1)
else:
    updateCrd = CrdFile(update_file)

if not os.path.isfile(reference_file):
    print >> sys.stderr, 'ERROR. File does not exist:',reference_file
    sys.exit (1)
else:
    referenceCrd = CrdFile(reference_file)

## Do we have a list of stations ?
if not len(stations):
    stations = None

## Do we have a list of flags ?
if not len(flags):
    flags = None

## Read all points from the updated file
try:
    lst1 = updateCrd.getListOfPoints(stations,drop_marker_numbers)
    if DDEBUG: print 'Read',len(lst1),'station from update file'
except:
    print >> sys.stderr,'ERROR. Failed reading points from file:',update_file
    sys.exit(1)

## Read all points from the reference file
try:
    lst2 = referenceCrd.getListOfPoints(stations,drop_marker_numbers)
    if DDEBUG: print 'Read',len(lst1),'station from update file'
except:
    print >> sys.stderr,'ERROR. Failed reading points from file:',reference_file
    sys.exit(1)

## Try to match the points in reference list and update list.
## Create a new list of (matched) points, where the point's name is
## extracted from the update file, and all other info are extracted
## from the reference file (i.e., coordinates, flag)
## If a station is not matched, it will be included in the update list,
## with the reciords as in the update file.
updlst = []
matched_stations = 0
for point in lst1:
    matched = False
    for refpt in lst2:
        if point.name(not drop_marker_numbers) == refpt.name(not drop_marker_numbers): ## match the name
            if not flags or refpt.flag_ in flags: ## match the flag (if any)
                pt = refpt
                pt.name_   = point.name_
                pt.number_ = point.number_
                updlst.append(pt)
                matched = True
                matched_stations += 1
                if DDEBUG: print 'Matched point ->',point.name(),' to point ->',refpt.name(),'number',matched_stations
            break
    if not matched and not delete_unmatched:
        if DDEBUG: print 'UnMatched point ->',point.name()
        updlst.append(point)

## Now, the user may want all stations included in the reference file
## included in the update file, regardless if it is matched.
if include_unmatched:
    for refpt in lst2:
        unmatched = True
        for mpt in updlst:
            if refpt.name(not drop_marker_numbers) == mpt.name(not drop_marker_numbers): ## match the name
                unmatched = False
                break
        if unmatched:
            updlst.append(refpt)

## if no stations are to be updated, just return
if not updlst:
    if DDEBUG: print 'No stations to update. Exiting...'
    sys.exit(0)

## Else, write the updated points in a temporary file, using the
## header of the reference file
header = referenceCrd.getCrdFileHeader()
fin = open('.tmp.CRD','w')
for l in header:
    print >> fin, l

j = 1
for i in updlst:
    print >> fin, i.asString(j)
    j += 1

fin.close()

## Last step: rename the temporary file to the updated file
os.rename('.tmp.CRD',update_file)

## Print the number of stations update and exit
if DDEBUG: print 'Wrote',len(updlst),'stations in file',update_file,'.'
if DDEBUG: print 'Updated ',matched_stations,'stations.'

sys.exit(0)
