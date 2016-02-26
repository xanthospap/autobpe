#! /usr/bin/python

import datetime
import bernutils.bsta2

x = bernutils.bsta2.BernSta('CODE.STA')

#x.match_old_name(['HARK', 'WTZR', 'EXWI', 'DYNG', 'S071'])
#x.get_station_list()
#x.__match_type_001__()

print '////////////////////////////////////////////////////////////////////////'
dict1 = x.__match_type_001__(['HARK', 'WTZR', 'EXWI', 'DYNG', 'S071'])
for i in dict1:
  print 'ENTRIES FOR STATION %s' %i
  for j in dict1[i]:
    print '[%s]' %j
print '////////////////////////////////////////////////////////////////////////'

dict2 = x.__match_type_002__(dict1)
for i in dict2:
  print 'ENTRIES FOR STATION %s' %i
  for j in dict2[i]:
    print '[%s]' %j

'''
print '////////////////////////////////////////////////////////////////////////'
dict3 = bernutils.bsta.rearange_dictionary(dict1)
for i in dict3:
  print 'ENTRIES FOR STATION %s' %i
  for j in dict3[i]:
    print '[%s]' %j
print '////////////////////////////////////////////////////////////////////////'
'''
