#! /usr/bin/python

import bernutils.products.pyion
import bernutils.products.pysp3
import datetime

# set a datetime and a date
dtm = datetime.datetime(2015,01,01,12,34,10)
dt  = datetime.date(2004,01,01)
yesterday = datetime.date.today() - datetime.timedelta(1)
today = datetime.datetime.today()

# path to download files
dir = '/home/xanthos/Downloads'


#print bernutils.products.pysp3.getNav(dtm, 'G', dir)
#print bernutils.products.pyion.getCodIon(dtm, dir)

#bernutils.products.pysp3.merge_sp3_GR('igs17545.sp3', 'igl17545.sp3', 'merged.sp3')

bernutils.products.pysp3.getOrb(dtm, 'igs', dir, use_glonass=True)
