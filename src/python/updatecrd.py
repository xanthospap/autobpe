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

## Variables for Bernese v5.2 .CRD files
## Describe the format of a .CRD data line
CRD_HEADER_LINES     = 6
MARKER_NAME_INDEX    = 5
MARKER_NAME_LENGTH   = 4
MARKER_NUMBER_INDEX  = 10
MARKER_NUMBER_LENGTH = 10
XCOMP_INDEX          = 22
XCOMP_LENGTH         = 15
YCOMP_INDEX          = 37
YCOMP_LENGTH         = 15
ZCOMP_INDEX          = 52
ZCOMP_LENGTH         = 15
FLAG_INDEX           = 67

## Global variables
stations = []
flags = []
drop_marker_numbers = False
update_file = ''
reference_file = ''
include_unmatched = False
delete_unmatched = False

## help function
def help (i):
    print ""
    print ""
    sys.exit(i)

## A class to hold CRD data line records.
class CrdPoint:
    name_   = ''
    number_ = ''
    xcmp_   = .0
    ycmp_   = .0
    zcmp_   = .0
    flag_   = ''

    ## Constructor
    def __init__(self,name='',number='',xcmp='.0',ycmp='.0',zcmp='.0',flag=''):
        self.name_   = name
        self.number_ = number
        try:
            self.xcmp_ = float(xcmp)
            self.ycmp_ = float(ycmp)
            self.zcmp_ = float(zcmp)
        except:
            raise ArithmeticError('Invalid initilization of CrdPoint')
            self.xcmp_ = self.ycmp_ = self.zcmp_ = .0
        self.flag_ = flag

    def setFromCrdLine(self,line):
        '''
        ## Set a CrdPoint from a .CRD data line.
        '''

        if len(line) < 65:
            raise BufferError('Error reading point from crd file ['+
                    line+'] ER1')

        self.name_   = line[MARKER_NAME_INDEX:
                MARKER_NAME_INDEX+MARKER_NAME_LENGTH].strip()
        self.number_ = line[MARKER_NUMBER_INDEX:
                MARKER_NUMBER_INDEX+MARKER_NUMBER_LENGTH].strip()
        try:
            self.xcmp_ = float(line[XCOMP_INDEX:XCOMP_INDEX+XCOMP_LENGTH])
            self.ycmp_ = float(line[YCOMP_INDEX:YCOMP_INDEX+YCOMP_LENGTH])
            self.zcmp_ = float(line[ZCOMP_INDEX:ZCOMP_INDEX+ZCOMP_LENGTH])
        except:
            raise BufferError('Error reading point from crd file ['+
                    line+'] ER2')

        if len(line) >= FLAG_INDEX:
            self.flag_ = line[FLAG_INDEX:].strip()
        else:
            self.flag_ = ''

    def name(self,use_marker_number=True):
        '''
        ## Return the full name of a station, i.e. marker_name + marker_number.
        '''
        if len(self.name_) < MARKER_NAME_LENGTH:
            while len(self.name_) < MARKER_NAME_LENGTH:
                self.name_ += ' '

        if not use_marker_number:
            return self.name_[0:4]

        if len(self.number_) < MARKER_NUMBER_LENGTH:
            while len(self.number_) < MARKER_NUMBER_LENGTH:
                self.number_ += ' '

        return ( self.name_[0:4] + ' ' + self.number_[0:10] )

    def asString(self,aa):
        '''
        ## Describe a station as a .CRD data line string
        WRITE(line,'(I3,2X,A16,3F15.5,4X,A5)')
        '''
        try:
            iaa = int(aa)
        except:
            raise ArithmeticError('')
        return "%03i  %-17s%15.5f%15.5f%15.5f   %-5s" %(iaa,self.name(),
                self.xcmp_,self.ycmp_,self.zcmp_,self.flag_)

def getListOfPoints(crdfile,stalst=None,disregard_number=False):
    '''
    ## Read points off from a .CRD file; return all points as list.
    ## If the optional argument 'stalst' is given, (which is supposed
    ## to hold a list of station names), then only stations matched
    ## in the stalst list will be returned. By matched, i mean that
    ## the tuple (marker_name, marker_number) is the same for both
    ## stations.
    ## If 'disregard_number' is set to True and 'stalst' is other than
    ## None, then the comparisson of station names, will only be performed
    ## using the 4char station id (i.e. self.name_) and NOT the marker number.
    '''

    points = []

    try:
        fin = open(crdfile,'r')
    except:
        raise IOError('Failed to open file' + crdfile)

    ## Skip the first header lines
    for i in range(0,6):
        line = fin.readline()

    pt  = CrdPoint()
    pts = 1
    ## Read off all the points and add them to the points list
    while (True):
        line = fin.readline()
        if not line or len(line) < 10:
            break
        try:
            pt = CrdPoint()
            pt.setFromCrdLine(line)
            if stalst is not None:
                if disregard_number:
                    if [x for x in stalst if x[0:4] == pt.name_]:
                        points.append(pt)
                else:
                    if pt.name() in stalst:
                        points.append(pt)
                        pts += 1
            else:
                points.append(pt)
                pts += 1
        except BufferError, e:
            fin.close()
            raise e

    ## Close the file
    fin.close()

    ## Return the list of points
    print 'returning :',len(points)
    return points

def getCrdFileHeader(crdfile):
    '''
    ## Return the header of a .CRD file as a list of lines,
    ## with no triling newline chars
    '''
    try:
        fin = open(crdfile,'r')
    except:
        raise IOError('Failed to open file' + crdfile)

    header_lines = []
    for i in range(0,6):
        header_lines.append(fin.readline().rstrip('\n'))

    return header_lines;

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
if not os.path.isfile(reference_file):
    print >> sys.stderr, 'ERROR. File does not exist:',reference_file
    sys.exit (1)

## Do we have a list of stations ?
if not len(stations):
    stations = None

## Do we have a list of flags ?
if not len(flags):
    flags = None

## Read all points from the updated file
try:
    lst1 = getListOfPoints(update_file,stations,drop_marker_numbers)
except:
    print >> sys.stderr,'ERROR. Failed reading points from file:',update_file
    sys.exit(1)

## Read all points from the reference file
try:
    lst2 = getListOfPoints(reference_file,stations,drop_marker_numbers)
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
                print 'Matched point ->',point.name(),' to point ->',refpt.name(),'number',matched_stations
            break
    if not matched and not delete_unmatched:
        print 'UnMatched point ->',point.name()
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
    sys.exit(0)

## Else, write the updated points in a temporary file, using the
## header of the reference file
header = getCrdFileHeader(reference_file)
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
print 'Wrote',len(updlst),'stations in file',update_file,'.'
print 'Updated ',matched_stations,'stations.'
sys.exit(0)