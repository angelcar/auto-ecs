#!/bin/bash
set -eou pipefail

CLUSTERNAME="${1:-}"
if [[ "$CLUSTERNAME" == "" ]]; then
    echo "You must specify a cluster to take down"
    exit 1
fi

REGION="${2:-}"
if [[ "$REGION" == "" ]]; then
    echo "You must specify a region"
    exit 1
fi

ecs-cli down --region "$REGION" --force --cluster-config "$CLUSTERNAME"
rm "./.clusters/$CLUSTERNAME.json"

