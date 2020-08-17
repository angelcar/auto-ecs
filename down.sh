#!/bin/bash
set -eou pipefail

CLUSTERNAME="${1:-}"
if [[ "$CLUSTERNAME" == "" ]]; then
    echo "You must specify a cluster to take down"
    exit 1
fi

rm "./.clusters/$CLUSTERNAME.json"
ecs-cli down --force --cluster-config "$CLUSTERNAME"

