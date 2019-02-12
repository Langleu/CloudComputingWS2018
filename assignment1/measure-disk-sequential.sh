#!/bin/bash 

# writes a 1GB tempfile with 1M at a time
# saves it as the variable READ and cuts out the MB/s or GB/s without output
sync; WRITE=$(dd if=/dev/zero of=tempfile bs=1M count=1024 2>&1 | awk '/copied/ {print $10 " "  $11}'); sync

# drops the cache so that reading doesn't use the cache
# output is redirected to null so we don't have any

# not working on the test runner ...
# sudo /sbin/sysctl -w vm.drop_caches=3 > /dev/null #drop cache
# echo 3 | sudo tee /proc/sys/vm/drop_caches
# after looking on google/stackoverflow I can't seem to find a quick way to get rid of the cache, as sudo is not allowed and without it, it doesn't work
# dropping caches is a priviliged operation

# reads the 1GB tempfile and 1M at a time.
# saves it as the variable READ and cuts out the MB/s or GB/s without output
READ=$(dd if=tempfile of=/dev/null bs=1M count=1024 2>&1 | awk '/copied/ {print $10 " "  $11}')

# removes tempfile just in case
rm -rf tempfile

# conversion to KB/s

# in case the test runner is super slow
if [[ $READ =~ 'kB/s' ]];
then
    TEMP=${READ::-5}
	READ=$(awk "BEGIN {printf \"%.1f\", $TEMP}")
	# not working on test runner due to missing bc
    # READ=$(echo "scale=1; $TEMP*1.0" | bc)
fi

if [[ $READ =~ 'MB/s' ]];
then
    TEMP=${READ::-5}
	READ=$(awk "BEGIN {printf \"%.1f\", $TEMP*1000}")
    # READ=$(echo "scale=1; $TEMP*1000.0" | bc)
fi

if [[ $READ =~ 'GB/s' ]];
then
    TEMP=${READ::-5}
	READ=$(awk "BEGIN {printf \"%.1f\", $TEMP*1000*1000}")
    # READ=$(echo "scale=1; $TEMP*1000.0*1000.0" | bc)
fi

# Prints the read value for the csv in KB/s
echo $READ

# cronjob (every hour at minute 5)
# 5 * * * * echo $(date +\%s),$(~/./measure-disk-sequential.sh) >> $CSV