#! /usr/bin/python

import sys
import re

def pad_ws(depth):
  if   depth == 1: return ''
  elif depth == 2: return '    '
  elif depth == 5: return '        '
  elif depth == 6: return '            '

empty_line= re.compile('^\s*$')             ## an empty line
chapter    = re.compile('^[0-9]+\\.\s+.*$')       ## an integer
subchapter = re.compile('^[0-9]+\\.[0-9]+\s+.*$') ## a float

def leading_ws(ln):
 ws_count = 0
 idx      = 0
 while ln[idx] == ' ':
   idx += 1
 return idx

def close_tags(dtc, tag_nr):
  if len(dtc) == 0: return dtc
  while len(dtc):
    maxkey = max(dtc)
    if maxkey >= tag_nr and maxkey != 6:
      print "%s</%s>"%(pad_ws(maxkey), dtc[maxkey])
      del dtc[maxkey]
    else:
      return dtc

igs_log = sys.argv[1]

with open(igs_log, 'r') as buf:
  lines = buf.readlines()

book_lines  = []
book_depths = []

for line in lines:
  if not empty_line.match(line):
    if chapter.match(line):
      book_lines.append(line)
      book_depths.append(1)
    elif subchapter.match(line):
      book_lines.append(line)
      book_depths.append(2)
    elif leading_ws(line) > 5:
      book_lines.append(line)
      book_depths.append(6)
    else:
      ## if the line has no ':' character, it probably is of depth 2!
      if line.find(':') == -1 :
        book_depths.append(2)
      else:
        book_depths.append(5)
      book_lines.append(line)

del lines[:]

open_tags = {}

#try:
for idx in range(4, len(book_lines)):
  line = book_lines[idx]
  if line.strip() == 'Antenna Graphics with Dimensions':
    print "%s<%s>"%(pad_ws(6), line.strip())
    for j in range(idx+1, len(book_lines)):
      print book_lines[j].strip()
    print "%s<%s>"%(pad_ws(6), "Antenna Graphics with Dimensions")
    close_tags(open_tags, 1)
    break
  if book_depths[idx] == 5:
    l = map( lambda x: x.strip(), line.split(':'))
    close_tags(open_tags, 5)
    tag          = l[0]
    description  = ':'.join(l[1:])
    open_tags[5] = tag
    print "%s<%s>%s"%(pad_ws(5), tag, description)
  elif book_depths[idx] == 1:
    l = map( lambda x: x.strip(), line.split())
    chapter     = l[0]
    description = ''.join(l[1:])
    close_tags(open_tags, 1)
    print "%s<%s>"%(pad_ws(1), description)
    open_tags[1] = description 
  elif book_depths[idx] == 2:
    l = map( lambda x: x.strip(), line.split())
    ## numbered subsections, e.g. 
    ## '9.2.x  Multipath Sources      : (METAL ROOF/DOME/VLBI ANTENNA/etc)'
    ## or (unnambered) lists, e.g.
    ## Secondary Contact
    ##       Contact Name           : 
    ##       Telephone (primary)    : 
    ##
    close_tags(open_tags, 2)
    try:
      float(l[0])
      tag          = l[1]
      description  = ' '.join(l[2:])
    except:
      close_tags(open_tags, 2)
      tag          = line.strip()
      description  = ''
    open_tags[2] = tag
    print "%s<%s>%s"%(pad_ws(2), tag, description)
  elif book_depths[idx] == 6:
    l = map( lambda x: x.strip(), line.split(':'))
    tag          = l[0]
    description  = ':'.join(l[1:])
    print "%s<%s>%s</%s>"%(pad_ws(6), tag, description, tag)
#except:
#  print 'EXCEPTION for line [%s] depth = %i'%(line, book_depths[idx])
