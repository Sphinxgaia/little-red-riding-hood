# Bounary

```
terraform init
```

Run terraform apply against the kubernetes terraform module:

```

aws-vault exec custom -- kubectl create ns boundary
aws-vault exec custom -- terraform apply -target module.kubernetes -auto-approve

export BOUNDARY_ADDR="http://ac6c7a66b9daf4986939b7e7dae09ff0-1723290738.eu-west-1.elb.amazonaws.com:9200" 
aws-vault exec custom -- terraform apply -auto-approve
```

Expose all 3 Boundary services running on minikube, on your local host using `kubectl port-forward` (you'll
need to do this in 3 separate long running shells):

```
$ kubectl port-forward pods/$(kubectl get pods | grep boundary | cut -d " " -f 1) 9200:9200
Forwarding from 127.0.0.1:9200 -> 9200
Forwarding from [::1]:9200 -> 9200

$ kubectl port-forward pods/$(kubectl get pods | grep boundary | cut -d " " -f 1) 9201:9201
Forwarding from 127.0.0.1:9201 -> 9201
Forwarding from [::1]:9201 -> 9201

$ kubectl port-forward pods/$(kubectl get pods | grep boundary | cut -d " " -f 1) 9202:9202
Forwarding from 127.0.0.1:9202 -> 9202
Forwarding from [::1]:9202 -> 9202
Handling connection for 9202
```

Run terraform apply against the boundary terraform module using the value for Boundary's 
address found in the previous command:

```
# Set the external address for your service
export KUBE_SERVICE_ADDRESS=$(echo "http://127.0.0.1:9200")
terraform apply -target module.boundary -var boundary_addr=$KUBE_SERVICE_ADDRESS
```

### Verify

Check the deployments:

```
$ kubectl get deployments
NAME       READY   UP-TO-DATE   AVAILABLE   AGE
boundary   1/1     1            1           12m
postgres   1/1     1            1           12m
redis      1/1     1            1           12m
```

### Login to Boundary

In the shell you intend to run `boundary` commands, export the `BOUNDARY_ADDR` variable with 
the value from the `kubectl port-forward` command:

```
$ export BOUNDARY_ADDR=http://localhost:9200
```

Get the auth method ID for the password auth method in the `primary` scope. We're going to use 
some jq foo to to get the correct ID (remember resource ID's are unique, so yours will be different
from the one I get here): 

```

boundary scopes list -format json | jq -c ".items[]  | select(.name | contains(\"primary\")) | .[\"id\"]"

$ boundary auth-methods list -scope-id $(boundary scopes list -format json | jq -c ".items[]  | select(.name | contains(\"primary\")) | .[\"id\"]" | tr -d '"')

boundary auth-methods list -scope-id  -format json $(boundary scopes list -format json | jq -c ".items[]  | select(.name | contains(\"primary\")) | .[\"id\"]" | tr -d '"')

# set BOUNDARY_AUTH_METHOD_ID

export BOUNDARY_SCOPE=$(boundary scopes list -keyring-type=none -format json | jq -c ".items[]  | select(.name | contains(\"primary\")) | .[\"id\"]")

export BOUNDARY_AUTH_METHOD_ID=$(boundary auth-methods list -keyring-type=none -format json -scope-id $(boundary scopes list -keyring-type=none -format json | jq -c ".items[]  | select(.name | contains(\"primary\")) | .[\"id\"]" | tr -d '"') | jq -c ".items[] | .id" |  sed -e 's/^"//' | sed -e 's/"$//' )


Auth Method information:
  ID:             ampw_1234567890
    Description:  Provides initial administrative authentication into Boundary
    Name:         Generated global scope initial auth method
    Type:         password
    Version:      1
```

Now login:

```
$ boundary authenticate password \
  -login-name=mark \
  -password=foofoofoo \
  -auth-method-id=${BOUNDARY_AUTH_METHOD_ID}
```

From the UI or the CLI, grab the target ID for the redis container in the databases project. If
you're doing this on the CLI, you'll want to list the scopes from the `primary` org scope we 
created using Terraform:

```
$ boundary scopes list
<get scope ID for primary org>
$ boundary scopes list -scope-id <primary org ID>
```

Once you have the databases project scope ID, you can list the targets (again, using some JQ foo to get the correct scope ID for the `primary` scope).

```
$ boundary targets list -scope-id <project_scope_id>
```

You can also navigate to the admin console, login, go to projects, and then targets and copy it from the UI.

You'll want the target ID for the Redis container. Use that target ID to start a session:

```
$ boundary connect -exec redis-cli -target-id ttcp_TBjC1bYRIQ -- -h {{boundary.ip}} -p {{boundary.port}}
127.0.0.1:57159> ping
PONG
127.0.0.1:57159>
```

Congrats! You've just deployed Boundary onto Kubernetes and are able to access other containers running on Kubernetes using it.


# Installation de Boundary pour sécuriser l'accès à votre environnement


kubectl apply -f setup_vault/vault-clusterrole.yaml

kubectl config view --minify --raw --output 'jsonpath={..cluster.certificate-authority-data}' | base64 -d > ca.crt

cat <<EOF > envs_files
export KUBE_API_URL=$(kubectl config view -o jsonpath="{.clusters[?(@.name == \"$(kubectl config current-context)\")].cluster.server}")

export VAULT_SVC_ACCT_TOKEN="$(kubectl create token vault -n vault)"

EOF


kubectl cp ca.crt vault/vault-0:/home/vault
kubectl cp envs_files vault/vault-0:/home/vault

kubectl exec -n vault vault-0 -it -- sh

cd /home/vault

ls

en cas de soucis de connexion

vault login $(grep 'Initial Root Token:' key-vault.txt | awk '{print $NF}')
vault secrets enable kubernetes

vault secrets enable -path=secret kv-v2

vault kv put secret/k8s-cluster ca_crt=@ca.crt

vault write -f kubernetes/config \
  kubernetes_host=$KUBE_API_URL \
  kubernetes_ca_cert=@ca.crt \
  service_account_jwt=$VAULT_SVC_ACCT_TOKEN

vault write kubernetes/roles/auto-managed-sa-and-role \
allowed_kubernetes_namespaces="*" \
token_default_ttl="10m" \
generated_role_rules='{"rules":[{"apiGroups":[""],"resources":["pods"],"verbs":["list"]}]}'

vault write kubernetes/creds/auto-managed-sa-and-role kubernetes_namespace=default

create a file remote_user_token with service_account_token fields

exit

kubectl cp vault/vault-0:/home/vault/remote_user_token remote_user_token

export KUBE_API_URL=$(kubectl config view -o jsonpath="{.clusters[?(@.name == \"$(kubectl config current-context)\")].cluster.server}")

export REMOTE_USER_TOKEN=$(cat remote_user_token)

export OLD_KUBECONFIG=$KUBECONFIG

export KUBECONFIG=toto

kubectl config view > toto

issue
kubectl get pod -A --certificate-authority=ca.crt --server=$KUBE_API_URL --token=$REMOTE_USER_TOKEN

ok
kubectl get pod --certificate-authority=ca.crt --server=$KUBE_API_URL --token=$REMOTE_USER_TOKEN



export KUBECONFIG=$OLD_KUBECONFIG

kubectl cp setup_vault/boundary-policy.hcl vault/vault-0:/home/vault

kubectl exec -n vault vault-0 -it -- sh

cd /home/vault

vault policy write boundary-controller boundary-policy.hcl

vault token create \
  -no-default-policy=true \
  -policy="boundary-controller" \
  -orphan=true \
  -period=45m \
  -renewable=true \
  -format=json

copy client_token (1 line) to boundary-token file

exit

kubectl cp vault/vault-0:/home/vault/boundary-token boundary-token

kubectl create ns boundary

kubectl apply -f kubernetes

access boundary ui

terraform apply -auto-approve

connect to boundary

terraform output password