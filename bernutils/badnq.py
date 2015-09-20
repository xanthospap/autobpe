import os
import datetime
import bernutils.geodesy

class FullStationRecord:
  
  def __init__(self, _list):
    ## [aa, obs, adjt, x, y, z, lat, lon, hgt, name,
    ## [x_apr, x_est, x_cor, x_rms]
    ## [y_apr, y_est, y_cor, y_rms]
    ## [z_apr, z_est, z_cor, z_rms]
    ## [u_apr, u_est, u_cor, u_rms, u_e3d, u_angle_e3d]
    ## [n_apr, n_est, n_cor, n_rms, n_e3d, n_angle_e3d, n_e2d, angle_e2d]
    ## [e_apr, e_est, e_cor, e_rms, e_e3d, e_angle_e3d, e_e2d]
    ## ]

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
    self.__name   = _list[9]
    
    xapr2  = _list[10][0]
    if xapr2 != self.__xapr:
      raise RuntimeError('Incompatible station info for station %s (x)' %self.__name)
    self.__xest   = _list[10][1]
    self.__xcor   = _list[10][2]
    self.__xrms   = _list[10][3]
    
    yapr2  = _list[11][0]
    if yapr2 != self.__yapr:
      raise RuntimeError('Incompatible station info for station %s (y)' %self.__name)
    self.__yest   = _list[11][1]
    self.__ycor   = _list[11][2]
    self.__yrms   = _list[11][3]
    
    zapr2  = _list[12][0]
    if zapr2 != self.__zapr:
      raise RuntimeError('Incompatible station info for station %s (z)' %self.__name)
    self.__zest   = _list[12][1]
    self.__zcor   = _list[12][2]
    self.__zrms   = _list[12][3]
    
    uapr2  = _list[13][0]
    if uapr2 != self.__hgtapr:
      raise RuntimeError('Incompatible station info for station %s (h)' %self.__name)
    self.__uest   = _list[13][1]
    self.__ucor   = _list[13][2]
    self.__urms   = _list[13][3]
    
    napr2  = _list[14][0]
    if napr2 != self.__latapr:
      raise RuntimeError('Incompatible station info for station %s (lat)' %self.__name)
    self.__nest   = _list[14][1]
    self.__ncor   = _list[14][2]
    self.__nrms   = _list[14][3]
    
    eapr2  = _list[15][0]
    if eapr2 != self.__lonapr:
      raise RuntimeError('Incompatible station info for station %s (lon)' %self.__name)
    self.__eest   = _list[15][1]
    self.__ecor   = _list[15][2]
    self.__erms   = _list[15][3]
    
    ## TODO what ellipsoid ?? which is the reference point ??
    self.__dn, self.__de, self.__du = bernutils.geodesy.cartesian2topocentric(self.__xapr, self.__yapr, self.__zapr, self.__xest, self.__yest, self.__zest)
  
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

  def __init__(self, filen):
    if not os.path.isfile(filen):
      raise RuntimeError('Cannot find ADDNEQ2 file [%s]' %filen)
    self.__filename = filen

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
      self.__campaign_name = os.path.basename(sln[1])
      self.__campaign_path = os.path.dirname(sln[1])
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

        :return: A list with the following info: ``[name, X, sx, dx, 
        
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
    
    return [ name, \
      [x_apr, x_est, x_cor, x_rms], \
      [y_apr, y_est, y_cor, y_rms], \
      [z_apr, z_est, z_cor, z_rms], \
      [u_apr, u_est, u_cor, u_rms, u_e3d, u_angle_e3d], \
      [n_apr, n_est, n_cor, n_rms, n_e3d, n_angle_e3d, n_e2d, angle_e2d], \
      [e_apr, e_est, e_cor, e_rms, e_e3d, e_angle_e3d, e_e2d] ]

  def get_station_coordinates(self):
    ''' Collect oordinate information of from a block of type: ::
    
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

        :returns: A list of lists, each containing station-specific information, i.e.
          a list of lists :
          [name, \
          [x_apr, x_est, x_cor, x_rms], \
          [y_apr, y_est, y_cor, y_rms], \
          [z_apr, z_est, z_cor, z_rms], \
          [u_apr, u_est, u_cor, u_rms, u_e3d, u_angle_e3d], \
          [n_apr, n_est, n_cor, n_rms, n_e3d, n_angle_e3d, n_e2d, angle_e2d], \
          [e_apr, e_est, e_cor, e_rms, e_e3d, e_angle_e3d, e_e2d] ]

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
      
      ## 
      sta_crd = []
      
      ## read one station block at a time, untill no more
      nr_sta = 0
      block  = []
      line   = fin.readline()
      while len(line) > 2:
        block.append(line)
        for i in range(0, 7):
          block.append(fin.readline())
        sta_crd.append(self.__resolve_station_block__(block))
        nr_sta += 1
        line = fin.readline()
        block= []
      
    return sta_crd

  def get_apriori_coordinates(self):
    '''
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
        #print aa, obs, adjt, x, y, z, lat, lon, hgt
        sta_dict[name] = [aa, obs, adjt, x, y, z, lat, lon, hgt]
        line = fin.readline()
      
    return sta_dict

  def warnings(self, format_str, html_output=False):
    
    ## In case we want html output, we will use Bootstrap
    ## http://www.w3schools.com/bootstrap/bootstrap_get_started.asp
    if html_output == True:
      print '<!DOCTYPE html>'\
        '<html lang=\"en\">'\
        '<head>'\
          '<title>Bootstrap Example</title>'\
          '<meta charset=\"utf-8\">'\
          '<meta name=\"viewport\" content=\"width=device-width, initial-scale=1\">'\
          '<link rel=\"stylesheet\" href=\"http://maxcdn.bootstrapcdn.com/bootstrap/3.3.5/css/bootstrap.min.css\">'\
          '<script src=\"https://ajax.googleapis.com/ajax/libs/jquery/1.11.3/jquery.min.js\"></script>'\
          '<script src=\"http://maxcdn.bootstrapcdn.com/bootstrap/3.3.5/js/bootstrap.min.js\"></script>'\
        '</head>'\
        '<body>'                                                              

    
    lst1  = self.get_station_coordinates()
    dict1 = self.get_apriori_coordinates()
    
    ##  combine into a single dictionary, with name as key
    ##+ and values of type FullStationRecord
    for key, val in dict1.iteritems():
      lta = [ x for x in lst1 if x[0] == key ]
      full_tuple = val+lta[0]
      dict1[key] = FullStationRecord(full_tuple)

    for sta, val in dict1.iteritems():
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

  def toHtml(self, format_str):
    
    lst1  = self.get_station_coordinates()
    dict1 = self.get_apriori_coordinates()
    
    ##  combine into a single dictionary, with name as key
    ##+ and values of type FullStationRecord
    for key, val in dict1.iteritems():
      lta = [ x for x in lst1 if x[0] == key ]
      full_tuple = val+lta[0]
      dict1[key] = FullStationRecord(full_tuple)

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
        print '<th>%.4f</th>' %func_dict[frm](val)
      print '</tr>'
      
    print "\t</tbody>"
    print "\t<caption>Adjustment information, extracted from %s at %s</caption>" %(self.__filename, datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S'))
    print "</table>"