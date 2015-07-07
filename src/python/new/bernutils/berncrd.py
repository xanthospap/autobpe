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

class CrdFile:
    filename_ = ''
    
    ## Constructor
    def __init__(self,filename):
        if not os.path.isfile(filename):
            raise Exception('Invalid initilization of .CRD file' + filename)
        self.filename_ = filename

    def getListOfPoints(self,stalst=None,disregard_number=False):
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
            fin = open(self.filename_,'r')
        except:
            raise IOError('Failed to open file' + self.filename_)

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
        ## print 'returning :',len(points)
        return points

    def getFileHeader(self):
        '''
        ## Return the header of a .CRD file as a list of lines,
        ## with no triling newline chars
        '''
        try:
            fin = open(self.filename_,'r')
        except:
            raise IOError('Failed to open file .CRD file' + self.filename_)

        header_lines = []
        for i in range(0,6):
            header_lines.append(fin.readline().rstrip('\n'))

        fin.close()
        return header_lines;