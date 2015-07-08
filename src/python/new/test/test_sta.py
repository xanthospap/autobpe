#! /usr/bin/python

import datetime
import bernutils.bsta

## Test Program
x = bernutils.bsta.stafile('CODE.STA')

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
