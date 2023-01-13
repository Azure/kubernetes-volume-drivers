#!/bin/bash

for i in $(seq $4)
do
    echo "test $i" >> $3
    sh attach_detach_test.sh $1 $2 $3
    sleep 30m
done
