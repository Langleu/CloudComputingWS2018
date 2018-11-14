#!/bin/bash
EXECUTABLE="memsweep"
if [ ! -e $EXECUTABLE ] ; then
	gcc -O -o memsweep memsweep.c -lm
fi

if [ "$SYSTEMROOT" = "C:\Windows" ] ; then
	./memsweep.exe
else
	./memsweep
fi
