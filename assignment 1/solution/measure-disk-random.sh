#!/bin/bash

# creates a 1GB testfile with 1M read/write at a time. The ratio is 75/25 meaning 3:1 for read and write.
# 3 reads are followed by 1 write and 64 Operations at a time.
READWRITE="$(fio --randrepeat=1 --ioengine=libaio --direct=1 --gtod_reduce=1 --name=random --filename=randomFile --bs=1M --iodepth=64 --size=1024M --readwrite=randrw -rwmixread=75 2>&1 | awk '/aggrb/ {printf substr($3,7,length($3)-6) }')"

# removes tempfile just in case
rm -rf randomFile

# output is timestamp, read and value in KB/s
READ=$(echo "${READWRITE::-1}" | cut -f1 -d, | sed 's/KB\/s//g')
printf "%.1f\n" $READ

# cronjob (every hour at minute 0)
# 0 * * * * echo $(date +\%s),$(~/./measure-disk-random.sh) >> $CSV