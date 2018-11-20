#!/bin/bash
EXECUTABLE="~/memsweep"
if [ ! -e $EXECUTABLE ] ; then
	gcc -O -o ~/memsweep ~/memsweep.c -lm -w
fi

if [ "$SYSTEMROOT" = "C:\Windows" ] ; then
	./memsweep.exe
else
	~/./memsweep
fi

# cronjob (every hour at minute 15)
# 15 * * * * ~/./measure-mem.sh >> $CPU