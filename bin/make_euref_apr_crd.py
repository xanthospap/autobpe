#! /usr/bin/python

import sys, os
import datetime
import argparse
import bernutils.webutils
import bernutils.bcrd

EUREF_SSC     = 'EPN_A_IGb08.SSC'
EUREF_HOST    = 'epncb.oma.be'
EUREF_DIR     = 'epncb/station/coord/EPN'

def resolve_ssc_date( date_str ):
    yy, doy, sod = map(int, date_str.split(':'))
    m, s = divmod(sod, 60)
    h, m = divmod(m, 60)
    dstr = '%02i %03i %02i %02i %02i'%(yy, doy, h, m, s)
    return datetime.datetime.strptime(dstr, '%y %j %H %M %S')

class sscinfo:
    def __init__(self, xyz_line, vel_line ):
        #13434M001 ACOR              GPS ACOR  4594489.710  -678367.775  4357066.136  0.001  0.000  0.001  1 99:237:00000 00:001:86370 05:001:00000
        xyz          = xyz_line.split()
        self.mnumber = xyz[0]
        self.mname   = xyz[1]
        self.tech    = xyz[2]
        self.mid     = xyz[3]
        self.mx      = float(xyz[4])
        self.my      = float(xyz[5])
        self.mz      = float(xyz[6])
        self.msx     = float(xyz[7])
        self.msy     = float(xyz[8])
        self.msz     = float(xyz[9])
        self.msolnum = int(xyz[10])
        self.mstart  = resolve_ssc_date(xyz[11])
        self.mend    = resolve_ssc_date(xyz[12])
        self.mref    = resolve_ssc_date(xyz[13])
        #13434M001       A                         -0.0097       0.0228       0.0104 0.0001 0.0000 0.0001
        vel = vel_line.split()
        if vel[0] != self.mnumber: raise 1
        self.mclass  = vel[1]
        self.mvx     = float(vel[2])
        self.mvy     = float(vel[3])
        self.mvz     = float(vel[4])
        self.msvx    = float(vel[5])
        self.msvy    = float(vel[6])
        self.msvz    = float(vel[7])

    def station(self): return '%s %s'%(self.mname, self.mnumber)

    def start_epoch(self) : return self.mstart

    def end_epoch(self): return self.mend

    def extrapolate_crd(self, py_datetm):
        delta_time = ( py_datetm - self.mref ).days / 365.25
        x = self.mx + delta_time * self.mvx
        y = self.my + delta_time * self.mvy
        z = self.mz + delta_time * self.mvz
        return x, y, z

def extrapolate_crd( station, ssc_lst, dt ):
    if len( ssc_lst  ) == 1:
        return ssc_lst[0].extrapolate_crd( dt )
    ##  walk through all elements and mark the ones that cover
    ##+ the earliest date and the latest date. If dt is exaclty
    ##+ between the limits of some element, just use this element.
    ##+ If we walk through all elements, and not found an exact
    ##+ matching element, then  ...
    min_epoch_ssc = 0
    max_epoch_ssc = 0
    status        = -1
    for idx, j in enumerate( ssc_lst ):
        if dt >= j.start_epoch() and dt < j.end_epoch() :
            return j.extrapolate_crd( dt )
        if   dt < j.start_epoch() : status = -1
        elif dt > j.end_epoch()   : status = 1
        if j.start_epoch() < ssc_lst[min_epoch_ssc].start_epoch() :
            min_epoch_ssc = idx
        if j.end_epoch() > ssc_lst[max_epoch_ssc].end_epoch() :
            max_epoch_ssc = idx
    if status == -1 : return ssc_lst[min_epoch_ssc].extrapolate_crd( dt )
    else            : return ssc_lst[max_epoch_ssc].extrapolate_crd( dt )


##  Set the cmd parser.
parser = argparse.ArgumentParser(
    description='Compile a .CRD file for all (or a subset) of EPN stations,'
    'using the file \'%s\' for a given epoch.'%(os.path.join(EUREF_HOST, EUREF_DIR, EUREF_SSC))
    )

## year 
parser.add_argument('-y', '--year',
    action='store',
    required=True,
    type=int,
    help='The year as a four digit integer.',
    metavar='YEAR',
    dest='year'
    )
## day of year 
parser.add_argument('-d', '--doy',
    action='store',
    required=True,
    type=int,
    help='The day of year as integer.',
    metavar='DOY',
    dest='doy'
    )
##  file with stations
parser.add_argument('-s', '--station-file',
    action='store',
    required=False,
    help='A file with the list of stations to be considered. Staion names'
    'should be given as \'MARKER DOMES\', one lie per station.',
    metavar='STA_FILE',
    dest='station_file',
    default=None
    )
## flush coordinate to a .CRD file
parser.add_argument('-a', '--append-to-crd',
    action='store',
    required=False,
    help='If this file is specified, then the coordinates of the stations are'
    'not written to stdout but instead appended to the given (.CRD) file. If'
    'the file does not exist, it will be created.',
    metavar='CRD_FILE',
    dest='crd_file',
    default=None
    )

files_to_delete = []

##  Parse command line arguments
args = parser.parse_args()

##  Check that the given date is valid
try:
    dtime = datetime.datetime.strptime( '%04i-%03i'%(args.year, args.doy), '%Y-%j' )
except:
    print >> sys.stderr, '[ERROR] Invalid date given! Year=\'%04i\', doy=\'%03i\''%(args.year, args.doy)
    sys.exit( 1 )

##  Download the SSC file and save it here
try:
    [[euref_ssc, remote_file]] = bernutils.webutils.grabFtpFile( EUREF_HOST, EUREF_DIR, EUREF_SSC )
    files_to_delete.append( euref_ssc )
    ## [['/home/bpe/autobpe/bin/EPN_A_IGb08.SSC', \
    ##   'epncb.oma.be/epncb/station/coord/EPN/EPN_A_IGb08.SSC']]
except:
    print >> sys.stderr, '[ERROR] Failed to download file \"%s\"'%(os.path.join(EUREF_HOST, EUREF_DIR, EUREF_SSC))
    sys.exit( 1 )

##  resolve the station list (if any)
if args.station_file is not None:
    station_list = []
    if not os .path.isfile( args.station_file ):
        print >> sys.stderr, '[ERROR] Invalid Station list file \'%s\''%(args.station_file)
        sys.exit(1)
    with open(args.station_file, 'r') as sf:
        for line in fin.readlines():
            station_list.append( line.strip() )
else:
    station_list = None

##  Let's see about that crd file ...
if args.crd_file != None:
    if os.path.isfile( args.crd_file ):
        #try:
        crd_file_obj = bernutils.bcrd.CrdFile( args.crd_file )
        point_list   = crd_file_obj.getPointList()
        if station_list is not None:
            for i in point_list: 
                if i.name() in station_list: 
                    print >>sys.stderr, '[WARNING] Station \"%s\" already in crd file; it will be overwitten.'
        crd_file_obj.set_reference_epoch( dtime )
        #except:
        #    print >> sys.stderr, '[ERROR] Invalid .CRD file \'%s\''%(args.crd_file)
        #    sys.exit (1)
    else:
        crd_file_obj = bernutils.bcrd.create_crd_file(args.crd_file, epoch=dtime)

##  read through the ssc file and make a dictionary:
##+ the keys are the names of the stations (name_number)
##+ the values are the station lines as sscinfo instances.
##  Note tha a single station can have more than one entries
##+ in the ssc file, hence the value of the keys are *not*
##+ single sscinfo elements but a *list* of sscinfo entries.
ssc_dict = {}
with open( euref_ssc, 'r' ) as fin :
    for i in range(0, 8): line = fin.readline()
    line = fin.readline()
    while line :
        line2 = fin.readline()
        tmp   = sscinfo(line, line2)
        if station_list == None or tmp.station() in station_list:
            if tmp.station() in ssc_dict: ssc_dict[tmp.station()].append(tmp)
            else: ssc_dict[tmp.station()] = [ tmp ]
        line = fin.readline()

if args.crd_file is None:
    i = 1
    for sta, lst in ssc_dict.iteritems() :
        x, y, z = extrapolate_crd( sta, lst, dtime )
        print '%3i  %-15s%15.4f%15.4f%15.4f '%(i, sta, x, y, z)
        i += 1
else:
    for sta, lst in ssc_dict.iteritems() :
        px, py, pz = extrapolate_crd( sta, lst, dtime )
        point = bernutils.bcrd.CrdPoint(name=sta, x=px, y=py, z=pz, flag='A')
        crd_file_obj.addPoint( point )
    crd_file_obj.flush()

for i in files_to_delete: os.remove( i )

sys.exit (0)
