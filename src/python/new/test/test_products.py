#! /usr/bin/python

import bernutils.products
import datetime

# set a datetime and a date
dtm = datetime.datetime(2015,01,01,12,34,10)
dt  = datetime.date(2004,01,01)
yesterday = datetime.date.today() - datetime.timedelta(1)
today = datetime.date.today()

# path to download files
dir = '/home/xanthos/Downloads'
'''
# final orbit for dtm
p1 = bernutils.products.getCodSp3('f',dtm,dir)
print 'downloaded file ->',p1

# final orbit for dt, from reprocessing campaign
p2 = bernutils.products.getCodSp3('f',dt,dir,True)
print 'downloaded file ->',p2

# rapid for yesterday
p3 = bernutils.products.getCodSp3('r',yesterday,dir)
print 'downloaded file ->',p3

# final erp for dtm
p1 = bernutils.products.getCodErp('f',dtm,dir)
print 'downloaded file ->',p1

# final erp for dt, from reprocessing campaign
p2 = bernutils.products.getCodErp('f',dt,dir,True)
print 'downloaded file ->',p2

# rapid for yesterday
p3 = bernutils.products.getCodErp('r',yesterday,dir)
print 'downloaded file ->',p3

# ulrta - rapid for today
p4 = bernutils.products.getCodErp('u',today,dir)
print 'downloaded file ->',p4

# lets get the min and max dates reported in this last erp file
mmd = bernutils.products.erpTimeSpan(p4[0],True)
print 'max and min dates in erp file: ',mmd
'''
## now same dcb's ...
dcb1 = bernutils.products.getCodDcb('c1',dtm)
print 'got cdb ->',dcb1

#dcb2 = bernutils.products.getCodDcb('c2_rnx',dt)
## WARNING This file actualy doesn't exist !!
#print 'got cdb ->',dcb2

dcb3 = bernutils.products.getCodDcb('p2',today,dir)
print 'got cdb ->',dcb3