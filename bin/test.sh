#! /bin/bash

# VAR=
echo "set -> # VAR="

if test -z "$VAR" ; then
  echo "VAR is unset"
else
  echo "VAR is set"
fi


VAR=
echo "set -> VAR="

if test -z "$VAR" ; then
  echo "VAR is unset"
else
  echo "VAR is set"
fi

VAR=koko
echo "set -> VAR=koko"

if test -z "$VAR" ; then
  echo "VAR is unset"
else
  echo "VAR is set"
fi

eval $(./test2.sh)

echo "FOO=$FOO"
echo "BAR=$BAR"
