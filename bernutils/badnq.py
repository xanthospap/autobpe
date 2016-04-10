import os, sys, json
import datetime
import bernutils.geodesy

class FullStationRecord:
  ''' This is just a helper class; it iis meant to hold a full, station solution
      info record block, with all relevant information from an ADDNEQ output
      file. These inlude (per station), cartesian and ellipsoidal coordinates
      (both estimated and a-priori), coordinate corrections and rms values,
      adjustment type (i.e. fixed, free, helmert, etc), error-ellipsoid values,
      etc...

      Each ``FullStationRecord`` should totally represent a station included in
      the adjustment.
  '''

  def __init__(self, _name, _list):
    ''' Constructor; this is not **at all** handy, but is useful when we need it
        the most, i.e. see function :fun:`toHtml`. To initialize an instance, all
        elements must be passed into this constructor, at a specific list/sublist
        order. The type of list passed in, must match the following: ::

          ``[aa, obs, adjt, x, y, z, lat, lon, hgt, \
          [x_apr, x_est, x_cor, x_rms] \
          [y_apr, y_est, y_cor, y_rms] \
          [z_apr, z_est, z_cor, z_rms] \
          [u_apr, u_est, u_cor, u_rms, u_e3d, u_angle_e3d] \
          [n_apr, n_est, n_cor, n_rms, n_e3d, n_angle_e3d, n_e2d, angle_e2d] \
          [e_apr, e_est, e_cor, e_rms, e_e3d, e_angle_e3d, e_e2d] \
          ]``

       For example ::

         WTZR [38, 'Y', 'HELMR', 4075580.43301, 931853.91975, 4801568.20234, 49.1441995, 12.8789118, 666.01954,\
         [4075580.43301, 4075580.42761, -0.0054, 0.0008], \
         [931853.91975, 931853.92017, 0.00042, 0.00036], \
         [4801568.20234, 4801568.19723, -0.00511, 0.00086], \
         [666.01954, 666.01229, -0.00724, 0.00114, 0.00114, 3.0], \
         [49.1441995, 49.1441995, 0.00057, 0.00036, 0.00029, 88.1, 0.00029, 86.2], \
         [12.8789118, 12.8789118, 0.00161, 0.00029, 0.00035, -1.5, 0.00036]]

    '''
    self.__name   = _name

    ## tuple[0]
    self.__aa     = _list[0]
    self.__obs    = _list[1]
    self.__adjt   = _list[2]
    self.__xapr   = _list[3]
    self.__yapr   = _list[4]
    self.__zapr   = _list[5]
    self.__latapr = _list[6]
    self.__lonapr = _list[7]
    self.__hgtapr = _list[8]
    # print 'Constructing new obj:', _name

    xapr2  = _list[9][0]
    if xapr2 != self.__xapr:
      raise RuntimeError('Incompatible station info for station %s (x)' %self.__name)
    self.__xest   = _list[9][1]
    self.__xcor   = _list[9][2]
    self.__xrms   = _list[9][3]

    yapr2  = _list[10][0]
    if yapr2 != self.__yapr:
      raise RuntimeError('Incompatible station info for station %s (y)' %self.__name)
    self.__yest   = _list[10][1]
    self.__ycor   = _list[10][2]
    self.__yrms   = _list[10][3]

    zapr2  = _list[11][0]
    if zapr2 != self.__zapr:
      raise RuntimeError('Incompatible station info for station %s (z)' %self.__name)
    self.__zest   = _list[11][1]
    self.__zcor   = _list[11][2]
    self.__zrms   = _list[11][3]

    uapr2  = _list[12][0]
    if uapr2 != self.__hgtapr:
      raise RuntimeError('Incompatible station info for station %s (h)' %self.__name)
    self.__uest   = _list[12][1]
    self.__ucor   = _list[12][2]
    self.__urms   = _list[12][3]

    napr2  = _list[13][0]
    if napr2 != self.__latapr:
      raise RuntimeError('Incompatible station info for station %s (lat)' %self.__name)
    self.__nest   = _list[13][1]
    self.__ncor   = _list[13][2]
    self.__nrms   = _list[13][3]

    eapr2  = _list[14][0]
    if eapr2 != self.__lonapr:
      raise RuntimeError('Incompatible station info for station %s (lon)' %self.__name)
    self.__eest   = _list[14][1]
    self.__ecor   = _list[14][2]
    self.__erms   = _list[14][3]

    ## TODO what ellipsoid ?? which is the reference point ??
    self.__dn, self.__de, self.__du = bernutils.geodesy.cartesian2topocentric(self.__xapr, self.__yapr, self.__zapr, self.__xest, self.__yest, self.__zest)

  def sta(self)   : return self.__name
  def xest(self)  : return float(self.__xest)
  def xapr(self)  : return float(self.__xapr)
  def xcor(self)  : return float(self.__xcor)
  def xrms(self)  : return float(self.__xrms)
  def yest(self)  : return float(self.__yest)
  def yapr(self)  : return float(self.__yapr)
  def ycor(self)  : return float(self.__ycor)
  def yrms(self)  : return float(self.__yrms)
  def zest(self)  : return float(self.__zest)
  def zapr(self)  : return float(self.__zapr)
  def zcor(self)  : return float(self.__zcor)
  def zrms(self)  : return float(self.__zrms)
  def latest(self): return float(self.__nest)
  def latapr(self): return float(self.__latapr)
  def latcor(self): return float(self.__ncor)
  def latrms(self): return float(self.__nrms)
  def lonest(self): return float(self.__eest)
  def lonapr(self): return float(self.__lonapr)
  def loncor(self): return float(self.__ecor)
  def lonrms(self): return float(self.__erms)
  def hgtest(self): return float(self.__uest)
  def hgtapr(self): return float(self.__hgtapr)
  def hgtcor(self): return float(self.__ucor)
  def hgtrms(self): return float(self.__urms)
  def adjtp(self) : return self.__adjt
  def north(self) : return self.__dn
  def east(self)  : return self.__de
  def up(self)    : return self.__du

  def tojson(self):
    jstr = "{ \"name\":\"%s\", \"xest\":%15.4f, \"yest\":%15.4f,\"zest\":%15.4f,\"xapr\":%15.4f,\"yapr\":%15.4f,\"zapr\":%15.4f,\"xcor\":%15.4f,\"ycor\":%15.4f,\"zcor\":%15.4f,\"xrms\":%15.4f,\"yrms\":%15.4f,\"zrms\":%15.4f,\"latest\":%15.4f,\"lonest\":%15.4f,\"hgtest\":%15.4f,\"latapr\":%15.4f,\"lonapr\":%15.4f,\"hgtapr\":%15.4f,\"latcor\":%15.4f,\"loncor\":%15.4f,\"hgtcor\":%15.4f,\"latrms\":%15.4f,\"lonrms\":%15.4f,\"hgtrms\":%15.4f,\"north\":%15.4f,\"east\":%15.4f,\"up\":%15.4f,\"adj\":\"%s\" }"%(self.sta(), self.xest(),self.yest(),self.zest(),self.xapr(),self.yapr(),self.zapr(),self.xcor(),self.ycor(),self.zcor(),self.xrms(),self.yrms(),self.zrms(),self.latest(),self.lonest(),self.hgtest(),self.latapr(),self.lonapr(),self.hgtapr(),self.latcor(),self.loncor(),self.hgtcor(),self.latrms(),self.lonrms(),self.hgtrms(),self.north(),self.east(),self.up(),self.adjtp())
    return jstr;

func_dict = { 'x': FullStationRecord.xest, 
  'xapr': FullStationRecord.xapr,
  'xcor': FullStationRecord.xcor,
  'xrms': FullStationRecord.xrms,
  'y'   : FullStationRecord.yest, 
  'yapr': FullStationRecord.yapr,
  'ycor': FullStationRecord.ycor,
  'yrms': FullStationRecord.yrms,
  'z'   : FullStationRecord.zest, 
  'zapr': FullStationRecord.zapr,
  'zcor': FullStationRecord.zcor,
  'zrms': FullStationRecord.zrms,
  'lat' : FullStationRecord.latest, 
  'latapr': FullStationRecord.latapr,
  'latcor': FullStationRecord.latcor,
  'latrms': FullStationRecord.latrms,
  'lon'   : FullStationRecord.lonest, 
  'lonapr': FullStationRecord.lonapr,
  'loncor': FullStationRecord.loncor,
  'lonrms': FullStationRecord.lonrms,
  'hgt'   : FullStationRecord.hgtest, 
  'hgtapr': FullStationRecord.hgtapr,
  'hgtcor': FullStationRecord.hgtcor,
  'hgtrms': FullStationRecord.hgtrms,
  'adj'   : FullStationRecord.adjtp,
  'dn'    : FullStationRecord.north,
  'de'    : FullStationRecord.east,
  'du'    : FullStationRecord.up
}
''' Ah! the dictionary! This dictionary matches a string literal with a member
    function of the ``FullStationRecord`` class. 

    .. warning:: The literals must match exactly the dictionary ``html_header_dict``.
'''

html_header_dict = { 'x': 'X', 
  'xapr'  : 'Xapr',
  'xcor'  : 'Xcor',
  'xrms'  : 'Xrms',
  'y'     : 'Y',
  'yapr'  : 'Yapr',
  'ycor'  : 'Ycor',
  'yrms'  : 'Yrms',
  'z'     : 'Z',
  'zapr'  : 'Zapr',
  'zcor'  : 'Zcor',
  'zrms'  : 'Zrms',
  'lat'   : 'Latitude',
  'latapr': 'Lat-Apr',
  'latcor': 'Lat-Cor',
  'latrms': 'Lat-rms',
  'lon'   : 'Longtitude',
  'lonapr': 'Lon-Apr',
  'loncor': 'Lon-Cor',
  'lonrms': 'Lon-Rms',
  'hgt'   : 'Height',
  'hgtapr': 'Hgt-Apr',
  'hgtcor': 'Hgt-Cor',
  'hgtrms': 'Hgt-Rms',
  'adj'   : 'Adjustment',
  'dn'    : 'dNorth',
  'de'    : 'dEast',
  'du'    : 'dUp'
}

class AddneqFile:
  ''' A class to hold ADDNEQ2 output/summary files.
  '''

  def __init__(self, filen):
    if not os.path.isfile(filen):
      raise RuntimeError('Cannot find ADDNEQ2 file [%s]' %filen)
    self.__filename = filen
    self.read_header()

  def read_header(self):
    ''' Read header, validate and assign basic information. A header block,
        looks like: ::

          ===================================================================================================================================
          Bernese GNSS Software, Version 5.2
          -----------------------------------------------------------------------------------------------------------------------------------
          Program        : ADDNEQ2
          Purpose        : Combine normal equation systems
          -----------------------------------------------------------------------------------------------------------------------------------
          Campaign       : ${P}/GREECE
          Default session: 0540 year 2012
          Date           : 07-Jun-2014 01:22:57
          User name      : bpe2
          ===================================================================================================================================

    '''
    header_lines = []
    with open(self.__filename, 'r') as fin:
      for i in range(0, 12):
        line = fin.readline().strip()
        if len(line) > 0 and line[0:5] != '=====' and line[0:5] != '-----':
          header_lines.append(line)
    if header_lines[0] != 'Bernese GNSS Software, Version 5.2':
      raise RuntimeError('Invalid ADDNEQ header for file [%s] (1)' %self.__filename)
    sln = header_lines[1].split()
    if sln[0] != 'Program':
      raise RuntimeError('Invalid ADDNEQ header for file [%s] (2)' %self.__filename)
    sln = header_lines[2].split()
    if sln[0] != 'Purpose':
      raise RuntimeError('Invalid ADDNEQ header for file [%s] (3)' %self.__filename)
    sln = header_lines[3].split()
    if sln[0] != 'Campaign':
      raise RuntimeError('Invalid ADDNEQ header for file [%s] (4)' %self.__filename)
    else:
      self.__campaign_name = os.path.basename(sln[2])
      self.__campaign_path = os.path.dirname(sln[2])
    sln = header_lines[4].split()
    if sln[0] + sln[1] != 'Defaultsession:':
      raise RuntimeError('Invalid ADDNEQ header for file [%s] (5)' %self.__filename)
    else:
      doy  = sln[2][0:3]
      ses  = sln[2][-1]
      year = sln[4]
      self.__date = datetime.datetime.strptime('%s-%s'%(year, doy), '%Y-%j')
      self.__ses  = ses
    sln = header_lines[5].split()
    if sln[0] != 'Date':
      raise RuntimeError('Invalid ADDNEQ header for file [%s] (6)' %self.__filename)
    else:
      self.__run_at = datetime.datetime.strptime('%s-%s'%(sln[2], sln[3]), '%d-%b-%Y-%H:%M:%S')
    sln = header_lines[6].split()
    if sln[0] != 'User':
      raise RuntimeError('Invalid ADDNEQ header for file [%s] (7)' %self.__filename)
    else:
      self.__user = sln[3]

  def filename(self): return self.__filename
  def campaign(self): return self.__campaign_name
  def date(self):     return self.__date
  def session(self):  return self.__ses
  def run_at(self):   return self.__run_at
  def run_by(self):   return self.__user

  def apriori_info(self):

    with open(self.__filename, 'r') as fin:

      ## 
      line = fin.readline()
      while line:
        if line == ' A PRIORI INFORMATION\n':
          break
        line = fin.readline()

      if not line:
        raise RuntimeError('Cannot find a-priori Information for file %s (1)' %self.__filename)

      # get 'a-priori sigma of unit weight'
      for i in range(0, 5): line = fin.readline()
      if line[0:31] != ' A priori sigma of unit weight:':
        raise RuntimeError('Cannot find a-priori Information for file %s (2)' %self.__filename)
      apr_sigma = float(line[32:].replace('m',''))

      #
      for i in range(0, 8): line = fin.readline()
      if line != ' Datum name         Ell. param./ Scale      Shifts to WGS-84       Rotations to WGS-84\n':
        raise RuntimeError('Cannot find a-priori Information for file %s (3)' %self.__filename)
      line = fin.readline()
      line = fin.readline()
      lns = line.split()
      ref_frame = lns[0]
      if lns[1] != 'A' or lns[2] != '=' or lns[5] != 'DX':
        raise RuntimeError('Cannot find a-priori Information for file %s (4)' %self.__filename)

      line = fin.readline()
      while line:
        if line.strip() == 'Network constraints:':
          break
        line = fin.readline()

      if not line:
        raise RuntimeError('Cannot find a-priori Information for file %s (5)' %self.__filename)

      line = fin.readline()
      line = fin.readline()
      if line.strip() != 'Component                      A priori sigma  Unit':
        raise RuntimeError('Cannot find a-priori Information for file %s (6)' %self.__filename)

      adj_cmp = []
      line = fin.readline()
      line = fin.readline()
      while line and len(line) > 5:
        param = line[0:33].strip()
        sigma = line[33:47].strip()
        unit  = line[47:].strip()
        adj_cmp.append([param, sigma, unit])
        line = fin.readline()

    return apr_sigma, ref_frame, adj_cmp

  def get_nq_files(self):
    ''' Return (as dictionary) the Normal Equation files that were combined to
        produce this ADDNEQ2 file, along with their detailed information.

        The block of records we will try to extract is: ::

          INPUT NORMAL EQUATION FILES
          ---------------------------

          -----------------------------------------------------------------------------------------------------------------------------------
          File  Name                             
          -----------------------------------------------------------------------------------------------------------------------------------
              1  ${P}/GREECE/SOL/FFG0540001.NQ0   
              2  ${P}/GREECE/SOL/FFG0540002.NQ0   
              3  ${P}/GREECE/SOL/FFG0540003.NQ0   
              4  ${P}/GREECE/SOL/FFG0540004.NQ0   
              5  ${P}/GREECE/SOL/FFG0540005.NQ0   
              6  ${P}/GREECE/SOL/FFG0540006.NQ0   
              7  ${P}/GREECE/SOL/FFG0540007.NQ0   
          -----------------------------------------------------------------------------------------------------------------------------------


          Main characteristics of normal equation files:
          ---------------------------------------------

          File  From                 To                   Number of observations / parameters / degree of freedom
          -----------------------------------------------------------------------------------------------------------------------------------
              1  2012-02-23 00:00:00  2012-02-24 00:00:00                  29369          518        28851
              2  2012-02-23 00:00:00  2012-02-24 00:00:00                  33065          618        32447
              3  2012-02-23 00:00:00  2012-02-24 00:00:00                  12679          298        12381
              4  2012-02-23 00:00:00  2012-02-24 00:00:00                  19665          378        19287
              5  2012-02-23 00:00:00  2012-02-24 00:00:00                  14217          360        13857
              6  2012-02-23 00:00:00  2012-02-24 00:00:00                   6202          152         6050
              7  2012-02-23 00:00:00  2012-02-24 00:00:00                   9709          158         9551
          -----------------------------------------------------------------------------------------------------------------------------------


        :returns: A dictionary with keys the number of the files, and values all
          other info, i.e. a list of type: [filename, start, stop, observations, parameters, degrees_of_freedom].
          For the xample extract above, we will have an entry in the dictionary e.g. ::

            4 ['${P}/GREECE/SOL/FFG0540004.NQ0', datetime.datetime(2012, 2, 23, 0, 0), datetime.datetime(2012, 2, 24, 0, 0), 19665, 378, 19287]

    '''

    with open(self.__filename, 'r') as fin:

      ## find the start of the block
      line = fin.readline()
      while line:
        if line == ' INPUT NORMAL EQUATION FILES\n':
          break
        line = fin.readline()

      if not line:
        raise RuntimeError('Cannot find Normal Equation Information for file %s (1)' %self.__filename)

      ## skip the next 5 lines
      for i in range(0, 5):
        line = fin.readline()

      nq_file_list = {}
      ## keep on reading NQ files until line = '----...'
      line = fin.readline()
      while line[0:5] != ' ----':
        lns = line.split()
        nq_file_list[int(lns[0])] = lns[1]
        line = fin.readline()

      ## keep on reading untill next block
      line = fin.readline()
      while line:
        if line == ' Main characteristics of normal equation files:\n':
          break
        line = fin.readline()

      if not line:
        raise RuntimeError('Cannot find Normal Equation Information for file %s (2)' %self.__filename)

      ## skip the next 4 lines
      for i in range(0, 4): line = fin.readline()

      nq_info_list = {}
      ## keep on reading NQ file info until line = '----...'
      line = fin.readline()
      while line[0:5] != ' ----':
        lns = line.split()
        start = datetime.datetime.strptime('%s %s'%(lns[1], lns[2]),'%Y-%m-%d %H:%M:%S')
        stop  = datetime.datetime.strptime('%s %s'%(lns[3], lns[4]),'%Y-%m-%d %H:%M:%S')
        obs   = int(lns[5])
        par   = int(lns[6])
        fre   = int(lns[7])
        nq_info_list[int(lns[0])] = [start, stop, obs, par, fre]
        line = fin.readline()

    ## Combine the two dictionaries (don't need the file anymore)
    if len(nq_file_list) != len(nq_info_list):
      raise RuntimeError('Cannot find Normal Equation Information for file %s (3)' %self.__filename)
    ret_dict = {}
    for idx, fl  in nq_file_list.iteritems():
      inf = nq_info_list[idx]
      ret_dict[idx] = [fl] + inf

    return ret_dict

  def __resolve_station_block__(self, block):
    ''' Resolve a station-specif block of information, i.e. something like: ::

          ANKR                  X      4121948.46828    4121948.47206       0.00378       0.00212
                                Y      2652187.87567    2652187.87553      -0.00014       0.00125
                                Z      4069023.81932    4069023.82211       0.00279       0.00189

                                U          976.01929        976.02347       0.00417       0.00292     0.00293    4.8
                                N         39.8873720       39.8873720       0.00015       0.00080     0.00066   83.9     0.00069   91.0
                                E         32.7584700       32.7584699      -0.00216       0.00069     0.00079    1.8     0.00080

        Note that the last line is empty!

        :param block: A list of 8 lines (two of which are empty) with station records
          (exactly as the block above).

        :return: A list with the following info: ``[name, X, sx, dx, ...]

    '''
    rblock = [ x.lstrip() for x in block if len(x) > 1 ]

    name = rblock[0][0:15].strip()
    lns  = rblock[0][25:].split()
    if rblock[0][22:23] != 'X' or len(lns) != 4 :
      raise RuntimeError('Invalid station block (X) [%s]' %rblock[0])
    x_apr, x_est, x_cor, x_rms = [ float(i) for i in lns ]

    lns  = rblock[1].split()
    if lns[0] != 'Y' or len(lns) != 5 :
      raise RuntimeError('Invalid station block (Y) [%s]' %rblock[1])
    y_apr, y_est, y_cor, y_rms = [ float(i) for i in lns[1:] ]

    lns  = rblock[2].split()
    if lns[0] != 'Z' or len(lns) != 5 :
      raise RuntimeError('Invalid station block (Z) [%s]' %rblock[2])
    z_apr, z_est, z_cor, z_rms = [ float(i) for i in lns[1:] ]

    lns  = rblock[3].split()
    if lns[0] != 'U' or len(lns) != 7 :
      raise RuntimeError('Invalid station block (U) [%s]' %rblock[3])
    u_apr, u_est, u_cor, u_rms, u_e3d, u_angle_e3d = [ float(i) for i in lns[1:] ]

    lns  = rblock[4].split()
    if lns[0] != 'N' or len(lns) != 9 :
      raise RuntimeError('Invalid station block (N) [%s]' %rblock[4])
    n_apr, n_est, n_cor, n_rms, n_e3d, n_angle_e3d, n_e2d, angle_e2d = [ float(i) for i in lns[1:] ]

    lns  = rblock[5].split()
    if lns[0] != 'E' or len(lns) != 8 :
      raise RuntimeError('Invalid station block (E) [%s]' %rblock[5])
    e_apr, e_est, e_cor, e_rms, e_e3d, e_angle_e3d, e_e2d = [ float(i) for i in lns[1:] ]

    ##  debug
    ## print 'got point ->', name, '(__resolve_station_block__)'

    return [ name, \
      [x_apr, x_est, x_cor, x_rms], \
      [y_apr, y_est, y_cor, y_rms], \
      [z_apr, z_est, z_cor, z_rms], \
      [u_apr, u_est, u_cor, u_rms, u_e3d, u_angle_e3d], \
      [n_apr, n_est, n_cor, n_rms, n_e3d, n_angle_e3d, n_e2d, angle_e2d], \
      [e_apr, e_est, e_cor, e_rms, e_e3d, e_angle_e3d, e_e2d] ]

  def get_station_coordinates(self):
    ''' Collect coordinate information of from a block of type: ::

          Station coordinates and velocities:
          ----------------------------------
          Reference epoch: 2012-02-23 12:00:00

          Station name          Typ   A priori value  Estimated value    Correction     RMS error      3-D ellipsoid        2-D ellipse
          ------------------------------------------------------------------------------------------------------------------------------------
          ANKR                  X      4121948.46828    4121948.47206       0.00378       0.00212
                                Y      2652187.87567    2652187.87553      -0.00014       0.00125
                                Z      4069023.81932    4069023.82211       0.00279       0.00189

                                U          976.01929        976.02347       0.00417       0.00292     0.00293    4.8
                                N         39.8873720       39.8873720       0.00015       0.00080     0.00066   83.9     0.00069   91.0
                                E         32.7584700       32.7584699      -0.00216       0.00069     0.00079    1.8     0.00080

        :returns: A dictionary where the key = station_name and value is a list of lists
          containing coordinate components info, as follows:
          [ [x_apr, x_est, x_cor, x_rms], \
            [y_apr, y_est, y_cor, y_rms], \
            [z_apr, z_est, z_cor, z_rms], \
            [u_apr, u_est, u_cor, u_rms, u_e3d, u_angle_e3d], \
            [n_apr, n_est, n_cor, n_rms, n_e3d, n_angle_e3d, n_e2d, angle_e2d], \
            [e_apr, e_est, e_cor, e_rms, e_e3d, e_angle_e3d, e_e2d] \
          ]

    '''
    with open(self.__filename, 'r') as fin:

      ##  find the start of the block
      ##  WARNING There is one more than one block starting with the string:
      ##+ 'Station coordinates and velocities:\n', so we need to make sure we
      ##+ get to the right one!. The one we want, is at the section:
      ##+ ' SUMMARY OF RESULTS', but it not he first one!
      sumary_of_results_found = False
      line = fin.readline()
      while line:
        if line == ' Station coordinates and velocities:\n' and sumary_of_results_found == True:
          line = fin.readline()
          line = fin.readline()
          if len(line.split()) == 4:
            break
        if line == ' SUMMARY OF RESULTS\n':
          sumary_of_results_found = True
        line = fin.readline()

      if not line:
        raise RuntimeError('Cannot find Station Information for file %s (1)' %self.__filename)

      ## resolve reference epoch (we should have already read that line)
      lns = line.split()
      reference_epoch = datetime.datetime.strptime('%s %s'%(lns[2], lns[3]),'%Y-%m-%d %H:%M:%S')

      ## verify header
      line = fin.readline()
      line = fin.readline()
      if line != ' Station name          Typ   A priori value  Estimated value    Correction     RMS error      3-D ellipsoid        2-D ellipse\n':
        raise RuntimeError('Cannot find Sation Information for file %s (2)' %self.__filename)
      line = fin.readline()

      ## dictionary to return
      ret_dict = {}

      ## read one station block at a time, untill no more
      nr_sta = 0
      block  = []
      line   = fin.readline()
      while len(line) > 2:
        block.append(line)
        for i in range(0, 7):
          block.append(fin.readline())
        ## print 'resolving station block:', block
        tmp_list = self.__resolve_station_block__(block)
        ret_dict[tmp_list[0]] = tmp_list[1:]
        nr_sta += 1
        line = fin.readline()
        block= []

    return ret_dict

  def get_apriori_coordinates(self):
    '''Collect coordinates and other information of from a block of type: ::

          A priori station coordinates:              ${P}/GREECE/STA/APR120540.CRD

                                                      A priori station coordinates                 A priori station coordinates
                                                                IGb08                          Ellipsoidal in local geodetic datum
          ------------------------------------------------------------------------------------------------------------------------------------
          num  Station name     obs e/f/h        X (m)           Y (m)           Z (m)        Latitude       Longitude    Height (m)
          ------------------------------------------------------------------------------------------------------------------------------------
            1  ANKR              Y  HELMR   4121948.46828   2652187.87567   4069023.81932     39.8873720     32.7584700    976.01929
            2  ARTU              Y  HELMR   1843956.54950   3016203.17700   5291261.76480     56.4298220     58.5604596    247.57539
            3  ATAL              Y  ESTIM   4591113.75160   1948751.15960   3962396.61490     38.6530580     22.9993549    135.12461

        i.e., basicaly collect a-priori coordinates!.

        :returns: A dictionary, with key = stations_name and value a list with all
          collected information, i.e. a list of type: [num, obs, adjt, x, y, z, lat, lon, hgt]

    '''
    sta_dict = {}

    with open(self.__filename, 'r') as fin:
      line = fin.readline()
      while line:
        if line[0:len('  A priori station coordinates:')-1] == ' A priori station coordinates:':
          break
        line = fin.readline()
      if not line:
        raise RuntimeError('Cannot find A-priori Station Information for file %s (1)' %self.__filename)

      a_priori_file = line[0:len('  A priori station coordinates:')+1].strip()

      ## next line is empty
      line = fin.readline()

      ## no info in this line; just validate
      line = fin.readline()
      if line.strip() != 'A priori station coordinates                 A priori station coordinates':
        raise RuntimeError('Cannot find A-priori Station Information for file %s (2)' %self.__filename)

      ## get the reference frame
      line = fin.readline()
      reference_frame = line.split()[0]

      ##
      line = fin.readline()
      line = fin.readline()
      if line.rstrip() != ' num  Station name     obs e/f/h        X (m)           Y (m)           Z (m)        Latitude       Longitude    Height (m)':
        raise RuntimeError('Cannot find A-priori Station Information for file %s (3)' %self.__filename)
      line = fin.readline()

      ## read until next empty line
      line = fin.readline()
      while line and len(line) > 1:
        aa   = int(line[0:5])
        name = line[5:22].strip()
        lns  = line[22:].split()
        obs  = lns[0]
        adjt = lns[1]
        x, y, z, lat, lon, hgt = [ float(x) for x in lns[2:] ]
        sta_dict[name] = [aa, obs, adjt, x, y, z, lat, lon, hgt]
        line = fin.readline()
        ## print 'got new station (a-priori)', name

    return sta_dict

  def warnings(self, format_str, html_output=False, mdict=None):
    ''' This function will output warning messages depending on criteria given as
        input. The output can be formated as html or plain text.

        :param format_str: A string created from comma-seperated substrings, each of
          which describes a field to be checked against a given value. These sub-
          strings are made-up of thwo parts: 1. the name of a valid field to check,
          and 2. a limit to check against; the two parts are seperated by a ``'='`` char.
          The substrings must match the ones in the ``func_dict`` dictionary. E.g., using: ::

            foo.warnings('dn=.001,de=.002,du=.003', True)

          where foo is a ``AddneqFile`` instance will create an html file, with
          warnings for every station in the ADDNEQ file for which is dNorth value
          is greater than .001 meters, or it's dEast > .002 or its dU > .003.

        :param html_output: If set to True, the output is going to be formated
          as an html file; else plain ascii.

        :param mdict: (Optional) If set, then the function will **NOT** seacrch
          through the file to collect station information; it will use the
          elements from the ``mdict`` dictionary. This dictionary should have
          key = stations name and value = corresponding FullStationRecord instance.

        .. note:: To produce nice-looking html warning messages, we will us Bootstrap,
          see http://www.w3schools.com/bootstrap/bootstrap_get_started.asp
    '''

    ## In case we want html output, we will use Bootstrap
    ## http://www.w3schools.com/bootstrap/bootstrap_get_started.asp
    if html_output == True:
      print '<!DOCTYPE html>'\
        '<html lang=\"en\">'\
        '<head>'\
          '<title>Some Title</title>'\
          '<meta charset=\"utf-8\">'\
          '<meta name=\"viewport\" content=\"width=device-width, initial-scale=1\">'\
          '<link rel=\"stylesheet\" href=\"http://maxcdn.bootstrapcdn.com/bootstrap/3.3.5/css/bootstrap.min.css\">'\
          '<script src=\"https://ajax.googleapis.com/ajax/libs/jquery/1.11.3/jquery.min.js\"></script>'\
          '<script src=\"http://maxcdn.bootstrapcdn.com/bootstrap/3.3.5/js/bootstrap.min.js\"></script>'\
        '</head>'\
        '<body>'


    if not mdict:
      lst1  = self.get_station_coordinates()
      dict1 = self.get_apriori_coordinates()

      ##  combine into a single dictionary, with name as key
      ##+ and values of type FullStationRecord
      for key, val in dict1.iteritems():
        full_info = val + lst1[key]
        dict1[key] = FullStationRecord(key, full_info)

      mdict = dict1

    for sta, val in mdict.iteritems():
      for frm in format_str.split(','):
        func, limit = frm.split('=')
        limit = float(limit)
        if abs(func_dict[func](val)) > limit:
          func_name = html_header_dict[func]
          warn_str = 'Station %s has %s = %.4f ; limit = %.4f' %(sta, func_name, func_dict[func](val), limit)
          if html_output == True:
            print '<div class=\"alert alert-danger\">'\
              '<a href=\"#\" class=\"close\" data-dismiss=\"alert\" aria-label=\"close\">&times;</a>'\
              '<strong>Warning!</strong> %s.' \
            '</div>' %(warn_str)
          else:
            print '[WARNING]', warn_str

  def toJson(self):
    lst1  = self.get_station_coordinates() ## in the old days, this was a list!
    dict1 = self.get_apriori_coordinates()
    assert len(lst1) == len(dict1)
    ##  combine into a single dictionary, with name as key
    ##+ and values of type FullStationRecord
    for key, val in dict1.iteritems():
      full_info  = val + lst1[key]
      dict1[key] = FullStationRecord(key, full_info)
    assert len(lst1) == len(dict1)
    print "\"addneq_summary\":["
    it = 0
    for sta, val in dict1.iteritems():
      print val.tojson(),
      it += 1
      if it > len(dict1) - 1:
        print ''
      else:
        print ','
    print ']'
    #json.dump(dict1, sys.stdout, indent=4)

  def toHtml(self, format_str, warnings_str=None):
    ''' Create an html table with adjustment information. The user can select the
        type of information to be recorded.

        :param format_str: A string created from comma-seperated substrings, each of
          which describes a field to appear on the table. The substrings must match
          the ones in the ``func_dict`` dictionary. E.g., using: ::

              foo.toHtml('latcor,dn,loncor,de,hgtcor,du')

          where foo is a ``AddneqFile`` instance will create an html table with
          columns = [Name, Latitude Correction, DNorth, Longtitude Correction, DEast, Height Correction, DUp]

        :param warnings_str: If set, the function :func:`warnings` will be used
          to produce warning messages. This parameter is going to act as the input
          parameter to the :func:`warnings` function.

    '''

    lst1  = self.get_station_coordinates() ## in the old days, this was a list!
    dict1 = self.get_apriori_coordinates()

    ##  combine into a single dictionary, with name as key
    ##+ and values of type FullStationRecord
    for key, val in dict1.iteritems():
      full_info = val + lst1[key]
      dict1[key] = FullStationRecord(key, full_info)

    ## Table header
    print """<table style="width:100%" id="t01" border="1">"""
    print "\t<thead>"
    print "\t<tr>"
    print '<th>Station</th>'
    for frm in format_str.split(','):
      print '<th>', html_header_dict[frm], '</th>'
    print "\t</tr>"
    print "\t</thead>"

    print "\t<tbody>"

    for sta, val in dict1.iteritems():
      print '<tr>'
      print '<th>%s</th>' %sta
      for frm in format_str.split(','):
        param = func_dict[frm](val)
        if type(param) != str:
          print '<th>%.4f</th>' %func_dict[frm](val)
        else:
          print '<th>%s</th>' %func_dict[frm](val)
      print '</tr>'

    print "\t</tbody>"
    print "\t<caption>Adjustment information, extracted from %s at %s</caption>" %(self.__filename, datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S'))
    print "</table>"

    if warnings_str != None:
      self.warnings(warnings_str, html_output=True, mdict=dict1)
