=============================
Module : bsta
=============================

This module contains the class **stafile** which represents a Bernese v5.2
station information file. 

Station Information files (extension .STA), contain information for GPS/GNSS
stations regarding naming, equipment, etc, all of which are related to certain
time intervals (epochs). In most cases when using the functions/modules of
a **stafile** instance to collect information, an epoch must be supplied (in
addition of-course to a station name).

Station Information file format format is very strict, and most of the 
functions/modules depend that this format is kept. For an example of .STA
files, see ftp://ftp.unibe.ch/aiub/BSWUSER52/STA/ and the collection of .STA
files placed there.

-----------------------------
Documentation
-----------------------------

.. currentmodule:: bernutils.bsta

.. autoclass:: bernutils.bsta.starec
   :members:
   :private-members:
   :special-members:
   :undoc-members:

.. autoclass:: bernutils.bsta.stafile
   :members:
   :private-members:
   :special-members:
   :undoc-members:

-----------------------------
Examples
-----------------------------

Example usage of the class **stafile**, using CODE's .STA file
(available at <ftp://ftp.unibe.ch/aiub/BSWUSER52/STA/CODE.STA>)

.. code-block:: python

    ## Test Program
    x = StaFile('CODE.STA')
    ## a renaming takes place, so this will fail if no epoch is given
    ln1 = x.findStationType01('S071',datetime.datetime(2008,01,01,01,00,00))
    print ln1
    ## a renaming takes place, so this will fail if no epoch is given
    ln1 = x.findStationType01('S071',datetime.datetime(2005,01,01,01,00,00))
    print ln1
    ## following two should be the same
    ln1 = x.findStationType01('OSN1 23904S001',datetime.datetime(2005,01,01,01,00,00))
    print ln1
    ln1 = x.findStationType01('OSN1 23904S001')
    print ln1
    ## a renaming takes place, so this will fail if no epoch is given
    ln2 = x.findStationType02('S071',datetime.datetime(2005,01,01,01,00,00))
    print ln2
    ## return all entries, for all epochs
    ln2 = x.findStationType02('ANKR')
    print ln2
    ## return entry for a specific interval
    ln2 = x.findStationType02('ANKR',datetime.datetime(2015,07,01,01,00,00))
    print ln2
    print x.getStationName('S071',datetime.datetime(2008,01,01,01,00,00))
    print x.getStationName('S071',datetime.datetime(2005,01,01,01,00,00))
    print x.getStationName('ANKR')
    print x.getStationAntenna('S071',datetime.datetime(2008,01,01,01,00,00))
    print x.getStationAntenna('S071',datetime.datetime(2005,01,01,01,00,00))
    print x.getStationAntenna('ANKR',datetime.datetime(2005,01,01,01,00,00))
    print x.getStationReceiver('S071',datetime.datetime(2008,01,01,01,00,00))
    print x.getStationReceiver('S071',datetime.datetime(2005,01,01,01,00,00))
    print x.getStationReceiver('ANKR',datetime.datetime(2005,01,01,01,00,00))
