#!/bin/bash 

# creates a 4GB testfile with 4kb read/write at a time. The ratio is 75/25 meaning 3:1 for read and write.
# 3 reads are followed by 1 write and 64 Operations at a time.
READWRITE="$(fio --randrepeat=1 --ioengine=libaio --direct=1 --gtod_reduce=1 --name=random --filename=randomFile --bs=4k --iodepth=64 --size=1024M --readwrite=randrw -rwmixread=75 2>&1 | awk '/aggrb/ {printf substr($3,7,length($3)-6) }')"

# removes tempfile just in case
rm -rf randomFile

# output is timestamp, read, write and all values in KB/s
echo "$(date +%s),${READWRITE::-1}" | sed 's/KB\/s//g'

# cronjob (every hour at minute 0)
# 0 * * * * ~/./measure-disk-random.sh >> $CSV