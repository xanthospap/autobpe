import os


class AddneqFile:

  def __init__(self, filen):
    if not os.path.isfile(filen):
      raise RuntimeError('Cannot find ADDNEQ2 file [%s]' %filen)
    self.__filename = filen

  def get_crd_estimates(self):
    fin = open(self.__filename, 'r')
    crd_lines = [ ln for ln in fin.readlines() if len(ln) > 50 and ln.split()[-1] == '#CRD' ]
    fin.close()
    return crd_lines