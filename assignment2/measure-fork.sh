#!/bin/bash

# use bash script instead of pipes for single value
# the script still results in one single value and the same amount of forks are used, another option would've been to used shared memory and skip pipes also entirelly.
START=$(date +%s%N/1000000)

RES="$(./fork 100 5000)"

a=($(echo "$RES" | tr ' ' '\n'))
FINAL_RESULT=0

for i in "${a[@]}"
do
	FINAL_RESULT=$(echo $i + $FINAL_RESULT | bc)
done

END=$(date +%s%N/1000000)
DIFF=$(( $END - $START ))
echo "scale=3; $DIFF / 1000" | bc
