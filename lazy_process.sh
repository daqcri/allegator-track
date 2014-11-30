#!/bin/bash

n=3
while true; do
  echo "sleeping $n seconds... (I am $$ btw)"
  sleep $n
done

echo "exiting gracefully"

