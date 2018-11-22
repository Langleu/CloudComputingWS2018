#!/bin/bash
EXECUTABLE="~/linpack"
if [ ! -e $EXECUTABLE ] ; then
	gcc -O -o ~/linpack ~/linpack.c -lm
fi

if [ "$SYSTEMROOT" = "C:\Windows" ] ; then
	result=$(./linpack.exe | tail -1 | sed "s/[[:blank:]]\+/ /g" | cut -d " " -f 7)
else
	result=$(~/./linpack | tail -1 | sed "s/[[:blank:]]\+/ /g" | cut -d " " -f 7)
fi
echo "$result"

# cronjob (every hour at minute 10)
# 10 * * * * echo $(date +\%s),$(~/./measure-cpu.sh) >> $CSV