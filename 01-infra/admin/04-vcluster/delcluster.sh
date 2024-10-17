#!/usr/bin/env bash

vcluster delete $1 

rm vcluster-$1-data.json
rm vcluster-$1-data-temp.json
rm vcluster-$1-vaulttoken
rm vcluster-$1-policy.hcl
rm vcluster-$1-kubeconfig.yaml
rm vcluster-$1.yaml

export VAULT_ADDR="http://vault.aws.sphinxgaia.jeromemasson.fr"

vault kv delete vclusters/data/vcluster-$1

# command to write policy
vault policy delete vcluster-$1
 