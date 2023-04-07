# Linkerd

## Installation du projet exemple dans le namespace dédié

Créer votre namespace de travail

```bash
❯ export NAMESPACE=<mon namespace à changer>
❯ kubectl create ns $NAMESPACE
namespace/<mon namespace à changer> created
❯ kubectl config set-context --current --namespace=$NAMESPACE

```

Déployer ensuite le manifeste permettant de créer les ressources du projet à savoir:

- 2 services:
  - goldie-body: exposé uniquement en interne sur le port 9007.
    - /metrics : endpoint prometheus qui sert aussi de liveprobe et readiness probe
    - /images/body.svg pour obtenir l’image de notre personnage
  - little-red-riding-hood-goldie-main: service exposé à l’extérieur via un CLB
    - / : endpoint pour obtenir la page principale de notre service
- 2 déploiements:
  - little-red-riding-hood-goldie-body
  - little-red-riding-hood-goldie-main
- 2 service accounts dédiés:
  - little-red-riding-hood-goldie-body
  - little-red-riding-hood-goldie-main

```bash
❯ kubectl apply -f manifest-red.yaml -n $NAMESPACE
serviceaccount/red-little-red-riding-hood-goldie-body created
serviceaccount/red-little-red-riding-hood-goldie-main created
service/goldie-body created
service/red-little-red-riding-hood-goldie-main created
deployment.apps/little-red-riding-hood-goldie-body created
deployment.apps/little-red-riding-hood-goldie-main created
```

Vérifier que les pods s’execute sans aucun problème:

```bash
❯ k -n $NAMESPACE get all
NAME                                                     READY   STATUS    RESTARTS   AGE
pod/little-red-riding-hood-goldie-body-9cb957f7-gzz2b    1/1     Running   0          6m31s
pod/little-red-riding-hood-goldie-main-77795f848-fwtc7   1/1     Running   0          6m31s

NAME                                             TYPE           CLUSTER-IP      EXTERNAL-IP                                                              PORT(S)        AGE
service/goldie-body                              ClusterIP      172.20.193.27   <none>                                                                   9007/TCP       6m32s
service/red-little-red-riding-hood-goldie-main   LoadBalancer   172.20.11.28    a2716861231d74a4e93dcc828d34d01a-531477736.eu-west-1.elb.amazonaws.com   80:30860/TCP   6m32s

NAME                                                 READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/little-red-riding-hood-goldie-body   1/1     1            1           6m31s
deployment.apps/little-red-riding-hood-goldie-main   1/1     1            1           6m31s

NAME                                                           DESIRED   CURRENT   READY   AGE
replicaset.apps/little-red-riding-hood-goldie-body-9cb957f7    1         1         1       6m31s
replicaset.apps/little-red-riding-hood-goldie-main-77795f848   1         1         1       6m31s
```

## Ajout du maillage via linkerd

Vérifier via linkerd  que les pods existants sur votre namespace n’est pas géré par linkerd

```bash
❯ kubectl -n $NAMESPACE get po -o jsonpath='{.items[0].spec.containers[*].name}'

little-red-riding-hood-goldie-body%
```

Pour ajouter dynamiquement un conteneur sidecar (linkerd proxy), il suffit d’ajouter l’annotation au niveau de la specification du conteneur dans le déploiement:

[linkerd.io/inject:](http://linkerd.io/inject:) enabled

ou plus simplement utiliser la cl linkerd pour injecter cette annotation sur tous les déploiements de notre ns

```bash
❯ kubectl -n $NAMESPACE get deploy -o yaml | linkerd inject - | kubectl apply -n $NAMESPACE -f -

deployment "little-red-riding-hood-goldie-body" injected
deployment "little-red-riding-hood-goldie-main" injected

the namespace from the provided object "ddh" does not match the namespace "red". You must pass '--namespace=ddh' to perform this operation.
the namespace from the provided object "ddh" does not match the namespace "red". You must pass '--namespace=ddh' to perform this operation.
```

puis vérifier de nouveau que le dataplane de linkerd a bien été injecté

```bash
❯ kubectl -n $NAMESPACE get po -o jsonpath='{.items[0].spec.containers[*].name}' | grep linkerd-proxy
linkerd-proxy little-red-riding-hood-goldie-body
```

Vérifiez les droits associés à chacune des routes de nos services

```bash
❯ linkerd viz authz -n $NAMESPACE deploy
ROUTE    SERVER                       AUTHORIZATION                UNAUTHORIZED  SUCCESS     RPS  LATENCY_P50  LATENCY_P95  LATENCY_P99
default  default:all-unauthenticated  default/all-unauthenticated        0.0rps  100.00%  0.2rps          1ms          1ms          1ms
probe    default:all-unauthenticated  default/probe                      0.0rps  100.00%  0.8rps          1ms          1ms          1ms
```

## Linkerd dashboard

L’extension dashboard a été installé sur le cluster k8s.

Vous pouvez y accéder via la commande suivante:

```bash
❯ linkerd viz dashboard
Linkerd dashboard available at:
http://localhost:50750
Grafana dashboard available at:
http://localhost:50750/grafana
Opening Linkerd dashboard in the default browser
```

Le dashboard alors disponible sur votre navigateur

![Dashboard1](Dashboard1.png)

Selectionner votre namespace pour visualiser les différentes statistiques

![Dashboard2](Dashboard2.png)

toutes les métriques associées à vos déploiements et pods sont disponibles en temps réel. Vous pouvez générer du trafic pour voir les valeurs changer en temps réel.

Sélectionner le déploiement little-red-riding-hood-goldie-body.

- Quel est le maillage de ce déploiement (qui appelle ce déploiement, et quel service appelle-t-il ?)
- Quel sont les métriques associées à la route / et quelles routes appelle-t-elle ?

## mTLS

Un des points forts d’un service mesh est la sécurisation des communications via du TLS mutuel sans le gérer dans nos déploiement.

```bash
❯ linkerd viz top deployment/little-red-riding-hood-goldie-body --namespace $NAMESPACE
req id=3:0 proxy=in  src=10.0.3.94:65513 dst=10.0.3.26:9000 tls=no_tls_from_remote :method=GET :authority=a2716861231d74a4e93dcc828d34d01a-531477736.eu-west-1.elb.amazonaws.com :path=/
rsp id=3:0 proxy=in  src=10.0.3.94:65513 dst=10.0.3.26:9000 tls=no_tls_from_remote :status=200 latency=1000µs
end id=3:0 proxy=in  src=10.0.3.94:65513 dst=10.0.3.26:9000 tls=no_tls_from_remote duration=30µs response-length=564B
req id=3:1 proxy=in  src=10.0.3.94:65513 dst=10.0.3.26:9000 tls=no_tls_from_remote :method=GET :authority=a2716861231d74a4e93dcc828d34d01a-531477736.eu-west-1.elb.amazonaws.com :path=/parts/body/body.svg
req id=3:2 proxy=out src=10.0.3.26:46142 dst=10.0.2.55:9000 tls=true :method=GET :authority=goldie-body:9007 :path=/images/body.svg
req id=3:0 proxy=in  src=10.0.3.26:52356 dst=10.0.2.55:9000 tls=true :method=GET :authority=goldie-body:9007 :path=/images/body.svg
rsp id=3:0 proxy=in  src=10.0.3.26:52356 dst=10.0.2.55:9000 tls=true :status=200 latency=1742µs
end id=3:0 proxy=in  src=10.0.3.26:52356 dst=10.0.2.55:9000 tls=true duration=163µs response-length=15492B
rsp id=3:2 proxy=out src=10.0.3.26:46142 dst=10.0.2.55:9000 tls=true :status=200 latency=2740µs
end id=3:2 proxy=out src=10.0.3.26:46142 dst=10.0.2.55:9000 tls=true duration=32µs response-length=15492B
rsp id=3:1 proxy=in  src=10.0.3.94:65513 dst=10.0.3.26:9000 tls=no_tls_from_remote :status=200 latency=3867µs
end id=3:1 proxy=in  src=10.0.3.94:65513 dst=10.0.3.26:9000 tls=no_tls_from_remote duration=139µs response-length=15492B
req id=3:3 proxy=in  src=10.0.3.94:65513 dst=10.0.3.26:9000 tls=no_tls_from_remote :method=GET :authority=a2716861231d74a4e93dcc828d34d01a-531477736.eu-west-1.elb.amazonaws.com :path=/
rsp id=3:3 proxy=in  src=10.0.3.94:65513 dst=10.0.3.26:9000 tls=no_tls_from_remote :status=200 latency=636µs
end id=3:3 proxy=in  src=10.0.3.94:65513 dst=10.0.3.26:9000 tls=no_tls_from_remote duration=83µs response-length=564B
req id=3:4 proxy=in  src=10.0.3.94:65513 dst=10.0.3.26:9000 tls=no_tls_from_remote :method=GET :authority=a2716861231d74a4e93dcc828d34d01a-531477736.eu-west-1.elb.amazonaws.com :path=/parts/body/body.svg
req id=3:1 proxy=in  src=10.0.3.26:52356 dst=10.0.2.55:9000 tls=true :method=GET :authority=goldie-body:9007 :path=/images/body.svg
req id=3:5 proxy=out src=10.0.3.26:46142 dst=10.0.2.55:9000 tls=true :method=GET :authority=goldie-body:9007 :path=/images/body.svg
rsp id=3:1 proxy=in  src=10.0.3.26:52356 dst=10.0.2.55:9000 tls=true :status=200 latency=654µs
rsp id=3:5 proxy=out src=10.0.3.26:46142 dst=10.0.2.55:9000 tls=true :status=200 latency=1615µs
end id=3:1 proxy=in  src=10.0.3.26:52356 dst=10.0.2.55:9000 tls=true duration=412µs response-length=15492B
end id=3:5 proxy=out src=10.0.3.26:46142 dst=10.0.2.55:9000 tls=true duration=335µs response-length=15492B
rsp id=3:4 proxy=in  src=10.0.3.94:65513 dst=10.0.3.26:9000 tls=no_tls_from_remote :status=200 latency=2774µs
end id=3:4 proxy=in  src=10.0.3.94:65513 dst=10.0.3.26:9000 tls=no_tls_from_remote duration=244µs response-length=15492B
req id=3:6 proxy=in  src=10.0.3.94:65513 dst=10.0.3.26:9000 tls=no_tls_from_remote :method=GET :authority=a2716861231d74a4e93dcc828d34d01a-531477736.eu-west-1.elb.amazonaws.com :path=/
rsp id=3:6 proxy=in  src=10.0.3.94:65513 dst=10.0.3.26:9000 tls=no_tls_from_remote :status=200 latency=665µs
end id=3:6 proxy=in  src=10.0.3.94:65513 dst=10.0.3.26:9000 tls=no_tls_from_remote duration=65µs response-length=564B
req id=3:7 proxy=in  src=10.0.3.94:65513 dst=10.0.3.26:9000 tls=no_tls_from_remote :method=GET :authority=a2716861231d74a4e93dcc828d34d01a-531477736.eu-west-1.elb.amazonaws.com :path=/parts/body/body.svg
req id=3:8 proxy=out src=10.0.3.26:46142 dst=10.0.2.55:9000 tls=true :method=GET :authority=goldie-body:9007 :path=/images/body.svg
req id=3:2 proxy=in  src=10.0.3.26:52356 dst=10.0.2.55:9000 tls=true :method=GET :authority=goldie-body:9007 :path=/images/body.svg
rsp id=3:2 proxy=in  src=10.0.3.26:52356 dst=10.0.2.55:9000 tls=true :status=200 latency=3809µs
end id=3:2 proxy=in  src=10.0.3.26:52356 dst=10.0.2.55:9000 tls=true duration=292µs response-length=15492B
rsp id=3:8 proxy=out src=10.0.3.26:46142 dst=10.0.2.55:9000 tls=true :status=200 latency=4808µs
end id=3:8 proxy=out src=10.0.3.26:46142 dst=10.0.2.55:9000 tls=true duration=283µs response-length=15492B
rsp id=3:7 proxy=in  src=10.0.3.94:65513 dst=10.0.3.26:9000 tls=no_tls_from_remote :status=200 latency=5975µs
end id=3:7 proxy=in  src=10.0.3.94:65513 dst=10.0.3.26:9000 tls=no_tls_from_remote duration=122µs response-length=15492B
```

Générer du trafic en se connectant sur le load balancer associé et vérifier que certaines routes sont bien protégées en TLS.

Pourquoi certaines routes ne sont-elles pas en TLS ?

Pour de plus amples détails : [https://linkerd.io/2.12/tasks/validating-your-traffic/](https://linkerd.io/2.12/tasks/validating-your-traffic/)

## Restreindre les accès à nos services

Nous pouvons sécuriser les accès à nos services. Dans notre exemple, nous voulons protéger le service goldie-body qui ne doit être accessible que par notre service prinicpal.

### Création d’une nouvelle ressource : le Server

Le server est une ressource spécifique à Linkerd qui décrit les ports spécifiques à nos applications. Une fois que nous aurons déclarés notre Server, seuls les clients autorisés pourront accéder à notre ressource.

Appliquer la définition de notre server goldie-body :

```bash
❯ kubectl apply -n $NAMESPACE -f - <<EOF
---
apiVersion: policy.linkerd.io/v1beta1
kind: Server
metadata:
  name: goldie-body-http
  labels:
    app.kubernetes.io/instance: red-body
    kubernetes.io/instance: body-server
spec:
  podSelector:
    matchLabels:
      app.kubernetes.io/name: little-red-riding-hood-goldie-body
  port: http
  proxyProtocol: HTTP/1
EOF
```

Générer du trafic et visualiser la page de notre goldie. Son image ne s’affiche plus vu que nous n’avons pas autorisé explicitement le flux.

```bash
❯ linkerd viz authz -n $NAMESPACE deploy/little-red-riding-hood-goldie-body
ROUTE    SERVER                       AUTHORIZATION                UNAUTHORIZED  SUCCESS     RPS  LATENCY_P50  LATENCY_P95  LATENCY_P99
default  default:all-unauthenticated  default/all-unauthenticated        0.0rps  100.00%  0.1rps          1ms          1ms          1ms
probe    default:all-unauthenticated  default/probe                      0.0rps  100.00%  0.2rps          1ms          1ms          1ms
default  goldie-body-http                                                0.2rps    0.00%  0.0rps          0ms          0ms          0ms
probe    goldie-body-http             default/probe                      0.0rps  100.00%  0.2rps          1ms          1ms          1ms
```

La route goldie-body-http par défaut n’est plus autorisée.

Nous pouvons autoriser l’accès à notre route uniquement pour les déploiements associés à notre service account. Appliquer la définition suivante:

```bash
kubectl apply -n $NAMESPACE -f - <<EOF
---
apiVersion: policy.linkerd.io/v1beta1
kind: ServerAuthorization
metadata:
  name: goldie-body-http
  labels:
    app.kubernetes.io/instance: red-body
    kubernetes.io/instance: body-server
spec:
  server:
    name: goldie-body-http
  # The voting service only allows requests from the web service.
  client:
    meshTLS:
      serviceAccounts:
        - name: red-little-red-riding-hood-goldie-main
EOF
```

Accédez de nouveau à notre page web, l’image de notre goldie est revenu. Lancer un conteneur supplémentaire qui n’a pas le service account spécifié pour vérifier si la connexion échoue avec un code d’erreur 403

```bash
❯ kubectl run debug --rm -it --image=busybox --restart=Never --command -- wget goldie-body.ddh.svc.cluster.local:9007/images/body.svg
Connecting to goldie-body.ddh.svc.cluster.local:9007 (172.20.193.27:9007)
wget: server returned error: HTTP/1.1 403 Forbidden
pod "debug" deleted
pod default/debug terminated (Error)
```

Pour aller plus loin, nous pouvons aussi refuser toutes les connexions à nos services si aucun server n’est défini. Nous pouvons aussi définir des politiques sur des routes spécifiques pour ajouter automatiquement un timeout, un circuit breaker etc. Pour plus d’infos aller sur la page [https://linkerd.io/2.12/tasks/configuring-per-route-policy/](https://linkerd.io/2.12/tasks/configuring-per-route-policy/)
## Back

[Next Step](../)