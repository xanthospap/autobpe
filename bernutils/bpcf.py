
class PcfVariable:
  
  def __init__(self, line):
    if line[0:2] != 'V_':
      raise RuntimeError('Cannot resolve PCF variable [%s]' %line)
    self.__var = line[0:9].rstrip().replace('V_', '')
    self.__dsc = line[10:50].rstrip()
    self.__val = line[50:80].rstrip()

class PcfFile:
  
  def __init__(self, filen):
  if not os.path.isfile(filen):
    raise RuntimeError('Cannot find .PCF file [%s]' %filen)
  self.__filename  = filen
  self.__variables = []

  def load_variables(self):
    try:
      fin = open(self.__filename, 'r')
    except:
      raise RuntimeError('Cannot open .PCF file [%s]' %self.__filename)
    
    lines = [ for line in fin.readlines() if line[0:2] == 'V_' ]