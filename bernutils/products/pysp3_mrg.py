''' @package merge_igl_igs
    @brief Function to merge two sp3 files

    Created         : Sep 2014
    Last Update     : Sep 2015

    List of Changes :

    National Technical University of Athens
    Dionysos Satellite Observatory
    Higher Geodesy Laboratory
'''

''' Import Libraries '''
import os
import sys
import datetime

def __close_fs(f1, f2):
  f1.close()
  f2.close()

def print_until_next_epoch (inf, line):
  ''' Print all lines untill next epoch header.

      :param inf:  The input file stream.

      :param line: The current line in buffer (read of from the ``inf`` stream.

      :returns: ``status, lines_read, last_line``

        * if status = -1, an error occured,
        * if status = -2, EOF encountered,
        * if status =  0,  all ok

  '''
  ln = line
  counter = 0
  while True:
    if ln[0] == '*':
      return 0, counter, ln
    if ln[0] == 'E':
      lns = ln.split()
      if lns[0] == 'EOF':
        return -2, counter, ln
    if ln[0] != 'P' and ln[0] != 'V':
      return -1, counter, ln
    print ln.strip()
    ln = inf.readline()
    counter += 1

def resolve_date_line (line):
  ''' Resolve an sp3 epoch line e.g. (``'*  2013  3  4 23 45  0.00000000'``) to 
      datetime.datetime instance
  '''
  l = line.split()
  if len(l) != 7:
    raise RuntimeError('ERROR (1) resolving epoch line: [%s]' %line)
  if l[0] != '*':
    raise RuntimeError('Error (2) resolving epoch line: [%s]' %line)
  try:
    iy, im, idom, ih, imn = [ int(x) for x in l[1:6] ]
    is_ = int(float(l[6]))
    if float(l[6]) != float (is_):
      raise RuntimeError('Error (2.5) resolving epoch line [%s] SECONDS NOT INTEGER !' %line)
  except:
    raise RuntimeError('Error (3) resolving epoch line [%s]' %line)
  try:
    d = datetime.datetime(iy,im,idom,ih,imn,is_)
  except:
    raise RuntimeError('Error (4) resolving epoch line [%s]' %line)
  return d

def __merge_igl_igs__(igsf, iglf):
  """
  """
  MIXED_GLONASS_SP3 = False
  SKIP_GPS_SATS     = 0

  try:
    gin = open (igsf, 'r')
    rin = open (iglf, 'r')
  except:
    raise RuntimeError('Unable to open input files')

  # number of current line
  gline_nr = 0
  rline_nr = 0

  '''
  ____LINE 1____________________________________________________________________
  read first line; must be the same ::

    #cP2013  8  3  0  0  0.00000000      96 ORBIT IGb08 HLM  IGS

  '''
  line_g = gin.readline ()
  line_r = rin.readline ()
  gline_nr = rline_nr = 1
  if line_g != line_r :
    __close_fs(gin, rin)
    raise RuntimeError('Error in line %4i' %gline_nr)
  ## write the first line
  print line_r,

  '''
  ____LINE 2____________________________________________________________________
  read second line; must be the same for the two orbit files ::

    ## 1751 518400.00000000   900.00000000 56507 0.0000000000000

  '''
  line_g = gin.readline ()
  line_r = rin.readline ()
  gline_nr+=1
  rline_nr+=1 
  if line_g != line_r :
    __close_fs(gin, rin)
    raise RuntimeError('Error in line %4i' %gline_nr)
  ## write the second line
  print line_r,

  '''
  ____LINES 3 - 7_______________________________________________________________
  third line contains number of sats and a list of the sats ::

    +   32   G01G02G03G04G05G06G07G08G09G10G11G12G13G14G15G16G17

  '''
  # first for gps
  gsats_s   = []
  line_g    = gin.readline().strip()
  gline_nr += 1
  try:
    gsats  = int(line_g[4:6])
  except:
    __close_fs(gin, rin)
    raise RuntimeError('Error in line %4i' %gline_nr)
  sat_str = line_g[9:]
  # read the following 4 lines
  for i in range(0, 4):
    line_g    = gin.readline ().strip ()
    gline_nr += 1
    if line_g[0] != '+' :
      __close_fs(gin, rin)
      raise RuntimeError('Error in line %4i' %gline_nr)
    sat_str += line_g[9:]
  # resolve satellites from accumulated line
  tl = [ sat_str[i:i+3] for i in range(0, len(sat_str), 3) ]
  for j in tl:
    if j != '  0':
      if j[0] != 'G' :
        __close_fs(gin, rin)
        raise RuntimeError('Error reading gps satellite: [%s]; line nr %4i' %(j, gline_nr))
      gsats_s.append(j)
  # see that all satellites are resolved
  if gsats != len(gsats_s):
    __close_fs(gin, rin)
    raise RuntimeError('Error reading gps satellites for file [%s]' %igsf)

  # then for glonass
  system_change = 0
  prev_system   = 'X'
  rsats_s   = []
  line_r    = rin.readline().strip();
  rline_nr +=1
  try:
    rsats  = int(line_r[4:6])
  except:
    __close_fs(gin, rin)
    raise RuntimeError('Error in line %4i' %rline_nr)
  sat_str = line_r[9:]
  # read the following 4 lines
  for i in range(0, 4):
    line_r    = rin.readline ().strip ()
    rline_nr += 1
    if line_r[0] != '+' :
      __close_fs(gin, rin)
      raise RuntimeError('Error in line %4i' %rline_nr)
    sat_str += line_r[9:]
  # resolve satellites from accumulated line
  tl = [ sat_str[i:i+3] for i in range(0, len(sat_str), 3) ]
  for j in tl:
    if j != '  0':
      ## diff +
      if j[0] != 'R' and j[0] != 'G':
        __close_fs(gin, rin)
        raise RuntimeError('Error reading glonass satellite: [%s]; line nr %4i' %(j, rline_nr))
      if j[0] == 'G':
        if prev_system == 'R':
          __close_fs(gin, rin)
          raise RuntimeError('Error reading glonass satellites: unordered gps/glo sats; line nr %4i' %(rline_nr))
        print >>sys.stderr, '[WARNING] Skippig gps satellite [%s] from glonass sp3'%(j)
        MIXED_GLONASS_SP3 = True
        SKIP_GPS_SATS += 1
        prev_system = 'G'
      else:
        rsats_s.append (j)
        prev_system = 'R'
  # see that all satellites are resolved
  if not MIXED_GLONASS_SP3 and rsats != len (rsats_s):
    __close_fs(gin, rin)
    raise RuntimeError('Error reading glonass satellites for file [%s]' %igsl)
  elif MIXED_GLONASS_SP3 and rsats != len(rsats_s) + SKIP_GPS_SATS:
    raise RuntimeError('Error reading glonass satellites for (mixed) file [%s]' %igsl)

  ##  AT THIS POINT THE LISTS gsats_s AND rsats_s CONTAIN ALL SATELLITES, GPS 
  ##+ PLUS GLONASS AS STRINGS

  ## write the accumulated satellites
  sat_str = gsats_s + rsats_s
  s=''
  for i in range(len(sat_str), 17*5):
    sat_str.append ('  0')
  # 17 sats in each line i.e. 17*3 = 51 chars
  print '+   %02i   %51s' %(rsats+gsats,s.join(sat_str[0:17]))
  print '+        %51s'   %(s.join(sat_str[17:2*17]))
  print '+        %51s'   %(s.join(sat_str[2*17:3*17]))
  print '+        %51s'   %(s.join(sat_str[3*17:4*17]))
  print '+        %51s'   %(s.join(sat_str[4*17:5*17]))

  '''
  ____LINES 8 - 12______________________________________________________________
  next 5 lines contain accuracy codes ::

    ++         2  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2

  '''
  # first for gps
  gsats_s = []
  sat_str = ''
  # read the following 5 lines
  for i in range(0,5):
    line_g = gin.readline().strip ()
    gline_nr += 1
    if line_g[0:2] != '++' :
      __close_fs(gin, rin)
      raise RuntimeError('Error in line %4i' %gline_nr)
    sat_str += line_g[9:]
  # resolve satellite accuracies from accumulated line
  tl = [ sat_str[i:i+3] for i in range(0, len(sat_str), 3) ]
  for j in tl:
    try:
      ij = int(j)
    except:
      __close_fs(gin, rin)
      raise RuntimeError('Error in line %4i' %gline_nr)
    gsats_s.append(j)
  # only save as many accuracies as the satellite number
  gsats_s = gsats_s[0:gsats]

  # then for glonass
  rsats_s = []
  sat_str = ''
  # read the following 5 lines
  for i in range (0,5):
    line_r = rin.readline().strip ()
    rline_nr+=1;
    if line_r[0:2] != '++' :
      __close_fs(gin, rin)
      raise RuntimeError('Error in line %4i' %rline_nr)
    sat_str += line_r[9:]
  # resolve satellite accuracies from accumulated line
  tl = [ sat_str[i:i+3] for i in range(0, len(sat_str), 3) ]
  code_nr = 0
  for j in tl:
    try:
      ij = int(j)
      code_nr += 1
    except:
      __close_fs(gin, rin)
      raise RuntimeError('Error in line %4i' %rline_nr)
    if code_nr > SKIP_GPS_SATS:
      rsats_s.append (j)
  # only save as many accuracies as the satellite number
  rsats_s = rsats_s[0:rsats]

  ## write info rof all satellites
  sat_str = gsats_s + rsats_s
  s=''
  for i in range (len(sat_str), 17*5):
    sat_str.append ('  0')
  # 17 sats in each line i.e. 17*3 = 51 chars
  print '++       %51s' %(s.join(sat_str[0:17]))
  print '++       %51s' %(s.join(sat_str[17:2*17]))
  print '++       %51s' %(s.join(sat_str[2*17:3*17]))
  print '++       %51s' %(s.join(sat_str[3*17:4*17]))
  print '++       %51s' %(s.join(sat_str[4*17:5*17]))

  '''
  ____LINE 13___________________________________________________________________
  THis line should follow the format: ::

    %c R  cc GPS ccc cccc cccc cccc cccc ccccc ccccc ccccc ccccc ## for lonass
    %c G  cc GPS ccc cccc cccc cccc cccc ccccc ccccc ccccc ccccc ## for gps
    ## we should write something like:
    %c ft  cc tsf ccc cccc cccc cccc cccc ccccc ccccc ccccc ccccc
    ##    ft: "G " for GPS only files
    ##        "M " for mixed files
    ##        "R " for GLONASS only files
    ## tsf: "GPS" for GPS time, "UTC" for UTC time

  '''
  line_g    = gin.readline ()
  line_r    = rin.readline ()
  gline_nr += 1
  rline_nr += 1
  gps_sys  = line_g[3:5].strip(' ')
  gps_tsys = line_g[9:12].strip()
  glo_sys  = line_r[3:5].strip()
  glo_tsys = line_r[9:12].strip()
  # chech the systems
  if gps_sys != 'G':
    __close_fs(gin, rin)
    raise RuntimeError('Error! Expected satellite system \"G\", found %s' %gps_sys)
  if MIXED_GLONASS_SP3:
    if glo_sys != 'M':
      __close_fs(gin, rin)
      raise RuntimeError('Error! Expected satellite system \"M\", found %s' %glo_sys)
  else:
    if glo_sys != 'R':
      __close_fs(gin, rin)
      raise RuntimeError('Error! Expected satellite system \"R\", found %s' %glo_sys)
  if gps_tsys != glo_tsys:
    __close_fs(gin, rin)
    raise RuntimeError('Error! Different time systems in orbit files')

  print '%%c %1s  cc %3s ccc cccc cccc cccc cccc ccccc ccccc ccccc ccccc' %('M',glo_tsys)

  '''
  ____LINE 14___________________________________________________________________
  this line hold nothing! ::

    %c cc cc ccc ccc cccc cccc cccc cccc ccccc ccccc ccccc ccccc

  '''
  line_g = gin.readline ()
  line_r = rin.readline ()
  gline_nr +=1
  rline_nr +=1
  print '%c cc cc ccc ccc cccc cccc cccc cccc ccccc ccccc ccccc ccccc'

  '''
  ____LINE 15___________________________________________________________________
  This line holds the base for Pos/Vel and Clk/Rate ::

    %f  1.2500000  1.025000000  0.00000000000  0.000000000000000

  '''
  line_g    = gin.readline().strip()
  line_r    = rin.readline().strip()
  gline_nr += 1
  rline_nr += 1
  gls = line_g.split()
  rls = line_r.split()
  try:
    g_base_for_pos = float(gls[1])
    g_base_for_clk = float(gls[2])
    r_base_for_pos = float(rls[1])
    r_base_for_clk = float(rls[2])
  except:
    __close_fs(gin, rin)
    raise RuntimeError('Error resolving base factors, line %2i' %gline_nr)

  if g_base_for_pos != r_base_for_pos or g_base_for_clk != r_base_for_clk:
    __close_fs(gin, rin)
    raise RuntimeError('Error different base factors, line %2i' %gline_nr)

  print '%%f %10.7f %12.9f  0.00000000000  0.000000000000000' %(g_base_for_pos, g_base_for_clk)

  '''
  ____LINES 16 - 18_____________________________________________________________
  these lines offer nothing! ::
  '''
  for i in range(0,3):
    line_g    = gin.readline ()
    line_r    = rin.readline ()
    gline_nr += 1
    rline_nr += 1

  print '%f  0.0000000  0.000000000  0.00000000000  0.000000000000000'
  print '%i    0    0    0    0      0      0      0      0         0'
  print '%i    0    0    0    0      0      0      0      0         0'

  '''
  ____COMMENT LINES (19 - 22)___________________________________________________
  '''
  while True:
    line_g    = gin.readline().strip()
    gline_nr += 1
    if line_g == 'EOF':
      __close_fs(gin, rin)
      raise RuntimeError('Error! EOF encountered while searching for comments! file : %s' %igsf)
    if line_g[0:2] == '/*':
      print line_g
    else:
      break

  while True:
    line_r = rin.readline().strip()
    rline_nr+=1;
    if line_r == 'EOF':
      __close_fs(gin, rin)
      raise RuntimeError('Error! EOF encountered while searching for comments! file : %s' %iglf)
    if line_r[0:2] == '/*':
      print line_r
    else:
      break

  nstr1 = '/* merged sp3 file G+R via bernutils@ntua '
  nstr2 = '/* files: %s and %s' %(os.path.basename(igsf), os.path.basename(iglf))
  if len(nstr2) >= 80 : nstr2 = nstr2[0:78]
  print nstr1
  print nstr2

  '''
  ____DATA LINES _______________________________________________________________
  '''
  ## Now the current lines for both files are the first epoch records, e.g.
  ## *  2013  3  4  0  0  0.00000000
  break_gps = False
  break_glo = False

  while (not break_gps) and (not break_glo):

    ## resolve dates
    gd = resolve_date_line(line_g)
    rd = resolve_date_line(line_r)

    ## first case, dates are the same
    if gd == rd:
      print line_g.strip()
      line_g    = gin.readline()
      gline_nr +=1
      i, c, line_g = print_until_next_epoch(gin, line_g)
      gline_nr +=c
      if i == -1:
        __close_fs(gin, rin)
      if i == -2:
        break_gps = True
      line_r    = rin.readline()
      rline_nr += 1
      i, c, line_r = print_until_next_epoch(rin, line_r)
      rline_nr += c
      if i == -1:
        __close_fs(gin, rin)
      if i == -2:
        break_glo = True

    elif gd > rd:
      print >>sys.stderr, '[WARNING] Epoch %s not available in gps orbit file' %rd
      print line_r.strip()
      line_r    = rin.readline()
      rline_nr += 1
      i, c, line_r = print_until_next_epoch(rin, line_r)
      rline_nr += c
      if i == -1:
        __close_fs(gin, rin)
      if i == -2:
        break_glo = True

    elif gd < rd:
      print >>sys.stderr,'[WARNING] Epoch %s not available in glonass orbit file' %gd
      print line_g.strip()
      line_g    = gin.readline()
      gline_nr += 1
      i, c, line_g = print_until_next_epoch(gin, line_g)
      gline_nr += c
      if i == -1:
        __close_fs(gin, rin)
      if i == -2:
        break_gps = True

  print 'EOF'

  ##print '#### Number of lines in GPS file',gline_nr
  ##print '#### Number of lines in GLO file',rline_nr
  return