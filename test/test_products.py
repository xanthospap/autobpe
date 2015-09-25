#! /usr/bin/python

import bernutils.products.pyion
import bernutils.products.pysp3
import bernutils.webutils
import datetime

# set a datetime and a date
dtm = datetime.datetime(2015,01,01,12,34,10)
dt  = datetime.date(2004,01,01)
yesterday = datetime.date.today() - datetime.timedelta(1)
today = datetime.datetime.today()

# path to download files
mydir = '/home/bpe2/src'


#print bernutils.products.pysp3.getNav(dtm, 'G', dir)
#print bernutils.products.pyion.getCodIon(dtm, dir)

#bernutils.products.pysp3.merge_sp3_GR('igs17545.sp3', 'igl17545.sp3', 'merged.sp3')

x = bernutils.products.pysp3.getOrb(dtm, ac='igs', out_dir=mydir, use_glonass=True)
print x

#host  = 'ftp.unibe.ch'
#dirn  = [ 'aiub/CODE', 'aiub/CODE', 'aiub/CODE/2015', 'aiub/BSWUSER52/STA/', 'aiub/CODE']
#filen = ['P1C1.DCB', 'COD.EPH_5D', 'COD18591.TRO.Z', 'IGS.STA', 'P1C1_RINEX.DCB']
#dirs  = mydir

#x = bernutils.webutils.grabFtpFile(host, dirn, filen, mydir)
#print x

#m_host='147.102.110.69'
#m_port=2754
#m_username='bpe2'
#m_password='gevdais;ia'
#dirn=['~/tables/sta/', '~/tables/atx/']
#filen=['toadd', 'ash111661.atx' ]

#x = bernutils.webutils.grabSshFile(m_host, dirn, filen, saveas='/home/bpe2/cron', s_username=m_username, s_password=m_password, s_port=m_port)
#print x
