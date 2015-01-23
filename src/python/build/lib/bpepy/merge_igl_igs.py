#! /usr/bin/python

""" @package merge_igl_igs
  @brief Function to merge two sp3 files

  Created         : Sep 2014
  Last Update     : Nov 2014

  List of Changes :

  National Technical University of Athens
  Dionysos Satellite Observatory
  Higher Geodesy Laboratory
"""

""" Import Libraries
"""
import sys
import datetime
import bpepy.gpstime

def _exit (f1,f2,i):
  f1.close ()
  f2.close ()
  sys.exit (i)

def print_until_next_epoch (inf,line):
  """ print all lines untill next epoch header
      returns status,lines_read,last_line
      if status = -1, an error occured,
      if status = -2, EOF encountered,
      if status = 0,  all ok
  """
  ln = line
  counter = 0
  while True:
    if ln[0] == '*':
      return 0,counter,ln
    if ln[0] == 'E':
      lns = ln.split()
      if lns[0] == 'EOF':
        return -2,counter,ln
    if ln[0] != 'P' and ln[0] != 'V':
      return -1,counter,ln
    print ln.strip()
    ln = inf.readline()
    counter+=1

def resolve_date_line (line):
  """ Resolve an epoch line e.g. (*  2013  3  4 23 45  0.00000000) to datetime
  """
  l = line.split()
  if len(l) != 7:
    print >> sys.stderr,'#### Error (1) resolving epoch line',line
    return 1
  if l[0] != '*':
    print >> sys.stderr,'#### Error (2) resolving epoch line',line
    return 1
  try:
    iy = int (l[1])
    im = int (l[2])
    idom = int (l[3])
    ih = int (l[4])
    imn= int (l[5])
    is_= int (float (l[6]))
    if float (l[6]) != float (is_):
      print >> sys.stderr,'#### Error (2.5) resolving epoch line',line,'SECONDS NOT INTEGER !'
      return 1
  except:
    print >> sys.stderr,'#### Error (3) resolving epoch line',line
    return 1
  try:
    d = datetime.datetime (iy,im,idom,ih,imn,is_);
  except:
    print >> sys.stderr,'#### Error (4) resolving epoch line',line
    return 1
  return 0,d

def merge_igl_igs (igsf, iglf):
  """
  """
  try:
    gin = open (igsf,'r');
    rin = open (iglf,'r');
  except:
    print >> sys.stderr,'#### Unable to open input files'
    return -1

  # number of current line
  gline_nr = 0;
  rline_nr = 0;

  """
  ____LINE 1____________________________________________________________________
  """
  ## read first line; must be the same
  # #cP2013  8  3  0  0  0.00000000      96 ORBIT IGb08 HLM  IGS
  line_g = gin.readline ()
  line_r = rin.readline ()
  gline_nr = rline_nr = 1;
  if line_g != line_r :
    print >> sys.stderr,'#### Error in line',gline_nr,'; no exact match !'
    _exit (gin,rin,1)
  ## write the first line
  print line_r,

  """
  ____LINE 2____________________________________________________________________
  """
  ## read second line; must be the same for the two orbit files
  # ## 1751 518400.00000000   900.00000000 56507 0.0000000000000
  line_g = gin.readline ()
  line_r = rin.readline ()
  gline_nr+=1; rline_nr+=1; 
  if line_g != line_r :
    print >> sys.stderr,'#### Error in line',gline_nr,'; no exact match !'
    _exit (gin,rin,2)
  ## write the second line
  print line_r,

  """
  ____LINES 3 - 7_______________________________________________________________
  """
  # third line contains number of sats and a list of the sats
  # +   32   G01G02G03G04G05G06G07G08G09G10G11G12G13G14G15G16G17

  # first for gps
  gsats_s = []
  line_g = gin.readline().strip();
  gline_nr+=1;
  try:
    gsats  = int (line_g[4:6])
  except:
    print >> sys.stderr,'#### Error reading number of satellites in line',line_g,'file',igsf
    _exit (gin,rin,gline_nr)
  sat_str = line_g[9:]
  # read the following 4 lines
  for i in range (0,4):
    line_g = gin.readline ().strip ()
    gline_nr+=1;
    if line_g[0] != '+' :
      print >> sys.stderr,'#### line nr',gline_nr,'does not start with "+"; error in file',igsf
      _exit (gin,rin,gline_nr)
    sat_str += line_g[9:]
  # resolve satellites from accumulated line
  tl = [sat_str[i:i+3] for i in range(0, len(sat_str), 3)]
  for j in tl:
    if j != '  0':
      if j[0] != 'G' :
        print >> sys.stderr,'#### Error reading gps satellite:',j,'; line nr',gline_nr
        _exit (gin,rin,gline_nr)
      gsats_s.append (j)
  # see that all satellites are resolved
  if gsats != len (gsats_s):
    print >> sys.stderr,'#### Error reading gps satellites for file',igsf
    print >> sys.stderr,'#### Should resolve',gsats,' satellites, but actually resolved',len (gsats_s)
    _exit (gin,rin,gline_nr)

  # then for glonass
  rsats_s = []
  line_r = rin.readline().strip();
  rline_nr+=1;
  try:
    rsats  = int (line_r[4:6])
  except:
    print >> sys.stderr,'#### Error reading number of satellites in line',line_r,'file',iglf
    _exit (gin,rin,rline_nr)
  sat_str = line_r[9:]
  # read the following 4 lines
  for i in range (0,4):
    line_r = rin.readline ().strip ()
    rline_nr+=1;
    if line_r[0] != '+' :
      print >> sys.stderr,'#### line nr',rline_nr,'does not start with "+"; error in file',iglf
      _exit (gin,rin,rline_nr)
    sat_str += line_r[9:]
  # resolve satellites from accumulated line
  tl = [sat_str[i:i+3] for i in range(0, len(sat_str), 3)]
  for j in tl:
    if j != '  0':
      if j[0] != 'R' :
        print >> sys.stderr,'#### Error reading glonass satellite:',j,'; line nr',rline_nr
        _exit (gin,rin,gline_nr)
      rsats_s.append (j)
  # see that all satellites are resolved
  if rsats != len (rsats_s):
    print >> sys.stderr,'#### Error reading glonass satellites for file',iglf
    print >> sys.stderr,'#### Should resolve',rsats,' satellites, but actually resolved',len (rsats_s)
    _exit (gin,rin,rline_nr)

  ## AT THIS POINT THE LISTS gsats_s AND rsats_s CONTAIN ALL SATELLITES, GPS 
  ## PLUS GLONASS AS STRINGS

  sat_str = gsats_s + rsats_s
  s=''
  for i in range (len(sat_str),17*5): sat_str.append ('  0')
  # 17 sats in each line i.e. 17*3 = 51 chars
  print '+   %02i   %51s' %(rsats+gsats,s.join(sat_str[0:17]))
  print '+        %51s' %(s.join(sat_str[17:2*17]))
  print '+        %51s' %(s.join(sat_str[2*17:3*17]))
  print '+        %51s' %(s.join(sat_str[3*17:4*17]))
  print '+        %51s' %(s.join(sat_str[4*17:5*17]))

  """
  ____LINES 8 - 12______________________________________________________________
  """
  # next 5 lines contain accuracy codes
  # ++         2  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2

  # first for gps
  gsats_s = []
  sat_str = ''
  # read the following 5 lines
  for i in range (0,5):
    line_g = gin.readline ().strip ()
    gline_nr+=1;
    if line_g[0:2] != '++' :
      print >> sys.stderr,'#### line nr',gline_nr,'does not start with "++"; error in file',igsf
      _exit (gin,rin,gline_nr)
    sat_str += line_g[9:]
  # resolve satellite accuracies from accumulated line
  tl = [sat_str[i:i+3] for i in range(0, len(sat_str), 3)]
  for j in tl:
    try:
      ij = int (j)
    except:
      print >> sys.stderr,'#### Error reading satellite accuracy:',j,'in file',igsf
      _exit (gin,rin,gline_nr)
    gsats_s.append (j)
  # only save as many accuracies as the satellite number
  gsats_s = gsats_s[0:gsats]

  # then for glonass
  rsats_s = []
  sat_str = ''
  # read the following 5 lines
  for i in range (0,5):
    line_r = rin.readline ().strip ()
    rline_nr+=1;
    if line_r[0:2] != '++' :
      print >> sys.stderr,'#### line nr',rline_nr,'does not start with "++"; error in file',igsl
      _exit (gin,rin,gline_nr)
    sat_str += line_r[9:]
  # resolve satellite accuracies from accumulated line
  tl = [sat_str[i:i+3] for i in range(0, len(sat_str), 3)]
  for j in tl:
    try:
      ij = int (j)
    except:
      print >> sys.stderr,'#### Error reading satellite accuracy:',j,'in file',iglf
      _exit (gin,rin,gline_nr)
    rsats_s.append (j)
  # only save as many accuracies as the satellite number
  rsats_s = rsats_s[0:rsats]

  sat_str = gsats_s + rsats_s
  s=''
  for i in range (len(sat_str),17*5): sat_str.append ('  0')
  # 17 sats in each line i.e. 17*3 = 51 chars
  print '++       %51s' %(s.join(sat_str[0:17]))
  print '++       %51s' %(s.join(sat_str[17:2*17]))
  print '++       %51s' %(s.join(sat_str[2*17:3*17]))
  print '++       %51s' %(s.join(sat_str[3*17:4*17]))
  print '++       %51s' %(s.join(sat_str[4*17:5*17]))

  """
  ____LINE 13___________________________________________________________________
  """
  #%c R  cc GPS ccc cccc cccc cccc cccc ccccc ccccc ccccc ccccc
  #%c G  cc GPS ccc cccc cccc cccc cccc ccccc ccccc ccccc ccccc
  ##%c ft  cc tsf ccc cccc cccc cccc cccc ccccc ccccc ccccc ccccc   <--- GPS or UTC
  ##    ft: "G " for GPS only files                            
  ##        "M " for mixed files
  ##        "R " for GLONASS only files
  ## tsf: "GPS" for GPS time, "UTC" for UTC time
  line_g = gin.readline ()
  line_r = rin.readline ()
  gline_nr+=1; rline_nr+=1; 
  gps_sys  = line_g[3:5].strip(' ')
  gps_tsys = line_g[9:12].strip()
  glo_sys  = line_r[3:5].strip()
  glo_tsys = line_r[9:12].strip()
  # chech the systems
  if gps_sys != 'G':
    print >> sys.stderr,'#### Error! Expected satellite system "G", found',gps_sys
    _exit (gin,rin,gline_nr)
  if glo_sys != 'R':
    print >> sys.stderr,'#### Error! Expected satellite system "R", found',glo_sys
    _exit (gin,rin,rline_nr)
  if gps_tsys != glo_tsys:
    print >> sys.stderr,'#### Error! Different time systems in orbit files'
    _exit (gin,rin,rline_nr)
  print '%%c %1s  cc %3s ccc cccc cccc cccc cccc ccccc ccccc ccccc ccccc' %('M',glo_tsys)

  """
  ____LINE 14___________________________________________________________________
  """
  #%c cc cc ccc ccc cccc cccc cccc cccc ccccc ccccc ccccc ccccc
  ## this line hold nothing!
  line_g = gin.readline ()
  line_r = rin.readline ()
  gline_nr+=1; rline_nr+=1;
  print '%c cc cc ccc ccc cccc cccc cccc cccc ccccc ccccc ccccc ccccc'

  """
  ____LINE 15___________________________________________________________________
  """
  #%f  1.2500000  1.025000000  0.00000000000  0.000000000000000
  line_g = gin.readline().strip()
  line_r = rin.readline().strip()
  gline_nr+=1; rline_nr+=1;
  gls = line_g.split()
  rls = line_r.split()
  try:
    g_base_for_pos = float (gls[1])
    g_base_for_clk = float (gls[2])
    r_base_for_pos = float (rls[1])
    r_base_for_clk = float (rls[2])
  except:
    print >> sys.stderr,'#### Error! cannot resolve base factors'
    _exit (gin,rin,rline_nr)
  if g_base_for_pos != r_base_for_pos:
    print >> sys.stderr,'#### Error! different bases for Pos/Vel stds'
    _exit (gin,rin,rline_nr)
  if g_base_for_clk != r_base_for_clk:
    print >> sys.stderr,'#### Error! different bases for Clk/Rate stds'
    _exit (gin,rin,rline_nr)
  print '%%f %10.7f %12.9f  0.00000000000  0.000000000000000' %(g_base_for_pos,g_base_for_clk)

  """
  ____LINES 16 - 18_____________________________________________________________
  """
  for i in range (0,3):
    line_g = gin.readline ()
    line_r = rin.readline ()
    gline_nr+=1; rline_nr+=1;
  print '%f  0.0000000  0.000000000  0.00000000000  0.000000000000000'
  print '%i    0    0    0    0      0      0      0      0         0'
  print '%i    0    0    0    0      0      0      0      0         0'

  """
  ____LINES COMMENT LINES_______________________________________________________
  """
  while True:
    line_g = gin.readline().strip()
    gline_nr+=1;
    if line_g == "EOF":
      print >> sys.stderr,'#### Error! EOF encountered while searching for comments! file',igsf
      _exit (gin,rin,gline_nr)
    if line_g[0:2] == "/*":
      print line_g
    else:
      break;
  while True:
    line_r = rin.readline().strip()
    rline_nr+=1;
    if line_r == "EOF":
      print >> sys.stderr,'#### Error! EOF encountered while searching for comments! file',iglf
      _exit (gin,rin,gline_nr)
    if line_r[0:2] == "/*":
      print line_r
    else:
      break;

  ## Now the current lines for both files are the first epoch records, e.g.
  ## *  2013  3  4  0  0  0.00000000
  break_gps = False
  break_glo = False
  while (not break_gps) and (not break_glo):
    ga, gd = resolve_date_line (line_g)
    ra, rd = resolve_date_line (line_r)
    if ga != 0 or ra != 0:
      _exit (gin,rin,rline_nr)
    # first case, dates are the same
    if gd == rd:
      print line_g.strip()
      line_g = gin.readline()
      gline_nr+=1;
      i,c,line_g = print_until_next_epoch (gin,line_g)
      gline_nr+=c;
      if i==-1:
        _exit (gin,rin,gline_nr)
      if i==-2:
        break_gps = True
      line_r = rin.readline()
      rline_nr+=1;
      i,c,line_r = print_until_next_epoch (rin,line_r)
      rline_nr+=c;
      if i==-1:
        _exit (gin,rin,rline_nr)
      if i==-2:
        break_glo = True
    elif gd > rd:
      print >> sys.stderr,'#### Epoch',rd,'not available in gps orbit file'
      print line_r.strip()
      line_r = rin.readline()
      rline_nr+=1;
      i,c,line_r = print_until_next_epoch (rin,line_r)
      rline_nr+=c;
      if i==-1:
        _exit (gin,rin,rline_nr)
      if i==-2:
        break_glo = True
    elif gd < rd:
      print >> sys.stderr,'#### Epoch',gd,'not available in glonass orbit file'
      print line_g.strip()
      line_g = gin.readline()
      gline_nr+=1;
      i,c,line_g = print_until_next_epoch (gin,line_g)
      gline_nr+=c;
      if i==-1:
        _exit (gin,rin,gline_nr)
      if i==-2:
        break_gps = True

  print 'EOF'

  ##print '#### Number of lines in GPS file',gline_nr
  ##print '#### Number of lines in GLO file',rline_nr
  sys.exit (0)
