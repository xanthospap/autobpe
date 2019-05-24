import json

# COD_HOST  = 'ftp.unibe.ch'
COD_HOST  = 'ftp.aiub.unibe.ch'
IGS_HOST  = 'cddis.gsfc.nasa.gov'

COD_DIR       = '/CODE'
COD_DIR_2013  = '/REPRO_2013/CODE'
IGS_DIR       = '/gnss/products'
IGS_DIR_GLO   = '/glonass/products'
IGS_DIR_REP2  = '/gnss/products/repro2'

SAT_SYS_TO_NAV_DICT = { 
  'G': 'n', 
  'R': 'g', 
  'S': 'h' 
}

SES_IDENTIFIERS_CHAR = {
  'a': 0, 'b': 1, 'c': 2, 'd': 3, 'e': 4, 'f': 5, 'g': 6,
  'h': 7, 'i': 8, 'j': 9,'k': 10, 'l':11, 'm': 12, 'n': 13,
  'o': 14, 'p': 15, 'q': 16, 'r': 17, 's': 18, 't':19, 'u': 20, 
  'v': 21, 'w': 22,'x': 23
}

SES_IDENTIFIERS_INT = {
  0:  'a', 1:  'b', 2:  'c',  3: 'd',  4: 'e',  5: 'f',  6: 'g',
  7:  'h', 8:  'i', 9:  'j', 10: 'k', 11: 'l', 12: 'm', 13: 'n',
  14: 'o', 15: 'p', 16: 'q', 17: 'r', 18: 's', 19: 't', 20: 'u', 
  21: 'v', 22: 'w', 23: 'x'
}

''' json product class
{
    "info"             : "Orbit Information",
    "format"           : "sp3",
    "satsys"           : "gps",
    "ac"               : "cod",
    "type"             : "final",
    "host"             : "cddis",
    "filename"         : "igs18753.sp3.Z"
}
'''
def prod2json(**kwargs):
  '''
  jd = {kwargs.get('info', ''),
      kwargs.get('format',   ''),
      kwargs.get('satsys',   ''),
      kwargs.get('ac',       ''),
      kwargs.get('type',     ''),
      kwargs.get('host',     ''),
      kwargs.get('filename', '')})
  '''
  return 0
