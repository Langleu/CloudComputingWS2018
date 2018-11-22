#!/bin/bash 

# writes a 1GB tempfile with 1M at a time
# saves it as the variable READ and cuts out the MB/s or GB/s without output
sync; WRITE=$(dd if=/dev/zero of=tempfile bs=1M count=1024 2>&1 | awk '/copied/ {print $10 " "  $11}'); sync

# drops the cache so that reading doesn't use the cache
# output is redirected to null so we don't have any
sudo /sbin/sysctl -w vm.drop_caches=3 > /dev/null #drop cache

# reads the 1GB tempfile and 1M at a time.
# saves it as the variable READ and cuts out the MB/s or GB/s without output
READ=$(dd if=tempfile of=/dev/null bs=1M count=1024 2>&1 | awk '/copied/ {print $10 " "  $11}')

# removes tempfile just in case
rm -rf tempfile

# conversion to KB/s
if [[ $READ =~ 'MB/s' ]];
then
    TEMP=${READ::-5}
    READ=$(echo "$TEMP*1000" | bc)
fi

if [[ $WRITE =~ 'MB/s' ]];
then
    TEMP=${WRITE::-5}
    WRITE=$(echo "$TEMP*1000" | bc)
fi

if [[ $READ =~ 'GB/s' ]];
then
    TEMP=${READ::-5}
    READ=$(echo "$TEMP*1000*1000" | bc)
fi

if [[ $WRITE =~ 'GB/s' ]];
then
    TEMP=${WRITE::-5}
    WRITE=$(echo "$TEMP*1000*1000" | bc)
fi

# Prints the timestamp with read variable for the csv and all values in KB/s
echo "$READ"

# cronjob (every hour at minute 5)
# 5 * * * * echo $(date +%s),$(~/./measure-disk-sequential.sh) >> $CSV