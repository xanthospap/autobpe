#! /usr/bin/python

import bernutils.products
import datetime

# set a datetime and a date
dtm = datetime.datetime(2015,01,01,12,34,10)
dt  = datetime.date(2004,01,01)
yesterday = datetime.date.today() - datetime.timedelta(1)

# path to download files
dir = '/home/xanthos/Downloads'

# final orbit for dtm
p1 = bernutils.products.getCodSp3('f',dtm,dir)
print 'downloaded file ->',p1

# final orbit for dt, from reprocessing campaign
p2 = bernutils.products.getCodSp3('f',dt,dir,True)
print 'downloaded file ->',p2

# rapid for yesterday
p3 = bernutils.products.getCodSp3('r',yesterday,dir)
print 'downloaded file ->',p3