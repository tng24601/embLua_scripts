#!/bin/bash
# catto.sh tt.lua /dev/ttyUSB0. You can have minicom running at the same time.
while IFS= read -r line; do
  for ((i = 0; i < ${#line}; i++)); do
    echo -n "${line:i:1}" >$2
    sleep 0.00003
  done
  echo "" >$2 # Send a line feed after each line
done <$1
echo -e "\004" >$2 # ctrl-d as EOF
