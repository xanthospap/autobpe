import os

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

amb_lcs   = {'cbwl': 1, 'cbnl': 1, 'pbwl': 1, 'pbnl': 1, 'qif': 2, 'l12': 1}
''' Number of LC's for every method (i.e. columns of type: 'Max/RMS ??').
'''
satsys_dict = {'G': 'GPS', 'R': 'GLONASS', 'GR': 'MIXED'}
''' Satellite System id-names and their equivelant representation in Bernese
    v5.2 ambiguity summary files (.SUM).
'''

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

  def toHtml(self, res_method, sat_sys=None):
    '''
    '''
    ## For every resolution method posible ..
    for ambmth in amb_dict:

      ## create a list holding all baselines (for this method)
      m_lines = self.method_lines(res_method, sat_sys, include_summary_block=True)
      