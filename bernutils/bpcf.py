import os

class PcfVar:
  ''' Helper class; instance of this class represent PCF variables
  '''

  def __init__(self, *args, **kwargs):
    ''' There are two ways to initialiaze/construct a PcfVar instance:

        * using a PCF variable line, e.g. ::

          pv = PcfVar('V_SATSYS Select the GNSS (GPS, GPS/GLO)           GPS/GLO')

        * using named arguments for ``variable`` and optionaly for ``description``
          and/or ``value``, e.g. ::

          pv = PcfVar(variable='SATSYS')
          pv = PcfVar(variable='SATSYS', value='GPS/GLO')
          pv = PcfVar(variable='SATSYS', value='GPS/GLO', description='blah, blah, blah ..')

    '''
    if len(args) == 1:
      line = args[0]
      if line[0:2] != 'V_':
        raise RuntimeError('Cannot resolve PCF variable [%s]' %line)
      self.__var = line[0:9].rstrip().replace('V_', '')
      self.__dsc = line[9:50].rstrip()
      self.__val = line[50:].rstrip()
    elif len(kwargs) >= 1:
      self.__var = kwargs['variable']
      if 'description' in kwargs:
        self.__dsc = kwargs['description']
      else:
        self.__dsc = ''
      if 'value' in kwargs:
        self.__val = kwargs['value']
      else:
        self.__val = ''

  def _sformat_(self):
    return '%-8s %-40s %-s' %('V_'+self.__var, self.__dsc, self.__val)

  def __str__(self):
    return self._sformat_()

  def __repr__(self):
    return self._sformat_()

  def var(self):
    ''' Return the variable name, **ommiting the 'V_' part**
    '''
    return self.__var

  def description(self):
    ''' Return the variable description.
    '''
    return self.__dsc

  def value(self):
    ''' Return the variable's value
    '''
    return self.__val

class PcfFile:
  ''' A class to represent/hold Bernese v5.2 Protocoil Control Files (.PCF)
  '''

  def __init__(self, filen):
    if not os.path.isfile(filen):
      raise RuntimeError('Cannot find .PCF file [%s]' %filen)
    self.__filename  = filen
    self.__varlist   = []

  def load_variables(self):
    ''' Read the PCF file and load into the instance's private member the list
        of variables recorded in the file.

        .. warning:: This function will re-set the the member variable ``self.__varlist``
          by reading the file. Any changes made to the instances variable list member
          will be lost.

    '''
    try:
      fin = open(self.__filename, 'r')
    except:
      raise RuntimeError('Cannot open .PCF file [%s]' %self.__filename)

    varlst = [ PcfVar(line) for line in fin.readlines() if line[0:2] == 'V_' ]

    fin.close()

    self.__varlist = varlst
    return varlst

  def set_variable(self, var_name, descr=None, val=None):
    ''' Set/Add a variable to the list of this instances variable list. If the 
        variable already exists and ``'descr'`` and/or ``'val'`` parameters are 
        given, then this variable is going to be modified to match the new
        description/value. If the variable does not exist, it will be appended.
    '''

    if len(self.__varlist) == 0:
      var_list = self.load_variables()
    else:
      var_list = self.__varlist

    index = -1

    for idx, v in enumerate(var_list):
      if v.var() == var_name:
        index = idx
        break

    if index == -1:
      var_list.append(PcfVar(variable=var_name, description=descr, value=val))
    else:
      if descr == None: descr = var_list[index].description()
      if val == None: val = var_list[index].value()
      var_list[index] = PcfVar(variable=var_name, description=descr, value=val)

    self.__varlist = var_list

    return var_list

  def dump_to_json(self):
    if len(self.__varlist) == 0:
      var_list = self.load_variables()
    else:
      var_list = self.__varlist

    print '{pcf_variables:['
    for i in var_list:
      var_str = '{\"var_name\":\"%s\", \"description\": \"%s\", \"value\": \"%s\" }'%(i.var(), i.description(), i.value())
      print var_str
    print ']}'


  def dump_to_html(self):
    ''' Dump the PCF's variables to stdout, in an html table format
    '''
    if len(self.__varlist) == 0:
      var_list = self.load_variables()
    else:
      var_list = self.__varlist

    print """<table style="width:100%" id="t01" border="1">"""
    print "\t<thead>"
    print "\t<tr>"
    print "\t\t<th>Var Name</th><th>Description</th><th>Value</th>"
    print "\t</tr>"
    print "\t</thead>"
    print "\t<tbody>"
    for i in var_list:
      print "\n\t<tr><td><var>%s</var></td><td><i>%s</i></td><td><code>%s</code></td></tr>"%(i.var(), i.description(), i.value())
    print "\t</tbody>"
    print "<caption>Variables in PCF file %s</caption>"%(self.__filename)
    print "</table>"
    return

  def flush_variables(self):
    ''' This function will re-write the PCF file, substituting the variables
        section with the variables this instance holds. The rest of the file
        will be identical.
    '''

    if len(self.__varlist) == 0:
      var_list = self.load_variables()
      var_list = map(lambda x: str(x)+'\n', var_list)
    else:
      var_list = [ str(x)+'\n' for x in self.__varlist ]

    try:
      fin = open(self.__filename, 'r')
    except:
      raise RuntimeError('Cannot open .PCF file [%s]' %self.__filename)

    lines_in = [ line for line in fin.readlines() if line[0:2] != 'V_']
    fin.close()

    idx  = lines_in.index('VARIABLE DESCRIPTION                              DEFAULT\n')
    idx += 2

    ## see SO http://stackoverflow.com/questions/7376019/list-extend-to-index-\
    ## inserting-list-elements-not-only-to-the-end/7376026#7376026
    lines_in[idx:idx] = var_list

    pcf_base = os.path.basename(self.__filename)
    pcf_dir  = os.path.dirname(self.__filename)
    tmp_file = os.path.join(pcf_dir, ".%s_scratch"%pcf_base)
    with open(tmp_file, 'w') as fout:
      for i in lines_in: print >>fout, i,

    try:
      os.rename(tmp_file, self.__filename)
    except:
      os.remove(tmp_file)
      raise RuntimeError('ERROR. Failed to move %s to %s' %(tmp_file, self.__filename))
