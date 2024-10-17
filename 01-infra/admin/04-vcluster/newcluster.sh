#!/usr/bin/env bash

cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Namespace
metadata:
  name: vcluster-$1
  annotations:
    vcluster.loft.sh/created: "true" 
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  annotations:
    nginx.ingress.kubernetes.io/backend-protocol: HTTPS
    nginx.ingress.kubernetes.io/ssl-passthrough: "true"
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
    external-dns.alpha.kubernetes.io/hostname: vcluster-$1.aws.sphinxgaia.jeromemasson.fr # give your domain name here
  name: vcluster-ingress
  namespace: vcluster-$1
spec:
  ingressClassName: nginx 
  rules:
  - host: vcluster-$1.aws.sphinxgaia.jeromemasson.fr
    http:
      paths:
      - backend:
          service:
            name: $1
            port: 
              number: 443
        path: /
        pathType: ImplementationSpecific
EOF

cat <<EOF > vcluster-$1.yaml
syncer:
  extraArgs:
  - --tls-san=vcluster-$1.aws.sphinxgaia.jeromemasson.fr
EOF

vcluster create $1 -n vcluster-$1 --upgrade --connect=false -f values.yaml -f vcluster-$1.yaml

sleep 10

vcluster connect $1 -n vcluster-$1 --update-current=false --server=https://vcluster-$1.aws.sphinxgaia.jeromemasson.fr

mv kubeconfig.yaml vcluster-$1-kubeconfig.yaml

export VAULT_ADDR="http://vault.aws.sphinxgaia.jeromemasson.fr"

cat <<EOF > vcluster-$1-data.json
{ "data": {
"kubeconfig": "$(base64 < vcluster-$1-kubeconfig.yaml | tr -d '\n' )"   
}}
EOF

cat vcluster-$1-data.json | tr -d "\n" > vcluster-$1-data-temp.json

sleep 1

curl -X PUT -H "X-Vault-Request: true" -H "X-Vault-Token: $(vault print token)" -d @vcluster-$1-data-temp.json http://vault.aws.sphinxgaia.jeromemasson.fr/v1/vclusters/data/vcluster-$1

cat <<EOF > vcluster-$1-policy.hcl
path "vclusters/data/vcluster-$1" {  capabilities = ["list","read"] }
EOF
# command to write policy
vault policy write vcluster-$1 vcluster-$1-policy.hcl
vault write auth/userpass/users/vcluster-$1 password=vcluster-$1 policies="vcluster-$1"

#vault token create -format=json -policy="vcluster-$1" | jq -r ".auth.client_token" > vcluster-$1-vaulttoken