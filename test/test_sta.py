#! /usr/bin/python

import datetime
import bernutils.bsta

x = bernutils.bsta.StaFile('CODE.STA')

#x.match_old_name(['HARK', 'WTZR', 'EXWI', 'DYNG', 'S071'])
#x.get_station_list()
#x.__match_type_001__()
dict1 = x.__match_type_001__(['HARK', 'WTZR', 'EXWI', 'DYNG', 'S071'])
dict2 = x.__match_type_002__(dict1)
for i in dict2:
  print 'ENTRIES FOR STATION %s' %i
  for j in dict2[i]:
    print '[%s]' %j

'''
## Test Program
x = bernutils.bsta.stafile('CODE.STA')

recs, num = x.fillStaRec1('S071')
print 'type001'
for i in recs.type1List():
    print i.line()

recs, num = x.fillStaRec2('S071',recs)
for i in recs.type2List():
    print i.line()

recs = []
recs = x.loadAll()
for i in recs.type1List():
    print i.line()
'''
