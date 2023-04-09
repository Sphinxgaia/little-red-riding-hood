# CONF: Le petit Chaperon rouge se met enfin au Zero Trust

## EDITO

Au travers du conte, pour enfant, je revisite le petit chaperon rouge: notre petite goldie rouge va voir sa mère-grand dans la maison de captain kube !!!

Et si notre petite application se décidait enfin à pratiquer le Zero Trust quand elle va voir sa mère-grand et que la maison de captain Kube était aussi sécurisée !!!

Nous aborderons les risques encourues lors d'un déploiement d'une application Kubernetes et d'un environnement non sécurisé.

## Sommaire

Au programme, nous allons:

Accèder au cluster avec Boudary
- authentification
- droits & rôles
Déployer l'application 
- vérification déploiement avec Kyverno
- vérification de l'image in-cluster avec Trivy
- Gestion des secrets avec Vault


Pour réaliser ces différentes opération, nous allons vous founir :
* Un nom de cluster kubernetes qui vous sera util pour obtenir le nom de domaine
* Un container Docker contenant tous les outils 
* Un context Kubernetes sur un cluster isolé
* TODO:
** Une Url vers un Vault pour récupérer le context Kube de votre cluster Kubernetes
** UN token Vault

## Préambule pour jouer les différents labs

### Obtenir les outils

Ce hands on Zero trust utilise beaucoup d'outils (Trivy, Linkerd, Vault, Terraform, Kyberno, ...).
Afin de ne pas emcombrer vos postes, nous vous proposons un container d'outillage qui contient l'ensemble des outils.
Cette image de tooling est multi-plateforme (Linux/amd64 et Linux/arm64) et disponible sur le dépôt github : https://github.com/ddrugeon/devoxx2023-tooling

#### Le container de tooling

```bash
docker pull ghcr.io/ddrugeon/devoxx2023-tooling:latest
```

Pour lancer le container d'outil, vous pouvez la commande suivante:

```bash
export REPO_ROOT_DIR=<chemin vers le clone du projet>
export KUBECONFIG=<chemin vers le fichier du config du cluster kubernetes>
docker run --rm -v $KUBECONFIG:/home/tooling/kubeconfig.yaml -v $REPO_ROOT_DIR/labs/00-preconfig/:/apps -it ghcr.io/ddrugeon/devoxx2023-tooling
```

Vérifier que vous avez bien accés à votre cluster Kubernetes :
```bash
kubectl get namespaces
```

Vous devriez obtenir ça:
```
NAME              STATUS   AGE
default           Active   29h
kube-system       Active   29h
kube-public       Active   29h
kube-node-lease   Active   29h
```

**TODO : Donner la commande Vault pour récupérer le context Kube**


## Ouvrons le livre

Nous allons maintenant instancer nos goldies, dans une version rouge et dans une version verte.

Pour se faire, ouvrons le containeur d'outillage avec le bon point de montage:
```bash
docker run --rm -v $KUBECONFIG:/home/tooling/kubeconfig.yaml -v $REPO_ROOT_DIR/labs/01-red-riding-hood-v1/:/red-riding-hood-v1 -it ghcr.io/ddrugeon/devoxx2023-tooling
```

Créons les namespaces :
```bash
kubectl create ns red
kubectl create ns green
```

Changer le manifest en fonction de votre nom de cluster pour l'ingress, les lignes 229 et 233. Par exemple, si je suis sur le cluster `toto2`, je remplace `vcluster-test-red.aws.sphinxgaia.jeromemasson.fr` par `vcluster-toto2-red.aws.sphinxgaia.jeromemasson.fr`.
```bash
vim /red-riding-hood-v1/static/manifest-red.yaml
```

Nous appliquons le manifest modifié :
```bash
kubectl apply -f /red-riding-hood-v1/static/manifest-red.yaml -n red
```

Changer le manifest en fonction de votre nom de cluster pour l'ingress, les lignes 227 et 231. Par exemple, si je suis sur le cluster `toto2`, je remplace `vcluster-test-green.aws.sphinxgaia.jeromemasson.fr` par `vcluster-toto2-green.aws.sphinxgaia.jeromemasson.fr`.
```bash
vim /red-riding-hood-v1/static/manifest-green.yaml
```

Nous appliquons le manifest modifié :
```bash
kubectl apply -f /red-riding-hood-v1/static/manifest-green.yaml -n green
```

Pour vous lancer dans l'aventure, vous pouvez vous rendre sur [labs](/labs)

## Troubleshooting

Si vous rencontrez des difficultés, vous pourriez trouver une solution

TODO A compléter

