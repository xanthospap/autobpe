#! /usr/bin/python

import os, sys

def error2json(buf, first_line):
  if first_line[0:4] != ' ###':
    print>>sys.stderr,'ERROR. Cannot resolve error message [%s]'%(first_line)
    sys.exit(1)
  erdict = {}
  fl = first_line.split()
  erdict['id'] = fl[1].strip()
  erdict['routine'] = fl[2].strip().replace(':', '')
  erdict['info'] = first_line[first_line.find(':')+1:].strip()
  erdictails = {}
  line = buf.readline()
  while len(line) > 5:
    split_at = line.find(':')
    erdictails[line[0:split_at].strip()] = line[split_at+1:].strip()
    line = buf.readline()
  print "{",
  for key, val in erdict.iteritems(): print "\"%s\":\"%s\","%(key, val),
  print "{",
  for key, val in erdictails.iteritems(): print "\"%s\":\"%s\","%(key, val),
  print "}",
  print "},"

if len(sys.argv) != 2:
  print>>sys.stderr,'ERROR. Must provide warnings file as cmd'
  sys.exit(1)

print "{warnings:["

with open(sys.argv[1], 'r') as w:
  line = w.readline()
  ##[ ### SR TRPVEC: TILTING ANGLE AND ITS RMS ERROR NOT COMPUTED]
  while line:
    if line[0:4] == ' ###':
      error2json(w, line)
    else:
      print>>sys.stderr,'[WARNING] skiping line [%s]'%line
    line = w.readline()

print "]}"
sys.exit(0)
