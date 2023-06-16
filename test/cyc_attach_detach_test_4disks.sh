#!/bin/bash

for i in $(seq $4)
do
    echo "`date` test $i" >> $3
    curl -skSL https://raw.githubusercontent.com/Azure/kubernetes-volume-drivers/master/test/attach_detach_test_4disks.sh | bash -s $1 $2 $3 --
    echo "sleep 3 minutes ..." >> $3
    sleep 3m
done
