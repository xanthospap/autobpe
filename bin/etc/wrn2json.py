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
  print " \"message\":{",
  print ', '.join(['\"{}\": \"{}\"'.format(k,v) for k,v in erdictails.iteritems()])
  print "}",
  print "}",

if len(sys.argv) != 2:
  print>>sys.stderr,'ERROR. Must provide warnings file as cmd'
  sys.exit(1)

print "\"warnings\":["

warnings = 0
with open(sys.argv[1], 'r') as w:
  line = w.readline()
  while line:
    if line[0:4] == ' ###':
      if warnings > 0: print ","
      error2json(w, line)
      warnings += 1
    else:
      print>>sys.stderr,'[WARNING] skiping line [%s]'%line
    line = w.readline()

print "],"
sys.exit(0)
