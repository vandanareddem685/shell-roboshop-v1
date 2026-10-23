#!/bin/bash

ami_id="ami-0055977a6e828a4f4"
instance_type="t3.micro"
domain_name="practicedaws92s.online"
hosted_zone_id="Z02394093N5U8D9PQSNO9"

for instance in $@
do
    echo "creating instance: $instance"
done