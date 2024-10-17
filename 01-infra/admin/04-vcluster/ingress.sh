#!/usr/bin/env bash

cat <<EOF | kubectl apply -f -
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