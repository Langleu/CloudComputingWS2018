#!/bin/bash 

# writes a 1GB tempfile with 4KB at a time
# saves it as the variable READ and cuts out the MB/s or GB/s without output
sync; WRITE=$(dd if=/dev/zero of=tempfile bs=4k count=1024 2>&1 | awk '/copied/ {print $10 " "  $11}'); sync

# drops the cache so that reading doesn't use the cache
# output is redirected to null so we don't have any
sudo /sbin/sysctl -w vm.drop_caches=3 > /dev/null #drop cache

# reads the 1GB tempfile and 4KB at a time.
# saves it as the variable READ and cuts out the MB/s or GB/s without output
READ=$(dd if=tempfile of=/dev/null bs=4k count=1024 2>&1 | awk '/copied/ {print $10 " "  $11}')

# removes tempfile just in case
rm -rf tempfile

# conversion to KB/s
if [[ $READ =~ 'MB/s' ]];
then
    TEMP=$((${READ::-5}*1000))
    READ=$TEMP
fi

if [[ $WRITE =~ 'MB/s' ]];
then
    TEMP=$((${WRITE::-5}*1000))
    WRITE=$TEMP
fi

if [[ $READ =~ 'GB/s' ]];
then
    TEMP=$((${READ::-5}*1000*1000))
    READ=$TEMP
fi

if [[ $WRITE =~ 'GB/s' ]];
then
    TEMP=$((${WRITE::-5}*1000*1000))
    WRITE=$TEMP
fi

# Prints the timestamp with read, write variable for the csv and all values in KB/s
echo "$(date +%s),$READ,$WRITE"

# cronjob (every hour at minute 5)
# 5 * * * * ./measure-disk-sequential.sh