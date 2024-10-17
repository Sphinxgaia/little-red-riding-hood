# Exercice 03 : Installation et Configuration de Linkerd

![Linkerd](../../images/linkerd_logo.png)

Dans un royaume technologique en constante évolution, le Petit Chaperon Rouge se déplaçait entre de nombreuses 
applications, toutes jouant un rôle crucial dans la vie du village. Cependant, un danger invisible rôdait : le loup, 
qui menaçait la sécurité des communications et l'intégrité des données échangées. Pour protéger son royaume et assurer 
la sécurité des échanges, le Petit Chaperon Rouge savait qu'elle devait déployer des mesures de protection efficaces.

## Le but de l'exercice 

L'objectif de cet exercice est d'installer et de configurer Linkerd sur votre cluster Kubernetes. Vous apprendrez à 
établir un maillage de services capable de sécuriser les échanges entre applications, tout en facilitant l'observabilité 
grâce à des métriques en temps réel.

Durant cet atelier, nous allons chercher à monter les deux composants sidecar qui vont avoir la responsabilité de sécurisé
la communication entre le frontend et le backend.

![Little Red Riding Hood Architecture Mesh](../../images/archi_mesh.png)

## Pourquoi utiliser Linkerd ?

Linkerd est un outil essentiel pour gérer les communications entre microservices dans les environnements cloud-native. 
Il apporte une sécurité accrue grâce à l’implémentation de TLS mutuel, assurant que seul le trafic autorisé est échangé 
entre les services. En outre, Linkerd offre des fonctionnalités d’observabilité qui vous permettent de visualiser le 
comportement de vos services en temps réel et d'identifier rapidement les problèmes de performance ou de sécurité. En 
adoptant Linkerd, vous renforcez la résilience et la sécurité de votre architecture microservices, garantissant ainsi 
un fonctionnement fluide et sécurisé.

## Installation de Linkerd

Pour commencer l'installation de Vault, nous allons utiliser l'image Docker de tooling fournie.

### Étapes d'Installation
1. Configuration de l'environnement :
Exécutez les commandes suivantes pour préparer votre environnement :

```bash
export REPO_ROOT_DIR=$(pwd)
export KUBECONFIG=$(pwd)/kubeconfig
docker run --rm -v $KUBECONFIG:/home/tooling/.kube/config -v $REPO_ROOT_DIR/labs:/labs -it ghcr.io/ddrugeon/little-red-riding-hood-tooling:latest
```

2. Avant d'installer Linkerd, vérifiez si votre cluster est prêt :

```bash
linkerd check --pre
```

3. Installer Linkerd et les CRD :

```bash
linkerd install --crds | kubectl apply -f -
linkerd install --set proxyInit.runAsRoot=true | kubectl apply -f -
```

3. Assurez-vous que Linkerd est correctement installé :

```bash
linkerd check
```

4. Installez le dashboard de Linkerd pour visualiser les métriques :

```bash
linkerd viz install | kubectl apply -f -
```

5. Vérifiez que le dashboard est correctement installé :

```bash
linkerd check
```

## Déploiement des Applications (Optionnel)

> **Note:** 
> cette étape est optionnelle, si vous avez déjà fait l'étape 02-vault

Nous allons maintenant déployer les applications et les services nécessaires :

1. Naviguer vers le Répertoire de l'Application :

```bash
cd /labs/01-red-riding-hood-v1
```

2. Appliquez le manifeste pour créer les services et déploiements :

```bash
kubectl apply -f manifest-red.yaml -n red
```

3. Vérifiez que les déploiements se déroulent sans problème :

```bash
kubectl -n red get deploy
```

## Ajout du Maillage avec Linkerd

1. Vérifiez que les pods existants sur votre namespace ne sont pas gérés par Linkerd :

```bash
kubectl -n red get po -o jsonpath='{.items[0].spec.containers[*].name}'
```

2. Modifiez les déploiements pour ajouter le proxy Linkerd :

```bash
kubectl -n red get deploy -o yaml | linkerd inject - | kubectl apply -n red -f -
```

3.Assurez-vous que le proxy Linkerd a bien été injecté :

```bash
kubectl -n red get po -o jsonpath='{.items[0].spec.containers[*].name}' | grep linkerd-proxy
```

4. Vérifiez que tout le trafic entre les services est autorisé :

```bash
linkerd viz authz -n red deploy
```

## Accesser le Dashboard de Linkerd

1. Accédez à l'interface web du dashboard pour visualiser les métriques :

```bash
linkerd viz dashboard --address 127.0.0.1
```

2. Ouvrez ensuite le dashboard dans votre navigateur à l'adresse http://localhost:50750.

3. Choisissez le namespace `red` pour visualiser les statistiques de trafic sur vos déploiements.

4. Sélectionnez le déploiement little-red-riding-hood-goldie-body, puis dans un autre terminal, 
générez du trafic sur l'ingress :

> **Note :** Modifiez l'URL de votre ingress en fonction de ce que vous avez configuré.

```bash
while [ true ]; do curl -sS http://vcluster-test-red.aws.sphinxgaia.jeromemasson.fr > /dev/null ; done;
```
5. Observez l'augmentation du trafic sur le déploiement.

## Sécurisation avec mTLS

L'un des avantages d'un service mesh est la sécurisation des communications via TLS mutuel, sans avoir à 
le gérer dans vos déploiements.

1. Vérifiez si le trafic entre vos pods est sécurisé :

```bash
linkerd viz -n red edges deployment
```

> Note: Pour des détails supplémentaires, consultez la documentation de Linkerd.

## Restreindre l'Accès à Nos Services

Nous allons sécuriser l'accès à nos services. Dans cet exemple, nous voulons protéger le service goldie-body pour 
qu'il ne soit accessible que par notre service principal.

1. Appliquez la définition pour le serveur goldie-body :

```bash
kubectl apply -n red -f manifests/server.yaml
```

2. Assurez-vous que le serveur a été correctement créé :

```bash
kubectl get server -n red
```

3. Accédez à l'URL de votre ingress. L'image de Goldie ne doit plus s'afficher, puisque le trafic n'est pas autorisé.

4. Vérifiez qu'aucun trafic entrant n'est autorisé :

```bash
linkerd viz authz -n red deploy/little-red-riding-hood-goldie-body
```

```text
ROUTE    SERVER                       AUTHORIZATION                  UNAUTHORIZED  SUCCESS     RPS  LATENCY_P50  LATENCY_P95  LATENCY_P99  
default  default:all-unauthenticated  default/all-unauthenticated          0.0rps  100.00%  0.1rps          3ms          3ms          3ms  
probe    default:all-unauthenticated  default/probe                        0.0rps  100.00%  0.2rps          1ms          1ms          1ms  
probe    red-body-server              default/probe                        0.0rps  100.00%  0.2rps          2ms          2ms          2ms  

```
5. Appliquez la définition suivante pour autoriser l'accès à la route uniquement pour les déploiements associés à 
notre service account :

```bash
kubectl apply -n red -f manifests/authorization.yaml
```

Accédez à nouveau à la page web, l'image de Goldie devrait apparaître.

6. Vérifiez que le trafic d'autres conteneurs n'est pas autorisé :

```bash
kubectl run debug --rm -it --image=busybox --restart=Never --command -- wget goldie-body.red.svc.cluster.local:9007/images/body.svg
```
```text
Connecting to goldie-body.red.svc.cluster.local:9007 (10.111.87.241:9007)
wget: server returned error: HTTP/1.1 403 Forbidden
pod "debug" deleted
pod default/debug terminated (Error)
```
## Conclusion

Linkerd permet de sécuriser vos services en gérant les communications inter-containers et en imposant des politiques 
d'accès. Cette configuration est essentielle pour maintenir une architecture microservices sécurisée et fonctionnelle. 
Pour aller plus loin, vous pouvez explorer des fonctionnalités avancées comme les timeouts, les circuit breakers, 
et bien plus, en consultant la documentation de Linkerd.

> Tout comme le Petit Chaperon Rouge a su se garder du loup en empruntant le chemin des sentiers sécurisés, vous avez 
> armé votre royaume numérique avec Linkerd, un bouclier efficace contre les dangers invisibles. Grâce à votre vigilance
> et aux outils appropriés, vous pouvez maintenant parcourir le royaume numérique en toute sécurité, en protégeant vos
> secrets et en garantissant la tranquillité d'esprit de tous les habitants du village.
 
Suite de l'aventure : [04 - Gestion des Politiques de Sécurité avec Kyverno](../04-kyverno/README.md)
