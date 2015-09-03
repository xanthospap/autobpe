#! /usr/bin/python

import os
from datetime import datetime

amb_method = {'Code-Based Widelane': '#AR_WL',
    'Code-Based Narrowlane': '#AR_NL',
    'Phase-Based Widelane': '#AR_L5',
    'Phase-Based Narrowlane': '#AR_L3',
    'Quasi-Ionosphere-Free': '#AR_QIF',
    'Direct L1/L2': '#AR_L12'
}
''' Ambiguity resolution methods and their id-codes.
'''

amb_keys   = {'cbwl': 'Code-Based Widelane',
    'cbnl': 'Code-Based Narrowlane',
    'pbwl': 'Phase-Based Widelane',
    'pbnl': 'Phase-Based Narrowlane',
    'qif': 'Quasi-Ionosphere-Free',
    'l12': 'Direct L1/L2'
}
''' Ambiguity resolution method short names (id's).
'''

satsys     = {'G': 'GPS', 'R': 'GLONASS', 'GR': 'MIXED'}
''' Satellite System id-names.
'''

amb_lcs   = {'cbwl': 1, 'cbnl': 1, 'pbwl': 1, 'pbnl': 1, 'qif': 2, 'l12': 1}
''' Number of LC's for every method (i.e. columns of type: Max/RMS L5').
'''

def satsys2key(ss):
  ''' Match a satellite system name (e.g. 'gps') to its identifier (e.g. 'G')
      This does the opposite of the dictionary :py:data:`satsys`. E.g. 
      ``satsys['G'] = 'GPS'`` and ``satsys2key('gps') = 'G'``. The argument
      ``ss`` can be in lower or uppercase (i.e. ``satsys2key('gps') = 
      satsys2key('GPS')``).
  '''
  ss = ss.strip()
  if ss == 'GPS' or ss == 'gps':
    return 'G'
  elif ss == 'GLONASS' or ss == 'glonass':
    return 'R'
  elif ss == 'MIXED' or ss == 'mixed':
    return 'GR'
  else:
    raise RuntimeError('Invalid satellite system string: '+ss)

def ambstr2key(ambs):
  ''' Match an ambiguity method string id (e.g. '#AR_QIF') to a method id
      (e.g. 'qif'). The method string (i.e argument ``ambs``) should be passed
      as recorded in an ambiguity summary file. The output string, can then
      be used as a key value in the :py:data:`amb_keys` and later in the 
      :py:data:`amb_method` dictionary.
      ``ambstr2key('#AR_QIF') = 'qif'``
      ``amb_keys[ambstr2key('#AR_QIF')] = 'Quasi-Ionosphere-Free'``
  '''
  ambs = ambs.strip()
  if ambs == '#AR_WL': return 'cbwl'
  elif ambs == '#AR_NL' : return 'cbnl'
  elif ambs == '#AR_L5' : return 'pbwl'
  elif ambs == '#AR_L3' : return 'pbnl'
  elif ambs == '#AR_QIF': return 'qif'
  elif ambs == '#AR_L12': return 'l12'
  else:
    raise RuntimeError('Invalid ambiguity method string: '+ambs)

class ambline:
  ''' Class to hold an ambiguity record line for a specific baseline, as
      described in an ambiguity summary file.
  '''

  def __init__(self,line):
    ''' Constructor; the input record line ``line`` is examined to check
        the resolution method, using the last column (field)
    '''
    self.__line    = line
    self.__lns     = line.split()
    self.__method  = ''
    self.__amb_key = ''
    try:
      ambkey           = ambstr2key(self.__lns[len(self.__lns)-1]) ## e.g. 'qif'
      self.__method    = amb_keys[ambkey] ## e.g. 'Quasi-Ionosphere-Free'
      self.__amb_key   = ambkey
    except:
      raise

  def receiver1(self):
    ''' Return the name of the first receiver '''
    if amb_lcs[self.__amb_key] == 1:
      return self.__line[80:101].rstrip()
    else:
      return self.__line[94:115].rstrip()
    
  def receiver2(self):
    ''' Return the name of the second receiver '''
    if amb_lcs[self.__amb_key] == 1:
      return self.__line[101:121].rstrip()
    else:
      return self.__line[115:136].rstrip()

  def baseline(self):
    ''' Return the baseline name. '''
    return self.__lns[0][0:4]

  def sta1(self):
    ''' Return the first (base) station. '''
    return self.__lns[1]

  def sta2(self):
    ''' Return the second (rover) station name. '''
    return self.__lns[2]

  def length(self):
    ''' Return the baseline length in km. '''
    return float(self.__lns[3])

  def method(self):
    ''' Return the resolution method, as a method id (e.g. 'qif'). '''
    return self.__amb_key

  def ambsbefore(self):
    ''' Number of ambiguities before the resolution and mm. '''
    return int(self.__lns[4]),float(self.__lns[5])

  def ambsafter(self):
    ''' Number of ambiguities after the resolution and mm. '''
    return int(self.__lns[6]),float(self.__lns[7])

  def percent(self):
    ''' Return the percentage of resolved ambiguities. '''
    return float(self.__lns[8])

  def satsys(self):
    ''' Return the satellite system as string (e.g. 'GPS'). '''
    sys = self.__lns[9].strip()
    try:
      return satsys[sys]
    except:
      raise RuntimeError('Invalid satellite system string: '+sys)

class ambfile:
  ''' A class to hold a Bernese ambiguity summary file (.SUM)
  '''

  def __init__(self,filename):
    ''' Initialize a sta object given its filename;
        try locating the file
    '''
    self.__filename = filename
    if not os.path.isfile(self.__filename):
      raise IOError('No such file '+filename)

  def collectBsls(self,method,satsys='MIXED'):
    ''' Collect the baseline records resolved using a given resolution 
        method (i.e. ``method``) with observations of a given satellite
        system (``satsys``). The baseline records are collected as 
        **RAW lines** and returned in a list.
    '''
    ## satellite system key:
    try:
      sat_sys_key = satsys2key(satsys)
    except:
      raise RuntimeError('Invalid satellite system.')

    try:
      bsls_list = self.collectMethodBsls(method)
    except:
      raise

    final_list = []
    for line in bsls_list:
      j = ambline(line)
      if j.method() != method:
        raise RuntimeError('Something went wrong in collecting baselines! Methods dont match: '+ method + '-' + j.method())
      if j.satsys() == satsys.upper():
        final_list.append(line)

    return final_list

  def collectMethodBsls(self,method):
    ''' Collect the baseline records resolved using a given resolution 
        method (i.e. ``method``). The baseline records are collected as 
        **RAW lines** and returned in a list.
    '''
    fin = open(self.__filename)

    try:
      self.goToMethod(fin,method)
    except:
      raise

    ## skip 5 lines
    for i in range(1,6): line = fin.readline()

    # read next line; if it is full of '=' no baselines to follow
    line = fin.readline()
    if not line:
      fin.close()
      raise RuntimeError('Cannot collect baselines for resolution method '+method)
    elif line[0:3] == '===':
      return []

    smeth1 = amb_keys[method]
    smeth2 = amb_method[smeth1]

    bsl_info = []

    while (line):
      if line.rstrip()[-6:] != smeth2:
        break
      if len(line) < 5:
        fin.close()
        raise RuntimeError('Error collecting baselines for resolution method '+method)
      elif line[0:3] == ' --': ## normal termination
        break
      else:
        bsl_info.append(line)
      line = fin.readline()

    fin.close()
    return bsl_info

  def collectMethodStats(self,method):
    fin = open(self.__filename)

    try:
      self.goToMethod(fin,method)
    except:
      raise

    ## skip 5 lines
    for i in range(1,6): line = fin.readline()

    # read next line; if it is full of '=' no baselines to follow
    line = fin.readline()
    if not line:
      fin.close()
      raise RuntimeError('Cannot collect baselines for resolution method '+method)
    elif line[0:3] == '===':
      return []
    
    smeth1 = amb_keys[method]
    smeth2 = amb_method[smeth1]

    bsl_info = []

    while (line):
      if line.strip()[-7:].strip() != smeth2:
        fin.close()
        #print 'smeth2 = ['+smeth2+'] line holds ['+line.strip()[-7:].strip()+']'
        raise RuntimeError('Error invalid resolution method '+method)
      if len(line) < 5:
        fin.close()
        raise RuntimeError('Error collecting baselines for resolution method '+method)
      line = fin.readline()
      if line[0:3] == ' --': ## normal termination
        #print 'SHOULD FUCKING BREAK !!!!!!!!!'
        break
      #print 'read new line ->',line, '['+line[0:3]+']'

    line = fin.readline()
    while len(line) > 4 and line[0:4] == "Tot:":
      bsl_info.append(line)
      line = fin.readline()
    
    fin.close()
    return bsl_info

  def goToMethod(self,istream,method,max_lines=1000):
    ''' Position the input stream ``istream`` at the start of results
        for method ``method`` (actualy at the end of the header line).

        :note: The file will be searched starting from the current
        position of the stream, and **NOT** from the begining of the
        file.

        :param istream:   The input stream (of an ambiguity summary file).
        :param method:    The method to search for; This must be a valid
                          string denoting a resolution method, as represented
                          in the ``__amb_keys`` dictionary.
        :param max_lines: Maximum number of lines to read before quiting.

    '''

    try:
      smeth1 = amb_keys[method]
      smeth2 = amb_method[smeth1]
    except:
      raise RuntimeError('Invalid resolution method '+method)

    if smeth2 == '#AR_L12':
      str = ' %s Ambiguity Resolution (<' %(smeth1)
    else:
      str   = ' %s (%s) Ambiguity Resolution (<' %(smeth1,smeth2.replace('#AR_',''))

    length = len(str)

    line = istream.readline()
    i    = 0
    line_found = False

    while (line and i < max_lines):
      if len(line) > length:
        if line[0:length] == str:
          line_found = True
          break
      line = istream.readline()
      i += 1

    if line_found:
      return line
    else:
      raise RuntimeError('Failed to find entry for method '+smeth1)

  def toHtmlTable(self,satsys=None):
    ''' Translate the file to an html table '''
    
    # CSS
    print "<head>"
    print "<style>"
    print "table#t01, th#t01, td#t01  {"
    print "\twidth: 100%;"
    print "\tbackground-color: #eee;"
    print "\tborder-collapse: collapse;"
    print "\tborder: 0.1px solid black;"
    print "}"
    print "table#t02 {"
    print "\twidth: 50%;"
    print "\tbackground-color: #eee;"
    print "\tborder: 1px solid black;"
    print "\tborder-collapse:collapse;"
    print "}"
    print "th#t02, td#t02 {"
    print "\tborder: 0;"
    print "}"
    print "</style>"
    print "</head>"

    print "<body>"
    # Header
    print """<table style="width:100%" id="t01">"""
    print "\t<thead>"
    print "\t<tr>"
    for th in ('Baseline', 'Station 1', 'Station 2', 'Length (km)', '# of Ambs', 'Resolved (%)', 'Receiver 1', 'Receiver 2', 'Sat. System', 'Method'):
      print "\t\t<th>"+th+"</th>"
    print "\t</tr>"
    print "\t</thead>"
    
    print "\t<tbody>"
    for ambmth in amb_keys:
      info_list = []
      if satsys:
        info_list = self.collectBsls(ambmth,satsys)
      else:
        info_list = self.collectMethodBsls(ambmth)
      for j in info_list:
        al = ambline(j)
        print "\t<tr>"
        print "\t\t<td>%s</td>" % al.baseline()
        print "\t\t<td>%s</td>" % al.sta1()
        print "\t\t<td>%s</td>" % al.sta2()
        print "\t\t<td>%06.1f</td>" % al.length()
        print "\t\t<td>%04i (%3.1f)</td>" % (al.ambsbefore()[0],al.ambsbefore()[1])
        print "\t\t<td>%04.1f</td>" % al.percent()
        print "\t\t<td>%s</td>"  % al.receiver1()
        print "\t\t<td>%s</td>" % al.receiver2()
        print "\t\t<td>%s</td>" % al.satsys()
        print "\t\t<td>%s</td>" % al.method()
        print "\t</tr>"
      info_list = self.collectMethodStats(ambmth)
      print "\t<tr>"
      for l in info_list:
        if ambstr2key(l.strip()[-7:].strip()) == ambmth or not satsys:
          print "\t\t<td>%s</td>" % l[1]
          print "\t\t<td></td>"
          print "\t\t<td></td>"
          print "\t\t<td>%06.1f</td>" % float(l[2])
          print "\t\t<td>%04i (%3.1f)</td>" % (int(l[3]), float(l[4]))
          print "\t\t<td>%04.1f</td>" % float(l[7])
          print "\t\t<td></td>"
          print "\t\t<td></td>"
          print "\t\t<td>%s</td>"  % al.satsys()
          print "\t\t<td>%s</td>" % al.method()
      print "\t</tr>"

    print "\t</tbody>"
    print "\t<caption>Ambiguity resolution information, extracted from %s at %s</caption>" %(self.__filename, datetime.now().strftime('%Y-%m-%d %H:%M:%S'))
    print "</table>"
    
    print "<p>Explanation of the ambiguity resolution methods:</p>"
    print """<table style="width:50%" id="t02">"""
    for ambmth, ambstr in amb_keys.iteritems():
      print "\t\t<tr><td>%s</td><td>%s</td></tr>" %(ambmth, ambstr)
    print "</table>"
    
    print "</body>"
      