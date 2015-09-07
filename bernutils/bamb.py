import os
from datetime import datetime

amb_dict  = {'cbwl': '#AR_WL',
  'cbnl': '#AR_NL',
  'pbwl': '#AR_L5',
  'pbnl': '#AR_L3',
  'qif': '#AR_QIF',
  'l12': '#AR_L12'
}
''' Ambiguity resolution method short names (id's) and their equivelant
    representation in Bernese v5.2 ambiguity summary files (.SUM).
'''

def amb_str2amb_key(ambstr):
  ''' Match an ambiguity resolution string as recorded in an ambiguity summary 
      file to its corresponding key (as in the ``amb_dict`` dictionary).

      :param ambstr: A (valid) ambiguity resolution method string. Can be any of:

                     * ``'#AR_WL'``
                     * ``'#AR_NL'``
                     * ``'#AR_L5'``
                     * ``'#AR_L3'``
                     * ``'#AR_QIF'``
                     * ``'#AR_L12'``

      :returns: The key (as string) corresponding to the input ambiguity 
                resolution method (see ``amb_dict`` dictionary).
  '''
  for key, astr in amb_dict.iteritems():
    if ambstr.strip() == astr:
      return key
  raise RuntimeError('Invalid AmbLine resolution string: %s' %ambstr)

amb_lcs   = {'cbwl': 1, 'cbnl': 1, 'pbwl': 1, 'pbnl': 1, 'qif': 2, 'l12': 1}
''' Number of LC's for every method (i.e. columns of type: 'Max/RMS ??').
'''
satsys_dict = {'G': 'GPS', 'R': 'GLONASS', 'GR': 'MIXED'}
''' Satellite System id-names and their equivelant representation in Bernese
    v5.2 ambiguity summary files (.SUM).
'''

class AmbLine:
  ''' Class to hold an ambiguity record line for a specific baseline, as
      described in an ambiguity summary file. Any raw ambiguity line can be cast
      to an instance of AmbLine.
  '''

  def __init__(self, line):
    ''' Constructor; the input record line ``line`` is examined to check
        the resolution method, using the last column (field).
    '''
    self.__line = line
    try:
      self.__method  = amb_str2amb_key(self.__line.split()[-1])
    except:
      raise RuntimeError('Invalid AmbLine resolution string: %s' %line)
    self.__lns = line.split()

  def receiver1(self):
    ''' Return the name of the first receiver '''
    if amb_lcs[self.__method] == 1: return self.__line[78:99].rstrip()
    else:  return self.__line[92:113].rstrip()

  def receiver2(self):
    ''' Return the name of the second receiver '''
    if amb_lcs[self.__method] == 1: return self.__line[99:120].rstrip()
    else: return self.__line[113:134].rstrip()

  def baseline(self):
    ''' Return the baseline name. '''
    return self.__lns[0][0:4]

  def station1(self):
    ''' Return the first (base) station. '''
    return self.__lns[1]

  def station2(self):
    ''' Return the second (rover) station name. '''
    return self.__lns[2]

  def length(self):
    ''' Return the baseline length in km as float. '''
    return float(self.__lns[3])

  def method(self):
    ''' Return the resolution method, as a method id (e.g. 'qif'). '''
    return self.__method

  def ambsbefore(self):
    ''' Number of ambiguities before the resolution and mm. '''
    return int(self.__lns[4]), float(self.__lns[5])

  def ambsafter(self):
    ''' Number of ambiguities after the resolution and mm. '''
    return int(self.__lns[6]), float(self.__lns[7])

  def percent(self):
    ''' Return the percentage of resolved ambiguities. '''
    return float(self.__lns[8])

  def satsys(self):
    ''' Return the satellite system id. '''
    sys = self.__lns[9].strip()
    if not sys in satsys_dict:
      raise RuntimeError('Invalid satellite system string %s' %sys)
    return sys, satsys_dict[sys]

class AmbFile:
  ''' A class to hold a Bernese ambiguity summary file (.SUM).
  '''

  def __init__(self, filename):
    ''' Initialize an ambiguity summary file instance given its filename. 
        Try locating the file, opening it and reading all of its lines in the
        instance's __lines list.
    '''
    ## try opening the file.
    self.__filename = filename
    if not os.path.isfile(self.__filename):
      raise IOError('No such file '+filename)

    ## open file and load all lines.
    fin = open(self.__filename, 'r')
    self.__lines = self.__load_lines__(fin)

    ## close the input stream
    fin.close()

  def __load_lines__(self, ibuf):
    ''' Load all lines with size > 0 to memory (i.e. in the object's lines list)
        given the input (stream) buffer.
    '''
    return [ line for line in ibuf.readlines() if len(line) > 0 ]

  def method_lines(self, res_method, sat_sys=None, include_summary_block=True):
    ''' Collect all info lines corresponding to the given ambiguity resolution
        method. Note that the returned list will also contain the "summary" 
        block, i.e. the lines containing the statistics for the given method, 
        except if the ``include_summary_block`` parameter is set to ``False``.

        :param res_method: The resolution method for which we want to extract
                           the information. Can be any of the keys of the
                           ``bernutils.bamb.amb_dict`` dictionary, i.e. any of
                           the strings:

                           * ``'cbwl'``
                           * ``'cbnl'``
                           * ``'pbwl'``
                           * ``'pbnl'``
                           * ``'qif'``
                           * ``'l12'``

        :param sat_sys:    **(Optional)** if set, only the lines corresponding
                           to the selected satellite system will be returned.
                           Can be any of the keys of the ``bernutils.bamb.sasys_dict``
                           dictionary, i.e. any of the strings:

                           * ``'G'`` for gps,
                           * ``'R'`` for glonass,
                           * ``'GR'`` for mixed, i.e. gps and glonass

        :param include_summary_block: **(Optional)** if set to ``True``, then 
                           the function will also return the lines contained in
                           the "summary" block, i.e. the lines containing the 
                           statistics/summary for the given method. If set to 
                           ``False`` then these lines will be skiped.

        :returns:          A list of lines (i.e. strings) corresponding to the 
                           given ambiguity resolution method.
    '''

    ## match the given method to an identifier
    if res_method in amb_dict:
      method_str = amb_dict[res_method]
    else:
      raise RuntimeError('Invalid resolution method string: %s' 
        %res_method)

    ret_list = []

    ## collect lines for the given method.
    ret_list = [l for l in self.__lines if len(l)>10 \
      and l.split()[len(l.split())-1] == method_str]

    ## filter the summary block (if needed)
    if not include_summary_block:
      ret_list = [l for l in ret_list if l.split()[0] != 'Tot:']

    ## filter the satellite system (if needed)
    if sat_sys:
      if not sat_sys in satsys_dict:
        raise RuntimeError('Invalid satellite system string: %s' 
          %method)
      ret_list = [l for l in ret_list if len(l.split())>9 \
        and ( l.split()[8] == sat_sys \
        or l.split()[9] == sat_sys) ]

    ## return the filtered list.
    return ret_list

  def toHtml(self, sat_sys=None):
    ''' Translate the ambiguity resolution information from this file to a
        html table.
        
        :param sat_sys:    **(Optional)** if set, only the lines corresponding
                           to the selected satellite system will be returned.
                           Can be any of the keys of the ``bernutils.bamb.sasys_dict``
                           dictionary, i.e. any of the strings:

                           * ``'G'`` for gps,
                           * ``'R'`` for glonass,
                           * ``'GR'`` for mixed, i.e. gps and glonass

        :returns: Nothing. All output is directed to stdout.
    '''

    ## current baseline
    cur_baseline = ''
    ## html table rows for a single baseline
    html_rows = []
    ## number of rows for a single baseline
    row_span = 1

    ## write CSS info and html head section
    print "<head>"
    print "<style>"
    print "table#t01, th#t01, td#t01  {"
    print "\twidth: 100%;"
    print "\tbackground-color: #eee;"
    print "\tborder-collapse: collapse;"
    print "\tborder: 1px solid black;"
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

    ## Table header
    print """<table style="width:100%" id="t01" border="1">"""
    print "\t<thead>"
    print "\t<tr>"
    for th in ('Baseline', 'Station 1', 'Station 2', 'Length (km)', '# of Ambs', \
      'Resolved (%)', 'Receiver 1', 'Receiver 2', 'Sat. System', 'Method'):
      print "\t\t<th>"+th+"</th>"
    print "\t</tr>"
    print "\t</thead>"

    print "\t<tbody>"

    ## For every resolution method posible ..
    for ambmth in amb_dict:

      ## create a list holding all baselines (for this method)
      m_lines = self.method_lines(ambmth, sat_sys, include_summary_block=True)

      ##  split the m_lines list in a list holding baseline records and 
      ##+ another holding the summary block
      s_lines = []
      if len(m_lines) > 0:
        while m_lines[-1].split()[0] == "Tot:" :
          s_lines.append(m_lines[-1])
          del m_lines[-1]

      ## for every ambiguity line (for current method) ..
      for aline in m_lines:

        ## cast the line to an AmbLine instance
        ambline = AmbLine(aline)

        ##  if this is a new baseline, flush the entries of html_rows list
        ##  this can happen (i.e. baselines repeated) if the ambiguity summary
        ##+ file is multi-gnss, so we have one line per method.
        if ambline.baseline() != cur_baseline:

          ## before flushing, substitute the correct number of ROWSPAN
          for tr in html_rows:
            print tr.replace("ROWSPAN", "\""+str(row_span)+"\"")

          ## re-initialize
          row_span     = 1
          html_rows    = []
          cur_baseline = ambline.baseline()

          ## read the line in the html_rows list
          html_rows.append("\n\t<tr>" + \
          "\n\t\t<td rowspan=ROWSPAN>%s</td>" % ambline.baseline() + \
          "\n\t\t<td rowspan=ROWSPAN>%s</td>" % ambline.station1() + \
          "\n\t\t<td rowspan=ROWSPAN>%s</td>" % ambline.station2() + \
          "\n\t\t<td rowspan=ROWSPAN>%6.1f</td>" % ambline.length() + \
          "\n\t\t<td>%4i (%3.1f)</td>" % (ambline.ambsbefore()[0], ambline.ambsbefore()[1]) + \
          "\n\t\t<td>%4.1f</td>" % ambline.percent() + \
          "\n\t\t<td rowspan=ROWSPAN>%s</td>"  % ambline.receiver1() + \
          "\n\t\t<td rowspan=ROWSPAN>%s</td>" % ambline.receiver2() + \
          "\n\t\t<td>%s</td>" % ambline.satsys()[1] + \
          "\n\t\t<td>%s</td>" % ambline.method().upper() + \
          "\n\t</tr>")

        else:
          ##  same baseline; just add the info in a new element in the 
          ##+ html_rows list.
          row_span += 1
          html_rows.append("\n\t<tr>" + \
          "\n\t\t<td>%4i (%3.1f)</td>" % (ambline.ambsbefore()[0], ambline.ambsbefore()[1]) + \
          "\n\t\t<td>%4.1f</td>" % ambline.percent() + \
          "\n\t\t<td>%s</td>" % ambline.satsys()[1] + \
          "\n\t\t<td>%s</td>" % ambline.method().upper() + \
          "\n\t</tr>")

      ## flush remaining baselines (last baseline of current method).
      for tr in html_rows:
        print tr.replace("ROWSPAN", "\""+str(row_span)+"\"")
      html_rows = []

      ## nearly done with this method; just add the statistics block
      if len(s_lines) == 0:
        print "\t<tr style=\"background-color:green\">"
        print "\t\t<td colspan=\"10\">Resolution method \"%s\" not used</td>" %(ambmth)
      else :
        for tr in s_lines:
          if not sat_sys or tr.split()[8] == sat_sys:
            l = tr.split()
            print "\t<tr style=\"background-color:red\">"
            print "\t\t<td colspan=\"3\">%s</td>" % l[1]
            print "\t\t<td>%6.1f</td>" % float(l[2])
            print "\t\t<td>%4i (%3.1f)</td>" % (int(l[3]), float(l[4]))
            print "\t\t<td>%4.1f</td>" % float(l[7])
            print "\t\t<td colspan=\"2\"></td>"
            print "\t\t<td>%s</td>"  %satsys_dict[l[8]]
            print "\t\t<td>%s</td>" %amb_str2amb_key(l[-1]).upper()
            print "\t</tr>"
      s_lines = []

    print "\t</tbody>"
    print "\t<caption>Ambiguity resolution information, extracted from %s at %s</caption>" %(self.__filename, datetime.now().strftime('%Y-%m-%d %H:%M:%S'))
    print "</table>"
    print "</body>"
