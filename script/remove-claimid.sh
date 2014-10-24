#!/bin/bash

echo 'Script to remove ClaimID from claim files'

pushd ../../dafna-datasets || exit 1

for dir in books/claims flights/claims population/claims weather/claims
do
  pushd $dir
  for csv in *.csv
  do
    printf "$csv\r"
    cut -d, -f2- $csv > /tmp/x
    mv /tmp/x $csv
  done
  popd
done

popd