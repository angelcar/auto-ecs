#!/bin/bash
set -eou pipefail

region=$(jq -r .aws_region < ./config.json)
clusterName=$(jq -r .clusterName < ./cluster.json)
taskDefinition=$(aws ecs register-task-definition --region "$region" --cli-input-json file://gpu-task-def.json | jq -r .taskDefinition.taskDefinitionArn)
aws ecs create-service --region "$region" --cluster "$clusterName" --service-name inference-service --task-definition "$taskDefinition" --scheduling-strategy REPLICA --desired-count 1 | jq .

