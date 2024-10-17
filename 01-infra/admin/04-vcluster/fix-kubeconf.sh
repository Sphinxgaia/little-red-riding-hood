#!/usr/bin/env bash

for (( i=0; i <= 21; i++ )); do 
  curl -X PUT -H "X-Vault-Request: true" -H "X-Vault-Token: $(vault print token)" -d @vcluster-app$i-data.json http://vault.aws.sphinxgaia.jeromemasson.fr/v1/vclusters/data/vcluster-app${i};
done
