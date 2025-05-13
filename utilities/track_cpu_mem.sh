#!/bin/bash
# This script monitors CPU and memory usage

while :
do 
  # Get the current usage of CPU and memory
  datetime=$(date)
  cpuUsage=$(top -bn1 | awk '/Cpu/ { if ($2 == "us,") { print 100 } else { print $2 } }')
  memUsage=$(free -m | awk '/Mem/{print $3}')1

  # Print the usage
  echo "$datetime - CPU: $cpuUsage% Mem: $memUsage MB"
 
  # Sleep for 1 second
  sleep 1
done
