#!/usr/bin/env bash

cat <<EOF > vcluster-$1-data.json
{ "data": {
"kubeconfig": "$(base64 < vcluster-$1-kubeconfig.yaml | tr -d '\n' )"   
}}
EOF

cat vcluster-$1-data.json | tr -d "\n" > vcluster-$1-data-temp.json

sleep 1

curl -X PUT -H "X-Vault-Request: true" -H "X-Vault-Token: $(vault print token)" -d @vcluster-$1-data-temp.json http://vault.aws.sphinxgaia.jeromemasson.fr/v1/vclusters/data/vcluster-$1
