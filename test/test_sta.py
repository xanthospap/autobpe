#! /usr/bin/python

import datetime
import bernutils.bsta

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