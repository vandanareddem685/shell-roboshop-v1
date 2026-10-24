#!/bin/bash

ami_id="ami-0055977a6e828a4f4"
instance_type="t3.micro"
domain_name="practicedaws92s.online"
hosted_zone_id="Z02394093N5U8D9PQSNO9"

for instance in $@
do
    echo "creating instance: $instance"

    instance_id=$(aws ec2 run-instances \
        --image-id $ami_id \
        --instance-type $instance_type \
        --security-groups "roboshop-common" "roboshop-$instance" \
        --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=roboshop-$instance}]" \
        --query 'Instances[0].InstanceId' \
        --output text
    )

    echo "InstanceId=$instance_id"

    if [ $instance! = "frontend" ];then
       IP=$(aws ec2 describe-instances \
            --instance-ids i-0ce78896fbffb0a07 \
            --query 'Reservations[].Instances[].PrivateIpAddress' \
            --output text
       )
       r53_record=$instance.$domain_name
    else
        IP=$(aws ec2 describe-instances \
            --instance-ids i-0ce78896fbffb0a07 \
            --query 'Reservations[].Instances[].PrivateIpAddress' \
            --output text
        )
    fi
        r53_record=$domain_name
    #update r53_record
    aws route53 change-resource-record-sets \
    --hosted-zone-id "$hosted_zone_id" \
    --change-batch '{
        "Changes": [
            {
                "Action": "UPSERT",
                "ResourceRecordSet": {
                    "Name": "r53_record",
                    "Type": "A",
                    "TTL": 1,
                    "ResourceRecords": [
                        {
                            "Value": "$IP"
                        }
                    ]
                }
            }
        ]
    }' 
done