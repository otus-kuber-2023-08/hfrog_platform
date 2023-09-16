# Выполнено ДЗ №1

 - [*] Основное ДЗ
 - [*] Задание со *

## В процессе сделано:
 - на macbook установлены kubectl, docker и minikube
 ```$ kubectl cluster-info
Kubernetes control plane is running at https://127.0.0.1:50143
CoreDNS is running at https://127.0.0.1:50143/api/v1/namespaces/kube-system/services/kube-dns:dns/proxy
```

 - установлен dashboard как дополнение к minikube, ознакомился с его интерфейсом и возможностями
 ```$ minikube addons enable dashboard```

 - установлен k9s, ознакомился с его интерфейсом и возможностями
 ```$ brew install derailed/k9s/k9s```

 - проверен перезапуск подов в namespace kube-system. Перезапуск обеспечивается разными механизмами, которые можно посмотреть командой kubectl describe, например
 ```$ kubectl describe pods coredns-5d78c9869d-jjd7s -n kube-system | grep ^Controlled
Controlled By:  ReplicaSet/coredns-5d78c9869d
$ kubectl describe ReplicaSet/coredns-5d78c9869d -n kube-system | grep ^Controlled
Controlled By:  Deployment/coredns```
В данном случае pod управляется ReplicaSet'ом, который в свою очередь был создан Deployment'ом.
По аналогии узнаём, что kube-proxy управляется DaemonSet/kube-proxy, metrics-server-7746886d4f-bgzzv управляется Deployment/metrics-server,
storage-provisioner ничем не управляется и не перезапускается. Чтобы его запустить снова, нужно выполнить ```$ minikube addons enable storage-provisioner```.
Поды etcd-minikube, kube-apiserver-minikube, kube-controller-manager-minikube, kube-scheduler-minikube управляются напрямую миникубом: Controlled By:  Node/minikube.
```
kube-system   coredns-5d78c9869d-jjd7s           1/1     Running   0          79m
Controlled By:  ReplicaSet/coredns-5d78c9869d -> Controlled By:  Deployment/coredns

kube-system   etcd-minikube                      1/1     Running   1          79m
Controlled By:  Node/minikube

kube-system   kube-apiserver-minikube            1/1     Running   1          79m
Controlled By:  Node/minikube

kube-system   kube-controller-manager-minikube   1/1     Running   1          79m
Controlled By:  Node/minikube

kube-system   kube-proxy-j4zmr                   1/1     Running   0          79m
Controlled By:  DaemonSet/kube-proxy

kube-system   kube-scheduler-minikube            1/1     Running   1          79m
Controlled By:  Node/minikube

kube-system   metrics-server-7746886d4f-bgzzv    1/1     Running   0          79m
ReplicaSet/metrics-server-7746886d4f -> Deployment/metrics-server
```

 - проверено, что кластер находится в рабочем состоянии
```$ kubectl get componentstatuses
Warning: v1 ComponentStatus is deprecated in v1.19+
NAME                 STATUS    MESSAGE   ERROR
controller-manager   Healthy   ok
scheduler            Healthy   ok
etcd-0               Healthy
```

 - написано приложение на node.js, отдающее файлы из директории
 - создан Dockerfile по заданным требованиям
 - собран образ и выложен на Docker Hub как hfrog/app:2
 - написан манифест web-pod.yaml с init-контейнером
 - приложение успешно запущено, к нему получен доступ через ```kubectl port-forward``` а также через kube-forwarder
 - собран образ hipstershop frontend и выложен на Docker Hub как hfrog/hipster-frontend:2
 - образ запущен через ```kubectl run```

## Задание со *
 - диагностирована причина ошибки, точнее ошибок, не хватало переменных среды. После нескольких итераций добавления переменных приложение заработало.
 ```$ kubectl get pods
NAME       READY   STATUS    RESTARTS   AGE
frontend   1/1     Running   0          36m
web        1/1     Running   0          56m
```

# Выполнено ДЗ №2

 - [*] Основное ДЗ
 - [*] Задание со *

## В процессе сделано:
 - на macbook установлен kind ```brew install kind```, создан файл kind-config.yaml и запущен кластер ```kind create cluster --config kind-config.yaml```:
```$ kubectl get nodes -o wide
NAME                 STATUS   ROLES           AGE   VERSION   INTERNAL-IP   EXTERNAL-IP   OS-IMAGE                         KERNEL-VERSION        CONTAINER-RUNTIME
kind-control-plane   Ready    control-plane   59m   v1.27.3   172.18.0.5    <none>        Debian GNU/Linux 11 (bullseye)   5.15.49-linuxkit-pr   containerd://1.7.1
kind-worker          Ready    <none>          58m   v1.27.3   172.18.0.2    <none>        Debian GNU/Linux 11 (bullseye)   5.15.49-linuxkit-pr   containerd://1.7.1
kind-worker2         Ready    <none>          58m   v1.27.3   172.18.0.4    <none>        Debian GNU/Linux 11 (bullseye)   5.15.49-linuxkit-pr   containerd://1.7.1
kind-worker3         Ready    <none>          58m   v1.27.3   172.18.0.3    <none>        Debian GNU/Linux 11 (bullseye)   5.15.49-linuxkit-pr   containerd://1.7.1
```

 - создан и применён файл frontend-replicaset.yaml, получена ошибка
```$ kubectl apply -f frontend-replicaset.yaml
The ReplicaSet "frontend" is invalid: 
* spec.selector: Required value
* spec.template.metadata.labels: Invalid value: map[string]string{"app":"frontend"}: `selector` does not match template `labels`
```
устранена добавлением секции в spec:
```
  selector:
    matchLabels:
      app: frontend
```
теперь контейнер запустился:
```$ kubectl get pods -l app=frontend
NAME             READY   STATUS    RESTARTS   AGE
frontend-s98n4   1/1     Running   0          81s
```

 - увеличено кол-во реплик в ReplicaSet frontend:
```$ kubectl scale replicaset frontend --replicas=3
replicaset.apps/frontend scaled
$ kubectl get rs
NAME       DESIRED   CURRENT   READY   AGE
frontend   3         3         3       20m
```

 - проверено, что поды восстанавливаются репликасетом после их удаления:
```$ kubectl delete pods -l app=frontend | kubectl get pods -l app=frontend -w
NAME             READY   STATUS    RESTARTS   AGE
frontend-5q485   1/1     Running   0          4m3s
frontend-hgr9n   1/1     Running   0          4m3s
frontend-s98n4   1/1     Running   0          7m15s
frontend-5q485   1/1     Terminating   0          4m3s
frontend-hgr9n   1/1     Terminating   0          4m3s
frontend-s98n4   1/1     Terminating   0          7m15s
frontend-x9qzz   0/1     Pending       0          0s
frontend-x9qzz   0/1     Pending       0          0s
frontend-fkghv   0/1     Pending       0          0s
frontend-x9qzz   0/1     ContainerCreating   0          0s
frontend-drv29   0/1     Pending             0          0s
frontend-fkghv   0/1     Pending             0          0s
frontend-drv29   0/1     Pending             0          1s
frontend-fkghv   0/1     ContainerCreating   0          1s
frontend-drv29   0/1     ContainerCreating   0          1s
frontend-5q485   0/1     Terminating         0          4m4s
frontend-s98n4   0/1     Terminating         0          7m17s
frontend-5q485   0/1     Terminating         0          4m5s
frontend-hgr9n   0/1     Terminating         0          4m5s
frontend-s98n4   0/1     Terminating         0          7m17s
frontend-s98n4   0/1     Terminating         0          7m17s
frontend-5q485   0/1     Terminating         0          4m5s
frontend-s98n4   0/1     Terminating         0          7m17s
frontend-5q485   0/1     Terminating         0          4m6s
frontend-fkghv   1/1     Running             0          3s
frontend-hgr9n   0/1     Terminating         0          4m6s
frontend-hgr9n   0/1     Terminating         0          4m6s
frontend-hgr9n   0/1     Terminating         0          4m6s
frontend-x9qzz   1/1     Running             0          3s
frontend-drv29   1/1     Running             0          4s
^C$ kubectl get pods
NAME             READY   STATUS    RESTARTS   AGE
frontend-drv29   1/1     Running   0          19s
frontend-fkghv   1/1     Running   0          19s
frontend-x9qzz   1/1     Running   0          19s
```

 - манифест применён снова, при этом кол-во реплик снова вернулось к 1:
```$ kubectl apply -f frontend-replicaset.yaml 
replicaset.apps/frontend configured
$ kubectl get pods
NAME             READY   STATUS    RESTARTS   AGE
frontend-fkghv   1/1     Running   0          2m38s
$ kubectl get rs
NAME       DESIRED   CURRENT   READY   AGE
frontend   1         1         1       24m
```

 - кол-во реплик в манифесте увеличено до 3 и манифест применён снова:
```$ kubectl apply -f frontend-replicaset.yaml 
replicaset.apps/frontend configured
$ kubectl get rs
NAME       DESIRED   CURRENT   READY   AGE
frontend   3         3         3       25m
$ kubectl get pods
NAME             READY   STATUS    RESTARTS   AGE
frontend-fkghv   1/1     Running   0          3m2s
frontend-gr52w   1/1     Running   0          6s
frontend-l2snk   1/1     Running   0          6s
```

 - манифест применён повторно, кол-во реплик вернулось на исходное значение, 1
 - кол-во реплик в манифесте увеличено до 3 и манифест применён вновь
 - к образу hfrog/hipster-frontend в Docker Hub добавлен тег v0.0.2, в манифесте изменена версия образа, манифест применён и запущено отслеживание изменений
```$ kubectl apply -f frontend-replicaset.yaml | kubectl get pods -l app=frontend -w
NAME             READY   STATUS    RESTARTS   AGE
frontend-fkghv   1/1     Running   0          20m
frontend-gr52w   1/1     Running   0          17m
frontend-l2snk   1/1     Running   0          17m
```
 - проверен образ, указанный в ReplicaSet frontend:
```$ kubectl get replicaset frontend -o=jsonpath='{.spec.template.spec.containers[0].image}' && echo
hfrog/hipster-frontend:v0.0.2
```

 - проверен образ в работающих подах:
```$ kubectl get pods -l app=frontend -o=jsonpath='{.items[0:3].spec.containers[0].image}' && echo
hfrog/hipster-frontend:2 hfrog/hipster-frontend:2 hfrog/hipster-frontend:2
```
это старый образ

 - удалены поды ReplicaSet:
```$ kubectl delete pods frontend-fkghv frontend-gr52w frontend-l2snk
pod "frontend-fkghv" deleted
pod "frontend-gr52w" deleted
pod "frontend-l2snk" deleted
$ kubectl get pods
NAME             READY   STATUS    RESTARTS   AGE
frontend-4w8zn   1/1     Running   0          81s
frontend-fz7lc   1/1     Running   0          81s
frontend-jhfcx   1/1     Running   0          76s
$ kubectl get pods -l app=frontend -o=jsonpath='{.items[0:3].spec.containers[0].image}' && echo
hfrog/hipster-frontend:v0.0.2 hfrog/hipster-frontend:v0.0.2 hfrog/hipster-frontend:v0.0.2
```
это новый образ. ReplicaSet не предназначен для обновления развёрнутых приложений, он только следит за их кол-вом. Для обновления следует использовать Deployment.
Из описания ReplicaSet (https://kubernetes.io/docs/concepts/workloads/controllers/replicaset/): However, it will not make any effort to make existing Pods match a new, different pod template. To update Pods to a new spec in a controlled way, use a Deployment, as ReplicaSets do not support a rolling update directly.

 - собран образ из Dockerfile в директории microservices-demo/src/paymentservice
 - образ помечен тегами hfrog/hipster-frontend:v0.0.1 и hfrog/hipster-frontend:v0.0.2 и залит на Docker Hub
 - создан манифест paymentservice-replicaset.yaml, запускающий три пода v0.0.1. Для устранения ошибок запуска добавлены переменные среды
```
        env:
        - name: PORT
          value: "50051"
        - name: DISABLE_PROFILER
          value: "1"
```

 - создан и применён манифест с Deployment:
```$ kubectl apply -f paymentservice-deployment.yaml
deployment.apps/payment created
$ kubectl get deploy
NAME      READY   UP-TO-DATE   AVAILABLE   AGE
payment   3/3     3            3           3s
$ kubectl get rs
NAME                DESIRED   CURRENT   READY   AGE
payment-d9cf45677   3         3         3       5s
$ kubectl get pods
NAME                      READY   STATUS    RESTARTS   AGE
payment-d9cf45677-6m9w2   1/1     Running   0          8s
payment-d9cf45677-6vfdx   1/1     Running   0          8s
payment-d9cf45677-zbl2h   1/1     Running   0          8s
```

 - в манифесте изменён тег v0.0.1 на v0.0.2, манифест применён и запущен мониторинг состояния подов:
```$ kubectl apply -f paymentservice-deployment.yaml | kubectl get pods -l app=paymentservice -w
NAME                      READY   STATUS    RESTARTS   AGE
payment-d9cf45677-6m9w2   1/1     Running   0          2m44s
payment-d9cf45677-6vfdx   1/1     Running   0          2m44s
payment-d9cf45677-zbl2h   1/1     Running   0          2m44s
payment-66d979cc46-p24bs   0/1     Pending   0          0s
payment-66d979cc46-p24bs   0/1     Pending   0          0s
payment-66d979cc46-p24bs   0/1     ContainerCreating   0          0s
payment-66d979cc46-p24bs   1/1     Running             0          3s
payment-d9cf45677-zbl2h    1/1     Terminating         0          2m47s
payment-66d979cc46-8wdhf   0/1     Pending             0          0s
payment-66d979cc46-8wdhf   0/1     Pending             0          0s
payment-66d979cc46-8wdhf   0/1     ContainerCreating   0          0s
payment-66d979cc46-8wdhf   1/1     Running             0          2s
payment-d9cf45677-6m9w2    1/1     Terminating         0          2m49s
payment-66d979cc46-4vj2m   0/1     Pending             0          0s
payment-66d979cc46-4vj2m   0/1     Pending             0          0s
payment-66d979cc46-4vj2m   0/1     ContainerCreating   0          0s
payment-66d979cc46-4vj2m   1/1     Running             0          2s
payment-d9cf45677-6vfdx    1/1     Terminating         0          2m51s
```
Видно, что в отличие от ReplicaSet поды рестартуют, причём по одному, и сначала создаётся новый под, потом удаляется один из старых

 - убедимся, что поды используют образ v0.0.2:
```$ kubectl get pods -l app=paymentservice -o=jsonpath='{.items[0:3].spec.containers[0].image}' && echo
hfrog/hipster-payment:v0.0.2 hfrog/hipster-payment:v0.0.2 hfrog/hipster-payment:v0.0.2
```

 - убедимся, что создано два ReplicaSet, один старый с версией образа v0.0.1, другой новый с версией образа v0.0.2; также посмотрим rollout status и history и расширенную информацию по Deployment:
```$ kubectl get rs
NAME                 DESIRED   CURRENT   READY   AGE
payment-66d979cc46   3         3         3       3m45s
payment-d9cf45677    0         0         0       6m29s
$ kubectl get replicaset payment-d9cf45677 -o=jsonpath='{.spec.template.spec.containers[0].image}' && echo
hfrog/hipster-payment:v0.0.1
$ kubectl get replicaset payment-66d979cc46 -o=jsonpath='{.spec.template.spec.containers[0].image}' && echo
hfrog/hipster-payment:v0.0.2
$ kubectl rollout status deploy payment
deployment "payment" successfully rolled out
$ kubectl rollout history deploy payment
deployment.apps/payment 
REVISION  CHANGE-CAUSE
1         <none>
2         <none>
$ kubectl get deploy -o wide
NAME      READY   UP-TO-DATE   AVAILABLE   AGE   CONTAINERS   IMAGES                         SELECTOR
payment   3/3     3            3           12m   server       hfrog/hipster-payment:v0.0.2   app=paymentservice
```

- произведём откат на версию v0.0.1 и посмотрим rollout status и history:
```$ kubectl rollout undo deployment payment --to-revision=1 | kubectl get rs -l app=paymentservice -w
NAME                 DESIRED   CURRENT   READY   AGE
payment-66d979cc46   3         3         3       12m
payment-d9cf45677    0         0         0       15m
payment-d9cf45677    0         0         0       15m
payment-d9cf45677    1         0         0       15m
payment-d9cf45677    1         0         0       15m
payment-d9cf45677    1         1         0       15m
payment-d9cf45677    1         1         1       15m
payment-66d979cc46   2         3         3       12m
payment-d9cf45677    2         1         1       15m
payment-66d979cc46   2         3         3       12m
payment-66d979cc46   2         2         2       12m
payment-d9cf45677    2         1         1       15m
payment-d9cf45677    2         2         1       15m
payment-d9cf45677    2         2         2       15m
payment-66d979cc46   1         2         2       12m
payment-d9cf45677    3         2         2       15m
payment-66d979cc46   1         2         2       12m
payment-d9cf45677    3         2         2       15m
payment-66d979cc46   1         1         1       12m
payment-d9cf45677    3         3         2       15m
payment-d9cf45677    3         3         3       15m
payment-66d979cc46   0         1         1       12m
payment-66d979cc46   0         1         1       12m
payment-66d979cc46   0         0         0       12m
$ kubectl get deploy -o wide
NAME      READY   UP-TO-DATE   AVAILABLE   AGE   CONTAINERS   IMAGES                         SELECTOR
payment   3/3     3            3           15m   server       hfrog/hipster-payment:v0.0.1   app=paymentservice
$ kubectl rollout status deploy payment
deployment "payment" successfully rolled out
$ kubectl rollout history deploy payment
deployment.apps/payment 
REVISION  CHANGE-CAUSE
2         <none>
3         <none>
```

## Задание со *
 - написан манифест, реализующий аналог blue-green деплоя, проверим его:
```$ kubectl rollout undo deploy payment --to-revision=1 | kubectl get pods -l app=paymentservice -w
NAME                       READY   STATUS    RESTARTS   AGE
payment-66d979cc46-6nqhg   1/1     Running   0          37s
payment-66d979cc46-nthxk   1/1     Running   0          37s
payment-66d979cc46-w2q5z   1/1     Running   0          37s
payment-d9cf45677-wfpkf    0/1     Pending   0          0s
payment-d9cf45677-4cppk    0/1     Pending   0          0s
payment-d9cf45677-mg589    0/1     Pending   0          0s
payment-d9cf45677-wfpkf    0/1     Pending   0          0s
payment-d9cf45677-mg589    0/1     Pending   0          0s
payment-d9cf45677-4cppk    0/1     Pending   0          0s
payment-d9cf45677-wfpkf    0/1     ContainerCreating   0          0s
payment-d9cf45677-4cppk    0/1     ContainerCreating   0          0s
payment-d9cf45677-mg589    0/1     ContainerCreating   0          0s
payment-d9cf45677-wfpkf    1/1     Running             0          2s
payment-66d979cc46-nthxk   1/1     Terminating         0          39s
payment-d9cf45677-mg589    1/1     Running             0          2s
payment-d9cf45677-4cppk    1/1     Running             0          3s
payment-66d979cc46-w2q5z   1/1     Terminating         0          40s
payment-66d979cc46-6nqhg   1/1     Terminating         0          40s
```
Видно, что сначала создаётся новых пода, и после того как они перейдут в состояние Running, удаляются старые поды

 - написан манифест, реализующий reverse rolling update, проверим его:
```$ kubectl rollout undo deploy payment --to-revision=2 | kubectl get pods -l app=paymentservice -w
NAME                       READY   STATUS    RESTARTS   AGE
payment-66d979cc46-f2mmd   1/1     Running   0          40s
payment-66d979cc46-ts8bc   1/1     Running   0          41s
payment-66d979cc46-zgf4q   1/1     Running   0          38s
payment-66d979cc46-f2mmd   1/1     Terminating   0          40s
payment-d9cf45677-rsqsg    0/1     Pending       0          0s
payment-d9cf45677-rsqsg    0/1     Pending       0          0s
payment-d9cf45677-rsqsg    0/1     ContainerCreating   0          0s
payment-d9cf45677-rsqsg    1/1     Running             0          1s
payment-66d979cc46-ts8bc   1/1     Terminating         0          42s
payment-d9cf45677-4znnj    0/1     Pending             0          0s
payment-d9cf45677-4znnj    0/1     Pending             0          0s
payment-d9cf45677-4znnj    0/1     ContainerCreating   0          0s
payment-d9cf45677-4znnj    1/1     Running             0          1s
payment-66d979cc46-zgf4q   1/1     Terminating         0          40s
payment-d9cf45677-6g5wg    0/1     Pending             0          0s
payment-d9cf45677-6g5wg    0/1     Pending             0          0s
payment-d9cf45677-6g5wg    0/1     ContainerCreating   0          0s
payment-d9cf45677-6g5wg    1/1     Running             0          1s
payment-66d979cc46-f2mmd   0/1     Terminating         0          70s
payment-66d979cc46-f2mmd   0/1     Terminating         0          71s
payment-66d979cc46-f2mmd   0/1     Terminating         0          71s
payment-66d979cc46-f2mmd   0/1     Terminating         0          71s
payment-66d979cc46-ts8bc   0/1     Terminating         0          72s
payment-66d979cc46-ts8bc   0/1     Terminating         0          72s
payment-66d979cc46-ts8bc   0/1     Terminating         0          72s
payment-66d979cc46-ts8bc   0/1     Terminating         0          72s
payment-66d979cc46-zgf4q   0/1     Terminating         0          70s
payment-66d979cc46-zgf4q   0/1     Terminating         0          71s
payment-66d979cc46-zgf4q   0/1     Terminating         0          71s
payment-66d979cc46-zgf4q   0/1     Terminating         0          71s
```
Видно, что поды пересоздаются по одному, причём сначала удаляется старый и потом стартует новый.

 - создан манифест frontend-deployment.yaml с readinessProbe, поды работают:
```$ kubectl apply -f frontend-deployment.yaml 
deployment.apps/frontend created
$ kubectl get deploy -o wide
NAME       READY   UP-TO-DATE   AVAILABLE   AGE     CONTAINERS   IMAGES                          SELECTOR
frontend   3/3     3            3           9m41s   server       hfrog/hipster-frontend:v0.0.1   app=frontend
$ kubectl get pods
NAME                       READY   STATUS    RESTARTS   AGE
frontend-97cf5dff9-59j44   1/1     Running   0          9m45s
frontend-97cf5dff9-qwc45   1/1     Running   0          9m45s
frontend-97cf5dff9-xfwlc   1/1     Running   0          9m45s
```

 - сымитирован отказ readynessProbe:
```$ kubectl get deploy -o wide
NAME       READY   UP-TO-DATE   AVAILABLE   AGE   CONTAINERS   IMAGES                          SELECTOR
frontend   3/3     1            3           11m   server       hfrog/hipster-frontend:v0.0.2   app=frontend
$ kubectl get pods
NAME                       READY   STATUS    RESTARTS   AGE
frontend-97cf5dff9-59j44   1/1     Running   0          11m
frontend-97cf5dff9-qwc45   1/1     Running   0          11m
frontend-97cf5dff9-xfwlc   1/1     Running   0          11m
frontend-b797d5c9b-bt8np   0/1     Running   0          16s
$ kubectl describe pod frontend-b797d5c9b-bt8np | tail
Tolerations:                 node.kubernetes.io/not-ready:NoExecute op=Exists for 300s
                             node.kubernetes.io/unreachable:NoExecute op=Exists for 300s
Events:
  Type     Reason     Age               From               Message
  ----     ------     ----              ----               -------
  Normal   Scheduled  36s               default-scheduler  Successfully assigned default/frontend-b797d5c9b-bt8np to kind-worker
  Normal   Pulled     36s               kubelet            Container image "hfrog/hipster-frontend:v0.0.2" already present on machine
  Normal   Created    36s               kubelet            Created container server
  Normal   Started    36s               kubelet            Started container server
  Warning  Unhealthy  6s (x3 over 26s)  kubelet            Readiness probe failed: HTTP probe failed with statuscode: 404
$ kubectl rollout status deployment frontend
Waiting for deployment "frontend" rollout to finish: 1 out of 3 new replicas have been updated...
```
Видно, что новый под не стартует успешно, и Deployment остановил обновление

 - найден и установлен манифест DaemonSet с Node Exporter https://raw.githubusercontent.com/bibinwilson/kubernetes-node-exporter/main/daemonset.yaml, проверим что метрики отдаются:
```$ kubectl create ns monitoring
namespace/monitoring created
$ kubectl apply -f node-exporter-daemonset.yaml
daemonset.apps/node-exporter created
$ kubectl get all -n monitoring
NAME                      READY   STATUS    RESTARTS   AGE
pod/node-exporter-77dtj   1/1     Running   0          39s
pod/node-exporter-bmlfw   1/1     Running   0          39s
pod/node-exporter-flg5c   1/1     Running   0          39s

NAME                           DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR   AGE
daemonset.apps/node-exporter   3         3         3       3            3           <none>          39s
$ kubectl port-forward pod/node-exporter-77dtj -n monitoring 9100:9100
Forwarding from 127.0.0.1:9100 -> 9100
Forwarding from [::1]:9100 -> 9100
[в другом окне]
$ curl -s localhost:9100/metrics | head
# HELP go_gc_duration_seconds A summary of the pause duration of garbage collection cycles.
# TYPE go_gc_duration_seconds summary
go_gc_duration_seconds{quantile="0"} 2.5071e-05
go_gc_duration_seconds{quantile="0.25"} 2.5071e-05
go_gc_duration_seconds{quantile="0.5"} 4.3052e-05
go_gc_duration_seconds{quantile="0.75"} 5.7574e-05
go_gc_duration_seconds{quantile="1"} 5.7574e-05
go_gc_duration_seconds_sum 0.000125697
go_gc_duration_seconds_count 3
# HELP go_goroutines Number of goroutines that currently exist.
```

 - манифест изменён так, чтобы поды запускались и на мастер-узлах, проверка:
```$ kubectl apply -f node-exporter-daemonset.yaml
daemonset.apps/node-exporter configured
$ kubectl get all -n monitoring -o wide
NAME                      READY   STATUS    RESTARTS   AGE   IP            NODE                 NOMINATED NODE   READINESS GATES
pod/node-exporter-8v76n   1/1     Running   0          8s    10.244.0.6    kind-control-plane   <none>           <none>
pod/node-exporter-cgqxb   1/1     Running   0          15s   10.244.3.26   kind-worker          <none>           <none>
pod/node-exporter-p2mzb   1/1     Running   0          11s   10.244.1.25   kind-worker3         <none>           <none>
pod/node-exporter-rr5mf   1/1     Running   0          18s   10.244.2.25   kind-worker2         <none>           <none>

NAME                           DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR   AGE   CONTAINERS      IMAGES               SELECTOR
daemonset.apps/node-exporter   4         4         4       4            4           <none>          14m   node-exporter   prom/node-exporter   app.kubernetes.io/component=exporter,app.kubernetes.io/name=node-exporter
$ kubectl port-forward pod/node-exporter-8v76n -n monitoring 9100:9100
Forwarding from 127.0.0.1:9100 -> 9100
Forwarding from [::1]:9100 -> 9100
[в другом окне]
$ curl -s localhost:9100/metrics | head
# HELP go_gc_duration_seconds A summary of the pause duration of garbage collection cycles.
# TYPE go_gc_duration_seconds summary
go_gc_duration_seconds{quantile="0"} 0
go_gc_duration_seconds{quantile="0.25"} 0
go_gc_duration_seconds{quantile="0.5"} 0
go_gc_duration_seconds{quantile="0.75"} 0
go_gc_duration_seconds{quantile="1"} 0
go_gc_duration_seconds_sum 0
go_gc_duration_seconds_count 0
# HELP go_goroutines Number of goroutines that currently exist.
```

