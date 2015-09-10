#! /usr/bin/python

import bernutils.products.pyerp
import datetime

# set a datetime and a date
dtm = datetime.datetime(2015,01,01,12,34,10)
dt  = datetime.date(2004,01,01)
yesterday = datetime.date.today() - datetime.timedelta(1)
today = datetime.datetime.today()

# path to download files
dir = '/home/xanthos/Downloads'


bernutils.products.pyerp.getErp(dtm, 'cod', dir, use_one_day_sol=True)

'''
print '//-------------------------------------------------------------------//'
bernutils.products.pyerp.getCodErp(dtm, '/home/xanthos/Downloads/tmp_prods/')
print '//-------------------------------------------------------------------//'
bernutils.products.pyerp.getIgsErp(dtm, '/home/xanthos/Downloads/tmp_prods/')
print '//-------------------------------------------------------------------//'
bernutils.products.pyerp.getCodErp(yesterday,'/home/xanthos/Downloads/tmp_prods')
print '//-------------------------------------------------------------------//'
bernutils.products.pyerp.getIgsErp(yesterday,'/home/xanthos/Downloads/tmp_prods')
print '//-------------------------------------------------------------------//'
bernutils.products.pyerp.getCodErp(datetime.date.today() - datetime.timedelta(10))
print '//-------------------------------------------------------------------//'
bernutils.products.pyerp.getIgsErp(datetime.date.today() - datetime.timedelta(10))
print '//-------------------------------------------------------------------//'
'''