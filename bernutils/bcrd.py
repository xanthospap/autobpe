import os, sys, re
import datetime
import shutil

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

class CrdPoint:
  ''' Class to represent a (GNSS/geodetic) Point as recorded in a Bernese
      format .CRD file. The name of the point (i.e. ``self.name_``) is a string
      4-chars long; the number (i.e. ``self.number_``) is a string 10-chars
      long and the flag (i.e. ``self.flag_``) is a char.
  '''

  def __init__(self, **kwargs):
    ''' Constructor; all initialized to empty strings and/or .0 
    '''
    if 'line' in kwargs:
        ln = kwargs['line']
        self.name_   = ln[MARKER_NAME_INDEX:
            MARKER_NAME_INDEX+MARKER_NAME_LENGTH+1+MARKER_NUMBER_LENGTH].strip()
        try:
            self.xcmp_ = float(ln[XCOMP_INDEX:XCOMP_INDEX+XCOMP_LENGTH])
            self.ycmp_ = float(ln[YCOMP_INDEX:YCOMP_INDEX+YCOMP_LENGTH])
            self.zcmp_ = float(ln[ZCOMP_INDEX:ZCOMP_INDEX+ZCOMP_LENGTH])
        except:
            raise RuntimeError('Error reading point from crd file [%s]' %ln)

        if len(ln) >= FLAG_INDEX:
            self.flag_ = ln[FLAG_INDEX:].strip()
        else:
            self.flag_ = ''
        return
    if 'name' in kwargs : self.name_ = kwargs['name']
    else:               self.name_ = ''
    if 'flag' in kwargs : self.flag_ = kwargs['flag']
    else:               self.flag_ = ''
    if 'x'    in kwargs : self.xcmp_ = float(kwargs['x'])
    else:               self.xcmp_ = .0
    if 'y'    in kwargs : self.ycmp_ = float(kwargs['y'])
    else:               self.ycmp_ = .0
    if 'z'    in kwargs : self.zcmp_ = float(kwargs['z'])
    else:               self.zcmp_ = .0

  def name(self): return self.name_

  def asString(self, aa=1):
    ''' Compile a Bernese v5.2 .CRD file record line, using the instance's
        attributes. ``aa`` is the number of station (can be any positive 
        integer), written at the begining of the returned line.

        :returns: A .CRD record line corresponding to the instance.
    '''
    try:
      iaa = int(aa)
    except:
      raise ArithmeticError('Invalid aa integer %s' %str(aa))
    return "%03i  %-16s%15.5f%15.5f%15.5f    %-5s" \
            %(iaa, self.name(), self.xcmp_,self.ycmp_,self.zcmp_,self.flag_)

def __getListOfPoints__(crd_filename, stalst=None):
    ''' Read points off from a .CRD file; return all points as list.
        If the optional argument ``stalst`` is given, (which is supposed
        to hold a list of station names), then only stations matched
        in the ``stalst`` list will be returned. By matched, i mean that
        the tuple ``(marker_name, marker_number)`` is the same for both
        stations.
        If ``disregard_number`` is set to ``True`` and ``stalst`` is other 
        than ``None``, then the comparisson of station names, will only 
        be performed using the 4char station id (i.e. ``self.name_``) and 
        *NOT* the marker number.

        :returns: A list of points (i.e. ``CrdPoint`` s)
    '''

    points = []
    with open( crd_filename, 'r' ) as fin:
        ## Skip the first header lines
        for i in range(0,6):
            ln = fin.readline()
        ln = fin.readline()
        ## Read off all the points and add them to the points list
        while ln:
            ## ignore empty lines ...
            if not re.match('\s*$', ln) :
                pt = CrdPoint( line=ln )
                if stalst is not None:
                    if pt.name() in stalst:
                        points.append(pt)
                else:
                    points.append(pt)
            ln = fin.readline()

    ## Return the list of points
    return points

class CrdFile:
  ''' A class to hold a Bernese v5.2 format .CRD file. '''

  def __init__(self, filename):
    ''' Contructor; checks whether the file exists or not 
    '''
    self.filename_ = filename
    if not os.path.isfile(self.filename_):
      raise RuntimeError('Error. Cannot locate .CRD file %s' %filename)
    self.point_list_ = __getListOfPoints__(self.filename_)

  def getPointList(self): return self.point_list_

  def addPoint(self, crdpoint):
    index = 0
    for i in self.point_list_:
        if i.name() == crdpoint.name():
            self.point_list_[index] = crdpoint
            return
        index += 1
    self.point_list_.append( crdpoint )

  def flush(self):
    header = self.getFileHeader()
    with open( self.filename_+'.tmp', 'w') as fout:
        for i in header: print >> fout, i
        aa = 1
        for j in self.point_list_: 
            print >> fout, j.asString(aa)
            aa += 1
    shutil.move( self.filename_ + '.tmp', self.filename_ )


  def getFileHeader(self):
    ''' Return the header of a .CRD file as a list of lines,
        with no trailing newline chars.

        :returns: A list of lines included in the file header.
    '''
    try:
      fin = open(self.filename_, 'r')
    except:
      raise RuntimeError('Failed to open file .CRD file %s' %self.filename_)

    header_lines = []
    for i in range(0, 6):
      header_lines.append(fin.readline().rstrip('\n'))

    fin.close()
    return header_lines

  def set_reference_frame(self, ref_frame):
    if len(ref_frame) > 5:
        print >>sys.sderr, '[WARNING] Reference frame \"%s\" is more than 5 chars'%ref_frame
    if len(ref_frame) < 5 : 
        while len(ref_frame) == 5 : 
            ref_frame += ' '
    with open( self.filename_, 'r' ) as inf:
        with open( self.filename_ + '.tmp', 'w' ) as outf:
            for line in inf.readlines():
                if re.match('^LOCAL GEODETIC DATUM: ([a-zA-Z0-9_]*)\s+EPOCH:.*', line):
                    m = re.match('^LOCAL GEODETIC DATUM: ([a-zA-Z0-9_]*)\s+EPOCH:.*', line)
                    old_datum = m.group(1)
                    if len(old_datum) > 5:
                        print >>sys.sderr, '[WARNING] Reference frame \"%s\" is more than 5 chars'%ref_frame
                    if len(old_datum) < 5 :
                        while len(old_datum) == 5 :
                            old_datum += ' '
                    print >> outf, line.replace(old_datum, ref_frame).strip()
                else:
                    print >> outf, line.strip()
    shutil.move(self.filename_ + '.tmp', self.filename_)
  
  def set_reference_epoch(self, epoch):
      epoch_str = epoch.strftime('%Y-%m-%d %H:%M:%S')
      with open( self.filename_, 'r' ) as inf:
          with open( self.filename_ + '.tmp', 'w' ) as outf:
              for line in inf.readlines():
                  if re.match('^LOCAL GEODETIC DATUM: [a-zA-Z0-9_]*\s+EPOCH: (.*)$', line):
                      m = re.match('^LOCAL GEODETIC DATUM: [a-zA-Z0-9_]*\s+EPOCH: (.*)$', line)
                      old_epoch = m.group(1)
                      print >> outf, line.replace(old_epoch, epoch_str).strip()
                  else:
                      print >> outf, line.strip()
      shutil.move(self.filename_ + '.tmp', self.filename_)

def create_crd_file( filename, **kwargs ):
    if os.path.isfile( filename ):
        raise RuntimeError('Filed to crete crd file \"%s\". File already exists'%filename)

    ## The epoch
    if not 'epoch' in kwargs:
        epoch_str = datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S')
    else:
        epoch_str = kwargs['epoch'].strftime('%Y-%m-%d %H:%M:%S')

    ## Creation date
    created_at = datetime.datetime.now().strftime('%d-%b-%Y').upper()

    ## Reference System
    if not 'ref_system' in kwargs: ref_system = 'IGb08'
    else                         : ref_system = kwargs['ref_system']

    with open( filename, 'w' ) as fout:
        print >> fout, 'IGb08 coordinates for BERNESE GNSS SOFTWARE 5.2                      %s'%(created_at)
        print >> fout, '--------------------------------------------------------------------------------'
        print >> fout, 'LOCAL GEODETIC DATUM: %5s             EPOCH: %s'%(ref_system, epoch_str)
        print >> fout, ''
        print >> fout, 'NUM  STATION NAME           X (M)          Y (M)          Z (M)     FLAG'
        print >> fout, ''
    x = CrdFile( filename )
    return x
