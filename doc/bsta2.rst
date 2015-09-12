***************
Module : bsta2
***************

.. currentmodule:: bernutils.bsta2

Itroduction
============

This module contains the class **StaFile** which represents a Bernese v5.2
station information file. 

Station Information files (extension .STA), contain information for GPS/GNSS
stations regarding naming, equipment, etc, all of which are related to certain
time intervals (epochs). In most cases when using the functions/modules of
a ``StaFile`` instance to collect information, an epoch must be supplied (in
addition of-course to a station name).

Station Information file format format is very strict, and most of the 
functions/modules depend that this format is kept. For an example of .STA
files, see ftp://ftp.unibe.ch/aiub/BSWUSER52/STA/ and the collection of .STA
files placed there.

Information Types
------------------

Each .STA file contains blocks of information, called *Types*. There can 
(and should) be up to 5 different blocks of info in the file, denoted as:

* **TYPE 001: RENAMING OF STATIONS**
* **TYPE 002: STATION INFORMATION**
* **TYPE 003: HANDLING OF STATION PROBLEMS**
* **TYPE 004: STATION COORDINATES AND VELOCITIES (ADDNEQ)**
* **TYPE 005: HANDLING STATION TYPES**

.. note:: The places (in the file) where each of these blocks start, are found and
  stored for each instance at initialization/construction.


Validity Intervals
-------------------

Validity intervals can be blank in .STA files to denote either the start of
operation of a station or the fact that the information is ongoing. To represent
such epochs in the source code, we use the two ``datetime.datetime`` objects:

* :any:`bernutils.bsta2.MIN_STA_DATE` defined as ::
    
    MIN_STA_DATE = datetime.datetime.min
    
* :any:`bernutils.bsta2.MAX_STA_DATE` defined as ::

    MAX_STA_DATE = datetime.datetime.max

Documentation
==============

Help Classes
-------------

Class Type001
^^^^^^^^^^^^^^

This class holds records of Type 001; any (valid) such raw line, can be cast to
an instance of this type. This will enable the easy manipulation and extraction 
of information.

The format of Type 001 lines is as follows: ::

  STATION NAME          FLG          FROM                   TO         OLD STATION NAME      REMARK
  ****************      ***  YYYY MM DD HH MM SS  YYYY MM DD HH MM SS  ********************  ************************
  AIRA 21742S001        001  1980 01 06 00 00 00  2099 12 31 00 00 00  AIRA*                 MGEX,aira_20120821.log
  AUT0 49431M001        001                                            AUT0*                 MGEX,aut0_20121227.log
  AXPV 10057M001        001                                            AXPV*                 MGEX,axpv_20130515.log
  BBYS 11514M001        001                                            BBYS*                 MGEX,bbys_20131111.log
  BJCO 32701M001        003                                            BJCO                  EXTRA RENAMING
  CEBR 13408M001        001                                            CEBR*                 MGEX,cebr_20140124.log

.. warning:: There may be records (in the Type 001) block, flaged as '003'. At this point,
  these lines do no mean anything; they just trigger a warning message but their information
  (records) are not used.

.. autoclass:: bernutils.bsta2.Type001
  :members:
  :undoc-members:
  
Class Type002
^^^^^^^^^^^^^^
  
.. autoclass:: bernutils.bsta2.Type002
  :members:
  :undoc-members:

The ``StaFile`` Class
----------------------

.. autoclass:: bernutils.bsta2.StaFile
  :members:
  :undoc-members:

Examples
==========

Example usage of the class **stafile**, using CODE's .STA file
(available at <ftp://ftp.unibe.ch/aiub/BSWUSER52/STA/CODE.STA>)
