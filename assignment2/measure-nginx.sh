#!/bin/bash

# assign first argument or else set default
URL=${1:-"http://localhost/5gb"}

# 3 parallel calls with results assigned to TIME
TIME="$(curl -so /dev/null -w '%{time_total}\n' $URL 2>&1 &
curl -so /dev/null -w '%{time_total}\n' $URL 2>&1 &
curl -so /dev/null -w '%{time_total}\n' $URL 2>&1 &
curl -so /dev/null -w '%{time_total}\n' $URL 2>&1 &
curl -so /dev/null -w '%{time_total}\n' $URL 2>&1 &
curl -so /dev/null -w '%{time_total}\n' $URL 2>&1 &
curl -so /dev/null -w '%{time_total}\n' $URL 2>&1 &
curl -so /dev/null -w '%{time_total}\n' $URL 2>&1 &
curl -so /dev/null -w '%{time_total}\n' $URL 2>&1 &
curl -so /dev/null -w '%{time_total}\n' $URL 2>&1 &
curl -so /dev/null -w '%{time_total}\n' $URL 2>&1 &
curl -so /dev/null -w '%{time_total}\n' $URL 2>&1)"

# wait for calls to finish
wait

# adjust to float value
TIME=$(echo $TIME | tr , .)

# cut TIME into array
a=($(echo "$TIME" | tr ' ' '\n'))

# add up time values
sum=0
for i in "${a[@]}"; do
  sum=$(echo $sum + $i | bc);
done
AVGTIME=$(echo "scale=3; ${sum} / 12" | bc)

# result in MB/s
echo "scale=3; 5120 / ${AVGTIME}" | bc