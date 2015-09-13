#! /usr/bin/python

import datetime
import bernutils.bsta2

x = bernutils.bsta2.StaFile('CODE.STA')

#x.match_old_name(['HARK', 'WTZR', 'EXWI', 'DYNG', 'S071'])
#x.get_station_list()
x.__match_type_001__()
x.__match_type_001__(['HARK', 'WTZR', 'EXWI', 'DYNG', 'S071'])

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
