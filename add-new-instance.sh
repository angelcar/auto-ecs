#!/bin/bash
set -eou pipefail

CLUSTERNAME="${1:-}"
if [[ "$CLUSTERNAME" == "" ]]; then
    echo "You must specify a cluster to add the instance to"
    exit 1
fi

echo "CLUSTERNAME=$CLUSTERNAME"

SGID=$(jq -r .sgID < "./.clusters/$CLUSTERNAME.json")
SUBNETID=$(jq -r .subnet2ID < "./.clusters/$CLUSTERNAME.json")
CLUSTERNAME=$(jq -r .clusterName < "./.clusters/$CLUSTERNAME.json")
REGION=$(jq -r .region < "./.clusters/$CLUSTERNAME.json")

echo "SGID=$SGID"
echo "SUBNETID=$SUBNETID"
echo "CLUSTERNAME=$CLUSTERNAME"
echo "REGION=$REGION"

SSH_KEY_NAME=$(jq -r ".ssh_keypairs.\"$REGION\"" < config.json)
INSTANCE_TYPE=$(jq -r .ec2_container_instance_type < ./config.json)

echo "SSH_KEY_NAME=$SSH_KEY_NAME"
echo "INSTANCE_TYPE=$INSTANCE_TYPE"

AMIID=$(aws ssm get-parameters --region "$REGION" --names /aws/service/ecs/optimized-ami/amazon-linux-2/arm64/recommended/image_id | jq -r ".Parameters[0].Value")

echo "AMIID=$AMIID"

#cat << EOF > /tmp/userdata
#<powershell>
#[Environment]::SetEnvironmentVariable("ECS_ENABLE_SPOT_INSTANCE_DRAINING", "true", "Machine")
#Import-Module ECSTools
#Initialize-ECSAgent -Cluster '$CLUSTERNAME' -EnableTaskIAMRole
#</powershell>
#EOF

cat << EOF > /tmp/userdata
#!/bin/bash
echo ECS_CLUSTER=$CLUSTERNAME >> /etc/ecs/ecs.config
EOF
cat ./userdata >> /tmp/userdata


ID=$(uuidgen)
echo "Launching instance. name=$CLUSTERNAME-$ID amiID=$AMIID type=$INSTANCE_TYPE"
aws ec2 run-instances --image-id "$AMIID" --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$CLUSTERNAME-$ID}]" --iam-instance-profile Name=ecsInstanceRole --count 1 --instance-type "$INSTANCE_TYPE" --key-name "$SSH_KEY_NAME" --user-data file:///tmp/userdata --security-group-ids "$SGID" --subnet-id "$SUBNETID" --region "$REGION" --block-device-mapping "[{\"DeviceName\":\"/dev/xvda\",\"Ebs\":{\"VolumeSize\":100}}]" --associate-public-ip-address >/dev/null

