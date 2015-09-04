=============================
Module : bcrd
=============================

This module contains the class **crdfile** which represents a Bernese v5.2
station coordinate file. 

A class named **crdpoints** is also included, to make easier the handling of
information recorded in the coordinate files.

Station Coordinate files (extension .CRD), contain coordinate components,
names and flags for a list of stations. Corrdinates are always in a
Cartesian reference frame, as [x,y,z] components, in meters.

Station Information file format format is very strict, and most of the 
functions/modules depend that this format is kept. For an example of .CRD
files, see ftp://ftp.unibe.ch/aiub/BSWUSER52/STA/ and the collection of .CRD
files placed there.

-----------------------------
Documentation
-----------------------------

.. currentmodule:: bernutils.bcrd

^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
Class crdpoint
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. autoclass:: bernutils.bcrd.crdpoint
   :members:
   :undoc-members:

^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
Class crdfile
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. autoclass:: bernutils.bcrd.crdfile
   :members:
   :undoc-members:

-----------------------------
Examples
-----------------------------
