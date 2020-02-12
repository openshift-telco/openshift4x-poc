#!/bin/bash

export IPMI_USER=user
export IPMI_PASS=password

export HOST_LIST=(host1 host2 host3 host4)

for host in "${HOST_LIST[@]}"; do
    ipmitool -I lanplus -H ${host} -U ${IPMI_USER} -P ${IPMI_PASS} chassis power off
done