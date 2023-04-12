# Installation de Vault + son injecteur

## Edito

Et si mère grand déposait ses digicodes d'entrées dans un vault et que seul goldie rouge pouvait y accéder.

> Le but: 
> 
> Trouver les configurations qui empèchent le loup d'obtenir le secret

## Installation
Pour faciliter l'installation de vault, nous utiliserons l'image docker de tooling que nous vous avons fournie.

```bash
export REPO_ROOT_DIR=<chemin vers le clone du projet>
export KUBECONFIG=<chemin vers le fichier du config du cluster kubernetes>
docker run --rm -v $KUBECONFIG:/home/tooling/kubeconfig.yaml -v $REPO_ROOT_DIR/labs/:/apps -it ghcr.io/ddrugeon/devoxx2023-tooling

```
Déplacer vous dans le dossier 01-red-riding-hood-v1
```bash
/apps/00-preconfig/03-vault
```

Installons vault sur notre cluster.

```bash
helm repo add hashicorp https://helm.releases.hashicorp.com
helm search repo hashicorp/vault
helm repo update
```

Créons le namespace vault.
```bash
kubectl create namespace vault
```
```bash
helm upgrade --install vault hashicorp/vault -n vault -f override.yaml
```

### Unseal du Vault

Notre serveur Vault est maintenant démarré, mais il est dans un état scellé.
L'espace de stockage est alors configuré, mais chiffré. Nous devons donc "desceller" vault pour obtenir la clé de chiffrement racine en clair.

Lançons un conteneur nous permettant d'avoir la cli vault.

```bash
kubectl exec -n vault vault-0 -it -- sh
```

Une fois dans le conteneur, nous pouvons récupérer la clé racine

```bash
cd /home/vault

export VAULT_ADDR="http://127.0.0.1:8200"

vault operator init -key-shares=1 -key-threshold=1 > key-vault.txt

sleep 2

vault operator unseal $(grep 'Key 1:' key-vault.txt | awk '{print $NF}')

sleep 2

vault login $(grep 'Initial Root Token:' key-vault.txt | awk '{print $NF}')

exit
```

Copier votre clé pour plus de sécurité

```bash
kubectl copy vault/vault0
```

Restons dans le conteneur pour exécuter les commandes suivantes.

## Create d'un dépôt de secret dans notre vault

Créons un dépôt où seront stockés nos secrets.

```bash
cd /home/vault

export VAULT_ADDR="http://127.0.0.1:8200"

vault login $(grep 'Initial Root Token:' key-vault.txt | awk '{print $NF}')

vault secrets enable -path=little-red kv-v2 

vault secrets list -detailed

```

## Configuration de votre cluster

Configuration d'un policy vault pour accéder au secret `grand-ma-secret`

```bash
cat <<EOF > little-red-policy.hcl
path "little-red/data/grand-ma-secret" {  capabilities = ["read"] }
EOF

# command to write policy
vault policy write little-red little-red-policy.hcl
```

Configurons l'intégration de Kubernetes dans vault

```bash

vault auth enable kubernetes

vault write auth/kubernetes/config \
    kubernetes_host="https://$KUBERNETES_PORT_443_TCP_ADDR:443"

vault write auth/kubernetes/role/little-red \
bound_service_account_names=red-little-red-riding-hood-goldie-body \
bound_service_account_namespaces=red-zero-trust \
policies=little-red \
ttl=24h
```

## Configuration du secret

Ajoutons un secret dans notre vault.

```bash
vault kv put little-red/grand-ma-secret bobinette=pull
```

Se deconnecter de notre conteneur vault.

```bash
exit
```

## Déployer et Patcher l'application du patch de connexion avec Vault

Se positionner sur le répertoire de travail dédié pour vault:

```bash
cd /apps/03-red-riding-hood-v1-vault/
```
---
> **Note:** Changer le manifeste static/manifest-wolf.yaml en fonction de votre nom de cluster pour l'ingress, les lignes 229 et 233.
> Par exemple, si je suis sur le cluster `toto2`, je remplace `vcluster-user1-red-zero-trust.aws.sphinxgaia.jeromemasson.fr`
> par `vcluster-toto2-red-zero-trust.aws.sphinxgaia.jeromemasson.fr`.
---

Appliquer le manifeste du loup puis vérifier que les déploiements sont corrects.

```bash
kubectl apply -f static/manifest-wolf.yaml
kubectl get deploy -n red-zero-trust
```

Se connecter sur l'ingress avec le navigateur sur l'url modifiée précédemment. Le little red hood s'affiche normalement.

Actuellement, l'injection du secret par vault n'est pas activée. Pour le faire, il faut ajouter les annotations suivantes au niveau du déploiement.
```yaml
...
spec:
  template:
    metadata:
      annotations:
        vault.hashicorp.com/agent-inject: 'true'
        vault.hashicorp.com/role: 'little-red'
        vault.hashicorp.com/agent-grand-ma-secret.txt: 'little-red/data/grand-ma-secret'  
```

Nous pouvons patcher le déploiement en appliquant la commande suivante:

```bash
kubectl patch deployment -n red-zero-trust little-red-riding-hood-goldie-body --patch "$(cat patch.yaml)"
```

Vérifier si le déploiement little-red-riding-hood-goldie-body est lancé

```bash
 kubectl get deploy -n red-zero-trust
 ```

Vérifier les logs du pod en défaut en remplacant little-red-riding-hood-goldie-body-xxx par celui en defaut
```bash
k logs little-red-riding-hood-goldie-body-xxx -n red-zero-trust -c vault-agent-init
```

Le loup n'est pas autorisé à aller chercher le secret dans vault. Mere Grand a bien des secrets à garder.

## Déployer et Patcher l'application dans le dossier success

Pour obtenir le secret, il faut utiliser le bon service account.
Seuls les déploiements avec le nom `red-little-red-riding-hood-goldie-body` peuvent aller récupérer le secret en utilisant
le role vault `auth/kubernetes/role/little-red` comme nous l'avons configuré en début du lab.

Appliquer le manifest success/manifest-red.yaml qui possède la bonne configuration

```bash
kubectl apply -f success
```

Et réinjecter la configuration de vault

```bash
kubectl patch deployment -n red-zero-trust little-red-riding-hood-goldie-body --patch "$(cat patch.yaml)"
```

Vérifier si le déploiement little-red-riding-hood-goldie-body est lancé

```bash
 kubectl get deploy -n red-zero-trust
 ```

Mère grand est rassurée, seule le petit chaperon rouge a récupéré son secret.