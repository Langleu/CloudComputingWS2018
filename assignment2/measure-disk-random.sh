#!/bin/bash

# creates a 1GB testfile with 8K read/write at a time. The ratio is 75/25 meaning 3:1 for read and write.
# 3 reads are followed by 1 write and 64 Operations at a time.
# for vio v3
WRITE_IOPS="$(fio --randrepeat=1 --ioengine=libaio --direct=1 --gtod_reduce=1 --name=random --filename=randomFile --bs=8K --iodepth=64 --size=1024M --readwrite=randrw -rwmixread=75 2>&1 | awk '/write: IOPS=/ {printf $2 }')"

# removes tempfile just in case
rm -rf randomFile

# output in IOPS
TEMP=$(echo ${WRITE_IOPS##*=})
echo ${TEMP::-1}
