# Выполнено ДЗ №1

 - [*] Основное ДЗ
 - [*] Задание со *

## В процессе сделано:

 - на macbook установлены kubectl, docker и minikube
```
$ kubectl cluster-info
Kubernetes control plane is running at https://127.0.0.1:50143
CoreDNS is running at https://127.0.0.1:50143/api/v1/namespaces/kube-system/services/kube-dns:dns/proxy
```

 - установлен dashboard как дополнение к minikube, ознакомился с его интерфейсом и возможностями
 `$ minikube addons enable dashboard`

 - установлен k9s, ознакомился с его интерфейсом и возможностями
 `$ brew install derailed/k9s/k9s`

 - проверен перезапуск подов в namespace kube-system. Перезапуск обеспечивается разными механизмами, которые можно посмотреть командой kubectl describe, например
```
$ kubectl describe pods coredns-5d78c9869d-jjd7s -n kube-system | grep ^Controlled
Controlled By:  ReplicaSet/coredns-5d78c9869d
$ kubectl describe ReplicaSet/coredns-5d78c9869d -n kube-system | grep ^Controlled
Controlled By:  Deployment/coredns
```
В данном случае pod управляется ReplicaSet'ом, который в свою очередь был создан Deployment'ом.
По аналогии узнаём, что kube-proxy управляется DaemonSet/kube-proxy, metrics-server-7746886d4f-bgzzv управляется Deployment/metrics-server,
storage-provisioner ничем не управляется и не перезапускается. Чтобы его запустить снова, нужно выполнить `$ minikube addons enable storage-provisioner`.
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
```
$ kubectl get componentstatuses
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
 - приложение успешно запущено, к нему получен доступ через `kubectl port-forward` а также через kube-forwarder
 - собран образ hipstershop frontend и выложен на Docker Hub как hfrog/hipster-frontend:2
 - образ запущен через `kubectl run`

## Задание со *

 - диагностирована причина ошибки, точнее ошибок, не хватало переменных среды. После нескольких итераций добавления переменных приложение заработало.
```
$ kubectl get pods
NAME       READY   STATUS    RESTARTS   AGE
frontend   1/1     Running   0          36m
web        1/1     Running   0          56m
```

# Выполнено ДЗ №2

 - [*] Основное ДЗ
 - [*] Задание со *
 - [*] Задание с **

## В процессе сделано:

 - на macbook установлен kind `brew install kind`, создан файл kind-config.yaml и запущен кластер `kind create cluster --config kind-config.yaml`:
```
$ kubectl get nodes -o wide
NAME                 STATUS   ROLES           AGE   VERSION   INTERNAL-IP   EXTERNAL-IP   OS-IMAGE                         KERNEL-VERSION        CONTAINER-RUNTIME
kind-control-plane   Ready    control-plane   59m   v1.27.3   172.18.0.5    <none>        Debian GNU/Linux 11 (bullseye)   5.15.49-linuxkit-pr   containerd://1.7.1
kind-worker          Ready    <none>          58m   v1.27.3   172.18.0.2    <none>        Debian GNU/Linux 11 (bullseye)   5.15.49-linuxkit-pr   containerd://1.7.1
kind-worker2         Ready    <none>          58m   v1.27.3   172.18.0.4    <none>        Debian GNU/Linux 11 (bullseye)   5.15.49-linuxkit-pr   containerd://1.7.1
kind-worker3         Ready    <none>          58m   v1.27.3   172.18.0.3    <none>        Debian GNU/Linux 11 (bullseye)   5.15.49-linuxkit-pr   containerd://1.7.1
```

 - создан и применён файл frontend-replicaset.yaml, получена ошибка
```
$ kubectl apply -f frontend-replicaset.yaml
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
```
$ kubectl get pods -l app=frontend
NAME             READY   STATUS    RESTARTS   AGE
frontend-s98n4   1/1     Running   0          81s
```

 - увеличено кол-во реплик в ReplicaSet frontend:
```
$ kubectl scale replicaset frontend --replicas=3
replicaset.apps/frontend scaled
$ kubectl get rs
NAME       DESIRED   CURRENT   READY   AGE
frontend   3         3         3       20m
```

 - проверено, что поды восстанавливаются репликасетом после их удаления:
```
$ kubectl delete pods -l app=frontend | kubectl get pods -l app=frontend -w
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
```
$ kubectl apply -f frontend-replicaset.yaml
replicaset.apps/frontend configured
$ kubectl get pods
NAME             READY   STATUS    RESTARTS   AGE
frontend-fkghv   1/1     Running   0          2m38s
$ kubectl get rs
NAME       DESIRED   CURRENT   READY   AGE
frontend   1         1         1       24m
```

 - кол-во реплик в манифесте увеличено до 3 и манифест применён снова:
```
$ kubectl apply -f frontend-replicaset.yaml
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
```
$ kubectl apply -f frontend-replicaset.yaml | kubectl get pods -l app=frontend -w
NAME             READY   STATUS    RESTARTS   AGE
frontend-fkghv   1/1     Running   0          20m
frontend-gr52w   1/1     Running   0          17m
frontend-l2snk   1/1     Running   0          17m
```
 - проверен образ, указанный в ReplicaSet frontend:
```
$ kubectl get replicaset frontend -o=jsonpath='{.spec.template.spec.containers[0].image}' && echo
hfrog/hipster-frontend:v0.0.2
```

 - проверен образ в работающих подах:
```
$ kubectl get pods -l app=frontend -o=jsonpath='{.items[0:3].spec.containers[0].image}' && echo
hfrog/hipster-frontend:2 hfrog/hipster-frontend:2 hfrog/hipster-frontend:2
```
это старый образ

 - удалены поды ReplicaSet:
```
$ kubectl delete pods frontend-fkghv frontend-gr52w frontend-l2snk
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
```
$ kubectl apply -f paymentservice-deployment.yaml
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
```
$ kubectl apply -f paymentservice-deployment.yaml | kubectl get pods -l app=paymentservice -w
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
```
$ kubectl get pods -l app=paymentservice -o=jsonpath='{.items[0:3].spec.containers[0].image}' && echo
hfrog/hipster-payment:v0.0.2 hfrog/hipster-payment:v0.0.2 hfrog/hipster-payment:v0.0.2
```

 - убедимся, что создано два ReplicaSet, один старый с версией образа v0.0.1, другой новый с версией образа v0.0.2; также посмотрим rollout status и history и расширенную информацию по Deployment:
```
$ kubectl get rs
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
```
$ kubectl rollout undo deployment payment --to-revision=1 | kubectl get rs -l app=paymentservice -w
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
```
$ kubectl rollout undo deploy payment --to-revision=1 | kubectl get pods -l app=paymentservice -w
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
```
$ kubectl rollout undo deploy payment --to-revision=2 | kubectl get pods -l app=paymentservice -w
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
```
$ kubectl apply -f frontend-deployment.yaml
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
```
$ kubectl get deploy -o wide
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
```
$ kubectl create ns monitoring
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

## Задание с **

 - манифест изменён так, чтобы поды запускались и на мастер-узлах, проверка:
```
$ kubectl apply -f node-exporter-daemonset.yaml
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

# Выполнено ДЗ №3

 - [*] Основное ДЗ
 - [*] Задание со *

## В процессе сделано:

 - установлен драйвер HyperKit для minikube
 - в web-pod.yaml добавлена readinessProbe, проверено, что под не проходит проверки:
```
$ kubectl apply -f web-pod.yaml
pod/web created
$ kubectl get pods -o wide
NAME   READY   STATUS    RESTARTS   AGE     IP           NODE       NOMINATED NODE   READINESS GATES
web    0/1     Running   0          8m57s   10.244.0.3   minikube   <none>           <none>
$ kubectl describe pod web | tail
  Normal   Scheduled  8m52s                   default-scheduler  Successfully assigned default/web to minikube
  Normal   Pulling    8m52s                   kubelet            Pulling image "busybox:1.31.0"
  Normal   Pulled     8m41s                   kubelet            Successfully pulled image "busybox:1.31.0" in 10.151595292s (10.151614417s including waiting)
  Normal   Created    8m41s                   kubelet            Created container init
  Normal   Started    8m41s                   kubelet            Started container init
  Normal   Pulling    8m40s                   kubelet            Pulling image "hfrog/app:2"
  Normal   Pulled     7m36s                   kubelet            Successfully pulled image "hfrog/app:2" in 1m3.06573033s (1m3.066921922s including waiting)
  Normal   Created    7m36s                   kubelet            Created container web
  Normal   Started    7m36s                   kubelet            Started container web
  Warning  Unhealthy  3m42s (x29 over 7m36s)  kubelet            Readiness probe failed: Get "http://10.244.0.3:80/index.html": dial tcp 10.244.0.3:80: connect: connection refused
$ kubectl describe pod web | grep -A 5 ^Conditions
Conditions:
  Type              Status
  Initialized       True
  Ready             False
  ContainersReady   False
  PodScheduled      True
```
 - добавим livenessProbe, ничего не изменилось:
```
$ grep -A 4 Probe web-pod.yaml
    readinessProbe:
      httpGet:
        path: /index.html
        port: 80
    livenessProbe:
      tcpSocket:
        port: 8000
    volumeMounts:
    - name: app
$ kubectl apply -f web-pod.yaml
pod/web created
$ kubectl get pods -o wide
NAME   READY   STATUS    RESTARTS   AGE   IP           NODE       NOMINATED NODE   READINESS GATES
web    0/1     Running   0          28s   10.244.0.6   minikube   <none>           <none>
$ kubectl describe pod web | tail -3
  Normal   Created    26s               kubelet            Created container web
  Normal   Started    26s               kubelet            Started container web
  Warning  Unhealthy  9s (x5 over 25s)  kubelet            Readiness probe failed: Get "http://10.244.0.6:80/index.html": dial tcp 10.244.0.6:80: connect: connection refused
```
 - Ответ на вопрос про бессмысленность livenessProbe посредством `sh -c 'ps aux | grep my_web_server_process'`:
   `my_web_server_process` говорит о том, что это основной процесс пода, а не какой-то вспомогательный, созданный после.
   Также учитываем, что livenessProbe предназначены для отслеживания ситуаций, когда под не может обслуживать запросы и требует рестарта.
   В таком случае указанная конструкция действительно не имеет смысла и её можно просто удалить. Если основной процесс завершится, kubernetes и так это обнаружит и перезапустит под.
   Стоит лишь отметить, что при поиске процессов указанным способом стоит добавлять ` | grep -v grep`, т.е. например
   `ps aux | grep my_web_server_process | grep -v grep`, чтобы убрать grep из поиска.
   Допускаю, что возможна ситуация, когда эта проверка имеет смысл, но это будет отход от канонов kubernetes. Система гибкая и позволяет создавать нестандартные настройки, но зачастую это неоправдано,
   ухудшает читаемость, диагностику и сопровождение кода.

 - написан и применён манифест Deployment web-приложения в файле web-deploy.yaml:
```
$ kubectl apply -f web-deploy.yaml
deployment.apps/web created
$ kubectl describe deploy web | grep -A 5 ^Conditions
Conditions:
  Type           Status  Reason
  ----           ------  ------
  Available      False   MinimumReplicasUnavailable
  Progressing    True    ReplicaSetUpdated
OldReplicaSets:  <none>
$ kubectl rollout status deploy web
Waiting for deployment "web" rollout to finish: 0 of 1 updated replicas are available...
$ kubectl get pods
NAME                   READY   STATUS    RESTARTS   AGE
web-6b847575b8-bxrnn   0/1     Running   0          4m14s
$ kubectl describe pod web-6b847575b8-bxrnn | tail -3
  Normal   Created    4m22s                  kubelet            Created container web
  Normal   Started    4m22s                  kubelet            Started container web
  Warning  Unhealthy  114s (x19 over 4m21s)  kubelet            Readiness probe failed: Get "http://10.244.0.9:80/index.html": dial tcp 10.244.0.9:80: connect: connection refused
```
Deployment не стартует из-за неуспеха проверки Readyness

- увеличим кол-во реплик до 3, поменяем порт в readinessProbe на 8000 и применим манифест снова:
```
$ kubectl rollout status deploy web
Waiting for deployment "web" rollout to finish: 2 out of 3 new replicas have been updated...
Waiting for deployment "web" rollout to finish: 2 out of 3 new replicas have been updated...
Waiting for deployment "web" rollout to finish: 2 out of 3 new replicas have been updated...
Waiting for deployment "web" rollout to finish: 1 old replicas are pending termination...
Waiting for deployment "web" rollout to finish: 1 old replicas are pending termination...
Waiting for deployment "web" rollout to finish: 1 old replicas are pending termination...
deployment "web" successfully rolled out
$ kubectl describe deploy web | grep -A 5 ^Conditions
Conditions:
  Type           Status  Reason
  ----           ------  ------
  Available      True    MinimumReplicasAvailable
  Progressing    True    NewReplicaSetAvailable
OldReplicaSets:  web-6b847575b8 (0/0 replicas created)
$ kubectl get pods
NAME                   READY   STATUS    RESTARTS   AGE
web-676c8fd944-b66h9   1/1     Running   0          110s
web-676c8fd944-rj7mr   1/1     Running   0          106s
web-676c8fd944-wnvvf   1/1     Running   0          116s
```
Все поды готовы, deployment работает

 - исследуем поведение стратегии обновления rollingUpdate при разных значениях maxSurge и maxUnavailable, используем для этого `kubectl get events --watch`:
   maxSurge: 100%, maxUnavailable: 0
```
2m39s       Normal   ScalingReplicaSet   deployment/web              Scaled up replica set web-676c8fd944 to 3 from 0
2m35s       Normal   ScalingReplicaSet   deployment/web              Scaled down replica set web-cc6cc849 to 2 from 3
2m34s       Normal   ScalingReplicaSet   deployment/web              Scaled down replica set web-cc6cc849 to 1 from 2
2m34s       Normal   ScalingReplicaSet   deployment/web              Scaled down replica set web-cc6cc849 to 0 from 1
```
Сначала создаются новые поды в кол-ве реплик, после чего по мере готовности новых подов старые поды удаляются

   maxSurge: 0, maxUnavailable: 0
```
The Deployment "web" is invalid: spec.strategy.rollingUpdate.maxUnavailable: Invalid value: intstr.IntOrString{Type:0, IntVal:0, StrVal:""}: may not be 0 when `maxSurge` is 0
```
Недопустимая комбинация значений. Дествительно, нельзя ни создавать новые поды, ни удалять старые.

   maxSurge: 100%, maxUnavailable: 100%
```
0s          Normal   ScalingReplicaSet   deployment/web              Scaled up replica set web-cc6cc849 to 3 from 0
0s          Normal   SuccessfulCreate    replicaset/web-cc6cc849     Created pod: web-cc6cc849-8s2db
0s          Normal   ScalingReplicaSet   deployment/web              Scaled down replica set web-676c8fd944 to 0 from 3
0s          Normal   Scheduled           pod/web-cc6cc849-8s2db      Successfully assigned default/web-cc6cc849-8s2db to minikube
0s          Normal   SuccessfulCreate    replicaset/web-cc6cc849     Created pod: web-cc6cc849-mp4b7
0s          Normal   Killing             pod/web-676c8fd944-ptm8p    Stopping container web
0s          Normal   Killing             pod/web-676c8fd944-wzgz8    Stopping container web
0s          Normal   SuccessfulCreate    replicaset/web-cc6cc849     Created pod: web-cc6cc849-bzsrv
0s          Normal   Scheduled           pod/web-cc6cc849-bzsrv      Successfully assigned default/web-cc6cc849-bzsrv to minikube
0s          Normal   Scheduled           pod/web-cc6cc849-mp4b7      Successfully assigned default/web-cc6cc849-mp4b7 to minikube
0s          Normal   SuccessfulDelete    replicaset/web-676c8fd944   Deleted pod: web-676c8fd944-ptm8p
0s          Normal   Killing             pod/web-676c8fd944-gd69l    Stopping container web
0s          Normal   SuccessfulDelete    replicaset/web-676c8fd944   Deleted pod: web-676c8fd944-wzgz8
0s          Normal   SuccessfulDelete    replicaset/web-676c8fd944   Deleted pod: web-676c8fd944-gd69l
0s          Warning   Unhealthy           pod/web-676c8fd944-gd69l    Readiness probe failed: Get "http://10.244.0.28:8000/index.html": dial tcp 10.244.0.28:8000: i/o timeout (Client.Timeout exceeded while awaiting headers)
0s          Warning   Unhealthy           pod/web-676c8fd944-ptm8p    Readiness probe failed: Get "http://10.244.0.29:8000/index.html": context deadline exceeded (Client.Timeout exceeded while awaiting headers)
0s          Normal    Pulled              pod/web-cc6cc849-mp4b7      Container image "busybox:1.31.0" already present on machine
0s          Normal    Created             pod/web-cc6cc849-mp4b7      Created container init
0s          Normal    Pulled              pod/web-cc6cc849-bzsrv      Container image "busybox:1.31.0" already present on machine
0s          Normal    Pulled              pod/web-cc6cc849-8s2db      Container image "busybox:1.31.0" already present on machine
0s          Normal    Created             pod/web-cc6cc849-bzsrv      Created container init
0s          Normal    Created             pod/web-cc6cc849-8s2db      Created container init
0s          Normal    Started             pod/web-cc6cc849-mp4b7      Started container init
0s          Normal    Started             pod/web-cc6cc849-bzsrv      Started container init
0s          Normal    Started             pod/web-cc6cc849-8s2db      Started container init
0s          Normal    Pulled              pod/web-cc6cc849-bzsrv      Container image "hfrog/app:v0.0.1" already present on machine
0s          Normal    Pulled              pod/web-cc6cc849-mp4b7      Container image "hfrog/app:v0.0.1" already present on machine
0s          Normal    Created             pod/web-cc6cc849-bzsrv      Created container web
0s          Normal    Pulled              pod/web-cc6cc849-8s2db      Container image "hfrog/app:v0.0.1" already present on machine
0s          Normal    Created             pod/web-cc6cc849-8s2db      Created container web
0s          Normal    Created             pod/web-cc6cc849-mp4b7      Created container web
0s          Normal    Started             pod/web-cc6cc849-bzsrv      Started container web
0s          Normal    Started             pod/web-cc6cc849-8s2db      Started container web
0s          Normal    Started             pod/web-cc6cc849-mp4b7      Started container web
```
В этом случае также создаются новые поды в кол-ве реплик, но старые поды удаляются не по мере готовности новых подов, а сразу же (maxUnavailable: 100%)

   maxSurge: 0, maxUnavailable: 100%
```
0s          Normal    ScalingReplicaSet   deployment/web              Scaled down replica set web-cc6cc849 to 0 from 3
0s          Normal    Killing             pod/web-cc6cc849-mp4b7      Stopping container web
0s          Normal    SuccessfulDelete    replicaset/web-cc6cc849     Deleted pod: web-cc6cc849-mp4b7
0s          Normal    Killing             pod/web-cc6cc849-8s2db      Stopping container web
0s          Normal    SuccessfulDelete    replicaset/web-cc6cc849     Deleted pod: web-cc6cc849-8s2db
0s          Normal    Killing             pod/web-cc6cc849-bzsrv      Stopping container web
0s          Normal    SuccessfulDelete    replicaset/web-cc6cc849     Deleted pod: web-cc6cc849-bzsrv
0s          Normal    ScalingReplicaSet   deployment/web              Scaled up replica set web-676c8fd944 to 3 from 0
0s          Normal    SuccessfulCreate    replicaset/web-676c8fd944   Created pod: web-676c8fd944-t6zvm
0s          Normal    Scheduled           pod/web-676c8fd944-t6zvm    Successfully assigned default/web-676c8fd944-t6zvm to minikube
0s          Normal    SuccessfulCreate    replicaset/web-676c8fd944   Created pod: web-676c8fd944-zv247
1s          Normal    Scheduled           pod/web-676c8fd944-zv247    Successfully assigned default/web-676c8fd944-zv247 to minikube
1s          Normal    SuccessfulCreate    replicaset/web-676c8fd944   Created pod: web-676c8fd944-g7jgb
1s          Normal    Scheduled           pod/web-676c8fd944-g7jgb    Successfully assigned default/web-676c8fd944-g7jgb to minikube
0s          Normal    Pulled              pod/web-676c8fd944-g7jgb    Container image "busybox:1.31.0" already present on machine
0s          Normal    Created             pod/web-676c8fd944-g7jgb    Created container init
0s          Normal    Started             pod/web-676c8fd944-g7jgb    Started container init
0s          Normal    Pulled              pod/web-676c8fd944-zv247    Container image "busybox:1.31.0" already present on machine
0s          Normal    Created             pod/web-676c8fd944-zv247    Created container init
0s          Normal    Pulled              pod/web-676c8fd944-t6zvm    Container image "busybox:1.31.0" already present on machine
0s          Normal    Created             pod/web-676c8fd944-t6zvm    Created container init
0s          Normal    Started             pod/web-676c8fd944-zv247    Started container init
0s          Normal    Started             pod/web-676c8fd944-t6zvm    Started container init
0s          Normal    Pulled              pod/web-676c8fd944-g7jgb    Container image "hfrog/app:2" already present on machine
0s          Normal    Created             pod/web-676c8fd944-g7jgb    Created container web
0s          Normal    Started             pod/web-676c8fd944-g7jgb    Started container web
0s          Normal    Pulled              pod/web-676c8fd944-zv247    Container image "hfrog/app:2" already present on machine
0s          Normal    Created             pod/web-676c8fd944-zv247    Created container web
0s          Normal    Pulled              pod/web-676c8fd944-t6zvm    Container image "hfrog/app:2" already present on machine
0s          Normal    Created             pod/web-676c8fd944-t6zvm    Created container web
0s          Normal    Started             pod/web-676c8fd944-zv247    Started container web
0s          Normal    Started             pod/web-676c8fd944-t6zvm    Started container web
```
В этом случае сначала удаляются все старые поды, после чего разом создаются новые в кол-ве реплик

Хочется отметить, что kubespy в режиме trace, т.е. например `kubespy trace deploy web`, позволяет следить за прогрессом обновления, но не даёт логов.

 - создан и применён файл `web-svc-cip.yaml` с манифестом сервиса, проверим его работоспособность и посмотрим на iptables:
```
$ kubectl apply -f web-svc-cip.yaml
service/web-svc-cip created
$ kubectl get svc
NAME          TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)   AGE
kubernetes    ClusterIP   10.96.0.1      <none>        443/TCP   14h
web-svc-cip   ClusterIP   10.108.65.32   <none>        80/TCP    5s
$ minikube ssh

            _         _ ( )           ( )
  ___ ___  (_)  ___  (_)| |/')  _   _ | |
/' _ ` _ `\| |/' _ `\| || , <  ( ) ( )| '_`\  /'__`\
| ( ) ( ) || || ( ) || || |\`\ | (_) || |_) )(  ___/
(_) (_) (_)(_)(_) (_)(_)(_) (_)`\___/'(_,__/'`\____)

$ curl -s http://10.108.65.32/index.html | head -5
<html>
<head/>
<body>
<!-- IMAGE BEGINS HERE -->
<font size="-3">
$ ping 10.108.65.32
PING 10.108.65.32 (10.108.65.32): 56 data bytes
^C
--- 10.108.65.32 ping statistics ---
4 packets transmitted, 0 packets received, 100% packet loss
$ arp -an | grep 10.108
$ ip addr show | grep 10.108
$ sudo iptables --list -nv -t nat | grep 10.108
   11   660 KUBE-SVC-6CZTMAROCN3AQODZ  tcp  --  *      *       0.0.0.0/0            10.108.65.32         /* default/web-svc-cip cluster IP */ tcp dpt:80
   11   660 KUBE-MARK-MASQ  tcp  --  *      *      !10.244.0.0/16        10.108.65.32         /* default/web-svc-cip cluster IP */ tcp dpt:80
```
Сервис доступен изнутри кластера по HTTP запросу на сервисный IP адрес, при этом на ICMP ответа нет, т.к. сервис реализован средствами iptables.

 - включен ipvs через редактирование configmap/kube-proxy и рестарт пода kube-proxy
 - удалены старые правила iptables:
```
$ iptables --list -nv -t nat
Chain PREROUTING (policy ACCEPT 0 packets, 0 bytes)
 pkts bytes target     prot opt in     out     source               destination
    7  1015 KUBE-SERVICES  all  --  *      *       0.0.0.0/0            0.0.0.0/0            /* kubernetes service portals */

Chain INPUT (policy ACCEPT 0 packets, 0 bytes)
 pkts bytes target     prot opt in     out     source               destination

Chain OUTPUT (policy ACCEPT 22 packets, 1320 bytes)
 pkts bytes target     prot opt in     out     source               destination
 1287 77948 KUBE-SERVICES  all  --  *      *       0.0.0.0/0            0.0.0.0/0            /* kubernetes service portals */

Chain POSTROUTING (policy ACCEPT 22 packets, 1320 bytes)
 pkts bytes target     prot opt in     out     source               destination
 1287 77948 KUBE-POSTROUTING  all  --  *      *       0.0.0.0/0            0.0.0.0/0            /* kubernetes postrouting rules */
    0     0 MASQUERADE  all  --  *      !docker0  172.17.0.0/16        0.0.0.0/0

Chain KUBE-KUBELET-CANARY (0 references)
 pkts bytes target     prot opt in     out     source               destination

Chain KUBE-LOAD-BALANCER (0 references)
 pkts bytes target     prot opt in     out     source               destination
    0     0 KUBE-MARK-MASQ  all  --  *      *       0.0.0.0/0            0.0.0.0/0

Chain KUBE-MARK-MASQ (2 references)
 pkts bytes target     prot opt in     out     source               destination
    0     0 MARK       all  --  *      *       0.0.0.0/0            0.0.0.0/0            MARK or 0x4000

Chain KUBE-NODE-PORT (1 references)
 pkts bytes target     prot opt in     out     source               destination

Chain KUBE-POSTROUTING (1 references)
 pkts bytes target     prot opt in     out     source               destination
    0     0 MASQUERADE  all  --  *      *       0.0.0.0/0            0.0.0.0/0            /* Kubernetes endpoints dst ip:port, source ip for solving hairpin purpose */ match-set KUBE-LOOP-BACK dst,dst,src
   22  1320 RETURN     all  --  *      *       0.0.0.0/0            0.0.0.0/0            mark match ! 0x4000/0x4000
    0     0 MARK       all  --  *      *       0.0.0.0/0            0.0.0.0/0            MARK xor 0x4000
    0     0 MASQUERADE  all  --  *      *       0.0.0.0/0            0.0.0.0/0            /* kubernetes service traffic requiring SNAT */ random-fully

Chain KUBE-SERVICES (2 references)
 pkts bytes target     prot opt in     out     source               destination
    4   240 RETURN     all  --  *      *       127.0.0.0/8          0.0.0.0/0
    0     0 KUBE-MARK-MASQ  all  --  *      *      !10.244.0.0/16        0.0.0.0/0            /* Kubernetes service cluster ip + port for masquerade purpose */ match-set KUBE-CLUSTER-IP dst,dst
   10   600 KUBE-NODE-PORT  all  --  *      *       0.0.0.0/0            0.0.0.0/0            ADDRTYPE match dst-type LOCAL
    0     0 ACCEPT     all  --  *      *       0.0.0.0/0            0.0.0.0/0            match-set KUBE-CLUSTER-IP dst,dst
```

 - для запуска ipvsadm я использовал образ `mariusv/ipvsadm` с Docker Hub, т.к. не хватало памяти на этапе `dnf install -y ipvsadm`:
```
$ docker run -it --rm --net=host --privileged mariusv/ipvsadm -l
IP Virtual Server version 1.2.1 (size=4096)
Prot LocalAddress:Port Scheduler Flags
  -> RemoteAddress:Port           Forward Weight ActiveConn InActConn
TCP  10.96.0.1:https rr
  -> control-plane.minikube.inter Masq    1      0          0
TCP  10.96.0.10:domain rr
  -> 10.244.0.41:domain           Masq    1      0          0
TCP  10.96.0.10:9153 rr
  -> 10.244.0.41:9153             Masq    1      0          0
TCP  10.108.65.32:http rr
  -> 10.244.0.38:8000             Masq    1      0          0
  -> 10.244.0.40:8000             Masq    1      0          0
  -> 10.244.0.42:8000             Masq    1      0          0
UDP  10.96.0.10:domain rr
  -> 10.244.0.41:domain           Masq    1      0          0
```
Есть наш сервис с адресом 10.108.65.32

 - ping также работает:
```
$ ping 10.108.65.32
PING 10.108.65.32 (10.108.65.32): 56 data bytes
64 bytes from 10.108.65.32: seq=0 ttl=64 time=0.173 ms
64 bytes from 10.108.65.32: seq=1 ttl=64 time=0.084 ms
^C
--- 10.108.65.32 ping statistics ---
2 packets transmitted, 2 packets received, 0% packet loss
round-trip min/avg/max = 0.084/0.128/0.173 ms
```
Только пришлось поднять интерфейс командой `ip link set kube-ipvs0 up`, до этого он был опущен
```
$ ip addr show
...
10: kube-ipvs0: <BROADCAST,NOARP> mtu 1500 qdisc noop state DOWN group default
    link/ether 7e:cd:10:29:bd:38 brd ff:ff:ff:ff:ff:ff
    inet 10.108.65.32/32 scope global kube-ipvs0
       valid_lft forever preferred_lft forever
    inet 10.96.0.10/32 scope global kube-ipvs0
       valid_lft forever preferred_lft forever
    inet 10.96.0.1/32 scope global kube-ipvs0
       valid_lft forever preferred_lft forever
$ ip link set kube-ipvs0 up
$ ip addr show
...
10: kube-ipvs0: <BROADCAST,NOARP,UP,LOWER_UP> mtu 1500 qdisc noqueue state UNKNOWN group default
    link/ether 7e:cd:10:29:bd:38 brd ff:ff:ff:ff:ff:ff
    inet 10.108.65.32/32 scope global kube-ipvs0
       valid_lft forever preferred_lft forever
    inet 10.96.0.10/32 scope global kube-ipvs0
       valid_lft forever preferred_lft forever
    inet 10.96.0.1/32 scope global kube-ipvs0
       valid_lft forever preferred_lft forever
```

 - посмотрим ipset:
```
$ docker run -it --rm --net=host --entrypoint='' --privileged caseydavenport/ipset ipset list
Name: KUBE-CLUSTER-IP
Type: hash:ip,port
Revision: 5
Header: family inet hashsize 1024 maxelem 65536
Size in memory: 512
References: 3
Number of entries: 5
Members:
10.96.0.10,17:53
10.96.0.10,6:9153
10.96.0.10,6:53
10.96.0.1,6:443
10.108.65.32,6:80
...
```
тут тоже есть наш сервисный адрес 10.108.65.32

 - созданы namespace `metallb-system` и секрет `memberlist`, запущен metallb, но образы `metallb/controller:v0.9.3` и `metallb/speaker:v0.9.3` недоступны, заменил на `bitnami/metallb-controller:0.9.3` и `bitnami/metallb-speaker:0.9.3`
```
$ kubectl -n metallb-system get all -o wide
NAME                            READY   STATUS    RESTARTS   AGE    IP             NODE       NOMINATED NODE   READINESS GATES
pod/controller-c4dcfb44-wpxf2   1/1     Running   0          2m8s   10.244.0.47    minikube   <none>           <none>
pod/speaker-5q94z               1/1     Running   0          67s    192.168.64.3   minikube   <none>           <none>

NAME                     DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR                 AGE     CONTAINERS   IMAGES                          SELECTOR
daemonset.apps/speaker   1         1         1       1            1           beta.kubernetes.io/os=linux   8m50s   speaker      bitnami/metallb-speaker:0.9.3   app=metallb,component=speaker

NAME                         READY   UP-TO-DATE   AVAILABLE   AGE     CONTAINERS   IMAGES                             SELECTOR
deployment.apps/controller   1/1     1            1           8m50s   controller   bitnami/metallb-controller:0.9.3   app=metallb,component=controller

NAME                                    DESIRED   CURRENT   READY   AGE     CONTAINERS   IMAGES                              SELECTOR
replicaset.apps/controller-859c6fdcdd   0         0         0       4m33s   controller   bitnami/metallb-controller:v0.9.3   app=metallb,component=controller,pod-template-hash=859c6fdcdd
replicaset.apps/controller-8785ccb65    0         0         0       8m50s   controller   metallb/controller:v0.9.3           app=metallb,component=controller,pod-template-hash=8785ccb65
replicaset.apps/controller-c4dcfb44     1         1         1       2m8s    controller   bitnami/metallb-controller:0.9.3    app=metallb,component=controller,pod-template-hash=c4dcfb44
```

 - создана и применена ConfigMap config в namespace metallb-system
 - создан и применён манифест сервиса web-svc-lb типа LoadBalancer, найдём его внешний IP адрес в логах контроллера metallb и в описании сервиса:
```
$ kubectl -n metallb-system logs controller-c4dcfb44-wpxf2 | grep web-svc-lb | grep ip
{"caller":"service.go:114","event":"ipAllocated","ip":"172.17.255.1","msg":"IP address assigned by controller","service":"default/web-svc-lb","ts":"2023-09-17T14:37:25.151647323Z"}
$ kubectl get svc web-svc-lb
NAME         TYPE           CLUSTER-IP       EXTERNAL-IP    PORT(S)        AGE
web-svc-lb   LoadBalancer   10.110.192.195   172.17.255.1   80:30853/TCP   7m24s
```
Это адрес 172.17.255.1

 - добавлен статический маршрут к сервисной сети
```
$ minikube ip
192.168.64.3
$ sudo route add 172.17.255.0/24 192.168.64.3
Password:
add net 172.17.255.0: gateway 192.168.64.3
```

 - проверяем доступ и обращения к разным репликам сервиса:
```
$ curl -s 172.17.255.1/index.html | head -5
<html>
<head/>
<body>
<!-- IMAGE BEGINS HERE -->
<font size="-3">
$ curl -s 172.17.255.1/index.html | grep HOSTNAME
export HOSTNAME='web-676c8fd944-zv247'
$ curl -s 172.17.255.1/index.html | grep HOSTNAME
export HOSTNAME='web-676c8fd944-28kk6'
$ curl -s 172.17.255.1/index.html | grep HOSTNAME
export HOSTNAME='web-676c8fd944-mcdjg'
$ curl -s 172.17.255.1/index.html | grep HOSTNAME
export HOSTNAME='web-676c8fd944-zv247'
$ curl -s 172.17.255.1/index.html | grep HOSTNAME
export HOSTNAME='web-676c8fd944-28kk6'
```
Из браузера также открывается

## Задание со *

- создан сервис типа LoadBalancer для coredns, работающий по TCP и UDP:
```
$ kubectl apply -f coredns-svc-lb.yaml
service/coredns-svc-lb-tcp created
service/coredns-svc-lb-udp created
$ kubectl get svc -n kube-system -o wide
NAME                 TYPE           CLUSTER-IP      EXTERNAL-IP    PORT(S)                  AGE   SELECTOR
coredns-svc-lb-tcp   LoadBalancer   10.106.21.13    172.17.255.2   53:31479/TCP             5s    k8s-app=kube-dns
coredns-svc-lb-udp   LoadBalancer   10.104.80.192   172.17.255.2   53:31954/UDP             5s    k8s-app=kube-dns
kube-dns             ClusterIP      10.96.0.10      <none>         53/UDP,53/TCP,9153/TCP   19h   k8s-app=kube-dns
$ host web-svc-lb.default.svc.cluster.local 172.17.255.2
Using domain server:
Name: 172.17.255.2
Address: 172.17.255.2#53
Aliases:

web-svc-lb.default.svc.cluster.local has address 10.110.192.195
$ host -T web-svc-lb.default.svc.cluster.local 172.17.255.2
Using domain server:
Name: 172.17.255.2
Address: 172.17.255.2#53
Aliases:

web-svc-lb.default.svc.cluster.local has address 10.110.192.195
```

 - создан ingress-nginx по манифесту из сети:
```
$ kubectl apply -f ingress-nginx-deploy.yaml
namespace/ingress-nginx created
serviceaccount/ingress-nginx created
serviceaccount/ingress-nginx-admission created
role.rbac.authorization.k8s.io/ingress-nginx created
role.rbac.authorization.k8s.io/ingress-nginx-admission created
clusterrole.rbac.authorization.k8s.io/ingress-nginx created
clusterrole.rbac.authorization.k8s.io/ingress-nginx-admission created
rolebinding.rbac.authorization.k8s.io/ingress-nginx created
rolebinding.rbac.authorization.k8s.io/ingress-nginx-admission created
clusterrolebinding.rbac.authorization.k8s.io/ingress-nginx created
clusterrolebinding.rbac.authorization.k8s.io/ingress-nginx-admission created
configmap/ingress-nginx-controller created
service/ingress-nginx-controller created
service/ingress-nginx-controller-admission created
deployment.apps/ingress-nginx-controller created
job.batch/ingress-nginx-admission-create created
job.batch/ingress-nginx-admission-patch created
ingressclass.networking.k8s.io/nginx created
validatingwebhookconfiguration.admissionregistration.k8s.io/ingress-nginx-admission created
```

 - создан и применён файл nginx-lb.yaml с манифестом сервиса ingress-nginx, работоспособность проверена посредством curl:
```
$ kubectl apply -f nginx-lb.yaml
service/ingress-nginx created
$ kubectl get svc ingress-nginx -n ingress-nginx
NAME            TYPE           CLUSTER-IP      EXTERNAL-IP    PORT(S)                      AGE
ingress-nginx   LoadBalancer   10.103.119.59   172.17.255.3   80:31770/TCP,443:31211/TCP   52m
$ curl 172.17.255.3
<html>
<head><title>404 Not Found</title></head>
<body>
<center><h1>404 Not Found</h1></center>
<hr><center>nginx</center>
</body>
</html>
```

 - создан headless сервис для web
```
$ kubectl apply -f web-svc-headless.yaml
service/web-svc created
$ kubectl get svc web-svc
NAME      TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)   AGE
web-svc   ClusterIP   None         <none>        80/TCP    43s
```
Видно, что у него нет ClusterIP.

 - создан и применён манифест в файле `web-ingress.yaml`, пришлось внести изменения, иначе он не работал. Указана новая apiVersion, добавлен ingressClassName, изменён rewrite-target чтобы поды не видели /web,
   и также backend приведён в соответствие с требуемым синтаксисом:
```
$ cat web-ingress.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: web
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /$2
spec:
  ingressClassName: nginx
  rules:
  - http:
      paths:
      - path: /web(/|$)(.*)
        pathType: ImplementationSpecific
        backend:
          service:
            name: web-svc
            port:
              number: 80
$ kubectl apply -f web-ingress.yaml
ingress.networking.k8s.io/web configured
$ kubectl describe ingress web
Name:             web
Labels:           <none>
Namespace:        default
Address:          192.168.64.3
Ingress Class:    nginx
Default backend:  <default>
Rules:
  Host        Path  Backends
  ----        ----  --------
  *
              /web(/|$)(.*)   web-svc:80 (10.244.0.38:8000,10.244.0.40:8000,10.244.0.42:8000)
Annotations:  nginx.ingress.kubernetes.io/rewrite-target: /$2
Events:
  Type    Reason  Age                  From                      Message
  ----    ------  ----                 ----                      -------
  Normal  Sync    2m46s (x4 over 10m)  nginx-ingress-controller  Scheduled for sync
$ kubectl get svc ingress-nginx -n ingress-nginx
NAME            TYPE           CLUSTER-IP      EXTERNAL-IP    PORT(S)                      AGE
ingress-nginx   LoadBalancer   10.103.119.59   172.17.255.3   80:31770/TCP,443:31211/TCP   79m
$ curl -s 172.17.255.3/web/index.html | head -5
<html>
<head/>
<body>
<!-- IMAGE BEGINS HERE -->
<font size="-3">
$ curl -s 172.17.255.3/web/index.html | grep HOSTNAME
export HOSTNAME='web-676c8fd944-28kk6'
$ curl -s 172.17.255.3/web/index.html | grep HOSTNAME
export HOSTNAME='web-676c8fd944-zv247'
$ curl -s 172.17.255.3/web/index.html | grep HOSTNAME
export HOSTNAME='web-676c8fd944-zv247'
$ curl -s 172.17.255.3/web/index.html | grep HOSTNAME
export HOSTNAME='web-676c8fd944-mcdjg'
$ curl -s 172.17.255.3/web/index.html | grep HOSTNAME
export HOSTNAME='web-676c8fd944-28kk6'
```

 - скачан и применён манифест kubernetes dashboard https://raw.githubusercontent.com/kubernetes/dashboard/v2.7.0/aio/deploy/recommended.yaml
 - создан ServiceAccount admin-user и его токен для доступа к dashboard:
```
$ cat admin-user.yaml
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: admin-user
  namespace: kubernetes-dashboard
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: admin-user
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- kind: ServiceAccount
  name: admin-user
  namespace: kubernetes-dashboard
$ kubectl apply -f admin-user.yaml
serviceaccount/admin-user created
clusterrolebinding.rbac.authorization.k8s.io/admin-user created
$ kubectl -n kubernetes-dashboard create token admin-user
eyJhbGciOiJSUzI1NiIs...GltUDqM9Cc2s9k7Q
```
 - написан и применён манифест Ingress для kubenetes-dashboard
```
$ curl -sk https://172.17.255.3/dashboard/ | head -17
<!--
Copyright 2017 The Kubernetes Authors.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
--><!DOCTYPE html><html lang="en" dir="ltr"><head>
  <meta charset="utf-8">
  <title>Kubernetes Dashboard</title>
```

 - реализовано канареечное развёртывание с помощью ingress-nginx: в дополнение к работающему деплойменту, сервису и ингрессу web созданы новые Deployment web2,
   сервис web2-svc и канареечный Ingress web2, настроенный на заголовок `Web-Version`:
```
$ kubectl apply -f web2-deploy.yaml
deployment.apps/web2 created
$ kubectl get pods
NAME                    READY   STATUS    RESTARTS       AGE
web-676c8fd944-28kk6    1/1     Running   1 (7h8m ago)   7h10m
web-676c8fd944-mcdjg    1/1     Running   0              7h5m
web-676c8fd944-zv247    1/1     Running   4 (7h8m ago)   10h
web2-57c54b4fcc-6zhd5   1/1     Running   0              7s
web2-57c54b4fcc-fqfmz   1/1     Running   0              4s
$ kubectl apply -f web2-svc-headless.yaml
service/web2-svc created
$ kubectl get svc
NAME          TYPE           CLUSTER-IP       EXTERNAL-IP    PORT(S)        AGE
kubernetes    ClusterIP      10.96.0.1        <none>         443/TCP        24h
web-svc       ClusterIP      None             <none>         80/TCP         3h34m
web-svc-cip   ClusterIP      10.108.65.32     <none>         80/TCP         10h
web-svc-lb    LoadBalancer   10.110.192.195   172.17.255.1   80:30853/TCP   5h21m
web2-svc      ClusterIP      None             <none>         80/TCP         29m
$ kubectl create -f web2-ingress-canary.yaml
ingress.networking.k8s.io/web2 created
$ kubectl get ingress
NAME   CLASS   HOSTS   ADDRESS        PORTS   AGE
web    nginx   *       192.168.64.3   80      3h32m
web2   nginx   *       192.168.64.3   80      2m46s
$ curl -s http://172.17.255.3/web/index.html | head -5
<html>
<head/>
<body>
<!-- IMAGE BEGINS HERE -->
<font size="-3">
$ curl -s -H 'Web-Version: never' http://172.17.255.3/web/index.html | head -5
<html>
<head/>
<body>
<!-- IMAGE BEGINS HERE -->
<font size="-3">
$ curl -s -H 'Web-Version: xxx' http://172.17.255.3/web/index.html | head -5
<html>
<head/>
<body>
<!-- IMAGE BEGINS HERE -->
<font size="-3">
$ curl -s -H 'Web-Version: always' http://172.17.255.3/web/index.html | head -5
new version
```

# Выполнено ДЗ №4

 - [*] Основное ДЗ
 - [*] Задание со *

## В процессе сделано:

 - создан кластер kubernetes командой `kind create cluster`
 - скачан, записан в `minio-statefulset.yaml` и применён манифест для StatefulSet minio:
```
$ kubectl get all
NAME          READY   STATUS    RESTARTS   AGE
pod/minio-0   1/1     Running   0          53m

NAME                 TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)   AGE
service/kubernetes   ClusterIP   10.96.0.1    <none>        443/TCP   56m

NAME                     READY   AGE
statefulset.apps/minio   1/1     53m
$ kubectl get pv -o wide
NAME                                       CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM                  STORAGECLASS   REASON   AGE   VOLUMEMODE
pvc-abd30d13-16fe-49b4-bebb-8a2e39e28b64   10Gi       RWO            Delete           Bound    default/data-minio-0   standard                54m   Filesystem
$ kubectl get pvc -o wide
NAME           STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   AGE   VOLUMEMODE
data-minio-0   Bound    pvc-abd30d13-16fe-49b4-bebb-8a2e39e28b64   10Gi       RWO            standard       54m   Filesystem
$ kubectl logs minio-0

 You are running an older version of MinIO released 4 years ago
 Update: https://docs.min.io/docs/deploy-minio-on-kubernetes


Endpoint:  http://10.244.0.7:9000  http://127.0.0.1:9000

Browser Access:
   http://10.244.0.7:9000  http://127.0.0.1:9000

Object API (Amazon S3 compatible):
   Go:         https://docs.min.io/docs/golang-client-quickstart-guide
   Java:       https://docs.min.io/docs/java-client-quickstart-guide
   Python:     https://docs.min.io/docs/python-client-quickstart-guide
   JavaScript: https://docs.min.io/docs/javascript-client-quickstart-guide
   .NET:       https://docs.min.io/docs/dotnet-client-quickstart-guide
$ kubectl get pv -o json | jq -r '.items[]|[.metadata.name,.spec.storageClassName]|join(" ")'
pvc-abd30d13-16fe-49b4-bebb-8a2e39e28b64 standard
$ kubectl get pvc -o json | jq -r '.items[]|[.metadata.name,.spec.storageClassName]|join(" ")'
data-minio-0 standard
```
Видим, что создан StatefulSet minio, PersistentVolume pvc-abd30d13-16fe-49b4-bebb-8a2e39e28b64 и PersistentVolumeClaim data-minio-0.
storageClassName одинаковый, `standard`

 - проверим, что данные в PersistentVolume сохраняются после рестарта пода:
```
$ kubectl exec -it minio-0 -- sh
/ # df -h
Filesystem                Size      Used Available Use% Mounted on
overlay                  58.4G      8.6G     46.8G  16% /
tmpfs                    64.0M         0     64.0M   0% /dev
/dev/vda1                58.4G      8.6G     46.8G  16% /data
/dev/vda1                58.4G      8.6G     46.8G  16% /etc/hosts
/dev/vda1                58.4G      8.6G     46.8G  16% /dev/termination-log
/dev/vda1                58.4G      8.6G     46.8G  16% /etc/hostname
/dev/vda1                58.4G      8.6G     46.8G  16% /etc/resolv.conf
shm                      64.0M         0     64.0M   0% /dev/shm
tmpfs                     3.8G     12.0K      3.8G   0% /run/secrets/kubernetes.io/serviceaccount
overlay                  58.4G      8.6G     46.8G  16% /sys/devices/virtual/dmi/id/product_name
overlay                  58.4G      8.6G     46.8G  16% /sys/devices/virtual/dmi/id/product_uuid
overlay                  58.4G      8.6G     46.8G  16% /sys/devices/virtual/dmi/id/product_uuid
tmpfs                     1.9G         0      1.9G   0% /proc/acpi
tmpfs                    64.0M         0     64.0M   0% /proc/kcore
tmpfs                    64.0M         0     64.0M   0% /proc/keys
tmpfs                    64.0M         0     64.0M   0% /proc/timer_list
tmpfs                     1.9G         0      1.9G   0% /sys/firmware
/ # ls -l /data
total 0
/ # echo test > /data/test
$ kubectl delete pod minio-0
pod "minio-0" deleted
$ kubectl get pods
NAME      READY   STATUS    RESTARTS   AGE
minio-0   1/1     Running   0          1s
$ kubectl exec -it minio-0 -- sh
/ # ls -l /data
total 4
-rw-r--r--    1 root     root             5 Sep 19 20:05 test
/ # cat /data/test
test
```
Видно, что файл `test` сохранился после перезапуска пода

 - скачан и применён файл `minio-headless-service.yaml` с манифестом сервиса minio
 - скачаем и установим minio client `mcli`:
```
$ kubectl exec -it minio-0 -- sh
/ # cat /etc/os-release
NAME="Alpine Linux"
ID=alpine
VERSION_ID=3.9.4
PRETTY_NAME="Alpine Linux v3.9"
HOME_URL="https://alpinelinux.org/"
BUG_REPORT_URL="https://bugs.alpinelinux.org/"
/ # wget http://dl-cdn.alpinelinux.org/alpine/v3.18/community/x86_64/minio-client-0.20230323.200304-r4.apk
Connecting to dl-cdn.alpinelinux.org (151.101.86.132:80)
minio-client-0.20230 100% |**************************************************************************************************************************************************************************************| 9616k  0:00:00 ETA
/ # apk add --allow-untrusted minio-client-0.20230323.200304-r4.apk
(1/1) Installing minio-client (0.20230323.200304-r4)
Executing busybox-1.29.3-r10.trigger
OK: 35 MiB in 21 packages
/ # mcli alias set k8s-minio-dev http://127.0.0.1:9000 minio minio123
Added `k8s-minio-dev` successfully.
/ # mcli ping k8s-minio-dev
  1: http://127.0.0.1:9000:9000   min=1.54ms     max=1.54ms     average=1.54ms     errors=0   roundtrip=1.54ms
  2: http://127.0.0.1:9000:9000   min=1.23ms     max=1.54ms     average=1.38ms     errors=0   roundtrip=1.23ms
  3: http://127.0.0.1:9000:9000   min=1.00ms     max=1.54ms     average=1.26ms     errors=0   roundtrip=1.00ms
/ # mcli admin info k8s-minio-dev
mcli: <ERROR> Unable to get service status: invalid character '<' looking for beginning of value.
```
Вероятно, ошибка вызвана несоответствием версий сервера и клиента. Сервер довольно старый.
Попробуем использовать образ `bitnami/minio:latest`, это потребовало удалить args, в остальном файл такой же:
```
$ kubectl apply -f minio-statefulset-new.yaml
statefulset.apps/minio configured
$ kubectl exec -it minio-0 -- sh
$ bash
I have no name!@minio-0:/opt/bitnami/minio-client$ mc admin info local
●  localhost:9000
   Uptime: 10 minutes
   Version: 2023-09-16T01:01:47Z
   Network: 1/1 OK
   Drives: 1/1 OK
   Pool: 1

Pools:
   1st, Erasure sets: 1, Drives per erasure set: 1

1 drive online, 0 drives offline
I have no name!@minio-0:/opt/bitnami/minio-client$ mc ping local
  1: http://localhost:9000:9000   min=1.01ms     max=1.01ms     average=1.01ms     errors=0   roundtrip=1.01ms
  2: http://localhost:9000:9000   min=0.80ms     max=1.01ms     average=0.90ms     errors=0   roundtrip=0.80ms
  3: http://localhost:9000:9000   min=0.49ms     max=1.01ms     average=0.77ms     errors=0   roundtrip=0.49ms
^CI have no name!@minio-0:/opt/bitnami/minio-client$
```
Так работает. Можно открыть доступ к web-консоли командой `kubectl port-forward pod/minio-0 9001:9001`, создать учётку и зайти туда:
```
^CI have no name!@minio-0:/opt/bitnami/minio-client$ mc admin user add local miniouser password
Added user `miniouser` successfully.
```

## Задание со *

 - создадим файл с секретом и применим его:
```
$ echo -n minio | base64
bWluaW8=
$ echo -n minio123 | base64
bWluaW8xMjM=
$ cat minio-secret.yaml
apiVersion: v1
kind: Secret
metadata:
  name: minio-admin-credentials
data:
  access-key: bWluaW8=
  secret-key: bWluaW8xMjM=
$ kubectl apply -f minio-secret.yaml
secret/minio-admin-credentials created
```

 - используем секрет для задания значений переменных среды, используя следующую конструкцию, запишем в файл `minio-statefulset.yaml`:
```
        - name: MINIO_ACCESS_KEY
          valueFrom:
            secretKeyRef:
              name: minio-admin-credentials
              key: access-key
        - name: MINIO_SECRET_KEY
          valueFrom:
            secretKeyRef:
              name: minio-admin-credentials
              key: secret-key

```

 - применим манифест и проверим доступ:
```
$ kubectl apply -f minio-statefulset.yaml
statefulset.apps/minio configured
$ kubectl get pods
NAME      READY   STATUS    RESTARTS   AGE
minio-0   1/1     Running   0          4s
$ kubectl exec -it minio-0 -- sh
...
[снова установим minio client]
...
/ # mcli alias set k8s-minio-dev http://127.0.0.1:9000 minio minio123
mcli: Configuration written to `/root/.mcli/config.json`. Please update your access credentials.
mcli: Successfully created `/root/.mcli/share`.
mcli: Initialized share uploads `/root/.mcli/share/uploads.json` file.
mcli: Initialized share downloads `/root/.mcli/share/downloads.json` file.
Added `k8s-minio-dev` successfully.
/ # mcli alias set k8s-minio-dev http://127.0.0.1:9000 minio minio123aa
mcli: <ERROR> Unable to initialize new alias from the provided credentials. The request signature we calculated does not match the signature you provided. Check your key and signing method.
```

# Выполнено ДЗ №5

 - [*] Основное ДЗ

## В процессе сделано:

 - создана сервисная учётка `bob`, кластерная привязка к ней кластерной роли `admin`:
```
$ kubectl apply -f 01-bob-sa.yaml
serviceaccount/bob created
$ kubectl apply -f 03-bob-clusterrolebinding-admin.yaml
clusterrolebinding.rbac.authorization.k8s.io/bob:admin created
$ kubectl get sa
NAME      SECRETS   AGE
dave      0         11m
default   0         6d21h
$ kubectl get clusterrolebindings | grep bob
bob:admin ClusterRole/admin 11m
```

 - создан ServiceAccount `dave`:
```
$ kubectl apply -f 02-dave-sa.yaml
serviceaccount/dave created
$ kubectl get sa
NAME      SECRETS   AGE
bob       0         13m
dave      0         11m
default   0         6d21h
```

 - проверим, что у `bob` есть доступ к кластеру, например на просмотр подов в namespace `kube-system`, а у `dave` - нет:
```
$ kubectl --as=system:serviceaccount:default:bob get pods -n kube-system
NAME                               READY   STATUS    RESTARTS   AGE
coredns-5d78c9869d-fc82z           1/1     Running   7          6d21h
etcd-minikube                      1/1     Running   4          6d21h
kube-apiserver-minikube            1/1     Running   4          6d21h
kube-controller-manager-minikube   1/1     Running   4          6d21h
kube-proxy-rtnvn                   1/1     Running   3          6d4h
kube-scheduler-minikube            1/1     Running   4          6d21h
storage-provisioner                1/1     Running   9          6d21h
$ kubectl --as=system:serviceaccount:default:dave get pods -n kube-system
NAME                               READY   STATUS    RESTARTS   AGE
coredns-5d78c9869d-fc82z           1/1     Running   7          6d21h
etcd-minikube                      1/1     Running   4          6d21h
kube-apiserver-minikube            1/1     Running   4          6d21h
kube-controller-manager-minikube   1/1     Running   4          6d21h
kube-proxy-rtnvn                   1/1     Running   3          6d4h
kube-scheduler-minikube            1/1     Running   4          6d21h
storage-provisioner                1/1     Running   9          6d21h
```
Права есть и у `dave` тоже, это неожиданно. Дело в том, что админские права есть у группы `system:serviceaccounts` (в minikube), куда они оба входят. Временно удалим её и проверим снова:
```
$ kubectl delete clusterrolebindings serviceaccounts-cluster-admin
clusterrolebinding.rbac.authorization.k8s.io "serviceaccounts-cluster-admin" deleted
$ kubectl --as=system:serviceaccount:default:bob get pods -n kube-system
NAME                               READY   STATUS    RESTARTS   AGE
coredns-5d78c9869d-fc82z           1/1     Running   7          6d21h
etcd-minikube                      1/1     Running   4          6d21h
kube-apiserver-minikube            1/1     Running   4          6d21h
kube-controller-manager-minikube   1/1     Running   4          6d21h
kube-proxy-rtnvn                   1/1     Running   3          6d4h
kube-scheduler-minikube            1/1     Running   4          6d21h
storage-provisioner                1/1     Running   9          6d21h
$ kubectl --as=system:serviceaccount:default:dave get pods -n kube-system
Error from server (Forbidden): pods is forbidden: User "system:serviceaccount:default:dave" cannot list resource "pods" in API group "" in the namespace "kube-system"
```
Теперь всё хорошо, у `bob` есть права, у `dave` - нет.

 - создан namespace `prometheus` и в нём ServiceAccount `carol`:
```
$ kubectl apply -f 01-prometheus-namespace.yaml
namespace/prometheus created
$ kubectl apply -f 02-carol-sa.yaml
serviceaccount/carol created
$ kubectl get sa -n prometheus
NAME      SECRETS   AGE
carol     0         63s
default   0         3m14s
```

 - создана роль `pod-viewer`, она кластерная, т.к. доступ нужен ко всем пространствам имён
```
$ kubectl apply -f 03-pod-viewer-clusterrole.yaml
clusterrole.rbac.authorization.k8s.io/pod-viewer created
```

 - создана привязка группы `system:serviceaccounts:prometheus` к ранее созданной роли. Привязка тоже кластерная, т.к. доступ нужен ко всему кластеру.
   Если привязка будет обычная, то доступ будет только внутри пространства имён `prometheus`. Сначала проверим, что RoleBinding даёт доступ только в своём пространстве имён:
```
$ cat test.yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: test
  namespace: prometheus
subjects:
- kind: Group
  name: system:serviceaccounts
  namespace: prometheus
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: ClusterRole
  name: pod-viewer
  apiGroup: rbac.authorization.k8s.io
$ kubectl apply -f test.yaml
rolebinding.rbac.authorization.k8s.io/test created
$ kubectl --as=system:serviceaccount:prometheus:carol get pods -n prometheus
No resources found in prometheus namespace.
$ kubectl --as=system:serviceaccount:prometheus:carol get pods -n default
Error from server (Forbidden): pods is forbidden: User "system:serviceaccount:prometheus:carol" cannot list resource "pods" in API group "" in the namespace "default"
```
Тут создана и применена RoleBinding в пространстве имён `prometheus`, которая даёт кластерную роль всем сервисным учёткам там же в `prometheus`. Затем проверено,
что системная учётка `carol` в пространстве имён `prometheus` имеет там доступ на просмотр подов, хотя подов там нет; а просматривать поды в пространстве имён
`default` - запрещено.
```
$ kubectl delete rolebinding test -n prometheus
rolebinding.rbac.authorization.k8s.io "test" deleted
$ cat 04-serviceaccounts-prometheus-clusterrolebinding-pod-viewer.yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: serviceaccounts-prometheus:pod-viewer
subjects:
- kind: Group
  name: system:serviceaccounts:prometheus
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: ClusterRole
  name: pod-viewer
  apiGroup: rbac.authorization.k8s.io
$ kubectl apply -f 04-serviceaccounts-prometheus-clusterrolebinding-pod-viewer.yaml
clusterrolebinding.rbac.authorization.k8s.io/serviceaccounts-prometheus:pod-viewer created
$ kubectl --as=system:serviceaccount:prometheus:carol get pods -A
NAMESPACE     NAME                               READY   STATUS    RESTARTS        AGE
kube-system   coredns-5d78c9869d-fc82z           1/1     Running   8 (38m ago)     7d15h
kube-system   etcd-minikube                      1/1     Running   5 (109m ago)    7d15h
kube-system   kube-apiserver-minikube            1/1     Running   5 (38m ago)     7d15h
kube-system   kube-controller-manager-minikube   1/1     Running   5 (109m ago)    7d15h
kube-system   kube-proxy-rtnvn                   1/1     Running   4 (109m ago)    6d22h
kube-system   kube-scheduler-minikube            1/1     Running   5 (109m ago)    7d15h
kube-system   storage-provisioner                1/1     Running   10 (109m ago)   7d15h
$ kubectl --as=system:serviceaccount:prometheus:default get pods -A
NAMESPACE     NAME                               READY   STATUS    RESTARTS        AGE
kube-system   coredns-5d78c9869d-fc82z           1/1     Running   8 (38m ago)     7d15h
kube-system   etcd-minikube                      1/1     Running   5 (109m ago)    7d15h
kube-system   kube-apiserver-minikube            1/1     Running   5 (38m ago)     7d15h
kube-system   kube-controller-manager-minikube   1/1     Running   5 (109m ago)    7d15h
kube-system   kube-proxy-rtnvn                   1/1     Running   4 (109m ago)    6d22h
kube-system   kube-scheduler-minikube            1/1     Running   5 (109m ago)    7d15h
kube-system   storage-provisioner                1/1     Running   10 (109m ago)   7d15h
$ kubectl --as=system:serviceaccount:prometheus:carol get deploy -n prometheus
Error from server (Forbidden): deployments.apps is forbidden: User "system:serviceaccount:prometheus:carol" cannot list resource "deployments" in API group "apps" in the namespace "prometheus"
$ kubectl --as=system:serviceaccount:default:default get pods -A
Error from server (Forbidden): pods is forbidden: User "system:serviceaccount:default:default" cannot list resource "pods" in API group "" at the cluster scope
```
Создана и применена кластерная привязка роли; доступ на просмотр подов во всех пространствах имён есть у любой сервисной учётки в `prometheus`, но нет доступа на просмотр деплойментов даже в своём пространстве имён;
Также нет доступа на просмотр подов у например sa `default` в ns `default`.

 - создано пространство имён `dev` и в нём сервисная учётка `jane`.
```
$ kubectl apply -f 01-dev-namespace.yaml
namespace/dev created
$ kubectl apply -f 02-jane-sa.yaml
serviceaccount/jane created
```

 - создана и применена привязка sa `jane` к кластерной роли `admin`
```
$ kubectl apply -f 03-jane-rolebinding-admin.yaml
rolebinding.rbac.authorization.k8s.io/jane:admin created
```

 - проверим доступ `jane`
```
$ kubectl --as=system:serviceaccount:dev:jane create deploy jane-deploy --image=busybox:latest -- sleep 3600
error: failed to create deployment: deployments.apps is forbidden: User "system:serviceaccount:dev:jane" cannot create resource "deployments" in API group "apps" in the namespace "default"
$ kubectl --as=system:serviceaccount:dev:jane -n dev create deploy jane-deploy --image=busybox:latest -- sleep 3600
deployment.apps/jane-deploy created
```
У sa `jane` нет доступа на создание деплоймента в ns `default`, но есть в ns `dev`.

 - создана сервисная учётка `ken` пространстве имён `dev`, создана и применена привязка sa `ken` к кластерной роли `view`
```
$ kubectl apply -f 04-ken-sa.yaml
serviceaccount/ken created
$ kubectl apply -f 05-ken-rolebinding-view.yaml
rolebinding.rbac.authorization.k8s.io/ken:view created
```

 - проверим доступ `ken`
```
$ kubectl --as=system:serviceaccount:dev:ken get all -n dev
No resources found in dev namespace.
$ kubectl --as=system:serviceaccount:dev:ken get all
Error from server (Forbidden): pods is forbidden: User "system:serviceaccount:dev:ken" cannot list resource "pods" in API group "" in the namespace "default"
Error from server (Forbidden): replicationcontrollers is forbidden: User "system:serviceaccount:dev:ken" cannot list resource "replicationcontrollers" in API group "" in the namespace "default"
Error from server (Forbidden): services is forbidden: User "system:serviceaccount:dev:ken" cannot list resource "services" in API group "" in the namespace "default"
Error from server (Forbidden): daemonsets.apps is forbidden: User "system:serviceaccount:dev:ken" cannot list resource "daemonsets" in API group "apps" in the namespace "default"
Error from server (Forbidden): deployments.apps is forbidden: User "system:serviceaccount:dev:ken" cannot list resource "deployments" in API group "apps" in the namespace "default"
Error from server (Forbidden): replicasets.apps is forbidden: User "system:serviceaccount:dev:ken" cannot list resource "replicasets" in API group "apps" in the namespace "default"
Error from server (Forbidden): statefulsets.apps is forbidden: User "system:serviceaccount:dev:ken" cannot list resource "statefulsets" in API group "apps" in the namespace "default"
Error from server (Forbidden): horizontalpodautoscalers.autoscaling is forbidden: User "system:serviceaccount:dev:ken" cannot list resource "horizontalpodautoscalers" in API group "autoscaling" in the namespace "default"
Error from server (Forbidden): cronjobs.batch is forbidden: User "system:serviceaccount:dev:ken" cannot list resource "cronjobs" in API group "batch" in the namespace "default"
Error from server (Forbidden): jobs.batch is forbidden: User "system:serviceaccount:dev:ken" cannot list resource "jobs" in API group "batch" in the namespace "default"
```
У sa `ken` есть доступ на просмотр (почти) всех ресурсов в ns `dev`, но нет в ns `default`.

# Выполнено ДЗ №6

 - [*] Основное ДЗ
 - [*] Задание со *

## В процессе сделано:

 - создан управляемый кластер kubernetes `otus` в облаке Yandex, настроен kubectl
```
Kubernetes control plane is running at https://158.160.12.170
CoreDNS is running at https://158.160.12.170/api/v1/namespaces/kube-system/services/kube-dns:dns/proxy

To further debug and diagnose cluster problems, use 'kubectl cluster-info dump'.
$ kubectl get nodes -o wide
NAME                        STATUS   ROLES    AGE   VERSION   INTERNAL-IP   EXTERNAL-IP     OS-IMAGE             KERNEL-VERSION      CONTAINER-RUNTIME
cl1rqs0kv2lussijle58-epis   Ready    <none>   67s   v1.27.3   10.129.0.8    158.160.28.63   Ubuntu 20.04.6 LTS   5.4.0-153-generic   containerd://1.6.21
```

 - установлен helm
```
$ helm version
version.BuildInfo{Version:"v3.12.3", GitCommit:"3a31588ad33fe3b89af5a2a54ee1d25bfe6eaa5e", GitTreeState:"clean", GoVersion:"go1.20.7"}
```

 - добавлен helm репозиторий `https://charts.helm.sh/stable`, т.к. указанный в ДЗ недоступен
```
$ helm repo add stable https://kubernetes-charts.storage.googleapis.com
Error: repo "https://kubernetes-charts.storage.googleapis.com" is no longer available; try "https://charts.helm.sh/stable" instead
$ helm repo add stable https://charts.helm.sh/stable
"stable" has been added to your repositories
$ helm repo list
NAME  	URL
stable	https://charts.helm.sh/stable
```

 - вместо предлагаемого старого nginx-ingress установлен свежий ingress-nginx из своего репозитория:
```
$ helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
"ingress-nginx" has been added to your repositories
$ helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx --wait --namespace=ingress-nginx --create-namespace
Release "ingress-nginx" does not exist. Installing it now.
NAME: ingress-nginx
LAST DEPLOYED: Wed Sep 27 21:33:58 2023
NAMESPACE: ingress-nginx
STATUS: deployed
REVISION: 1
TEST SUITE: None
NOTES:
The ingress-nginx controller has been installed.
It may take a few minutes for the LoadBalancer IP to be available.
You can watch the status by running 'kubectl --namespace ingress-nginx get services -o wide -w ingress-nginx-controller'

An example Ingress that makes use of the controller:
  apiVersion: networking.k8s.io/v1
  kind: Ingress
  metadata:
    name: example
    namespace: foo
  spec:
    ingressClassName: nginx
    rules:
      - host: www.example.com
        http:
          paths:
            - pathType: Prefix
              backend:
                service:
                  name: exampleService
                  port:
                    number: 80
              path: /
    # This section is only required if TLS is to be enabled for the Ingress
    tls:
      - hosts:
        - www.example.com
        secretName: example-tls

If TLS is enabled for the Ingress, a Secret containing the certificate and key must also be provided:

  apiVersion: v1
  kind: Secret
  metadata:
    name: example-tls
    namespace: foo
  data:
    tls.crt: <base64 encoded cert>
    tls.key: <base64 encoded key>
  type: kubernetes.io/tls
```

 - добавлен репозиторий для `cert-manager`, установлены CRDs и сам `cert-manager` по свежей инструкции
```
$ helm repo add jetstack https://charts.jetstack.io
"jetstack" has been added to your repositories
$ kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.0/cert-manager.crds.yaml
customresourcedefinition.apiextensions.k8s.io/certificaterequests.cert-manager.io created
customresourcedefinition.apiextensions.k8s.io/certificates.cert-manager.io created
customresourcedefinition.apiextensions.k8s.io/challenges.acme.cert-manager.io created
customresourcedefinition.apiextensions.k8s.io/clusterissuers.cert-manager.io created
customresourcedefinition.apiextensions.k8s.io/issuers.cert-manager.io created
customresourcedefinition.apiextensions.k8s.io/orders.acme.cert-manager.io created
$ helm upgrade --install cert-manager jetstack/cert-manager --namespace cert-manager --create-namespace --version v1.13.0
Release "cert-manager" does not exist. Installing it now.
NAME: cert-manager
LAST DEPLOYED: Wed Sep 27 21:35:55 2023
NAMESPACE: cert-manager
STATUS: deployed
REVISION: 1
TEST SUITE: None
NOTES:
cert-manager v1.13.0 has been deployed successfully!

In order to begin issuing certificates, you will need to set up a ClusterIssuer
or Issuer resource (for example, by creating a 'letsencrypt-staging' issuer).

More information on the different types of issuers and how to configure them
can be found in our documentation:

https://cert-manager.io/docs/configuration/

For information on how to configure cert-manager to automatically provision
Certificates for Ingress resources, take a look at the `ingress-shim`
documentation:

https://cert-manager.io/docs/usage/ingress/
```

 - добавлены файлы `cert-manager/acme-http-staging.yaml` и `cert-manager/acme-http-production.yaml` с методом проверки `http01`.
 Первый файл для проверки, второй боевой:
```
$ kubectl apply -f acme-http-staging.yaml
clusterissuer.cert-manager.io/letsencrypt-staging created
$ kubectl apply -f acme-http-production.yaml
clusterissuer.cert-manager.io/letsencrypt-production created
```

 - создан файл `chartmuseum/values.yaml` c `ingress.hosts[0].name` `chartmuseum.84.201.157.43.nip.io`,
`ingress.annotaions`: `cert-manager.io/cluster-issuer: "letsencrypt-production"` и `cert-manager.io/acme-challenge-type: http01`:

 - установлен чарт `chartmuseum` из локальной директории, так как требовались правки. diff находится в файле `chartmuseum/helm.diff`:
```
$ helm upgrade --install chartmuseum --wait --namespace=chartmuseum --create-namespace --version=2.13.2 -f values.yaml ../../../7-helm/chartmuseum
Release "chartmuseum" does not exist. Installing it now.
WARNING: This chart is deprecated
NAME: chartmuseum
LAST DEPLOYED: Wed Sep 27 21:38:43 2023
NAMESPACE: chartmuseum
STATUS: deployed
REVISION: 1
TEST SUITE: None
NOTES:
** Please be patient while the chart is being deployed **

Get the ChartMuseum URL by running:

  export POD_NAME=$(kubectl get pods --namespace chartmuseum -l "app=chartmuseum" -l "release=chartmuseum" -o jsonpath="{.items[0].metadata.name}")
  echo http://127.0.0.1:8080/
  kubectl port-forward $POD_NAME 8080:8080 --namespace chartmuseum
$ helm ls -n chartmuseum
NAME       	NAMESPACE  	REVISION	UPDATED                            	STATUS  	CHART             	APP VERSION
chartmuseum	chartmuseum	1       	2023-09-27 21:38:43.38214 +0300 MSK	deployed	chartmuseum-2.14.2	0.12.0
```
Созданный сайт доступен по адресу https://chartmuseum.84.201.157.43.nip.io, сертификат действителен.

## Задание со *

 - Для проверки работоспособности chartmuseum я установил свежую версию в namespace `chartmuseum2`
```
$ helm upgrade --install chartmuseum --wait --namespace=chartmuseum2 --create-namespace --version=3.10.1 -f values.yaml chartmuseum/chartmuseum
Release "chartmuseum" does not exist. Installing it now.
NAME: chartmuseum
LAST DEPLOYED: Sat Sep 30 21:13:24 2023
NAMESPACE: chartmuseum2
STATUS: deployed
REVISION: 1
TEST SUITE: None
NOTES:
** Please be patient while the chart is being deployed **

Get the ChartMuseum URL by running:

  export POD_NAME=$(kubectl get pods --namespace chartmuseum2 -l "app=chartmuseum" -l "release=chartmuseum" -o jsonpath="{.items[0].metadata.name}")
  echo http://127.0.0.1:8080/
  kubectl port-forward $POD_NAME 8080:8080 --namespace chartmuseum2
```
Она использует другой URL, https://chartmuseum.84.201.157.43.hfrog.ru. Добавим helm репозиторий `mychartmuseum`:
```
$ helm repo add mychartmuseum https://chartmuseum.84.201.157.43.hfrog.ru
"mychartmuseum" has been added to your repositories
```
Попробуем записать созданный в этой домашней работе чарт `hipster-shop/charts/frontend-0.1.0.tgz`
```
$ helm push hipster-shop/charts/frontend-0.1.0.tgz mychartmuseum
Error: scheme prefix missing from remote (e.g. "oci://")
```
Chartmuseum не поддерживает протокол oci (Open Container Initiative), установим плагин для работы по http
```
$ helm plugin install https://github.com/chartmuseum/helm-push
Downloading and installing helm-push v0.10.4 ...
https://github.com/chartmuseum/helm-push/releases/download/v0.10.4/helm-push_0.10.4_darwin_arm64.tar.gz
Installed plugin: cm-push
```
Попробуем записать чарт снова, с использованием плагина
```
% helm cm-push hipster-shop/charts/frontend-0.1.0.tgz mychartmuseum
Pushing frontend-0.1.0.tgz to mychartmuseum...
Done.
```
Записали успешно. Теперь попробуем установить в другое пространство имён
```
$ helm upgrade --install frontend2 --wait --namespace=frontend2 --create-namespace mychartmuseum/frontend
Release "frontend2" does not exist. Installing it now.
Error: chart "frontend" matching  not found in mychartmuseum index. (try 'helm repo update'): no chart name found
```
Не находит. Последуем совету и обновим локальный каталог чартов
```
$ helm repo update mychartmuseum
Hang tight while we grab the latest from your chart repositories...
...Successfully got an update from the "mychartmuseum" chart repository
Update Complete. ⎈Happy Helming!⎈
```
Проверим, что есть в репозитории
```
$ helm search repo mychartmuseum
NAME                  	CHART VERSION	APP VERSION	DESCRIPTION
mychartmuseum/frontend	0.1.0        	1.16.0     	A Helm chart for Kubernetes
```
Отлично, чарт есть, попробуем установить его снова
```
$ helm upgrade --install frontend2 --wait --namespace=frontend2 --create-namespace mychartmuseum/frontend
Release "frontend2" does not exist. Installing it now.
Error: 1 error occurred:
	* admission webhook "validate.nginx.ingress.kubernetes.io" denied the request: host "shop.84.201.157.43.hfrog.ru" and path "/" is already defined in ingress hipster-shop/frontend
```
На этот раз чарт скачивается и пытается установиться, но не устанавливается из-за конфликта ingress с существующим.
Чинить не буду, т.к. для демонстрации использования chartmuseum описанных шагов достаточно.

 - Самостоятельное задание: установить `harbor`. `harbor` установлен, но более новой версии, т.к. на починку старого впустую ушло много времени.
   Причина в том, что в чартах указаны образы dev, которые по прошествии нескольких лет уже потеряли совместимость с использующими их манифестами.
```
$ helm repo add harbor https://helm.goharbor.io
"harbor" has been added to your repositories
$ helm upgrade --install harbor harbor/harbor -n harbor --create-namespace --version 1.13.0 -f values.yaml
Release "harbor" does not exist. Installing it now.
NAME: harbor
LAST DEPLOYED: Fri Sep 29 22:22:59 2023
NAMESPACE: harbor
STATUS: deployed
REVISION: 1
TEST SUITE: None
NOTES:
Please wait for several minutes for Harbor deployment to complete.
Then you should be able to visit the Harbor portal at https://harbor.84.201.157.43.nip.io
For more details, please visit https://github.com/goharbor/harbor
```
Я использовал свой домен `hfrog.ru`, чтобы ускорить получение сертификатов.
Созданный сайт доступен по адресу https://harbor.84.201.157.43.hfrog.ru, сертификат действителен.
Там иногда падает база, так что на момент проверки сайт может быть сломан, но страница логина всё равно должна отображаться.

 - Посмотрим на секреты helm с информацией о релизах, они соответствуют истории:
```
$ kubectl get secrets -n harbor -l owner=helm
NAME                           TYPE                 DATA   AGE
sh.helm.release.v1.harbor.v1   helm.sh/release.v1   1      89m
sh.helm.release.v1.harbor.v2   helm.sh/release.v1   1      81m
sh.helm.release.v1.harbor.v3   helm.sh/release.v1   1      39m
sh.helm.release.v1.harbor.v4   helm.sh/release.v1   1      35m
$ helm history harbor -n harbor
REVISION	UPDATED                 	STATUS    	CHART        	APP VERSION	DESCRIPTION
1       	Fri Sep 29 22:22:59 2023	superseded	harbor-1.13.0	2.9.0      	Install complete
2       	Fri Sep 29 22:31:40 2023	superseded	harbor-1.13.0	2.9.0      	Upgrade complete
3       	Fri Sep 29 23:13:29 2023	superseded	harbor-1.13.0	2.9.0      	Upgrade complete
4       	Fri Sep 29 23:17:23 2023	deployed  	harbor-1.13.0	2.9.0      	Upgrade complete
```

## Задание со *

 - написан `helmfile.yaml`
```
$ helmfile init
...
helmfile initialization completed!
$ cat helmfile.yaml
repositories:
- name: ingress-nginx
  url: https://kubernetes.github.io/ingress-nginx
- name: jetstack
  url: https://charts.jetstack.io
- name: harbor
  url: https://helm.goharbor.io

releases:
- name: ingress-nginx
  namespace: ingress-nginx
  chart: ingress-nginx/ingress-nginx
  wait: true
- name: cert-manager
  namespace: cert-manager
  chart: jetstack/cert-manager
  version: v1.13.0
  hooks:
  - events: ['presync']
    command: cert-manager-crds.sh
- name: harbor
  namespace: harbor
  chart: harbor/harbor
  version: 1.13.0
  values:
  - ../harbor/values.yaml
$ helmfile deps
Adding repo ingress-nginx https://kubernetes.github.io/ingress-nginx
"ingress-nginx" has been added to your repositories

Adding repo jetstack https://charts.jetstack.io
"jetstack" has been added to your repositories

Adding repo harbor https://helm.goharbor.io
"harbor" has been added to your repositories

Updating dependency /var/folders/fl/1pwg8mps3wgc9lcd314fshm40000gn/T/594695724
Hang tight while we grab the latest from your chart repositories...
...Successfully got an update from the "chartmuseum" chart repository
...Successfully got an update from the "mychartmuseum" chart repository
...Successfully got an update from the "ingress-nginx" chart repository
...Successfully got an update from the "harbor" chart repository
...Successfully got an update from the "jetstack" chart repository
...Successfully got an update from the "stable" chart repository
Update Complete. ⎈Happy Helming!⎈
Saving 3 charts
Downloading ingress-nginx from repo https://kubernetes.github.io/ingress-nginx
Downloading cert-manager from repo https://charts.jetstack.io
Downloading harbor from repo https://helm.goharbor.io
Deleting outdated charts
$ helmfile lint
Adding repo ingress-nginx https://kubernetes.github.io/ingress-nginx
"ingress-nginx" has been added to your repositories

Adding repo jetstack https://charts.jetstack.io
"jetstack" has been added to your repositories

Adding repo harbor https://helm.goharbor.io
"harbor" has been added to your repositories

Fetching jetstack/cert-manager
Fetching harbor/harbor
Fetching ingress-nginx/ingress-nginx
Linting release=ingress-nginx, chart=/var/folders/fl/1pwg8mps3wgc9lcd314fshm40000gn/T/helmfile588239832/ingress-nginx/ingress-nginx/ingress-nginx/ingress-nginx/latest/ingress-nginx
==> Linting /var/folders/fl/1pwg8mps3wgc9lcd314fshm40000gn/T/helmfile588239832/ingress-nginx/ingress-nginx/ingress-nginx/ingress-nginx/latest/ingress-nginx

1 chart(s) linted, 0 chart(s) failed

Linting release=cert-manager, chart=/var/folders/fl/1pwg8mps3wgc9lcd314fshm40000gn/T/helmfile588239832/cert-manager/cert-manager/jetstack/cert-manager/v1.13.0/cert-manager
==> Linting /var/folders/fl/1pwg8mps3wgc9lcd314fshm40000gn/T/helmfile588239832/cert-manager/cert-manager/jetstack/cert-manager/v1.13.0/cert-manager

1 chart(s) linted, 0 chart(s) failed

Linting release=harbor, chart=/var/folders/fl/1pwg8mps3wgc9lcd314fshm40000gn/T/helmfile588239832/harbor/harbor/harbor/harbor/1.13.0/harbor
==> Linting /var/folders/fl/1pwg8mps3wgc9lcd314fshm40000gn/T/helmfile588239832/harbor/harbor/harbor/harbor/1.13.0/harbor

1 chart(s) linted, 0 chart(s) failed
$ helmfile sync
Adding repo ingress-nginx https://kubernetes.github.io/ingress-nginx
"ingress-nginx" has been added to your repositories

Adding repo jetstack https://charts.jetstack.io
"jetstack" has been added to your repositories

Adding repo harbor https://helm.goharbor.io
"harbor" has been added to your repositories

Upgrading release=ingress-nginx, chart=ingress-nginx/ingress-nginx
Upgrading release=harbor, chart=harbor/harbor
Upgrading release=cert-manager, chart=jetstack/cert-manager
false
Release "harbor" has been upgraded. Happy Helming!
NAME: harbor
LAST DEPLOYED: Sun Oct  1 10:10:35 2023
NAMESPACE: harbor
STATUS: deployed
REVISION: 5
TEST SUITE: None
NOTES:
Please wait for several minutes for Harbor deployment to complete.
Then you should be able to visit the Harbor portal at https://harbor.84.201.157.43.hfrog.ru
For more details, please visit https://github.com/goharbor/harbor

Listing releases matching ^harbor$
false
Release "cert-manager" has been upgraded. Happy Helming!
NAME: cert-manager
LAST DEPLOYED: Sun Oct  1 10:10:34 2023
NAMESPACE: cert-manager
STATUS: deployed
REVISION: 2
TEST SUITE: None
NOTES:
cert-manager v1.13.0 has been deployed successfully!

In order to begin issuing certificates, you will need to set up a ClusterIssuer
or Issuer resource (for example, by creating a 'letsencrypt-staging' issuer).

More information on the different types of issuers and how to configure them
can be found in our documentation:

https://cert-manager.io/docs/configuration/

For information on how to configure cert-manager to automatically provision
Certificates for Ingress resources, take a look at the `ingress-shim`
documentation:

https://cert-manager.io/docs/usage/ingress/

Listing releases matching ^cert-manager$
harbor	harbor   	5       	2023-10-01 10:10:35.01689 +0300 MSK	deployed	harbor-1.13.0	2.9.0

cert-manager	cert-manager	2       	2023-10-01 10:10:34.979262 +0300 MSK	deployed	cert-manager-v1.13.0	v1.13.0

false
Release "ingress-nginx" has been upgraded. Happy Helming!
NAME: ingress-nginx
LAST DEPLOYED: Sun Oct  1 10:10:34 2023
NAMESPACE: ingress-nginx
STATUS: deployed
REVISION: 2
TEST SUITE: None
NOTES:
The ingress-nginx controller has been installed.
It may take a few minutes for the LoadBalancer IP to be available.
You can watch the status by running 'kubectl --namespace ingress-nginx get services -o wide -w ingress-nginx-controller'

An example Ingress that makes use of the controller:
  apiVersion: networking.k8s.io/v1
  kind: Ingress
  metadata:
    name: example
    namespace: foo
  spec:
    ingressClassName: nginx
    rules:
      - host: www.example.com
        http:
          paths:
            - pathType: Prefix
              backend:
                service:
                  name: exampleService
                  port:
                    number: 80
              path: /
    # This section is only required if TLS is to be enabled for the Ingress
    tls:
      - hosts:
        - www.example.com
        secretName: example-tls

If TLS is enabled for the Ingress, a Secret containing the certificate and key must also be provided:

  apiVersion: v1
  kind: Secret
  metadata:
    name: example-tls
    namespace: foo
  data:
    tls.crt: <base64 encoded cert>
    tls.key: <base64 encoded key>
  type: kubernetes.io/tls

Listing releases matching ^ingress-nginx$
ingress-nginx	ingress-nginx	2       	2023-10-01 10:10:34.414643 +0300 MSK	deployed	ingress-nginx-4.8.0	1.9.0


UPDATED RELEASES:
NAME            CHART                         VERSION   DURATION
harbor          harbor/harbor                 1.13.0          9s
cert-manager    jetstack/cert-manager         v1.13.0         9s
ingress-nginx   ingress-nginx/ingress-nginx   4.8.0          22s
```

 - Содаём чарт `hipster-shop` и устанавливаем его
```
$ helm create hipster-shop
Creating hipster-shop
[тут меняем файлы]
$ helm upgrade --install hipster-shop ./hipster-shop --namespace hipster-shop --create-namespace
Release "hipster-shop" does not exist. Installing it now.
NAME: hipster-shop
LAST DEPLOYED: Sat Sep 30 11:42:09 2023
NAMESPACE: hipster-shop
STATUS: deployed
REVISION: 1
TEST SUITE: None
$ kubectl get svc frontend -n hipster-shop
NAME       TYPE       CLUSTER-IP     EXTERNAL-IP   PORT(S)        AGE
frontend   NodePort   10.10.10.147   <none>        80:31541/TCP   2m45s
$ kubectl port-forward svc/frontend -n hipster-shop 8000:80
Forwarding from 127.0.0.1:8000 -> 8080
Forwarding from [::1]:8000 -> 8080
Handling connection for 8000
```
Сайт открывается и работает.

```
$ helm upgrade --install frontend ./frontend --namespace hipster-shop --create-namespace
Release "frontend" does not exist. Installing it now.
NAME: frontend
LAST DEPLOYED: Sat Sep 30 12:16:22 2023
NAMESPACE: hipster-shop
STATUS: deployed
REVISION: 1
TEST SUITE: None
```

 - Поменяем тип сервиса на `ClusterIP` и заодно переделаем ingress на получение сертификата. Сайт https://shop.84.201.157.43.hfrog.ru открывается.

```
$ helm delete frontend -n hipster-shop
release "frontend" uninstalled
```

```
$ helm dep list hipster-shop
NAME    	VERSION	REPOSITORY        	STATUS
frontend	0.1.0  	file://../frontend	missing

$ helm dep update hipster-shop
Hang tight while we grab the latest from your chart repositories...
...Successfully got an update from the "ingress-nginx" chart repository
...Successfully got an update from the "jetstack" chart repository
...Successfully got an update from the "harbor" chart repository
...Successfully got an update from the "stable" chart repository
Update Complete. ⎈Happy Helming!⎈
Saving 1 charts
Deleting outdated charts
$ helm dep list hipster-shop
NAME    	VERSION	REPOSITORY        	STATUS
frontend	0.1.0  	file://../frontend	ok
```

```
$ helm upgrade --install hipster-shop ./hipster-shop -n hipster-shop --create-namespace
false
Release "hipster-shop" has been upgraded. Happy Helming!
NAME: hipster-shop
LAST DEPLOYED: Sat Sep 30 13:05:53 2023
NAMESPACE: hipster-shop
STATUS: deployed
REVISION: 3
TEST SUITE: None
```
Сайт https://shop.84.201.157.43.hfrog.ru открывается.

 - Проверим передачу значений из командной строки, для этого используем `replicas` вместо `nodePort`, т.к. тип сервиса изменён на `ClusterIP`:
```
$ helm upgrade --install hipster-shop ./hipster-shop -n hipster-shop --create-namespace --set frontend.replicas=2
false
Release "hipster-shop" has been upgraded. Happy Helming!
NAME: hipster-shop
LAST DEPLOYED: Sat Sep 30 13:14:19 2023
NAMESPACE: hipster-shop
STATUS: deployed
REVISION: 8
TEST SUITE: None
$ kubectl get deploy frontend -n hipster-shop
NAME       READY   UP-TO-DATE   AVAILABLE   AGE
frontend   2/2     2            2           9m12s
```
Кол-во подов в деплойменте `frontend` увеличилось до 2.

## Задание со *

 - Выносим redis в зависимости. Вместо используемого в helm2 `requirements.yaml` используем `Chart.yaml`. Удалим redis из файла `all-hipster-shop.yaml` и добавим зависимость
```
$ tail -3 hipster-shop/Chart.yaml
- name: redis
  version: 18.1.1
  repository: https://charts.bitnami.com/bitnami
$ helm dependency update
Hang tight while we grab the latest from your chart repositories...
...Successfully got an update from the "chartmuseum" chart repository
...Successfully got an update from the "mychartmuseum" chart repository
...Successfully got an update from the "harbor" chart repository
...Successfully got an update from the "ingress-nginx" chart repository
...Successfully got an update from the "jetstack" chart repository
...Successfully got an update from the "stable" chart repository
Update Complete. ⎈Happy Helming!⎈
Saving 2 charts
Downloading redis from repo https://charts.bitnami.com/bitnami
Deleting outdated charts
```
По умолчанию redis стартует в кластерном режиме с аутентификацией, отключим это передачей настроек через командную строку. Также redis из чарта использует другое название сервиса,
поэтому сервис в `all-hipster-shop.yaml` оставим, изменив селектор на `app.kubernetes.io/name: redis`
```
$ helm upgrade --install hipster-shop -n hipster-shop . --set redis.architecture=standalone --set redis.auth.enabled=false
false
Release "hipster-shop" has been upgraded. Happy Helming!
NAME: hipster-shop
LAST DEPLOYED: Sun Oct  1 11:31:42 2023
NAMESPACE: hipster-shop
STATUS: deployed
REVISION: 18
TEST SUITE: None
```
Можно также перенести эти настройки в файл `Values.yaml`. Сайт работает.

 - Работа с helm-secrets
```
$ gpg --full-generate-key
...
$ gpg -k
[keyboxd]
---------
pub   ed25519 2023-10-01 [SC]
      9B43BB2710F227A40506F19A5B8D911CB96E667F
uid         [  абсолютно ] aaivanov <and@hfrog.ru>
sub   cv25519 2023-10-01 [E]
$ cat secrets.yaml
visibleKey: hiddenValue
$ sops -e -i --pgp 9B43BB2710F227A40506F19A5B8D911CB96E667F secrets.yaml
$ cat secrets.yaml
visibleKey: ENC[AES256_GCM,data:KwBgd0NezUV/rTM=,iv:Z7wq+u0fOX658n8oythN5yq7obOjJ8FXzlTRGtlBNAM=,tag:aPPp3UAgjBaJX9fY1WZFqg==,type:str]
sops:
    kms: []
    gcp_kms: []
    azure_kv: []
    hc_vault: []
    age: []
    lastmodified: "2023-10-01T12:00:18Z"
    mac: ENC[AES256_GCM,data:KI2oVVWlaYoRK+zMpC4/aYp8VjiBjVZ/WJZGSzmjSblptHRsZu8jb3m2KxDyIu+QmR/cx/5KQRM3EQnhe4DmLIGc/zLMjQB9hoH7CaBWG99uXyibHEnd/Ojg/LkuucM7I8kIEMDq+ytW0B3LJvViUf+HcyJu0TvVriB8Dl76tGQ=,iv:Y8pf+5Fr1ewUG6wYl7RnV3avYhHK5B/I/RH9re0QV6g=,tag:t3M2s8mTYfmb21lf2cOtNw==,type:str]
    pgp:
        - created_at: "2023-10-01T12:00:18Z"
          enc: |-
            -----BEGIN PGP MESSAGE-----

            hF4D7RLrnX6o53gSAQdATjxRc8lW2VnYDBeqcqdHvxDXhUsUWqHN9y5bGCLoGDkw
            6NEtQkPabxWVA+Sg69gD7syHjhikN44THpXKjN0rfNjN+088/PtCy0BLEYqt86x/
            1GgBCQIQdzabyn/gTsfABpvKGLNxInufHCKX7O69UfF9WJXJWv8orcnF/EKAGtcE
            /fqoh8svu8cxEzwzGkBnABsmK3JFYsqRXQ1e/72q7OP1H46A19lPzB35BuNmObPK
            YO1Co/crBmUlMQ==
            =PnCs
            -----END PGP MESSAGE-----
          fp: 9B43BB2710F227A40506F19A5B8D911CB96E667F
    unencrypted_suffix: _unencrypted
    version: 3.8.0
$ helm secrets decrypt secrets.yaml && echo
visibleKey: hiddenValue
$ sops -d secrets.yaml
visibleKey: hiddenValue
```
Создадим файл `templates/secret.yaml` и попробуем установить чарт `frontend`
```
$ helm secrets upgrade --install frontend . --namespace=hipster-shop -f secrets.yaml
[helm-secrets] Decrypt: secrets.yaml
Release "frontend" does not exist. Installing it now.
Error: Unable to continue with install: Service "frontend" in namespace "hipster-shop" exists and cannot be imported into the current release: invalid ownership metadata; annotation validation error: key "meta.helm.sh/release-name" must equal "frontend": current value is "hipster-shop"

[helm-secrets] Removed: secrets.yaml.dec
Error: plugin "secrets" exited with error
```
Ошибка. Дело в том, что сервис `frontend` в пространстве имён `hipster-shop` уже существует, мы его развернули как зависимость чарта `hipster-shop`, и отдельно helm его обновить не даёт.
Попробуем его развернуть отдельно
```
$ helm secrets upgrade --install frontend . --namespace=frontend --create-namespace -f secrets.yaml
[helm-secrets] Decrypt: secrets.yaml
false
Error: UPGRADE FAILED: failed to create resource: admission webhook "validate.nginx.ingress.kubernetes.io" denied the request: host "shop.84.201.157.43.hfrog.ru" and path "/" is already defined in ingress hipster-shop/frontend

[helm-secrets] Removed: secrets.yaml.dec
Error: plugin "secrets" exited with error
$ kubectl get secret secret -n frontend -o jsonpath='{.data.visibleKey}' | base64 -d && echo
hiddenValue
```
Установка не прошла из-за ingress, тем не менее секрет успешно создан.
`helm-secrets` можно использовать для расшифровки паролей для аутентификации. Для защиты секретов от записи в репозиторий в открытом виде можно использовать скрипты, запускаемые перед коммитом, и в них проверять, зашифрованы ли данные.

 - Запись чартов в harbor. Мне удалось записать чарты в созданный harbor, но `helm repo add` не работает, видимо есть только поддержка oci, а работа с oci не предполагает repo add, как описано в https://helm.sh/docs/topics/registries/
```
$ helm registry login harbor.84.201.157.43.hfrog.ru
Username: admin
Password:
Login Succeeded
$ helm push hipster-shop/charts/frontend-0.1.0.tgz oci://harbor.84.201.157.43.hfrog.ru/library
Pushed: harbor.84.201.157.43.hfrog.ru/library/frontend:0.1.0
Digest: sha256:ac213d93a3555081b2e4381c16c14f9029816ae3c8f78bdef4527faab82b596c
$ helm package hipster-shop
Successfully packaged chart and saved it to: /Users/aaivanov/Yandex.Disk.localized/Обучение/O/2023 Otus Kubernetes/hfrog_platform/kubernetes-templating/hipster-shop-0.1.0.tgz
$ helm push hipster-shop-0.1.0.tgz oci://harbor.84.201.157.43.hfrog.ru/library
Pushed: harbor.84.201.157.43.hfrog.ru/library/hipster-shop:0.1.0
Digest: sha256:21623c9f0bce723ece3e9c4153a35d33685d99d718b672148a8ff090893d9e63
$ helm repo add templating https://harbor.84.201.157.43.hfrog.ru/chartrepo/library
Error: looks like "https://harbor.84.201.157.43.hfrog.ru/chartrepo/library" is not a valid chart repository or cannot be reached: failed to fetch https://harbor.84.201.157.43.hfrog.ru/chartrepo/library/index.yaml : 404 Not Found
```
Поэтому я записал чарты в chartmuseum и указал его в `repo.sh`
```
$ helm repo list | grep templating
templating   	https://chartmuseum.84.201.157.43.hfrog.ru
$ helm search repo templating
NAME                   	CHART VERSION	APP VERSION	DESCRIPTION
templating/frontend    	0.1.0        	1.16.0     	A Helm chart for Kubernetes
templating/hipster-shop	0.1.0        	1.16.0     	A Helm chart for Kubernetes
```

```
$ kubecfg version
kubecfg version: v0.34.0
jsonnet version: v0.20.0
client-go version: v0.0.0-master+$Format:%H$
```

```
$ kubecfg update services.jsonnet --namespace hipster-shop
INFO  Validating deployments paymentservice
INFO  validate object "apps/v1, Kind=Deployment"
INFO  Validating services paymentservice
INFO  validate object "/v1, Kind=Service"
INFO  Validating deployments shippingservice
INFO  validate object "apps/v1, Kind=Deployment"
INFO  Validating services shippingservice
INFO  validate object "/v1, Kind=Service"
INFO  Fetching schemas for 4 resources
INFO  Creating services paymentservice
INFO  Creating services shippingservice
INFO  Creating deployments paymentservice
INFO  Creating deployments shippingservice
```
Сервис работает.

## Задание со *

 - Сервис `cartservice` переведён на jsonnet с использованием `qbec`. Сначала создаём базовую структуру
```
$ qbec init cartservice
using server URL "https://158.160.12.170" and default namespace "default" for the default environment
wrote cartservice/params.libsonnet
wrote cartservice/environments/base.libsonnet
wrote cartservice/environments/default.libsonnet
wrote cartservice/qbec.yaml
```
Затем создаём параметризованные манифесты на jsonnet в директории `components`, прописываем параметры в `environments/base.libsonnet`, правим namespace в `qbec.yaml`, проверяем и деплоим:
```
$ tree
.
├── components
│   ├── deployment.jsonnet
│   └── service.jsonnet
├── environments
│   ├── base.libsonnet
│   └── default.libsonnet
├── params.libsonnet
└── qbec.yaml
$ qbec show default > manifests.yaml # Смотрим что получилось, отлаживаем
$ qbec apply -n default # Отладочный прогон без применения манифестов
$ qbec apply default
setting cluster to yc-managed-k8s-cat0hmpsqp6rp88iiouh
setting context to yc-otus
cluster metadata load took 812ms
2 components evaluated in 8ms

will synchronize 2 object(s)

Do you want to continue [y/n]: y
2 components evaluated in 5ms
create deployments cartservice -n hipster-shop (source deployment)
create services cartservice -n hipster-shop (source service)
waiting for deletion list to be returned
server objects load took 635ms
---
stats:
  created:
  - deployments cartservice -n hipster-shop (source deployment)
  - services cartservice -n hipster-shop (source service)

waiting for readiness of 1 objects
  - deployments cartservice -n hipster-shop

  0s    : deployments cartservice -n hipster-shop :: 0 of 1 updated replicas are available
✓ 21s   : deployments cartservice -n hipster-shop :: successfully rolled out (0 remaining)

✓ 21s: rollout complete
command took 25.13s
```

 - Переделан на Kustomize сервис `adservice`
```
$ kubectl create ns hipster-shop-dev
namespace/hipster-shop-dev created
$ kubectl apply -k kustomize/overrides/dev
service/dev-adservice created
deployment.apps/dev-adservice created
$ kubectl apply -k kustomize/overrides/prod
service/adservice created
deployment.apps/adservice created
$ kubectl get pods -n hipster-shop-dev
NAME                             READY   STATUS    RESTARTS   AGE
dev-adservice-6d7c7bd86d-x26ft   1/1     Running   0          4m19s
```

## Как проверить работоспособность:

 - Перейти по ссылке https://chartmuseum.84.201.157.43.nip.io
 - Перейти по ссылке https://chartmuseum.84.201.157.43.hfrog.ru
 - Перейти по ссылке https://harbor.84.201.157.43.hfrog.ru
 - Перейти по ссылке https://shop.84.201.157.43.hfrog.ru

# Выполнено ДЗ №7

 - [*] Основное ДЗ
 - [*] Задание с Python
 - [*] Задание со *

## В процессе сделано:

 - Создадим манифест с несуществующим типом ресурса и попробуем применить его, выдаётся ошибка:
```
$ kubectl apply -f deploy/cr.yml
error: resource mapping not found for name: "mysql-instance" namespace: "" from "deploy/cr.yml": no matches for kind "MySQL" in version "otus.homework/v1"
ensure CRDs are installed first
```

 - Создадим манифест с CRD из ДЗ и попробуем применить его, выдаётся ошибка:
```
$ kubectl apply -f deploy/crd.yml
error: resource mapping not found for name: "mysqls.otus.homework" namespace: "" from "deploy/crd.yml": no matches for kind "CustomResourceDefinition" in version "apiextensions.k8s.io/v1beta1"
ensure CRDs are installed first
```
Версия `apiextensions.k8s.io/v1beta1` более не работает, узнаем текущую через `kubectl api-resources` и поменяем:
```
$ kubectl api-resources | grep -i custom
customresourcedefinitions         crd,crds            apiextensions.k8s.io/v1                false        CustomResourceDefinition
$ kubectl apply -f deploy/crd.yml
The CustomResourceDefinition "mysqls.otus.homework" is invalid: spec.versions[0].schema.openAPIV3Schema: Required value: schemas are required
```
В текущей версии схема обязательна, добавим её
```
$ cat deploy/crd.yml
apiVersion: apiextensions.k8s.io/v1
kind: CustomResourceDefinition
metadata:
  name: mysqls.otus.homework # имя CRD должно иметь формат plural.group
spec:
  scope: Namespaced
  group: otus.homework
  names:
    kind: MySQL
    plural: mysqls
    singular: mysql
    shortNames:
    - ms
  versions:
  - name: v1
    served: true
    storage: true
    schema:
      openAPIV3Schema:
        type: object
        properties:
          spec:
            type: object
            properties:
              image:
                type: string
              database:
                type: string
              password:
                type: string
              storage_size:
                type: string
$ kubectl apply -f deploy/crd.yml
customresourcedefinition.apiextensions.k8s.io/mysqls.otus.homework created
```
Определение ресурса успешно создано.

 - Снова пробуем создать кастомный ресурс
```
$ kubectl apply -f deploy/cr.yml
Error from server (BadRequest): error when creating "deploy/cr.yml": MySQL in version "v1" cannot be handled as a MySQL: strict decoding error: unknown field "useless_data"
```
В манифесте содержится поле `useless_data` вне спецификации, удалим его и проверим снова
```
$ kubectl apply -f deploy/cr.yml
mysql.otus.homework/mysql-instance created
```

 - Посмотрим, существуют ли созданные объекты и взглянем на описание
```
$ kubectl get crd | grep mysql
mysqls.otus.homework                             2023-10-07T14:48:03Z
$ kubectl get mysql
NAME             AGE
mysql-instance   64s
$ kubectl describe mysql mysql-instance
Name:         mysql-instance
Namespace:    default
Labels:       <none>
Annotations:  <none>
API Version:  otus.homework/v1
Kind:         MySQL
Metadata:
  Creation Timestamp:  2023-10-07T14:50:16Z
  Generation:          1
  Resource Version:    4071622
  UID:                 11f2b8b2-cb57-498e-b31c-a55bac388f07
Spec:
  Database:      otus-database
  Image:         mysql:5.7
  Password:      otuspassword
  storage_size:  1Gi
Events:          <none>
```
Значения полей соответствуют указанным в `cr.yml`

 - Уберём `password` из `cr.yml` и применим его снова, применяется успешно, пароля нет:
```
$ kubectl apply -f deploy/cr.yml
mysql.otus.homework/mysql-instance configured
$ kubectl get mysql mysql-instance -o jsonpath='{.spec}' | jq
{
  "database": "otus-database",
  "image": "mysql:5.7",
  "storage_size": "1Gi"
}
```

 - Добавим требование пароля в схеме и проверим
```
$ cat deploy/crd.yml
...
        properties:
          spec:
            type: object
            required:
            - password
            properties:
              image:
                type: string
...
$ kubectl apply -f deploy/crd.yml
customresourcedefinition.apiextensions.k8s.io/mysqls.otus.homework configured
$ kubectl apply -f deploy/cr.yml
mysql.otus.homework/mysql-instance unchanged
$ kubectl delete mysql mysql-instance
mysql.otus.homework "mysql-instance" deleted
$ kubectl apply -f deploy/cr.yml
The MySQL "mysql-instance" is invalid: spec.password: Required value
```
Существующий объект остаётся без изменений, а новый уже не создаётся. Вернём пароль обратно.

 - Напишем контроллер `build/mysql-operator.py`, создадим требуемые шаблоны, установим требуемые питоновские пакеты через `pip` и запустим его
```
$ kopf run mysql-operator.py
/Library/Python/3.9/site-packages/kopf/_core/reactor/running.py:179: FutureWarning: Absence of either namespaces or cluster-wide flag will become an error soon. For now, switching to the cluster-wide mode for backward compatibility.
  warnings.warn("Absence of either namespaces or cluster-wide flag will become an error soon."
[2023-10-07 20:18:00,761] kopf._core.engines.a [INFO    ] Initial authentication has been initiated.
[2023-10-07 20:18:01,698] kopf.activities.auth [INFO    ] Activity 'login_via_client' succeeded.
[2023-10-07 20:18:01,699] kopf._core.engines.a [INFO    ] Initial authentication has finished.
```

 - Адаптируем шаблоны mysql PV и PVC к Яндекс облаку.
По смыслу ДЗ том, используемый для базы, не должен быть постоянным т.к. мы базу бэкапим и восстанавливаем, поэтому сделаем его динамическим,
и просто удалим `mysql-pv.yml.j2` вместе с поддержкой его в контроллере. А в PVC удалим более ненужный селектор для привязки PV и PVC по метке,
а также добавим класс хранилища `storageClassName: yc-network-hdd`

 - Создадим кастомный ресурс mysql и посмотрим логи контроллера
```
[2023-10-07 20:24:01,214] kopf.objects         [INFO    ] [default/mysql-instance] Handler 'mysql_on_create' succeeded.
[2023-10-07 20:24:01,214] kopf.objects         [INFO    ] [default/mysql-instance] Creation is processed: 1 succeeded; 0 failed.
```
Если во время запуска контроллера кастомный ресурс уже существует, обработчик всё равно вызывается, и в нашем случае выдаёт ошибку создания деплоя, PV, PVC и сервиса.
Идемпотентность создания надо специально обеспечить, не пытаясь создавать уже существующие ресурсы.
В отслеживаемые кастомные ресурсы контроллер добавляет свою аннотацию, например
```
Annotations:  kopf.zalando.org/last-handled-configuration:
                {"spec":{"database":"otus-database","image":"mysql:5.7","password":"very_secret_password","storage_size":"1Gi"}}
```
Когда контроллер стартует, он вызывает обработчики для ресурсов без аннотаций или если их состояние с тех пор изменилось,
этим объясняется вызов обработчика для уже существующего ресурса. См. https://kopf.readthedocs.io/en/stable/continuity/#downtime
Кстати, есть возможность написать обработчик для события 'Resume', он вызывается как раз когда контроллер стартует и обнаруживает существующий объект с аннотацией:
```
@kopf.on.resume('otus.homework', 'v1', 'mysqls')
def mysql_on_resume(body, spec, **kwargs):
    kopf.info(body, reason='Resume', message='Resume handler is called')
```
Вот как выглядят эти события в описании ресурса:
```
$ kubectl describe mysql mysql-instance | tail -6
  Normal  Logging  7m25s  kopf  Resuming is processed: 1 succeeded; 0 failed.
  Normal  Resume   7m25s  kopf  Resume handler is called
  Normal  Logging  7m25s  kopf  Handler 'mysql_on_resume' succeeded.
  Normal  Logging  4m25s  kopf  Resuming is processed: 1 succeeded; 0 failed.
  Normal  Resume   4m25s  kopf  Resume handler is called
  Normal  Logging  4m25s  kopf  Handler 'mysql_on_resume' succeeded.
```

 - Удалим кастомный ресурс `mysql-instance`, убедимся что созданные контроллером ресурсы не удалены и удалим их руками
```
$ kubectl delete mysql mysql-instance
mysql.otus.homework "mysql-instance" deleted
$ kubectl get all | grep mysql
pod/mysql-instance-7c5cf946cb-4w66c   1/1     Running   0          3m36s
service/mysql-instance   ClusterIP   None           <none>        3306/TCP   3m36s
deployment.apps/mysql-instance   1/1     1            1           3m36s
replicaset.apps/mysql-instance-7c5cf946cb   1         1         1       3m36s
$ kubectl get pv | grep mysql
pvc-d81b1d03-4f7d-455d-ac22-66cd482646a4   1Gi        RWO            Delete           Bound       default/mysql-instance-pvc               yc-network-hdd            3m40s
$ kubectl get pvc | grep mysql
mysql-instance-pvc   Bound    pvc-d81b1d03-4f7d-455d-ac22-66cd482646a4   1Gi        RWO            yc-network-hdd   3m50s
$ kubectl delete deploy mysql-instance
deployment.apps "mysql-instance" deleted
$ kubectl delete svc mysql-instance
service "mysql-instance" deleted
$ kubectl delete pvc mysql-instance-pvc
persistentvolumeclaim "mysql-instance-pvc" deleted
```
PV через непродолжительное время удаляется автоматически, т.к. был создан динамически.

 - Добавим в обработчик создания ресурса добавление связей а также обработчик удаления, и проверим:
```
$ kubectl apply -f deploy/cr.yml
mysql.otus.homework/mysql-instance created
$ kubectl delete mysql mysql-instance
mysql.otus.homework "mysql-instance" deleted
$ kubectl get all | grep mysql
$ kubectl get pvc | grep mysql
$ kubectl get pv | grep mysql
[лог контроллера]
[2023-10-07 22:43:16,444] kopf.objects         [INFO    ] [default/mysql-instance] Handler 'mysql_on_create' succeeded.
[2023-10-07 22:43:16,445] kopf.objects         [INFO    ] [default/mysql-instance] Creation is processed: 1 succeeded; 0 failed.
[2023-10-07 22:46:27,808] kopf.objects         [INFO    ] [default/mysql-instance] Handler 'delete_object_make_backup' succeeded.
[2023-10-07 22:46:27,808] kopf.objects         [INFO    ] [default/mysql-instance] Deletion is processed: 1 succeeded; 0 failed.
[2023-10-07 22:46:27,953] kopf.objects         [WARNING ] [default/mysql-instance] Patching failed with inconsistencies: (('remove', ('status',), {'delete_object_make_backup': {'message': 'mysql and its children resources deleted'}}, None),)
```

 - Добавим в контроллер код создания PV и PVC для бэкапа, создание задачи восстановления при создании ресурса и её зависимость,
   функцию удаления успешно завершённых задач (Job), функцию ожидания завершения задачи.
   Также добавим в обработчике удаления CR MySQL удаление успешных задач, создание задачи бэкапа и ожидание её завершения.

 - Создадим ресурс и проверим наличие томов:
```
$ kubectl get pv
NAME                                       CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM                               STORAGECLASS     REASON   AGE
backup-mysql-instance-pv                   2Gi        RWO            Retain           Bound    default/backup-mysql-instance-pvc   yc-network-hdd            2d23h
pvc-e85dc75d-c8ef-4736-b202-bd8f2cfcb9bf   1Gi        RWO            Delete           Bound    default/mysql-instance-pvc          yc-network-hdd            23m
$ kubectl get pvc
NAME                        STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS     AGE
backup-mysql-instance-pvc   Bound    backup-mysql-instance-pv                   2Gi        RWO            yc-network-hdd   2d23h
mysql-instance-pvc          Bound    pvc-e85dc75d-c8ef-4736-b202-bd8f2cfcb9bf   1Gi        RWO            yc-network-hdd   23m
```
Здесь `backup-mysql-instance-pv` это статический том, созданный на явно созданном диске Яндекс облака, а `pvc-e85dc75d-c8ef-4736-b202-bd8f2cfcb9bf` это
динамический том, созданный по заявке `mysql-instance-pvc`.
Кстати, я немного поменял команду в заче восстановления, чтобы она успешно выходила в случае отсутствия файла для восстановления. В противном случае задача будет
пытаться запускаться снова и снова.

 - Подключимся к базе, создадим таблицу и заполним её данными
```
$ kubectl get pods
NAME                               READY   STATUS      RESTARTS   AGE
mysql-instance-7c5cf946cb-gghg4    1/1     Running     0          29m
restore-mysql-instance-job-mrz4c   0/1     Completed   0          29m
$ kubectl exec -ti mysql-instance-7c5cf946cb-gghg4 -- bash
bash-4.2# mysql -p otus-database
Enter password:
Welcome to the MySQL monitor.  Commands end with ; or \g.
Your MySQL connection id is 2
Server version: 5.7.43 MySQL Community Server (GPL)

Copyright (c) 2000, 2023, Oracle and/or its affiliates.

Oracle is a registered trademark of Oracle Corporation and/or its
affiliates. Other names may be trademarks of their respective
owners.

Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.

mysql> show tables;
Empty set (0.00 sec)

mysql> CREATE TABLE test (
    ->      id smallint unsigned not null auto_increment, name varchar(20) not null, constraint
    ->      pk_example primary key (id) );
Query OK, 0 rows affected (0.03 sec)

mysql> describe test;
+-------+----------------------+------+-----+---------+----------------+
| Field | Type                 | Null | Key | Default | Extra          |
+-------+----------------------+------+-----+---------+----------------+
| id    | smallint(5) unsigned | NO   | PRI | NULL    | auto_increment |
| name  | varchar(20)          | NO   |     | NULL    |                |
+-------+----------------------+------+-----+---------+----------------+
2 rows in set (0.01 sec)

mysql> INSERT INTO test ( id, name ) VALUES ( null, 'some data' );
Query OK, 1 row affected (0.00 sec)

mysql> INSERT INTO test ( id, name ) VALUES ( null, 'some data-2' );
Query OK, 1 row affected (0.00 sec)

mysql> INSERT INTO test ( id, name ) VALUES ( null, '333' );
Query OK, 1 row affected (0.02 sec)

mysql> select * from test;
+----+-------------+
| id | name        |
+----+-------------+
|  1 | some data   |
|  2 | some data-2 |
|  3 | 333         |
+----+-------------+
3 rows in set (0.00 sec)
```

 - Удалим ресурс MySQL mysql-instance и посмотрим вывод контроллера
```
$ kubectl delete mysql mysql-instance
mysql.otus.homework "mysql-instance" deleted
[тут пауза, пока работает задача бэкапа]
```

```
start deletion
job with name backup-mysql-instance-job found, wait until end
job with name backup-mysql-instance-job found, wait until end
job with name backup-mysql-instance-job found, wait until end
job with name backup-mysql-instance-job found, wait until end
job with name backup-mysql-instance-job found, wait until end
job with name backup-mysql-instance-job found, wait until end
job with name backup-mysql-instance-job found, wait until end
job with name backup-mysql-instance-job found, wait until end
job with name backup-mysql-instance-job found, wait until end
job with name backup-mysql-instance-job found, wait until end
job with name backup-mysql-instance-job found, wait until end
job with name backup-mysql-instance-job found, wait until end
job with name backup-mysql-instance-job found, wait until end
job with name backup-mysql-instance-job found, wait until end
job with name backup-mysql-instance-job found, wait until end
job with backup-mysql-instance-job is successful
[2023-10-11 21:01:10,350] kopf.objects         [INFO    ] [default/mysql-instance] Handler 'delete_object_make_backup' succeeded.
[2023-10-11 21:01:10,350] kopf.objects         [INFO    ] [default/mysql-instance] Deletion is processed: 1 succeeded; 0 failed.
```

 - Посмотрим список томов
```
$ kubectl get pv
NAME                       CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM                               STORAGECLASS     REASON   AGE
backup-mysql-instance-pv   2Gi        RWO            Retain           Bound    default/backup-mysql-instance-pvc   yc-network-hdd            2d23h
```
Остался один статический том с бэкапом, динамический с базой удалён

 - Посмотрим список задач
```
$ kubectl get jobs
NAME                        COMPLETIONS   DURATION   AGE
backup-mysql-instance-job   1/1           15s        4m47s
```
Задача бэкапа выполнена успешно

 - Заново создадим `mysql-instance`
```
$ kubectl apply -f deploy/cr.yml
mysql.otus.homework/mysql-instance created
```

 - Посмотрим список задач
```
$ kubectl get jobs
NAME                         COMPLETIONS   DURATION   AGE
backup-mysql-instance-job    1/1           15s        8m22s
restore-mysql-instance-job   1/1           56s        85s
```
Задача восстановления выполнена успешно

 - Проверим наличие данных в таблице
```
$ kubectl exec -ti $(kubectl get pods -l app=mysql-instance -o jsonpath='{.items[*].metadata.name}') -- bash
bash-4.2# mysql -p otus-database
Enter password:
Reading table information for completion of table and column names
You can turn off this feature to get a quicker startup with -A

Welcome to the MySQL monitor.  Commands end with ; or \g.
Your MySQL connection id is 3
Server version: 5.7.43 MySQL Community Server (GPL)

Copyright (c) 2000, 2023, Oracle and/or its affiliates.

Oracle is a registered trademark of Oracle Corporation and/or its
affiliates. Other names may be trademarks of their respective
owners.

Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.

mysql> show tables;
+-------------------------+
| Tables_in_otus-database |
+-------------------------+
| test                    |
+-------------------------+
1 row in set (0.00 sec)

mysql> select * from test;
+----+-------------+
| id | name        |
+----+-------------+
|  1 | some data   |
|  2 | some data-2 |
|  3 | 333         |
+----+-------------+
3 rows in set (0.00 sec)
```

 - Создадим `Dockerfile`, образ из него и выгрузим в docker hub
```
$ docker build --tag hfrog/crd-mysql-controller:0.0.1 .
[+] Building 1.2s (10/10) FINISHED                                                                                                                     docker:desktop-linux
...
$ docker images
REPOSITORY                   TAG       IMAGE ID       CREATED              SIZE
hfrog/crd-mysql-controller   0.0.1     52c942827a15   About a minute ago   1.06GB
$ docker push hfrog/crd-mysql-controller:0.0.1
The push refers to repository [docker.io/hfrog/crd-mysql-controller]
...
0.0.1: digest: sha256:6953e86b92e5719a343f1ebe3eec6721d54eeadc757fddcc149c90df2f0f4146 size: 2635
```

 - Создадим манифесты для деплоймента контроллера из созданного образа, сервисной учётки, роли и привязки, и применим их
```
$ kubectl apply -f service-account.yml
serviceaccount/mysql-operator created
$ kubectl apply -f role.yml
clusterrole.rbac.authorization.k8s.io/mysql-operator created
$ kubectl apply -f role-binding.yml
clusterrolebinding.rbac.authorization.k8s.io/workshop-operator created
$ kubectl apply -f deploy-operator.yml
deployment.apps/mysql-operator created
```

 - Снова создадим `mysql-instance`
```
$ kubectl apply -f cr.yml
mysql.otus.homework/mysql-instance created
```

 - Проверим, что создался том для базы
```
$ kubectl get pv
NAME                                       CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM                               STORAGECLASS     REASON   AGE
backup-mysql-instance-pv                   2Gi        RWO            Retain           Bound    default/backup-mysql-instance-pvc   yc-network-hdd            3d
pvc-b020d206-ee54-403a-bd48-961089eb5f62   1Gi        RWO            Delete           Bound    default/mysql-instance-pvc          yc-network-hdd            65s
$ kubectl get pvc
NAME                        STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS     AGE
backup-mysql-instance-pvc   Bound    backup-mysql-instance-pv                   2Gi        RWO            yc-network-hdd   3d
mysql-instance-pvc          Bound    pvc-b020d206-ee54-403a-bd48-961089eb5f62   1Gi        RWO            yc-network-hdd   77s
```

 - Подключимся к базе, проверим что в ней есть старые данные и дозапишем новые
```
$ kubectl exec -ti $(kubectl get pods -l app=mysql-instance -o jsonpath='{.items[*].metadata.name}') -- bash
bash-4.2# mysql -p otus-database
Enter password:
...
mysql> select * from test;
+----+-------------+
| id | name        |
+----+-------------+
|  1 | some data   |
|  2 | some data-2 |
|  3 | 333         |
+----+-------------+
3 rows in set (0.00 sec)

mysql> INSERT INTO test ( id, name) VALUES ( null, '444' );
Query OK, 1 row affected (0.00 sec)

mysql> select * from test;
+----+-------------+
| id | name        |
+----+-------------+
|  1 | some data   |
|  2 | some data-2 |
|  3 | 333         |
|  4 | 444         |
+----+-------------+
4 rows in set (0.00 sec)
```

 - Удалим ресурс MySQL `mysql-instance` и убедимся что том базы исчез
```
$ kubectl delete mysql mysql-instance
mysql.otus.homework "mysql-instance" deleted
$ kubectl get pv
NAME                                       CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS     CLAIM                               STORAGECLASS     REASON   AGE
backup-mysql-instance-pv                   2Gi        RWO            Retain           Bound      default/backup-mysql-instance-pvc   yc-network-hdd            3d
pvc-b020d206-ee54-403a-bd48-961089eb5f62   1Gi        RWO            Delete           Released   default/mysql-instance-pvc          yc-network-hdd            7m30s
$ kubectl get pvc
NAME                        STATUS   VOLUME                     CAPACITY   ACCESS MODES   STORAGECLASS     AGE
backup-mysql-instance-pvc   Bound    backup-mysql-instance-pv   2Gi        RWO            yc-network-hdd   3d
```
Он в состоянии `Released` и пропадёт через минуту или около того

 - И опять создадим `mysql-instance`, дождёмся завершения задачи восстановления, подключимся к базе и посмотрим, есть ли там свежие данные
```
$ kubectl apply -f cr.yml
mysql.otus.homework/mysql-instance created
$ kubectl get pods
NAME                               READY   STATUS      RESTARTS   AGE
backup-mysql-instance-job-b2pgc    0/1     Completed   0          4m41s
mysql-instance-7c5cf946cb-9mswf    1/1     Running     0          114s
mysql-operator-7b74c55fcf-gwdfm    1/1     Running     0          14m
restore-mysql-instance-job-9jb8l   0/1     Completed   3          114s
$ kubectl exec -ti mysql-instance-7c5cf946cb-9mswf -- bash
bash-4.2# mysql -p otus-database
Enter password:
...
mysql> select * from test;
+----+-------------+
| id | name        |
+----+-------------+
|  1 | some data   |
|  2 | some data-2 |
|  3 | 333         |
|  4 | 444         |
+----+-------------+
4 rows in set (0.00 sec)
```
Всё в норме.

 - Посмотрим список задач
```
$ kubectl get jobs
NAME                         COMPLETIONS   DURATION   AGE
backup-mysql-instance-job    1/1           17s        8m19s
restore-mysql-instance-job   1/1           55s        5m31s
```

## Задание со *

 - Для добавления статуса в CRD добавим `schema.openAPIV3Schema.x-kubernetes-preserve-unknown-fields: true` и `subresources.status: {}` в `.spec.versions[]`:
```
apiVersion: apiextensions.k8s.io/v1
kind: CustomResourceDefinition
...
spec:
...
  versions:
...
    schema:
      openAPIV3Schema:
        type: object
        x-kubernetes-preserve-unknown-fields: true
...
    subresources:
      status: {}
```
 Статус будем менять установкой `patch.status['Kopf']` после создания CR, а также по таймеру, опрашивая статусы задач бэкапа и восстановления:
```
def mysql_on_create(body, patch, **kwargs):
...
  patch.status['Kopf'] = 'Init'
...
@kopf.timer('otus.homework', 'v1', 'mysqls', interval=1)
def get_jobs_status(body, spec, patch, **kwargs):
    name = body['metadata']['name']
    if does_job_exist(f'backup-{name}-job') and not is_job_succeeded(f'backup-{name}-job'):
        patch.status['Kopf'] = 'Doing backup'
    if does_job_exist(f'restore-{name}-job') and not is_job_succeeded(f'restore-{name}-job'):
        patch.status['Kopf'] = 'Doing restore'
    else:
        patch.status['Kopf'] = 'Ready'
```

 - Проверим статус в процессе создания CR командой `kubectl describe mysqls mysql-instance | grep -A 5 ^Status`:
```
Status:
  Kopf:  Doing restore
Events:
  Type    Reason   Age   From  Message
  ----    ------   ----  ----  -------
  Normal  Logging  2s    kopf  Timer 'get_jobs_status' succeeded.
```

```
Status:
  Kopf:  Doing restore
Events:
  Type    Reason   Age   From  Message
  ----    ------   ----  ----  -------
  Normal  Logging  69s   kopf  Timer 'get_jobs_status' succeeded.
```

```
Status:
  Kopf:  Ready
Events:
  Type    Reason   Age   From  Message
  ----    ------   ----  ----  -------
  Normal  Logging  72s   kopf  Timer 'get_jobs_status' succeeded.

```
Стоит отметить, что при удалении статус не выставляется. Есть несколько мест, где бы его можно было выставить, но нигде не работает:
Функция `delete_object_make_backup` завершается только после удаления CR, а статус выставляется как раз после завершения функции.
Таймер перестаёт вызываться. Ещё один обработчик `kopf.on.delete` также завершается вместе с удалением CR.
Скорее все способ есть, просто я не нашёл. Если знаете - скажите)

## Задание со *

 - Реализуем смену пароля в базе при изменении CR, сделаем это через отдельную задачу `change-password-mysql-instance-job`.
Задача будет запускать команду смена пароля `mysql -u root -h {{ name }} -p{{ old_password }} {{ database }} -e 'set password for \"root\"@\"%\" = \"{{ new_password }}\";'`.
Также добавим обрабочик изменения пароля в наш оператор:
```
@kopf.on.field('otus.homework', 'v1', 'mysqls', field='spec.password')
def change_password(body, old, new, **kwargs):
...
```
Обработчик удаляет завершённые задачи, создаёт задачу изменения пароля и ждёт её завершения.
Старый пароль передаётся параметром `old', новый - параметром `new`.
Также в таймер добавлена установка статуса `Changing password` если задача смены пароля активна.

- Проверим:
```
$ kubectl apply -f deploy/cr.yml
mysql.otus.homework/mysql-instance configured
[вывод контроллера]
[2023-10-13 20:40:28,768] kopf.objects         [INFO    ] [default/mysql-instance] Timer 'get_jobs_status' succeeded.
start deletion
[2023-10-13 20:40:30,623] kopf.objects         [INFO    ] [default/mysql-instance] Timer 'get_jobs_status' succeeded.
job with name change-password-mysql-instance-job found, waiting until end
job with name change-password-mysql-instance-job found, waiting until end
[2023-10-13 20:40:32,521] kopf.objects         [INFO    ] [default/mysql-instance] Timer 'get_jobs_status' succeeded.
job with name change-password-mysql-instance-job found, waiting until end
job with name change-password-mysql-instance-job found, waiting until end
job with change-password-mysql-instance-job is successful
[2023-10-13 20:40:34,173] kopf.objects         [INFO    ] [default/mysql-instance] Handler 'change_password/spec.password' succeeded.
[2023-10-13 20:40:34,173] kopf.objects         [INFO    ] [default/mysql-instance] Updating is processed: 1 succeeded; 0 failed.
[2023-10-13 20:40:34,241] kopf.objects         [INFO    ] [default/mysql-instance] Timer 'get_jobs_status' succeeded.
[2023-10-13 20:40:35,939] kopf.objects         [INFO    ] [default/mysql-instance] Timer 'get_jobs_status' succeeded.
```
Задача успешно отработала, пароль изменён.
Также собран и выгружен в Docker hub новый образ с контроллером `hfrog/crd-mysql-controller:0.0.3`

# Выполнено ДЗ №8

 - [*] Основное ДЗ (Can i play, daddy?)
 - [*] Основное ДЗ (Bring`em on!)

## В процессе сделано:

 - Создан образ nginx, который умеет отдавать статус по пути `/basic_status`.
   `Dockerfile` и конфиг nginx лежат в директории `build`. Образ выложен в docker hub, называется `hfrog/nginx-with-metrics:1.25.2`.

 - Выполним задание двумя способами, установкой пакета helm и примененением манифестов `prometheus-operator`. Сначала helm. Создадим файл `values.yaml`, в котором
   включим grafana и настроим её и prometheus на использование постоянных дисков. Также зададим пароль для grafana. Файл лежит в директории `helm3`.
   Перейдём в эту директорию и установим prometheus в namespace prometheus:
```
$ helm upgrade --install prometheus prometheus-community/kube-prometheus-stack --namespace=prometheus --create-namespace --values values.yaml --wait
Release "prometheus" does not exist. Installing it now.
NAME: prometheus
LAST DEPLOYED: Fri Nov 10 20:02:50 2023
NAMESPACE: prometheus
STATUS: deployed
REVISION: 1
NOTES:
kube-prometheus-stack has been installed. Check its status by running:
  kubectl --namespace prometheus get pods -l "release=prometheus"

Visit https://github.com/prometheus-operator/kube-prometheus for instructions on how to create & configure Alertmanager and Prometheus instances using the Operator.
```

 - Напишем манифест для деплоймента `nginx-with-exporter` с двумя контейнерами `nginx` и `exporter`. Если сделать два разных деплоймента,
   один с nginx и другой с экспортером, то не будет однозначного соответствия между подами exporter и nginx, и потенциально каждый экспортер будет собирать информацию
   то с одного nginx, то с другого, что вызовет путаницу в метриках. Контейнер `nginx` использует ранее созданный образ и работает на 80-м порту,
   а контейнер `exporter` использует штатный образ и работает на порту 9113.
   Файл лежит в `helm3/01-nginx-with-exporter-deployment.yaml`. Применим его как обычно
```
$ kubectl apply -f 01-nginx-with-exporter-deployment.yaml
deployment.apps/nginx-with-exporter created
```

 - Напишем манифест для сервиса `nginx-with-exporter`, обслуживающий два порта, боевой 80-й и 9113 для метрик.
   Файл лежит в `helm3/02-nginx-with-exporter-service.yaml`. Применяем.
```
$ kubectl apply -f 02-nginx-with-exporter-service.yaml
service/nginx-with-exporter created
```

 - Создадим файл с описанием ServiceMonitor, который будет мониторить наш `nginx-with-exporter`. Для того, чтобы prometheus его принял,
   необходимо добавить метку `release: prometheus`, где `prometheus` это название нашей инсталляции прометея, указанное ранее при запуске helm.
   Это особенность `kube-prometheus-stack`, она настраивается, но по умолчанию так. Файл лежит в `helm3/03-service-monitor-helm.yaml`. Применяем.
```
$ kubectl apply -f 03-service-monitor-helm.yaml
servicemonitor.monitoring.coreos.com/nginx-with-exporter configured
```

 - Зайдём в web-интерфейс prometheus по URL http://localhost:9090. Для этого настроим port-forward
```
$ kubectl port-forward svc/prometheus-kube-prometheus-prometheus -n prometheus 9090:9090
Forwarding from 127.0.0.1:9090 -> 9090
Forwarding from [::1]:9090 -> 9090
```
  Страница открывается, в Status/Targets видны наши nginx экспортеры: `serviceMonitor/default/nginx-with-exporter/0 (3/3 up)`.
  Выполнив `nginx_up` на основной странице, получим список из трёх элементов, соответствующим репликам деплоймента, например
  `nginx_up{container="exporter", endpoint="9113", instance="172.16.152.58:9113", job="nginx-with-exporter", namespace="default", pod="nginx-with-exporter-7cbbd4445-fbbb5", service="nginx-with-exporter"}`.

 - Зайдём в web-интерфейс grafana по URL http://localhost:3000 c логином `admin` и указанным в `values.yaml` паролем. Для этого также настроим port-forward
```
$ kubectl port-forward svc/prometheus-grafana -n prometheus 3000:80
Forwarding from 127.0.0.1:3000 -> 3000
Forwarding from [::1]:3000 -> 3000
```
  Из коробки в папке General доступно множество системных куберовских досок. Скачаем штатную доску для nginx-exporter отсюда https://grafana.com/grafana/dashboards/12708-nginx/
  и импортируем её в графану. Доска работает, показывая поды и метрики. Снимок экрана доступен тут https://jmp.sh/s/kkbaE2Zdayq2l21phCep, не знаю сколько он будет храниться.

 - Удалим всё созданное и повторим через `prometheus-operator`.

 - Скачаем https://github.com/prometheus-operator/prometheus-operator/blob/main/bundle.yaml, сохраним в `prometheus-operator/bundle-0.69.yaml`,
   поменяем в нём namespace с `default` на `prometheus`, создадим namespace `prometheus` и применим файл с манифестами:
```
$ kubectl create namespace prometheus
namespace/prometheus created
$ kubectl create -f bundle-0.69.yaml
customresourcedefinition.apiextensions.k8s.io/alertmanagerconfigs.monitoring.coreos.com created
customresourcedefinition.apiextensions.k8s.io/alertmanagers.monitoring.coreos.com created
customresourcedefinition.apiextensions.k8s.io/podmonitors.monitoring.coreos.com created
customresourcedefinition.apiextensions.k8s.io/probes.monitoring.coreos.com created
customresourcedefinition.apiextensions.k8s.io/prometheusagents.monitoring.coreos.com created
customresourcedefinition.apiextensions.k8s.io/prometheuses.monitoring.coreos.com created
customresourcedefinition.apiextensions.k8s.io/prometheusrules.monitoring.coreos.com created
customresourcedefinition.apiextensions.k8s.io/scrapeconfigs.monitoring.coreos.com created
customresourcedefinition.apiextensions.k8s.io/servicemonitors.monitoring.coreos.com created
customresourcedefinition.apiextensions.k8s.io/thanosrulers.monitoring.coreos.com created
clusterrolebinding.rbac.authorization.k8s.io/prometheus-operator created
clusterrole.rbac.authorization.k8s.io/prometheus-operator created
deployment.apps/prometheus-operator created
serviceaccount/prometheus-operator created
service/prometheus-operator created
```

 - Снова применим `01-nginx-with-exporter-deployment.yaml` и `02-nginx-with-exporter-service.yaml`, содержимое то же самое
```
$ kubectl apply -f 01-nginx-with-exporter-deployment.yaml
deployment.apps/nginx-with-exporter created
$ kubectl apply -f 02-nginx-with-exporter-service.yaml
service/nginx-with-exporter created
```

 - Взяв за основу https://github.com/prometheus-operator/prometheus-operator/blob/main/Documentation/user-guides/getting-started.md,
   напишем манифесты для сервисной учётки и кластерной роли `prometheus`, соответствующей ClusterRoleBinding; затем кастомный ресурс Prometheus,
   использующий созданную сервисную учётку и фильтром сервисных мониторов по метке `otus: homework`, сервис для него и наконец ServiceMonitor
   с меткой `otus: homework`, который ищет во всех пространствах имён сервисы с метками `app: nginx-with-exporter`.
   Всё лежит в директории `prometheus-operator`. Применяем.
```
$ kubectl apply -f 03-service-account.yaml
serviceaccount/prometheus created

$ kubectl apply -f 04-clusterrole.yaml
clusterrole.rbac.authorization.k8s.io/prometheus created

$ kubectl apply -f 05-clusterrolebinding.yaml
clusterrolebinding.rbac.authorization.k8s.io/prometheus created

$ kubectl apply -f 06-prometheus-prometheus.yaml
prometheus.monitoring.coreos.com/prometheus created

$ kubectl apply -f 07-prometheus-service.yaml
service/prometheus created

$ kubectl apply -f 08-service-monitor.yaml
servicemonitor.monitoring.coreos.com/nginx-with-exporter created
```

 - Как и раньше, зайдём в web-интерфейс prometheus
```
$ kubectl port-forward svc/prometheus -n prometheus 9090:9090
Forwarding from 127.0.0.1:9090 -> 9090
Forwarding from [::1]:9090 -> 9090
```
Видим там в Service Discovery `serviceMonitor/prometheus/nginx-with-exporter/0 (3 / 26 active targets)` и в Targets
`serviceMonitor/prometheus/nginx-with-exporter/0 (3/3 up)`. nginx_up выдаёт
`nginx_up{container="exporter", endpoint="9113", instance="172.16.152.66:9113", job="nginx-with-exporter", namespace="default", pod="nginx-with-exporter-7cbbd4445-msmfh", service="nginx-with-exporter"}`

 - Но в `prometheus-operator` нет grafana, поэтому скачаем манифесты с https://grafana.com/docs/grafana/latest/setup-grafana/installation/kubernetes/
  и установим отдельно:
```
$ kubectl create namespace grafana
namespace/grafana created
$ kubectl apply -f grafana.yaml --namespace=grafana
persistentvolumeclaim/grafana-pvc created
deployment.apps/grafana created
service/grafana created
```

 - Настроим port-forward и зайдём в grafana по http://localhost:3000
```
$ kubectl port-forward svc/grafana -n grafana 3000:3000
Forwarding from 127.0.0.1:3000 -> 3000
Forwarding from [::1]:3000 -> 3000
```

 - Так же, как и раньше, импортируем доску с метриками nginx, но на этот раз нужно настроить источник данных.
  Укажем URL http://prometheus.prometheus.svc.cluster.local:9090, всё работает.
  Снимок экрана тут https://jmp.sh/ZDomDqH3.

 - Не понял, как поставить всё руками (уровень I am death incarnate!).
   Возможно, имеется в виду что-то похожее на https://se7entyse7en.dev/posts/how-to-set-up-kubernetes-service-discovery-in-prometheus/,
   без CRD и с ручным созданием конфигов. Но думаю хватит, остановлюсь на том что есть)

 - Насчёт названий уровней - это из Wolf 3D, когда-то давно играл в него)

# Выполнено ДЗ №9

 - [*] Основное ДЗ

## В процессе сделано:

 - Изменим настройку пула по умолчанию, задав шаблон для названий нод, и создадим второй пул:
```
$ yc managed-kubernetes node-group update node-group-1-default --node-name 'node{instance.index}-default-pool'
$ yc managed-kubernetes node-group create --cluster-name otus --cores 2 --core-fraction 20 --disk-size 64 --disk-type network-hdd --fixed-size 3 --memory 8 --name node-group-2-infra --container-runtime containerd --preemptible --public-ip --node-name 'node{instance.index}-infra-pool' --node-taints node-role=infra:NoSchedule
```

 - Проверим состояние нод и taints:
```
$ kubectl get nodes -o wide
NAME                 STATUS   ROLES    AGE     VERSION   INTERNAL-IP   EXTERNAL-IP      OS-IMAGE             KERNEL-VERSION      CONTAINER-RUNTIME
node3-default-pool   Ready    <none>   12m     v1.27.3   10.129.0.15   51.250.109.231   Ubuntu 20.04.6 LTS   5.4.0-153-generic   containerd://1.6.21
node4-default-pool   Ready    <none>   177m    v1.27.3   10.129.0.12   158.160.15.116   Ubuntu 20.04.6 LTS   5.4.0-153-generic   containerd://1.6.21
node4-infra-pool     Ready    <none>   11m     v1.27.3   10.129.0.35   51.250.20.175    Ubuntu 20.04.6 LTS   5.4.0-153-generic   containerd://1.6.21
node5-infra-pool     Ready    <none>   2m49s   v1.27.3   10.129.0.4    84.252.140.182   Ubuntu 20.04.6 LTS   5.4.0-153-generic   containerd://1.6.21
node6-infra-pool     Ready    <none>   8m24s   v1.27.3   10.129.0.27   51.250.103.250   Ubuntu 20.04.6 LTS   5.4.0-153-generic   containerd://1.6.21
$ kubectl describe node node4-infra-pool | grep -A1 -i taint
Taints:             node-role=infra:NoSchedule
Unschedulable:      false
```

 - Скачаем и установим свежий hipster-shop:
```
$ curl -O https://raw.githubusercontent.com/GoogleCloudPlatform/microservices-demo/main/release/kubernetes-manifests.yaml
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100 19878  100 19878    0     0   228k      0 --:--:-- --:--:-- --:--:--  245k
$ kubectl apply -f kubernetes-manifests.yaml -n microservices-demo
deployment.apps/emailservice created
service/emailservice created
deployment.apps/checkoutservice created
service/checkoutservice created
deployment.apps/recommendationservice created
service/recommendationservice created
deployment.apps/frontend created
service/frontend created
service/frontend-external created
deployment.apps/paymentservice created
service/paymentservice created
deployment.apps/productcatalogservice created
service/productcatalogservice created
deployment.apps/cartservice created
service/cartservice created
deployment.apps/loadgenerator created
deployment.apps/currencyservice created
service/currencyservice created
deployment.apps/shippingservice created
service/shippingservice created
deployment.apps/redis-cart created
service/redis-cart created
deployment.apps/adservice created
service/adservice created
```

 - Проверим где развернулись поды, все в пуле по умолчанию:
```
$ kubectl get pods -n microservices-demo -o wide
NAME                                     READY   STATUS    RESTARTS   AGE    IP              NODE                 NOMINATED NODE   READINESS GATES
adservice-7986b85799-mc6tg               1/1     Running   0          178m   172.16.142.5    node4-default-pool   <none>           <none>
cartservice-7d4899b484-j9zhq             1/1     Running   0          178m   172.16.142.6    node4-default-pool   <none>           <none>
checkoutservice-7dfddf54c7-d4cvw         1/1     Running   0          178m   172.16.142.7    node4-default-pool   <none>           <none>
currencyservice-67d46ff6d5-8h4zj         1/1     Running   0          178m   172.16.142.8    node4-default-pool   <none>           <none>
emailservice-6477bdbdf5-fbjzd            1/1     Running   0          178m   172.16.142.9    node4-default-pool   <none>           <none>
frontend-755cdc7957-7mnb5                1/1     Running   0          16m    172.16.142.12   node4-default-pool   <none>           <none>
loadgenerator-6b55f6c4c8-ht7p2           1/1     Running   0          16m    172.16.142.15   node4-default-pool   <none>           <none>
paymentservice-746db6d55-k64pq           1/1     Running   0          178m   172.16.142.11   node4-default-pool   <none>           <none>
productcatalogservice-764965c957-27dkl   1/1     Running   0          16m    172.16.142.14   node4-default-pool   <none>           <none>
recommendationservice-7669d8b8dc-swq5g   1/1     Running   0          16m    172.16.142.16   node4-default-pool   <none>           <none>
redis-cart-76b9545755-mnr7b              1/1     Running   0          16m    172.16.142.13   node4-default-pool   <none>           <none>
shippingservice-699f4bf479-26kc6         1/1     Running   0          178m   172.16.142.10   node4-default-pool   <none>           <none>
```

 - Добавим репозиторий `elastic`, создадим пространство имён и попробуем установить elasticsearch:
```
$ helm repo add elastic https://helm.elastic.co
"elastic" has been added to your repositories

$ kubectl create ns observability
namespace/observability created

$ helm upgrade --install elasticsearch elastic/elasticsearch --namespace observability
Release "elasticsearch" does not exist. Installing it now.
Error: failed to fetch https://helm.elastic.co/helm/elasticsearch/elasticsearch-8.5.1.tgz : 403 Forbidden
```
Не ставится, доступ заблокирован. Скачаем пакет и установим elasticsearch из локального файла:
```
$ helm upgrade --install elasticsearch ./elasticsearch-8.5.1.tgz --namespace observability
Release "elasticsearch" does not exist. Installing it now.
NAME: elasticsearch
LAST DEPLOYED: Sat Nov 11 17:30:29 2023
NAMESPACE: observability
STATUS: deployed
REVISION: 1
NOTES:
1. Watch all cluster members come up.
  $ kubectl get pods --namespace=observability -l app=elasticsearch-master -w
2. Retrieve elastic user's password.
  $ kubectl get secrets --namespace=observability elasticsearch-master-credentials -ojsonpath='{.data.password}' | base64 -d
3. Test cluster health using Helm test.
  $ helm --namespace=observability test elasticsearch
```
Установился успешно.

 - Аналогично скачаем и установим kibana
```
$ helm upgrade --install kibana ./kibana-8.5.1.tgz --namespace observability
Release "kibana" does not exist. Installing it now.
...
```

 - Установим fluent-bit
```
$ helm upgrade --install fluent-bit stable/fluent-bit --namespace observability
Release "fluent-bit" does not exist. Installing it now.
WARNING: This chart is deprecated
NAME: fluent-bit
LAST DEPLOYED: Sat Nov 11 17:27:34 2023
NAMESPACE: observability
STATUS: deployed
REVISION: 1
NOTES:
fluent-bit is now running.

It will forward all container logs to the svc named fluentd on port: 24284
```
Пишет, что `This chart is deprecated`, это действительно старая версия, поэтому старую удалим и поставим новую
```
$ helm repo add fluent https://fluent.github.io/helm-charts
"fluent" has been added to your repositories

$ helm upgrade --install fluent-bit fluent/fluent-bit --namespace observability
Release "fluent-bit" does not exist. Installing it now.
NAME: fluent-bit
LAST DEPLOYED: Sat Nov 11 23:56:03 2023
NAMESPACE: observability
STATUS: deployed
REVISION: 1
NOTES:
Get Fluent Bit build information by running these commands:
...
```

 - Elasticsearch не запускается, посмотрим почему
```
$ kubectl describe pod elasticsearch-master-0 -n observability | tail
QoS Class:                   Burstable
Node-Selectors:              <none>
Tolerations:                 node.kubernetes.io/not-ready:NoExecute op=Exists for 300s
                             node.kubernetes.io/unreachable:NoExecute op=Exists for 300s
Events:
  Type     Reason            Age    From                Message
  ----     ------            ----   ----                -------
  Warning  FailedScheduling  6m22s  default-scheduler   0/5 nodes are available: 2 Insufficient cpu, 3 node(s) had untolerated taint {node-role: infra}. preemption: 0/5 nodes are available: 2 No preemption victims found for incoming pod, 3 Preemption is not helpful for scheduling..
  Warning  FailedScheduling  79s    default-scheduler   0/5 nodes are available: 2 Insufficient cpu, 3 node(s) had untolerated taint {node-role: infra}. preemption: 0/5 nodes are available: 2 No preemption victims found for incoming pod, 3 Preemption is not helpful for scheduling..
  Normal   TriggeredScaleUp  6m16s  cluster-autoscaler  pod triggered scale-up: [{catg28jubq13ic411e9b 2->5 (max: 10)}]
```
На двух нодах пула по умолчанию не хватает CPU, а на трёх нодах пула infra запускаться запрещено из-за taint.

 - Создадим файл elasticsearch.values.yaml, добавим туда tolerations, чтобы игнорировать taint, пароль, также добавим nodeSelector,
  чтоб запускаться на нодах пула infra. Метки с названием пула на нодах нет, только с ID, поэтому используем его.
  И забегая вперёд переопределим образ elasticsearch, т.к. образ по умолчанию не скачивается из-за блокировки доступа.
  Вот что получилось:
```
$ cat elasticsearch.values.yaml
image: elasticsearch
secret:
  password: "pass"
tolerations:
- key: node-role
  operator: Equal
  value: infra
  effect: NoSchedule
nodeSelector:
  yandex.cloud/node-group-id: catqdjfpuj7ben20ohas
```

 - Обновим эластик:
```
$ helm upgrade --install elasticsearch ./elasticsearch-8.5.1.tgz --namespace observability --values elasticsearch.values.yaml
false
Release "elasticsearch" has been upgraded. Happy Helming!
NAME: elasticsearch
LAST DEPLOYED: Sat Nov 11 17:40:57 2023
NAMESPACE: observability
STATUS: deployed
REVISION: 2
NOTES:
1. Watch all cluster members come up.
  $ kubectl get pods --namespace=observability -l app=elasticsearch-master -w
2. Retrieve elastic user's password.
  $ kubectl get secrets --namespace=observability elasticsearch-master-credentials -ojsonpath='{.data.password}' | base64 -d
3. Test cluster health using Helm test.
  $ helm --namespace=observability test elasticsearch
```

 - Проверим:
```
$ kubectl get pods -n observability -o wide -l chart=elasticsearch
NAME                     READY   STATUS    RESTARTS   AGE     IP             NODE               NOMINATED NODE   READINESS GATES
elasticsearch-master-0   1/1     Running   0          5m33s   172.16.146.3   node5-infra-pool   <none>           <none>
elasticsearch-master-1   1/1     Running   0          13m     172.16.144.4   node4-infra-pool   <none>           <none>
elasticsearch-master-2   1/1     Running   0          11m     172.16.145.3   node6-infra-pool   <none>           <none>
```
Всё хорошо, поды работают, каждая на своей ноде в пуле infra.

 - Установим ingress-nginx:
```
$ helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx --wait --namespace=ingress-nginx --create-namespace --values ingress-nginx.values.yaml
Release "ingress-nginx" does not exist. Installing it now.
NAME: ingress-nginx
LAST DEPLOYED: Sat Nov 11 22:11:36 2023
NAMESPACE: ingress-nginx
STATUS: deployed
REVISION: 1
TEST SUITE: None
NOTES:
The ingress-nginx controller has been installed.
It may take a few minutes for the LoadBalancer IP to be available.
You can watch the status by running 'kubectl --namespace ingress-nginx get services -o wide -w ingress-nginx-controller'

An example Ingress that makes use of the controller:
  apiVersion: networking.k8s.io/v1
  kind: Ingress
  metadata:
    name: example
    namespace: foo
  spec:
    ingressClassName: nginx
    rules:
      - host: www.example.com
        http:
          paths:
            - pathType: Prefix
              backend:
                service:
                  name: exampleService
                  port:
                    number: 80
              path: /
    # This section is only required if TLS is to be enabled for the Ingress
    tls:
      - hosts:
        - www.example.com
        secretName: example-tls

If TLS is enabled for the Ingress, a Secret containing the certificate and key must also be provided:

  apiVersion: v1
  kind: Secret
  metadata:
    name: example-tls
    namespace: foo
  data:
    tls.crt: <base64 encoded cert>
    tls.key: <base64 encoded key>
  type: kubernetes.io/tls
```
В `ingress-nginx.values.yaml` указаны кол-во реплик 3, tolerations, anti-affinity и nodeSelector.

 - Создадим файл `kibana.values.yaml` со значениями для кибаны, в нём переопределим образ из-за доступа, включим ingress,
  укажем ingress.class и host. host использую на личном домене. Обновим кибану:
```
$ helm upgrade --install kibana ./kibana-8.5.1.tgz --namespace observability --values kibana.values.yaml
false
Release "kibana" has been upgraded. Happy Helming!
NAME: kibana
LAST DEPLOYED: Sat Nov 11 22:22:28 2023
NAMESPACE: observability
STATUS: deployed
REVISION: 2
TEST SUITE: None
NOTES:
1. Watch all containers come up.
  $ kubectl get pods --namespace=observability -l release=kibana -w
2. Retrieve the elastic user's password.
  $ kubectl get secrets --namespace=observability elasticsearch-master-credentials -ojsonpath='{.data.password}' | base64 -d
3. Retrieve the kibana service account token.
  $ kubectl get secrets --namespace=observability kibana-kibana-es-token -ojsonpath='{.data.token}' | base64 -d
```

 - Зайдём в кибану и увидим, что там нет индексов (data views). Причин несколько, все они на стороне fluent-bit. Не считая версии и отсутствии настройки output es,
 это: использование http вместо https, проверка сертификата эластика, отсутствие логина/пароля, передача type, что запрещено с 7-й версии эластика, передача точек
 в названиях полей.
 Напишем файл `fluent-bit.values.yaml` с правильными значениями, также добавим туда tolerations чтоб fluent-bit запускался на всех нодах, и применим как обычно.
 Ниже просто для истории некоторые встреченные ошибки
```
{"@timestamp":"2023-11-11T20:12:05.012Z", "log.level": "WARN", "message":"received plaintext http traffic on an https channel, closing connection Netty4HttpChannel{localAddress=/172.16.146.3:9200, remoteAddress=/10.129.0.15:50856}", "ecs.version": "1.2.0","service.name":"ES_ECS","event.dataset":"elasticsearch.server","process.thread.name":"elasticsearch[elasticsearch-master-0][transport_worker][T#1]","log.logger":"org.elasticsearch.xpack.security.transport.netty4.SecurityNetty4HttpServerTransport","elasticsearch.cluster.uuid":"dmLAoQ-3Qdy5zejVDdcnNw","elasticsearch.node.id":"vqNkxNwxSOSxra5QLGeuKg","elasticsearch.node.name":"elasticsearch-master-0","elasticsearch.cluster.name":"elasticsearch"}

{"error":{"root_cause":[{"type":"illegal_argument_exception","reason":"Action/metadata line [1] contains an unknown parameter [_type]"}],"type":"illegal_argument_exception","reason":"Action/metadata line [1] contains an unknown parameter [_type]"},"status":400}

{"took":108,"errors":true,"items":[{"create":{"_index":"logstash-2023.11.11","_id":"XO9PwIsBSYCn7ZGO4wgK","status":400,"error":{"type":"mapper_parsing_exception","reason":"object mapping for [kubernetes.labels.app] tried to parse field [app] as object, but found a concrete value"}}},{"create":{"_index":"logstash-2023.11.11","_id":"Xe9PwIsBSYCn7ZGO4wgK","status":400,"error":{"type":"mapper_parsing_exception","reason":"object mapping for [kubernetes.labels.app] tried to parse field [app] as object, but found a concrete value"}}},{"create":{"_index":"logstash-2023.11.11","_id":"Xu9PwIsBSYCn7ZGO4wgK","status":400,"error":{"type":"mapper_parsing_exception","reason":"object mapping for [kubernetes.labels.app] tried to parse field [app] as object, but found a concrete value"}}},{"create":{"_index":"logstash-2023.11.11","_id":"X-9PwIsBSYCn7ZGO4wgK","status":400,"error":{"type":"mapper_parsing_exception","reason":"object mapping for [kubernetes.labels.app] tried to parse field [app] as object, but found a concrete value"}}}]}
[2023/11/11 21:35:42] [ warn] [engine] failed to flush chunk '1-1699738532.645976786.flb', retry in 12 seconds: task_id=556, input=tail.0 > output=es.0 (out_id=0)
[2023/11/11 21:35:42] [error] [output:es:es.0] error: Output
```

 - После обновления fluent-bit индексы в эластике появились. Вот несколько снимков экрана:
   https://jmp.sh/M1Bok9YL, https://jmp.sh/jLYzLU6B, https://jmp.sh/qG7XNmUo

## Задание со *

 - В логах не вижу ошибок насчёт дублирующихся полей `time` и `timestamp`. Изучив тему и issue, полагаю что наилучшим вариантом будет подход из статьи
   https://bk0010-01.blogspot.com/2020/03/fluent-bit-and-kibana-in-kubernetes.html, а именно парсить лог и записывать его
   в отдельный ключ, например `app`. Соответствующие параметры в конфиге fluent-bit это `Merge_Log: On` и `Merge_Log_Key: app`. Вслепую не буду их добавлять)

 - Установим prometheus
```
$ helm upgrade --install prometheus prometheus-community/kube-prometheus-stack --namespace=observability --values prometheus.values.yaml --wait
Release "prometheus" does not exist. Installing it now.
NAME: prometheus
LAST DEPLOYED: Sun Nov 12 22:35:22 2023
NAMESPACE: observability
STATUS: deployed
REVISION: 1
NOTES:
kube-prometheus-stack has been installed. Check its status by running:
  kubectl --namespace observability get pods -l "release=prometheus"

Visit https://github.com/prometheus-operator/kube-prometheus for instructions on how to create & configure Alertmanager and Prometheus instances using the Operator.
```

 - Установим свежий elasticsearch-exporter, передав файл `elasticsearch-exporter.values.yaml`, в которм пропишем URL эластика с https и паролем,
  а также включим ServiceMonitor с нужной меткой релиза.
```
$ helm upgrade --install elasticsearch-exporter prometheus-community/prometheus-elasticsearch-exporter --namespace=observability --values elasticsearch-exporter.values.yaml
false
Release "elasticsearch-exporter" has been upgraded. Happy Helming!
NAME: elasticsearch-exporter
LAST DEPLOYED: Sun Nov 12 23:20:31 2023
NAMESPACE: observability
STATUS: deployed
REVISION: 2
TEST SUITE: None
NOTES:
1. Get the application URL by running these commands:
  export POD_NAME=$(kubectl get pods --namespace observability -l "app=elasticsearch-exporter-prometheus-elasticsearch-exporter" -o jsonpath="{.items[0].metadata.name}")
  echo "Visit http://127.0.0.1:9108/metrics to use your application"
  kubectl port-forward $POD_NAME 9108:9108 --namespace observability
```

 - Импортируем в графану доску эластика, починим статус, всё работает.
  ![Страничка импорта доски](https://jmp.sh/odqe6VGG)
  ![Доска эластика в графане](https://jmp.sh/0qhmoIUg)

 - Эластик в рабочем состянии
```
$ kubectl get pods -n observability -l app=elasticsearch-master -o wide
NAME                     READY   STATUS    RESTARTS       AGE     IP              NODE               NOMINATED NODE   READINESS GATES
elasticsearch-master-0   1/1     Running   1 (3d4h ago)   3d23h   172.16.146.15   node5-infra-pool   <none>           <none>
elasticsearch-master-1   1/1     Running   1 (3d4h ago)   4d      172.16.144.16   node4-infra-pool   <none>           <none>
elasticsearch-master-2   1/1     Running   1 (3d4h ago)   3d23h   172.16.145.16   node6-infra-pool   <none>           <none>
```

 - расселим `node4-infra-pool`
```
$ kubectl drain node4-infra-pool --ignore-daemonsets
node/node4-infra-pool cordoned
Warning: ignoring DaemonSet-managed Pods: kube-system/ip-masq-agent-8hbgk, kube-system/kube-proxy-5h6rt, kube-system/npd-v0.8.0-8jnhb, kube-system/yc-disk-csi-node-v2-87d65, observability/fluent-bit-d7x7r, observability/prometheus-prometheus-node-exporter-kbpxs
evicting pod observability/elasticsearch-master-1
evicting pod ingress-nginx/ingress-nginx-controller-5c844c8cd5-r66tv
pod/elasticsearch-master-1 evicted
pod/ingress-nginx-controller-5c844c8cd5-r66tv evicted
node/node4-infra-pool drained

$ kubectl get pods -n observability -l app=elasticsearch-master -o wide
NAME                     READY   STATUS    RESTARTS       AGE     IP              NODE               NOMINATED NODE   READINESS GATES
elasticsearch-master-0   1/1     Running   1 (3d4h ago)   3d23h   172.16.146.15   node5-infra-pool   <none>           <none>
elasticsearch-master-1   0/1     Pending   0              37s     <none>          <none>             <none>           <none>
elasticsearch-master-2   1/1     Running   1 (3d4h ago)   3d23h   172.16.145.16   node6-infra-pool   <none>           <none>
```
На доске кол-во узлов эластика уменьшилось до 2
![grafana-elastic-2-nodes](https://jmp.sh/BV9Swghv)


 - Попробуем расселить `node6-infra-pool`, не получается
```
$ kubectl drain node6-infra-pool --ignore-daemonsets
node/node6-infra-pool cordoned
Warning: ignoring DaemonSet-managed Pods: kube-system/ip-masq-agent-5tl5r, kube-system/kube-proxy-xtx29, kube-system/npd-v0.8.0-qhdm5, kube-system/yc-disk-csi-node-v2-mxbbb, observability/fluent-bit-hggch, observability/prometheus-prometheus-node-exporter-kj9h5
evicting pod observability/elasticsearch-master-2
evicting pod ingress-nginx/ingress-nginx-controller-5c844c8cd5-2h5ss
error when evicting pods/"elasticsearch-master-2" -n "observability" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget.
evicting pod observability/elasticsearch-master-2
error when evicting pods/"elasticsearch-master-2" -n "observability" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget.
evicting pod observability/elasticsearch-master-2
error when evicting pods/"elasticsearch-master-2" -n "observability" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget.
pod/ingress-nginx-controller-5c844c8cd5-2h5ss evicted
evicting pod observability/elasticsearch-master-2
error when evicting pods/"elasticsearch-master-2" -n "observability" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget.
evicting pod observability/elasticsearch-master-2
error when evicting pods/"elasticsearch-master-2" -n "observability" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget.
^C
```

 - Удалим pod `elasticsearch-master-2` ручками
```
$ kubectl get pods -n observability -l app=elasticsearch-master -o wide
NAME                     READY   STATUS    RESTARTS       AGE     IP              NODE               NOMINATED NODE   READINESS GATES
elasticsearch-master-0   1/1     Running   1 (3d4h ago)   3d23h   172.16.146.15   node5-infra-pool   <none>           <none>
elasticsearch-master-1   0/1     Pending   0              5m      <none>          <none>             <none>           <none>
elasticsearch-master-2   0/1     Pending   0              5s      <none>          <none>             <none>           <none>
```
Статус в кибане стал недоступен
![grafana-elastic-1-node](https://jmp.sh/tyGVTgR3)

 - Возвращаем ноды обратно
```
$ kubectl uncordon node4-infra-pool
node/node4-infra-pool uncordoned

$ kubectl uncordon node6-infra-pool
node/node6-infra-pool uncordoned

$ kubectl get pods -n observability -l app=elasticsearch-master -o wide
NAME                     READY   STATUS    RESTARTS       AGE     IP              NODE               NOMINATED NODE   READINESS GATES
elasticsearch-master-0   1/1     Running   1 (3d4h ago)   3d23h   172.16.146.15   node5-infra-pool   <none>           <none>
elasticsearch-master-1   1/1     Running   0              9m4s    172.16.144.17   node4-infra-pool   <none>           <none>
elasticsearch-master-2   1/1     Running   0              4m9s    172.16.145.17   node6-infra-pool   <none>           <none>
```

 - Логи `ingress-nginx` в моём случае есть, они собираются по обычному пути `/var/log/containers/*.log`, поэтому в этом месте ничего не делаю
 ![kibana-ingress-nginx-logs](https://jmp.sh/9fdOzAQr)

 - Для вывода логов в формате json добавим в конфиг `ingress-nginx` параметры `log-format-escape-json` и `log-format-upstream`
 ![kibana-ingress-nginx-logs-json](https://jmp.sh/E5rsXiuV)

 - Создадим визуализации запросов к `ingress-nginx`
 Общее кол-во запросов
 ![kibana-ingress-nginx-visualize](https://jmp.sh/TC5fcaO5)
 Доска `ingress-nginx`
 ![kibana-ingress-nginx-dashboard](https://jmp.sh/WIqLke6Q)

 - Экспортируем доску `ingress-nginx`. В интерфейсе сохранения у меня не видны отдельные визуализации, только вся доска целиком. Версия 8.5.1
 ![kibana-ingress-nginx-export](https://jmp.sh/Go6w5CTw)

 - Установим Loki и Promtail. В Loki отключим аутентификацию (loki.auth_enabled: false) а также добавим игнорирование на запрет запуска подов
 в пуле infra для Promtail:
```
$ helm repo add grafana https://grafana.github.io/helm-charts
"grafana" has been added to your repositories

$ helm install loki grafana/loki --namespace observability --values loki.values.yaml
NAME: loki
LAST DEPLOYED: Fri Nov 17 20:24:35 2023
NAMESPACE: observability
STATUS: deployed
REVISION: 1
NOTES:
***********************************************************************
 Welcome to Grafana Loki
 Chart version: 5.36.3
 Loki version: 2.9.2
***********************************************************************

Installed components:
* grafana-agent-operator
* loki

$ helm upgrade --install promtail grafana/promtail --namespace observability
Release "promtail" does not exist. Installing it now.
NAME: promtail
LAST DEPLOYED: Fri Nov 17 20:37:26 2023
NAMESPACE: observability
STATUS: deployed
REVISION: 1
TEST SUITE: None
NOTES:
***********************************************************************
 Welcome to Grafana Promtail
 Chart version: 6.15.3
 Promtail version: 2.9.2
***********************************************************************

Verify the application is working by running these commands:
* kubectl --namespace observability port-forward daemonset/promtail 3101
* curl http://127.0.0.1:3101/metrics
```

 - Добавим источник данных Loki в графану следующим блоком в `prometheus.values.yaml` и обновим прометей:
```
grafana:
  additionalDataSources:
  - name: Loki
    type: loki
    access: proxy
    url: http://loki:3100
    jsonData:
      maxLines: 1000

$ helm upgrade --install prometheus prometheus-community/kube-prometheus-stack --namespace=observability --values prometheus.values.yaml --wait
false
Release "prometheus" has been upgraded. Happy Helming!
NAME: prometheus
LAST DEPLOYED: Fri Nov 17 21:04:40 2023
NAMESPACE: observability
STATUS: deployed
REVISION: 3
NOTES:
kube-prometheus-stack has been installed. Check its status by running:
  kubectl --namespace observability get pods -l "release=prometheus"

Visit https://github.com/prometheus-operator/kube-prometheus for instructions on how to create & configure Alertmanager and Prometheus instances using the Operator.
```

 - Добавим ServiceMonitor в ingress-nginx добавлением блока ниже в `ingress-nginx.values.yaml` и применим как обычно
```
controller:
  metrics:
    enabled: true
    serviceMonitor:
      enabled: true
      additionalLabels:
        release: prometheus
```

 - Создадим доску c требуемыми визуализациями, экспортируем её и сохраним в `ingress-nginx.json`
 ![grafana-ingress-nginx-1](https://jmp.sh/HwrxPRG3)
Я не нашёл, как показывать длинные логи в несколько строк, но думаю что такая возможность должна быть.

 - Создание своего кластера я пропущу для экономии времени)

 - Логи аудита в Яндексе можно включить через `yc managed-kubernetes cluster update --master-logging audit-enabled`.
   Для включения аудита в self-hosted кластере, нужно создать политику, добавить параметры для kube-apiserver, добавить проброс директорий с файлами
   политики и логов с хоста внутрь kube-apiserver. Описание https://kubernetes.io/docs/tasks/debug/debug-cluster/audit/.
   Также нужно будет создать во fluent-bit input и output.

 - Насчёт логов с виртуальных машин мне видится два подхода, один через systemd, второй просто чтением файлов. Первый способ я реализовал,
   убрав фильтр `Systemd_Filter` в конфигурации input systemd, который по умолчанию оставляет только kubelet. Появились логи ssh, containerd и др.
   Второй способ не реализовывал, нужно использовать input `tail`, указав путь к файлу с логами, например `/var/log/syslog`. Также потребуется
   указать `Tag`, `DB`, `Path_Key`, можно `Parser`. И соответствующий указанному тегу output.

# Выполнено ДЗ №10

 - [*] Основное ДЗ

## В процессе сделано:

 - Регистрация в gitLab.com из России закрыта, поэтому я поднял свой GitLab в облаке Яндекса и создал там публичный проект
   https://hfrog.gitlab.yandexcloud.net/aaivanov/microservices-demo. Копирование кода из проекта GCP:
```
$ git clone https://github.com/GoogleCloudPlatform/microservices-demo
Клонирование в «microservices-demo»...
remote: Enumerating objects: 14343, done.
remote: Counting objects: 100% (207/207), done.
remote: Compressing objects: 100% (128/128), done.
remote: Total 14343 (delta 124), reused 128 (delta 77), pack-reused 14136
Получение объектов: 100% (14343/14343), 32.92 МиБ | 3.45 МиБ/с, готово.
Определение изменений: 100% (10919/10919), готово.
$ cd microservices-demo/
$ git remote -v
origin	https://github.com/GoogleCloudPlatform/microservices-demo (fetch)
origin	https://github.com/GoogleCloudPlatform/microservices-demo (push)
$ git remote add gitlab git@hfrog.gitlab.yandexcloud.net:aaivanov/microservices-demo.git
$ git remote remove origin
$ git remote -v
gitlab	git@hfrog.gitlab.yandexcloud.net:aaivanov/microservices-demo.git (fetch)
gitlab	git@hfrog.gitlab.yandexcloud.net:aaivanov/microservices-demo.git (push)
$ git push gitlab main
The authenticity of host 'hfrog.gitlab.yandexcloud.net (158.160.133.95)' can't be established.
ED25519 key fingerprint is SHA256:dXKL8J8arzObXEkUcCQ8g1ZoLSzHp6v0pyACI/tX+/o.
This key is not known by any other names.
Are you sure you want to continue connecting (yes/no/[fingerprint])? yes
Warning: Permanently added 'hfrog.gitlab.yandexcloud.net' (ED25519) to the list of known hosts.
Перечисление объектов: 13955, готово.
Подсчет объектов: 100% (13955/13955), готово.
При сжатии изменений используется до 10 потоков
Сжатие объектов: 100% (3135/3135), готово.
Запись объектов: 100% (13955/13955), 32.82 МиБ | 9.31 МиБ/с, готово.
Всего 13955 (изменений 10646), повторно использовано 13948 (изменений 10643), повторно использовано пакетов 0
remote: Resolving deltas: 100% (10646/10646), done.
To hfrog.gitlab.yandexcloud.net:aaivanov/microservices-demo.git
 * [new branch]      main -> main
```

 - Я не стал делать helm чарты для всех микросервисов, ограничившись только `frontend`. Его я взял свежий с GitHub.
   В репозитории с домашним заданием он находится в директории `deploy/charts/frontend', а в репозитории GitLab - в директории `helm-charts/frontend`,
   т.к. в директории `deploy` будут лежать манифесты.

 - Для выполнения задания используем существующий кластер Kubernetes в Яндекс облаке, создание я не автоматизировал.

 - Для сборки образов всех микросервисов написан `.gitlab-ci.yml`, он находится в репозитории `microservices-demo`.
   Я не стал разделять стадии сборки и выгрузки образов, чтобы не передавать артефакты между этапами. Они могут быть большими,
   а в GitLab есть ограничение на размер артефактов. Стадия `build_and_push` использует dind с сервисным образом. Сборка происходит по тегам.

 - Flux v2 установлен по свежей инструкции. Сразу добавим опциональные компоненты `image-reflector-controller` и `image-automation-controller`, они пригодятся
   для автоматического использования новых образов:
```
$ brew install fluxcd/tap/flux
==> Tapping fluxcd/tap
...
$ export GITLAB_TOKEN=$(cat microservices-demo-fluxcd.token)
$ flux bootstrap gitlab --hostname hfrog.gitlab.yandexcloud.net --owner=aaivanov --repository=microservices-demo --path=deploy --components-extra image-reflector-controller,image-automation-controller --token-auth
► connecting to https://hfrog.gitlab.yandexcloud.net
► cloning branch "main" from Git repository "https://hfrog.gitlab.yandexcloud.net/aaivanov/microservices-demo.git"
✔ cloned repository
► generating component manifests
✔ generated component manifests
✔ committed sync manifests to "main" ("2ceb19352e6fd605b8ed2386a227ece2d8bf685c")
► pushing component manifests to "https://hfrog.gitlab.yandexcloud.net/aaivanov/microservices-demo.git"
► installing components in "flux-system" namespace
✔ installed components
✔ reconciled components
► determining if source secret "flux-system/flux-system" exists
► generating source secret
► applying source secret "flux-system/flux-system"
✔ reconciled source secret
► generating sync manifests
✔ generated sync manifests
✔ committed sync manifests to "main" ("17a58d30d67ac9af0371bc1ae3fb6d13e8e69130")
► pushing sync manifests to "https://hfrog.gitlab.yandexcloud.net/aaivanov/microservices-demo.git"
► applying sync manifests
✔ reconciled sync configuration
◎ waiting for Kustomization "flux-system/flux-system" to be reconciled
✔ Kustomization reconciled successfully
► confirming components are healthy
✔ helm-controller: deployment ready
✔ image-automation-controller: deployment ready
✔ image-reflector-controller: deployment ready
✔ kustomize-controller: deployment ready
✔ notification-controller: deployment ready
✔ source-controller: deployment ready
✔ all components are healthy
```

 - поместим манифест создания namespace `microservices-demo` в файл `deploy/namespaces/microservices-demo.yaml`,
   после commit и push namespace создаётся:
```
$ cat deploy/namespaces/microservices-demo.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: microservices-demo

$ kubectl get ns
NAME                 STATUS   AGE
...
microservices-demo   Active   114s
...

$ flux get all -A
NAMESPACE       NAME                            REVISION                SUSPENDED       READY   MESSAGE
flux-system     gitrepository/flux-system       main@sha1:17a58d30      False           True    stored artifact for revision 'main@sha1:17a58d30'

NAMESPACE       NAME                            REVISION                SUSPENDED       READY   MESSAGE
flux-system     kustomization/flux-system       main@sha1:17a58d30      False           True    Applied revision: main@sha1:17a58d30

# события из моего предыдущего эксперимента, в текущем к моменту составления описания события уже пропали, но суть та же
$ flux events
...
19s               	Normal 	NewArtifact               	GitRepository/microservices-demo	stored artifact for commit 'add microservices-demo namespace'
18s               	Normal 	ReconciliationSucceeded   	Kustomization/microservices-demo	Reconciliation finished in 485.276163ms, next run in 3m0s
18s               	Normal 	Progressing               	Kustomization/microservices-demo	Health check passed in 59.381508ms
18s               	Normal 	Progressing               	Kustomization/microservices-demo	Namespace/microservices-demo created
```

 - Установим доску weave-gitops, https://github.com/weaveworks/weave-gitops. Сначала установим gitops через brew, затем
   создадим и сохраним в репозитории файл с манифестами создания доски:
```
$ gitops create dashboard ww-gitops --password=pass --export > deploy/ww-gitops/dashboard.yaml
```
После commit, push и небольшого ожидания либо применения `flux reconcile` у нас есть [web-интерфейс](https://jmp.sh/Y2QP1uIt).

 - Создадим `HelmRelease`:
```
$ flux create helmrelease frontend --source=GitRepository/flux-system.flux-system --chart=./helm-charts/frontend --namespace microservices-demo --values frontend.values.yaml --export
---
apiVersion: helm.toolkit.fluxcd.io/v2beta1
kind: HelmRelease
metadata:
  name: frontend
  namespace: microservices-demo
spec:
  chart:
    spec:
      chart: ./helm-charts/frontend
      reconcileStrategy: ChartVersion
      sourceRef:
        kind: GitRepository
        name: flux-system
        namespace: flux-system
  interval: 1m0s
  values:
    images:
      repository: cr.yandex/crpsgjav4a792j80c0iu
      tag: v0.0.1
```
Запишем манифест в файл `deploy/releases/frontend.yaml`, commit, push и проверяем
```
$ flux get helmrelease -n microservices-demo
NAME            REVISION        SUSPENDED       READY   MESSAGE
frontend        0.8.1           False           True    Release reconciliation succeeded

$ kubectl get helmrelease -n microservices-demo
NAME       AGE    READY   STATUS
frontend   100s   True    Release reconciliation succeeded

$ helm list -n microservices-demo
NAME                            NAMESPACE               REVISION        UPDATED                                 STATUS          CHART           APP VERSION
microservices-demo-frontend     microservices-demo      1               2023-11-25 14:54:14.674237307 +0000 UTC deployed        frontend-0.8.1  v0.8.1
```

 - Проставим в репозитории `microservices-demo` тег `v0.0.2`, инициируя сборку новых образов. Образы собрались и появились в Container Registry Яндекса.
   Кстати, я использовал именно его вместо hub.docker.com, чтобы не утекла моя учётка. 
   Для того, чтобы `frontend` использовал новый образ, нужно проделать ряд действий, а именно создать несколько кастомных ресурсов и добавить специальный
   комментарий к HelmRelease. Сначала создаём секрет для скачивания образов. Вообще образы скачиваются и без него, но нам нужен также доступ к просмотру
   всех тегов, а для этого нужны дополнительные права. Итак, создаём сервисную учётку image-puller, даём ему роль `container-registry.images.puller`,
   создаём ключ, записываем его в файл и из файла создаём секрет:
```
$ kubectl create secret generic cr-yandex-image-puller --from-file=.dockerconfigjson=docker-config.json --type=kubernetes.io/dockerconfigjson --namespace microservices-demo
secret/cr-yandex-image-puller created
```

 - Создаём кастомный ресурс `ImageRepository` для фронтенда
```
$ flux create image repository yandex-hfrog-frontend --image cr.yandex/crpsgjav4a792j80c0iu/frontend --interval 3m --namespace microservices-demo --secret-ref cr-yandex-image-puller --export > deploy/releases/frontend-image-repository.yaml
```
затем commit, push и проверяем
```
$ flux get images repository yandex-hfrog-frontend -n microservices-demo
NAME                    LAST SCAN                       SUSPENDED       READY   MESSAGE
yandex-hfrog-frontend   2023-11-25T18:27:26+03:00       False           True    successful scan: found 2 tags
```
Видно, что он нашёл два тега.

 - Создадим `ImagePolicy` для фронтенда, в этой политике указывается условие поиска образов, в нашем случае это '~v0.0', т.е. фиксируем мажорную и минорные версии по нулям,
   а последнее число, фикс версия, может меняться. В политике ссылаемся на ранее созданную `ImageRepository`:
```
$ flux create image policy frontend-image-policy --image-ref yandex-hfrog-frontend --select-semver '~v0.0' --namespace microservices-demo --export > deploy/releases/frontend-image-policy.yaml
```
commit, push и проверяем:
```
$ flux get images policy frontend-image-policy -n microservices-demo
NAME                    LATEST IMAGE                                    READY   MESSAGE
frontend-image-policy   cr.yandex/crpsgjav4a792j80c0iu/frontend:v0.0.2  True    Latest image tag for 'cr.yandex/crpsgjav4a792j80c0iu/frontend' resolved to v0.0.2
```
Политика выдала тег `v0.0.2` для использования.

 - Создаём собственно автоматизатор обновления, который будет коммитить изменения в `HelmRelease`:
```
$ flux create image update frontend-image-updater --author-name FluxBot --author-email fluxbot@noreply.ru --git-repo-ref flux-system  --git-repo-namespace flux-system --interval 3m --checkout-branch main --namespace microservices-demo --export > deploy/releases/frontend-image-updater.yaml
```
затем commit, push и проверяем:
```
$ flux get images update frontend-image-updater -n microservices-demo
NAME                    LAST RUN                        SUSPENDED       READY   MESSAGE
frontend-image-updater  2023-11-25T18:36:31+03:00       False           True    no updates made
```
Возможно, его стоило создать в namespace `flux-system`, похоже его одного достаточно на все образы, в отличие от `ImageRepository` и `ImagePolicy`.

 - Но этого недостаточно, остался последний шаг - добавить специальный комментарий в `HelmRelease` фронтенда:
```
-      tag: v0.0.1
+      tag: v0.0.1 # {"$imagepolicy": "microservices-demo:frontend-image-policy:tag"}
```
commit, push и проверяем:
```
$ flux get images policy frontend-image-policy -n microservices-demo
NAME                    LATEST IMAGE                                    READY   MESSAGE
frontend-image-policy   cr.yandex/crpsgjav4a792j80c0iu/frontend:v0.0.2  True    Latest image tag for 'cr.yandex/crpsgjav4a792j80c0iu/frontend' updated from v0.0.1 to v0.0.2
```
Смотрим, что в репозитории появился коммит:
```
commit e3468efb0276a44b2185209b0b0c490c1333a859 (HEAD -> main, gitlab/main)
Author: FluxBot <fluxbot@noreply.ru>
Date:   Sat Nov 25 15:53:11 2023 +0000

    Update from image update automation

diff --git a/deploy/releases/frontend.yaml b/deploy/releases/frontend.yaml
index 3f61269..d91da2b 100644
--- a/deploy/releases/frontend.yaml
+++ b/deploy/releases/frontend.yaml
@@ -1,4 +1,3 @@
----
 apiVersion: helm.toolkit.fluxcd.io/v2beta1
 kind: HelmRelease
 metadata:
@@ -17,4 +16,4 @@ spec:
   values:
     images:
       repository: cr.yandex/crpsgjav4a792j80c0iu
-      tag: v0.0.1 # {"$imagepolicy": "microservices-demo:frontend-image-policy:tag"}
+      tag: v0.0.2 # {"$imagepolicy": "microservices-demo:frontend-image-policy:tag"}
```
Новый образ успешно подхватился.

 - После изменения названия чарта с `frontend` на `frontend-hipster` и версии с 0.8.1 на 0.8.2, обновился helmchart `microservices-demo-frontend`:
```
$ flux get sources chart microservices-demo-frontend -n flux-system
NAME                            REVISION        SUSPENDED       READY   MESSAGE
microservices-demo-frontend     0.8.2           False           True    packaged 'frontend-hipster' chart with version '0.8.2'
```
В логах source-controller появилась строчка
```
{"level":"info","ts":"2023-11-25T16:12:44.632Z","msg":"packaged 'frontend-hipster' chart with version '0.8.2'","controller":"helmchart","controllerGroup":"source.toolkit.fluxcd.io","controllerKind":"HelmChart","HelmChart":{"name":"microservices-demo-frontend","namespace":"flux-system"},"namespace":"flux-system","name":"microservices-demo-frontend","reconcileID":"2cefa7c5-acf6-4a40-8b49-6a115c2a1648"}
```
В логах helm-controller изменений нет, только обычные дежурные сообщения
```
{"level":"info","ts":"2023-11-25T16:12:45.738Z","msg":"reconciliation finished in 1.050075338s, next run in 1m0.494465146s","controller":"helmrelease","controllerGroup":"helm.toolkit.fluxcd.io","controllerKind":"HelmRelease","HelmRelease":{"name":"frontend","namespace":"microservices-demo"},"namespace":"microservices-demo","name":"frontend","reconcileID":"38668850-3687-46bf-9c14-f333e276527b"}
```

 - Добавил в flux микросервисы `currencyservice`, `productcatalogservice`, `cartservice` и `redis`, чтобы фронтенд не выдавал 500-ю ошибку.
   Все остальные я не стал затаскивать в flux, для экономии времени. Подход там то же самый.

 - Текущее состояние объектов flux:
```
NAMESPACE       NAME                            REVISION                SUSPENDED       READY   MESSAGE
flux-system     gitrepository/flux-system       main@sha1:746d47f6      False           True    stored artifact for revision 'main@sha1:746d47f6'

NAMESPACE       NAME                            REVISION        SUSPENDED       READY   MESSAGE
flux-system     helmrepository/ww-gitops                        False           True    Helm repository is ready

NAMESPACE       NAME                                                    REVISION        SUSPENDED       READY   MESSAGE
flux-system     helmchart/flux-system-ww-gitops                         4.0.35          False           True    pulled 'weave-gitops' chart with version '4.0.35'
flux-system     helmchart/microservices-demo-cartservice                0.8.1           False           True    packaged 'cartservice' chart with version '0.8.1'
flux-system     helmchart/microservices-demo-currencyservice            0.8.1           False           True    packaged 'currencyservice' chart with version '0.8.1'
flux-system     helmchart/microservices-demo-frontend                   0.9.1           False           True    packaged 'frontend' chart with version '0.9.1'
flux-system     helmchart/microservices-demo-productcatalogservice      0.8.1           False           True    packaged 'productcatalogservice' chart with version '0.8.1'
flux-system     helmchart/microservices-demo-redis                      0.8.1           False           True    packaged 'redis' chart with version '0.8.1'

NAMESPACE               NAME                                    LAST SCAN                       SUSPENDED       READY   MESSAGE
microservices-demo      imagerepository/yandex-hfrog-frontend   2023-11-26T12:42:16+03:00       False           True    successful scan: found 3 tags

NAMESPACE               NAME                                    LATEST IMAGE                                    READY   MESSAGE
microservices-demo      imagepolicy/frontend-image-policy       cr.yandex/crpsgjav4a792j80c0iu/frontend:v0.0.3  True    Latest image tag for 'cr.yandex/crpsgjav4a792j80c0iu/frontend' updated from v0.0.2 to v0.0.3

NAMESPACE               NAME                                            LAST RUN                        SUSPENDED       READY   MESSAGE
microservices-demo      imageupdateautomation/frontend-image-updater    2023-11-26T12:40:08+03:00       False           True    no updates made; last commit d08983d at 2023-11-26T08:45:13Z

NAMESPACE               NAME                                    REVISION        SUSPENDED       READY   MESSAGE
flux-system             helmrelease/ww-gitops                   4.0.35          False           True    Release reconciliation succeeded
microservices-demo      helmrelease/cartservice                 0.8.1           False           True    Release reconciliation succeeded
microservices-demo      helmrelease/currencyservice             0.8.1           False           True    Release reconciliation succeeded
microservices-demo      helmrelease/frontend                    0.9.1           False           True    Release reconciliation succeeded
microservices-demo      helmrelease/productcatalogservice       0.8.1           False           True    Release reconciliation succeeded
microservices-demo      helmrelease/redis                       0.8.1           False           True    Release reconciliation succeeded

NAMESPACE       NAME                            REVISION                SUSPENDED       READY   MESSAGE
flux-system     kustomization/flux-system       main@sha1:746d47f6      False           True    Applied revision: main@sha1:746d47f6
```

 - Хочется отметить, что получившаяся конструкция работает, но сломается при пересоздании из git, т.к. секреты я создавал ручками, и в гите их нет.
  Для улучшения ситуации можно использовать `sealed-secrets` от `bitnami-labs`, как рекомендуется в [документации flux](https://fluxcd.io/flux/security/secrets-management/).

 - Картинка из доски Weave-gitops, показывает [зависимости фронтенда](https://jmp.sh/F6vg9S2u).

 - Установим istio:
```
$ brew install istioctl
...

$ istioctl install --set profile=demo -y
✔ Istio core installed
✔ Istiod installed
✔ Egress gateways installed
✔ Ingress gateways installed
✔ Installation complete
Made this installation the default for injection and validation.
```

 - Установка `Istio` через оператор не одобряется разработчиками, пропущу.

 - Установим `Flagger`:
```
$ helm repo add flagger https://flagger.app
"flagger" has been added to your repositories

$ kubectl apply -f https://raw.githubusercontent.com/fluxcd/flagger/main/artifacts/flagger/crd.yaml
Warning: resource customresourcedefinitions/canaries.flagger.app is missing the kubectl.kubernetes.io/last-applied-configuration annotation which is required by kubectl apply. kubectl apply should only be used on resources created declaratively by either kubectl create --save-config or kubectl apply. The missing annotation will be patched automatically.
customresourcedefinition.apiextensions.k8s.io/canaries.flagger.app configured
Warning: resource customresourcedefinitions/metrictemplates.flagger.app is missing the kubectl.kubernetes.io/last-applied-configuration annotation which is required by kubectl apply. kubectl apply should only be used on resources created declaratively by either kubectl create --save-config or kubectl apply. The missing annotation will be patched automatically.
customresourcedefinition.apiextensions.k8s.io/metrictemplates.flagger.app configured
Warning: resource customresourcedefinitions/alertproviders.flagger.app is missing the kubectl.kubernetes.io/last-applied-configuration annotation which is required by kubectl apply. kubectl apply should only be used on resources created declaratively by either kubectl create --save-config or kubectl apply. The missing annotation will be patched automatically.
customresourcedefinition.apiextensions.k8s.io/alertproviders.flagger.app configured

$ kubectl apply -f https://raw.githubusercontent.com/fluxcd/flagger/main/artifacts/flagger/crd.yaml
customresourcedefinition.apiextensions.k8s.io/canaries.flagger.app unchanged
customresourcedefinition.apiextensions.k8s.io/metrictemplates.flagger.app unchanged
customresourcedefinition.apiextensions.k8s.io/alertproviders.flagger.app unchanged

$ helm upgrade -i flagger flagger/flagger --namespace=istio-system --set crd.create=false --set meshProvider=istio --set metricsServer=http://prometheus:9090
Release "flagger" does not exist. Installing it now.
NAME: flagger
LAST DEPLOYED: Sat Nov 25 23:36:32 2023
NAMESPACE: istio-system
STATUS: deployed
REVISION: 1
TEST SUITE: None
NOTES:
Flagger installed
```

 - Добавим в namespace `microservices-demo` метку для `Istio`: `istio-injection: enabled`. Сделаем это через манифест в репозитории:
```
$ flux events | tail
...
2s                      Normal  Progressing             Kustomization/flux-system               Namespace/microservices-demo configured                                           >
2s                      Normal  ReconciliationSucceeded Kustomization/flux-system               Reconciliation finished in 1.024988739s, next run in 10m0s                        >

$ kubectl get ns microservices-demo --show-labels
NAME                 STATUS   AGE     LABELS
microservices-demo   Active   6h30m   istio-injection=enabled,kubernetes.io/metadata.name=microservices-demo,kustomize.toolkit.fluxcd.io/name=flux-system,kustomize.toolkit.fluxcd.io/namespace=flux-system
```

 - Удалим поды в namespace `microservices-demo` и проверим что добавился контейнер `istio-proxy` (на тот момент у меня был только фронтенд):
```
$ kubectl delete pods --all -n microservices-demo
pod "frontend-6686db9b66-9plqb" deleted
$ kubectl get pods -n microservices-demo
NAME                        READY   STATUS    RESTARTS   AGE
frontend-6686db9b66-wd98p   2/2     Running   0          75s
$ kubectl describe pod -l app=frontend -n microservices-demo
...
  istio-proxy:
    Container ID:  containerd://73650aad1deb5880677a63b149d557990c72c0163cc617051387ee4ab59570f3
    Image:         docker.io/istio/proxyv2:1.20.0
    Image ID:      docker.io/istio/proxyv2@sha256:19e8ca96e4f46733a3377fa962cb88cad13a35afddb9139ff795e36237327137
    Port:          15090/TCP
    Host Port:     0/TCP
...
```

 - Добавим файлы с манифестами `Gateway` и `VirtualService` сразу в helm-чарт, вот сюда `helm-charts/frontend/templates/gateway.yaml`,
 `helm-charts/frontend/templates/virtualservice.yaml` и проверим:
```
$ kubectl get gateway -n microservices-demo
NAME               AGE
frontend-gateway   25s
$ kubectl get svc istio-ingressgateway -n istio-system
NAME                   TYPE           CLUSTER-IP     EXTERNAL-IP       PORT(S)                                                                      AGE
istio-ingressgateway   LoadBalancer   10.10.10.185   158.160.129.149   15021:32373/TCP,80:30530/TCP,443:32435/TCP,31400:31271/TCP,15443:31638/TCP   10m
```
Доступ по http://158.160.129.149 работает.

 - Для метрик, используемых канареечными деплоями, установим `Prometheus`:
```
$ kubectl apply -f https://raw.githubusercontent.com/istio/istio/release-1.20/samples/addons/prometheus.yaml
serviceaccount/prometheus created
configmap/prometheus created
clusterrole.rbac.authorization.k8s.io/prometheus created
clusterrolebinding.rbac.authorization.k8s.io/prometheus created
service/prometheus created
deployment.apps/prometheus created
```

 - Добавим манифест для Canary в helm-чарт, затем commit, push:
```
$ kubectl get canary -n microservices-demo
NAME       STATUS        WEIGHT   LASTTRANSITIONTIME
frontend   Initialized   0        2023-11-26T08:32:46Z

$ kubectl get deployment -n microservices-demo | grep frontend
frontend           0/0     0            0           17h
frontend-primary   1/1     1            1           8m8s

$ kubectl get pods -n microservices-demo | grep frontend
frontend-primary-6dddbd98cd-2fpkr   2/2     Running   0          8m21s
```

 - Соберём новый образ и проверим канареечный деплой:
```
$ kubectl describe canary frontend -n microservices-demo | tail -15
  Last Transition Time:    2023-11-26T08:50:45Z
  Phase:                   Failed
  Tracked Configs:
Events:
  Type     Reason  Age                    From     Message
  ----     ------  ----                   ----     -------
  Warning  Synced  18m                    flagger  frontend-primary.microservices-demo not ready: waiting for rollout to finish: observed deployment generation less than desired generation
  Normal   Synced  18m (x2 over 18m)      flagger  all the metrics providers are available!
  Normal   Synced  18m                    flagger  Initialization done! frontend.microservices-demo
  Normal   Synced  5m14s                  flagger  New revision detected! Scaling up frontend.microservices-demo
  Normal   Synced  4m44s                  flagger  Starting canary analysis for frontend.microservices-demo
  Normal   Synced  4m44s                  flagger  Advance frontend.microservices-demo canary weight 5
  Warning  Synced  2m14s (x5 over 4m14s)  flagger  Halt advancement no values found for istio metric request-success-rate probably frontend.microservices-demo is not receiving traffic: running query failed: no values found
  Warning  Synced  104s                   flagger  Rolling back frontend.microservices-demo failed checks threshold reached 5
  Warning  Synced  104s                   flagger  Canary failed! Scaling down frontend.microservices-demo
```
Не получилось, т.к. нет трафика.

 - Запустим в цикле раз в секунду `http://158.160.129.149` и попробуем ещё раз, добавив аннотацию `spec.template.metadata.timestamp`
  в деплоймент `frontend`, прям наживую в кластере, без изменения манифестов, это чтобы автоматика заметила изменение объекта, и проверим:
```
$ kubectl describe canary frontend -n microservices-demo | tail -15
Events:
  Type     Reason  Age                  From     Message
  ----     ------  ----                 ----     -------
  Normal   Synced  6m37s (x2 over 98m)  flagger  New revision detected! Scaling up frontend.microservices-demo
  Normal   Synced  6m7s (x2 over 98m)   flagger  Starting canary analysis for frontend.microservices-demo
  Normal   Synced  6m7s (x2 over 98m)   flagger  Advance frontend.microservices-demo canary weight 5
  Warning  Synced  5m7s (x7 over 97m)   flagger  Halt advancement no values found for istio metric request-success-rate probably frontend.microservices-demo is not receiving traffic: running query failed: no values found
  Normal   Synced  4m37s                flagger  Advance frontend.microservices-demo canary weight 10
  Warning  Synced  4m7s                 flagger  Halt advancement no values found for istio metric request-duration probably frontend.microservices-demo is not receiving traffic
  Normal   Synced  3m37s                flagger  Advance frontend.microservices-demo canary weight 15
  Normal   Synced  3m7s                 flagger  Advance frontend.microservices-demo canary weight 20
  Normal   Synced  2m37s                flagger  Advance frontend.microservices-demo canary weight 25
  Normal   Synced  2m7s                 flagger  Advance frontend.microservices-demo canary weight 30
  Normal   Synced  97s                  flagger  Copying frontend.microservices-demo template spec to frontend-primary.microservices-demo
  Normal   Synced  37s (x2 over 67s)    flagger  (combined from similar events): Promotion completed! Scaling down frontend.microservices-demo
```
Получилось. 

 - Теперь попробуем без ручной генерации трафика, установим `flagger-loadtester`
```
$ helm upgrade --install flagger-loadtester flagger/loadtester --namespace=test --create-namespace --set cmd.timeout=1h --set cmd.namespaceRegexp=''
Release "flagger-loadtester" does not exist. Installing it now.
NAME: flagger-loadtester
LAST DEPLOYED: Sun Nov 26 13:47:41 2023
NAMESPACE: test
STATUS: deployed
REVISION: 1
TEST SUITE: None
NOTES:
Flagger's load testing service is available at http://flagger-loadtester.test/
```

 - Добавим webhook и поменяем аннотацию timestamp
```
$ kubectl events --for canary/frontend -n microservices-demo --watch
0s (x4 over 137m)     Normal    Synced   Canary/frontend   New revision detected! Scaling up frontend.microservices-demo
0s (x4 over 137m)     Normal    Synced   Canary/frontend   Starting canary analysis for frontend.microservices-demo
0s (x4 over 137m)     Normal    Synced   Canary/frontend   Advance frontend.microservices-demo canary weight 5
0s (x13 over 137m)    Warning   Synced   Canary/frontend   Halt advancement no values found for istio metric request-success-rate probably frontend.microservices-demo is not receiving traffic: running query failed: no values found
0s (x2 over 44m)      Normal    Synced   Canary/frontend   Advance frontend.microservices-demo canary weight 10
0s (x2 over 44m)      Normal    Synced   Canary/frontend   Advance frontend.microservices-demo canary weight 15
0s (x14 over 138m)    Warning   Synced   Canary/frontend   Halt advancement no values found for istio metric request-success-rate probably frontend.microservices-demo is not receiving traffic: running query failed: no values found
0s                    Warning   Synced   Canary/frontend   Halt frontend.microservices-demo advancement request duration 634ms > 500ms
0s (x2 over 45m)      Normal    Synced   Canary/frontend   Advance frontend.microservices-demo canary weight 20
0s                    Warning   Synced   Canary/frontend   Halt frontend.microservices-demo advancement request duration 630ms > 500ms
0s (x3 over 139m)     Warning   Synced   Canary/frontend   Rolling back frontend.microservices-demo failed checks threshold reached 5
```
Не получилось из-за большого времени ответа.

 - Увеличим request-duration до 750мс и попробуем снова
```
0s (x5 over 154m)     Normal    Synced   Canary/frontend   New revision detected! Scaling up frontend.microservices-demo
0s (x5 over 154m)     Normal    Synced   Canary/frontend   Starting canary analysis for frontend.microservices-demo
0s                    Warning   Synced   Canary/frontend   Halt frontend.microservices-demo advancement request duration 819ms > 750ms
```
Опять не получилось.

 - Увеличим время до 1000мс и уменьшим кол-во запросов тестовой нагрузки до 3 запросов в секунду
`hey -z 1m -q 3 -c 1 http://{{ .Values.frontend.name }}-canary.{{.Release.Namespace}}/`
```
$ kubectl describe canary frontend -n microservices-demo | tail
...
  Normal   Synced  8m39s (x6 over 3h1m)  flagger  New revision detected! Scaling up frontend.microservices-demo
  Normal   Synced  8m9s (x6 over 3h)     flagger  Starting canary analysis for frontend.microservices-demo
  Normal   Synced  8m9s (x6 over 3h)     flagger  Advance frontend.microservices-demo canary weight 5
  Normal   Synced  3m39s (x2 over 84m)   flagger  Copying frontend.microservices-demo template spec to frontend-primary.microservices-demo
$ kubectl get canary frontend -n microservices-demo
NAME       STATUS      WEIGHT   LASTTRANSITIONTIME
frontend   Succeeded   0        2023-11-26T11:44:15Z
```
На этот раз получилось.

# Выполнено ДЗ №11

 - [*] Основное ДЗ
 - [*] Задание со * (1)
 - [*] Задание со * (2)
 - [*] Задание со * (3)

## В процессе сделано:

 - Склонируем репозиторий consul-k8s
```
$ git clone https://github.com/hashicorp/consul-k8s.git
...
```

 - Создадим файл значений для консула, укажем там три реплики.
```
$ cat consul.values.yaml
global:
  name: consul
server:
  replicas: 3
```

 - Запустим consul
```
$ cd consul-k8s/charts
$ helm upgrade --install consul ./consul --namespace consul --create-namespace --values=...path...consul.values.yaml
Release "consul" does not exist. Installing it now.
NAME: consul
LAST DEPLOYED: Fri Jan  5 14:06:04 2024
NAMESPACE: consul
STATUS: deployed
REVISION: 1
NOTES:
Thank you for installing HashiCorp Consul!

Your release is named consul.

To learn more about the release, run:

  $ helm status consul --namespace consul
  $ helm get all consul --namespace consul

Consul on Kubernetes Documentation:
https://www.consul.io/docs/platform/k8s

Consul on Kubernetes CLI Reference:
https://www.consul.io/docs/k8s/k8s-cli
```

 - Зайдём на любой pod консула, например `consul-server-0` и выведем список членов кластера
```
$ kubectl exec -it consul-server-0 -n consul -c consul -- consul members
Node             Address              Status  Type    Build      Protocol  DC   Partition  Segment
consul-server-0  172.16.129.77:8301   alive   server  1.18.0dev  2         dc1  default    <all>
consul-server-1  172.16.128.39:8301   alive   server  1.18.0dev  2         dc1  default    <all>
consul-server-2  172.16.134.112:8301  alive   server  1.18.0dev  2         dc1  default    <all>
```

 - Склонируем репозиторий vault-helm
```
$ git clone https://github.com/hashicorp/vault-helm.git
...
```

 - Подготовим файл со значениями для helm.
  Без явного указания consul-server.consul.svc:8500 vault не видит консула, т.к. у того по умолчанию выключен
  daemonset, который слушает на ноде порт 8500. Однако если его включить, vault всё равно не видит, т.к. на ноде
  не создаются порты, по видимому из-за CNI. Можно включить hostNetwork, но лучше укажем имя сервиса.
```
$ cat vault.values.yaml
server:
  standalone:
    enabled: false
  ha:
    enabled: true
    config: |
      ui = true

      listener "tcp" {
        tls_disable = 1
        address = "[::]:8200"
        cluster_address = "[::]:8201"
      }
      storage "consul" {
        path = "vault"
        address = "consul-server.consul.svc:8500"
      }

ui:
  enabled: true
```


 - Установим vault
```
$ helm upgrade --install vault ./vault-helm --namespace vault --create-namespace --values ...path...vault.values.yaml
Release "vault" does not exist. Installing it now.
NAME: vault
LAST DEPLOYED: Fri Jan  5 15:00:02 2024
NAMESPACE: vault
STATUS: deployed
REVISION: 1
NOTES:
Thank you for installing HashiCorp Vault!

Now that you have deployed Vault, you should look over the docs on using
Vault with Kubernetes available here:

https://developer.hashicorp.com/vault/docs


Your release is named vault. To learn more about the release, try:

  $ helm status vault
  $ helm get manifest vault

$ helm status vault -n vault
NAME: vault
LAST DEPLOYED: Fri Jan  5 15:00:02 2024
NAMESPACE: vault
STATUS: deployed
REVISION: 1
NOTES:
Thank you for installing HashiCorp Vault!

Now that you have deployed Vault, you should look over the docs on using
Vault with Kubernetes available here:

https://developer.hashicorp.com/vault/docs


Your release is named vault. To learn more about the release, try:

  $ helm status vault
  $ helm get manifest vault
```

- Vault кластер не готов, об этом говорят значения в столбце READY:
```
$ kubectl get pods -n vault -o wide
NAME                                    READY   STATUS    RESTARTS   AGE   IP               NODE                        NOMINATED NODE   READINESS GATES
vault-0                                 0/1     Running   0          80s   172.16.128.40    cl1t71pih712apipoeeo-icul   <none>           <none>
vault-1                                 0/1     Running   0          80s   172.16.134.113   node3-default-pool          <none>           <none>
vault-2                                 0/1     Running   0          80s   172.16.129.79    node1-default-pool          <none>           <none>
vault-agent-injector-7f7f68d457-jnlgm   1/1     Running   0          80s   172.16.129.78    node1-default-pool          <none>           <none>
```

 - Посмотрим логи. Vault не инициализирован:
```
$ kubectl logs vault-0 -n vault
==> Vault server configuration:

Administrative Namespace:
             Api Address: http://172.16.128.40:8200
                     Cgo: disabled
         Cluster Address: https://vault-0.vault-internal:8201
   Environment Variables: GODEBUG, HOME, HOSTNAME, HOST_IP, KUBERNETES_PORT, ...
              Go Version: go1.21.3
              Listener 1: tcp (addr: "[::]:8200", cluster address: "[::]:8201", max_request_duration: "1m30s", max_request_size: "33554432", tls: "disabled")
               Log Level:
                   Mlock: supported: true, enabled: false
           Recovery Mode: false
                 Storage: consul (HA available)
                 Version: Vault v1.15.2, built 2023-11-06T11:33:28Z
             Version Sha: cf1b5cafa047bc8e4a3f93444fcb4011593b92cb

2024-01-05T12:35:27.420Z [INFO]  proxy environment: http_proxy="" https_proxy="" no_proxy=""
2024-01-05T12:35:27.421Z [WARN]  storage.consul: appending trailing forward slash to path
2024-01-05T12:35:27.424Z [INFO]  incrementing seal generation: generation=1
2024-01-05T12:35:27.426Z [INFO]  core: Initializing version history cache for core
2024-01-05T12:35:27.426Z [INFO]  events: Starting event system
==> Vault server started! Log data will stream in below:

2024-01-05T12:35:32.163Z [INFO]  core: security barrier not initialized
2024-01-05T12:35:32.163Z [INFO]  core: seal configuration missing, not initialized
2024-01-05T12:35:37.140Z [INFO]  core: security barrier not initialized
2024-01-05T12:35:37.140Z [INFO]  core: seal configuration missing, not initialized
...
```

 - Статус кластера подтверждает, он не инициализирован:
```
$ kubectl exec -it vault-0 -n vault -- vault status
Key                Value
---                -----
Seal Type          shamir
Initialized        false
Sealed             true
Total Shares       0
Threshold          0
Unseal Progress    0/0
Unseal Nonce       n/a
Version            1.15.2
Build Date         2023-11-06T11:33:28Z
Storage Type       consul
HA Enabled         true
command terminated with exit code 2
```

 - Инициализируем кластер vault:
```
$ kubectl exec -it vault-0 -n vault -- vault operator init --key-shares=1 --key-threshold=1
Unseal Key 1: ozLtD6E41N1kLHNTkttjbmjWebBQL80NIqOz2mOtPpA=

Initial Root Token: hvs.ICk2GESAFpMyR6JqkeCqkF8t

Vault initialized with 1 key shares and a key threshold of 1. Please securely
distribute the key shares printed above. When the Vault is re-sealed,
restarted, or stopped, you must supply at least 1 of these keys to unseal it
before it can start servicing requests.

Vault does not store the generated root key. Without at least 1 keys to
reconstruct the root key, Vault will remain permanently sealed!

It is possible to generate new unseal keys, provided you have a quorum of
existing unseal keys shares. See "vault operator rekey" for more information.
```

 - Кластер инициализирован, но всё ещё запечатан
```
$ kubectl exec -it vault-0 -n vault -- vault status
Key                Value
---                -----
Seal Type          shamir
Initialized        true
Sealed             true
Total Shares       1
Threshold          1
Unseal Progress    0/1
Unseal Nonce       n/a
Version            1.15.2
Build Date         2023-11-06T11:33:28Z
Storage Type       consul
HA Enabled         true
command terminated with exit code 2
```

 - В логах также видно, что теперь кластер инициализирован
```
2024-01-05T12:39:00.422Z [INFO]  core: seal configuration missing, not initialized
2024-01-05T12:39:00.426Z [INFO]  core: security barrier not initialized
2024-01-05T12:39:00.644Z [INFO]  core: security barrier initialized: stored=1 shares=1 threshold=1
2024-01-05T12:39:00.817Z [INFO]  core: post-unseal setup starting
2024-01-05T12:39:00.912Z [INFO]  core: loaded wrapping token key
2024-01-05T12:39:00.912Z [INFO]  core: successfully setup plugin runtime catalog
2024-01-05T12:39:00.912Z [INFO]  core: successfully setup plugin catalog: plugin-directory=""
2024-01-05T12:39:00.914Z [INFO]  core: no mounts; adding default mount table
2024-01-05T12:39:01.059Z [INFO]  core: successfully mounted: type=cubbyhole version="v1.15.2+builtin.vault" path=cubbyhole/ namespace="ID: root. Path: "
2024-01-05T12:39:01.060Z [INFO]  core: successfully mounted: type=system version="v1.15.2+builtin.vault" path=sys/ namespace="ID: root. Path: "
2024-01-05T12:39:01.060Z [INFO]  core: successfully mounted: type=identity version="v1.15.2+builtin.vault" path=identity/ namespace="ID: root. Path: "
2024-01-05T12:39:01.350Z [INFO]  core: successfully mounted: type=token version="v1.15.2+builtin.vault" path=token/ namespace="ID: root. Path: "
2024-01-05T12:39:01.384Z [INFO]  rollback: Starting the rollback manager with 256 workers
2024-01-05T12:39:01.384Z [INFO]  rollback: starting rollback manager
2024-01-05T12:39:01.384Z [INFO]  core: restoring leases
2024-01-05T12:39:01.386Z [INFO]  expiration: lease restore complete
2024-01-05T12:39:01.445Z [INFO]  identity: entities restored
2024-01-05T12:39:01.445Z [INFO]  identity: groups restored
2024-01-05T12:39:01.449Z [INFO]  core: usage gauge collection is disabled
2024-01-05T12:39:01.498Z [INFO]  core: Recorded vault version: vault version=1.15.2 upgrade time="2024-01-05 12:39:01.449137625 +0000 UTC" build date=2023-11-06T11:33:28Z
2024-01-05T12:39:02.101Z [INFO]  core: post-unseal setup complete
2024-01-05T12:39:02.210Z [INFO]  core: root token generated
2024-01-05T12:39:02.210Z [INFO]  core: pre-seal teardown starting
2024-01-05T12:39:02.211Z [INFO]  rollback: stopping rollback manager
2024-01-05T12:39:02.211Z [INFO]  core: pre-seal teardown complete
```

 - Удалим данные vault из key/value consul через web-интерфейс, удалим поды vault, они перезапустятся и проверим статус. Кластер снова не инициализирован
```
$ kubectl exec -it vault-0 -n vault -- vault status
Key                Value
---                -----
Seal Type          shamir
Initialized        false
Sealed             true
Total Shares       0
Threshold          0
Unseal Progress    0/0
Unseal Nonce       n/a
Version            1.15.2
Build Date         2023-11-06T11:33:28Z
Storage Type       consul
HA Enabled         true
command terminated with exit code 2
```

 - Инициализируем его снова, но теперь разделим ключ на 5 частей, для распечатывания требуя 3 из них:
```
$ kubectl exec -it vault-0 -n vault -- vault operator init --key-shares=5 --key-threshold=3
Unseal Key 1: AauNrLfv+zGYmSwYT2D+rbm1vRIgaeblfUT/ViM/9iWF
Unseal Key 2: ZSVDeOD5acKcxm8q/NyTmByu/qw2rRe1kngD1w4AN1I8
Unseal Key 3: DM9anLGLQn5g/W4VhLkgKnrjDa1s5zG6xLuca/LcDYvb
Unseal Key 4: 2Q58IqPqyJGRpqR265609HZzZpRkvP+moywnvZrJf190
Unseal Key 5: Irl0//rNp14/sEj7Z7nLIx1tuEjJWTMNgVKvno2gMBfL

Initial Root Token: hvs.5ht9q3twVQ2170TrHHY3gBuv

Vault initialized with 5 key shares and a key threshold of 3. Please securely
distribute the key shares printed above. When the Vault is re-sealed,
restarted, or stopped, you must supply at least 3 of these keys to unseal it
before it can start servicing requests.

Vault does not store the generated root key. Without at least 3 keys to
reconstruct the root key, Vault will remain permanently sealed!

It is possible to generate new unseal keys, provided you have a quorum of
existing unseal keys shares. See "vault operator rekey" for more information.
```

 - Распечатаем кластер vault командой `vault operator unseal`, вводя по три ключа из пяти на каждом поде и потом проверим статус. На каждом Sealed == false:
```
$ kubectl exec -it vault-0 -n vault -- vault status
Key                    Value
---                    -----
Seal Type              shamir
Initialized            true
Sealed                 false
Total Shares           5
Threshold              3
Version                1.15.2
Build Date             2023-11-06T11:33:28Z
Storage Type           consul
Cluster Name           vault-cluster-6a9f6950
Cluster ID             aee820b5-6c9b-4d48-d27f-6a3711ed8823
HA Enabled             true
HA Cluster             https://vault-1.vault-internal:8201
HA Mode                standby
Active Node Address    http://172.16.134.114:8200
```

 - Попробуем сделать запрос к vault, неудачно
```
$ kubectl exec -it vault-0 -n vault -- vault auth list
Error listing enabled authentications: Error making API request.

URL: GET http://127.0.0.1:8200/v1/sys/auth
Code: 403. Errors:

* permission denied
command terminated with exit code 2
```

 - Залогинимся в vault, введя root token
```
$ kubectl exec -it vault-0 -n vault -- vault login
Token (will be hidden):
Success! You are now authenticated. The token information displayed below
is already stored in the token helper. You do NOT need to run "vault login"
again. Future Vault requests will automatically use this token.

Key                  Value
---                  -----
token                hvs.5ht9q3twVQ2170TrHHY3gBuv
token_accessor       qGNmstqRq7eXtZtFcHTM6Gj5
token_duration       ∞
token_renewable      false
token_policies       ["root"]
identity_policies    []
policies             ["root"]
```

 - Снова проверим список авторизаций, на этот раз успешно
```
$ kubectl exec -it vault-0 -n vault -- vault auth list
Path      Type     Accessor               Description                Version
----      ----     --------               -----------                -------
token/    token    auth_token_548b4429    token based credentials    n/a
```

- Включим движок key-value по пути otus и запишем туда несколько значений:
```
$ kubectl exec -it vault-0 -n vault -- vault secrets enable --path=otus kv
Success! Enabled the kv secrets engine at: otus/
$ kubectl exec -it vault-0 -n vault -- vault secrets list --detailed
Path          Plugin       Accessor              Default TTL    Max TTL    Force No Cache    Replication    Seal Wrap    External Entropy Access    Options    Description                                                UUID                                    Version    Running Version          Running SHA256    Deprecation Status
----          ------       --------              -----------    -------    --------------    -----------    ---------    -----------------------    -------    -----------                                                ----                                    -------    ---------------          --------------    ------------------
cubbyhole/    cubbyhole    cubbyhole_a8f62704    n/a            n/a        false             local          false        false                      map[]      per-token private secret storage                           bf3c88ec-c12b-bf85-5106-141fe14249c8    n/a        v1.15.2+builtin.vault    n/a               n/a
identity/     identity     identity_73a7c494     system         system     false             replicated     false        false                      map[]      identity store                                             48aba652-729a-e57e-821c-ae90991815e4    n/a        v1.15.2+builtin.vault    n/a               n/a
otus/         kv           kv_cc043026           system         system     false             replicated     false        false                      map[]      n/a                                                        4bae8338-f7de-fa13-adda-47cf16de923c    n/a        v0.16.1+builtin          n/a               supported
sys/          system       system_40941c2f       n/a            n/a        false             replicated     true         false                      map[]      system endpoints used for control, policy and debugging    c1fa8a1e-03e5-33c6-1872-a54f4da51b73    n/a        v1.15.2+builtin.vault    n/a               n/a
$ kubectl exec -it vault-0 -n vault -- vault kv put otus/otus-ro/config username='otus' password='asajkjkahs'
Success! Data written to: otus/otus-ro/config
$ kubectl exec -it vault-0 -n vault -- vault kv put otus/otus-rw/config username='otus' password='asajkjkahs'
Success! Data written to: otus/otus-rw/config
$ kubectl exec -it vault-0 -n vault -- vault read otus/otus-ro/config
Key                 Value
---                 -----
refresh_interval    768h
password            asajkjkahs
username            otus
$ kubectl exec -it vault-0 -n vault -- vault kv get otus/otus-rw/config
====== Data ======
Key         Value
---         -----
password    asajkjkahs
username    otus
```

 - Включим Kubernetes auth:
```
$ kubectl exec -it vault-0 -n vault -- vault auth enable kubernetes
Success! Enabled kubernetes auth method at: kubernetes/
$ kubectl exec -it vault-0 -n vault -- vault auth list
Path           Type          Accessor                    Description                Version
----           ----          --------                    -----------                -------
kubernetes/    kubernetes    auth_kubernetes_2a8e13f8    n/a                        n/a
token/         token         auth_token_548b4429         token based credentials    n/a
```

 - Создадим сервисную учётку `vault-auth`, файл `vault-auth-service-account.yml` с ClusterRoleBinding, он есть в репозитории, и применим его:
```
$ kubectl create serviceaccount vault-auth
serviceaccount/vault-auth created
$ kubectl apply -f vault-auth-service-account.yml
clusterrolebinding.rbac.authorization.k8s.io/role-tokenreview-binding created
```

 - Соберём данные для настройки auth/kubernetes. Поскольку начиная с 1.24 kubernetes не создаёт секреты при создании сервисных учёток,
 создадим сами, через файл:
```
$ cat vault-auth-secret.yaml
apiVersion: v1
kind: Secret
metadata:
  name: vault-auth-secret
  annotations:
    kubernetes.io/service-account.name: vault-auth
type: kubernetes.io/service-account-token
$ kubectl apply -f vault-auth-secret.yaml
secret/vault-auth-secret created
```

 - Токен и корневой сертификат возьмём непосредственно из созданного секрета:
```
$ export SA_JWT_TOKEN=$(kubectl get secret vault-auth-secret -o jsonpath="{.data.token}" | base64 --decode)
$ export SA_CA_CRT=$(kubectl get secret vault-auth-secret -o jsonpath="{.data.ca\.crt}" | base64 --decode)
```
 - K8S_HOST можем взять из конфига kubectl, а можем из вывода `kubectl cluster-info`. Второй не предназначен для машинного разбора,
   хотя это можно сделать, вырезав escape-последовательности ANSI командой sed ’s/\x1b\[[0-9;]*m//g’.
   Поэтому возьмём из конфига kubectl, выведя текущий контекст в формате JSON и выбрав соответствующее значение:
```
export K8S_HOST=$(kubectl config view --minify -o json | jq -r .clusters[].cluster.server)
```

 - Настроим auth/kubernetes:
```
$ kubectl exec -it vault-0 -n vault -- vault write auth/kubernetes/config \
> token_reviewer_jwt="$SA_JWT_TOKEN" kubernetes_host="$K8S_HOST" kubernetes_ca_cert="$SA_CA_CRT"
Success! Data written to: auth/kubernetes/config
```

 - Создадим файл `otus-policy.hcl` с политикой доступа к секретам otus и скопируем его в первый pod vault.
 Директория /tmp, т.к. в корень нет доступа. И создадим политику из загруженного файла:
```
$ cat otus-policy.hcl
path "otus/otus-ro/*" {
    capabilities = ["read", "list"]
}
path "otus/otus-rw/*" {
    capabilities = ["read", "create", "list"]
}
$ kubectl cp -n vault otus-policy.hcl vault-0:/tmp
$ kubectl exec -it vault-0 -n vault -- vault policy write otus-policy /tmp/otus-policy.hcl
Success! Uploaded policy: otus-policy
```

 - Создадим роль, дающую на 24 часа доступ сервисной учётке vault-auth в namespace default, согласно политике otus-policy:
```
$ kubectl exec -it vault-0 -n vault -- vault write auth/kubernetes/role/otus \
> bound_service_account_names=vault-auth bound_service_account_namespaces=default policies=otus-policy ttl=24h
Success! Data written to: auth/kubernetes/role/otus
```

 - Запустим тестовый pod с Alpine, манифест `alpine.yaml` есть в репозитории, залогинимся и получим клиентский токен
```
$ kubectl exec -it alpine -- sh
/ # VAULT_ADDR=http://vault.vault:8200
/ # KUBE_TOKEN=$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)
/ # curl -s --request POST --data '{"jwt": "'$KUBE_TOKEN'", "role": "otus"}' $VAULT_ADDR/v1/auth/kubernetes/login | jq
{
  "request_id": "b1933d3a-eed2-3436-02c7-017ad87a44cc",
  "lease_id": "",
  "renewable": false,
  "lease_duration": 0,
  "data": null,
  "wrap_info": null,
  "warnings": null,
  "auth": {
    "client_token": "hvs.CAESIMrv25PEt5r14JqtP4_qBPgUUPdIYGlzmrAtWjZ1bA0iGh4KHGh2cy5VcW84OVRmWmR0YUJETHBMdEdDSUdEc3A",
    "accessor": "O2NqDPhajua6bd13lx9cDUfl",
    "policies": [
      "default",
      "otus-policy"
    ],
    "token_policies": [
      "default",
      "otus-policy"
    ],
    "metadata": {
      "role": "otus",
      "service_account_name": "vault-auth",
      "service_account_namespace": "default",
      "service_account_secret_name": "",
      "service_account_uid": "7a7ee837-f61d-4ecc-8b75-d879a481a06f"
    },
    "lease_duration": 86400,
    "renewable": true,
    "entity_id": "3780c340-bdb7-68d6-bfdc-db06e1f1969e",
    "token_type": "service",
    "orphan": true,
    "mfa_requirement": null,
    "num_uses": 0
  }
}
/ # TOKEN=$(curl -s --request POST --data '{"jwt": "'$KUBE_TOKEN'", "role": "otus"}' $VAULT_ADDR/v1/auth/kubernetes/login | jq -r .auth.client_token)
```

 - Используем полученный токен для доступа к данным:
```
/ # curl -s --header "X-Vault-Token: $TOKEN" $VAULT_ADDR/v1/otus/otus-ro/config | jq
{
  "request_id": "15e0557e-726c-69af-e939-60bbf003e9e6",
  "lease_id": "",
  "renewable": false,
  "lease_duration": 2764800,
  "data": {
    "password": "asajkjkahs",
    "username": "otus"
  },
  "wrap_info": null,
  "warnings": null,
  "auth": null
}
/ # curl -s --header "X-Vault-Token: $TOKEN" $VAULT_ADDR/v1/otus/otus-rw/config | jq
{
  "request_id": "e9c179c1-3ce0-8194-c28d-10f5e846f912",
  "lease_id": "",
  "renewable": false,
  "lease_duration": 2764800,
  "data": {
    "password": "asajkjkahs",
    "username": "otus"
  },
  "wrap_info": null,
  "warnings": null,
  "auth": null
}
/ # curl -s --request POST --data '{"bar": "baz"}' --header "X-Vault-Token: $TOKEN" $VAULT_ADDR/v1/otus/otus-ro/config | jq
{
  "errors": [
    "1 error occurred:\n\t* permission denied\n\n"
  ]
}
/ # curl -s --request POST --data '{"bar": "baz"}' --header "X-Vault-Token: $TOKEN" $VAULT_ADDR/v1/otus/otus-rw/config | jq
{
  "errors": [
    "1 error occurred:\n\t* permission denied\n\n"
  ]
}
/ # curl -s --request POST --data '{"bar": "baz"}' --header "X-Vault-Token: $TOKEN" $VAULT_ADDR/v1/otus/otus-rw/config1 | jq
/ #
/ # curl -s --request POST --data '{"bar": "baz"}' --header "X-Vault-Token: $TOKEN" $VAULT_ADDR/v1/otus/otus-rw/config1 | jq
{
  "errors": [
    "1 error occurred:\n\t* permission denied\n\n"
  ]
}
```

 - Запись в существующий ключ запрещена, поэтому не получилось записать ни в otus-rw/config, ни второй раз в otus-rw/config1.
  Добавим в политику возможность "update" и проверим ещё раз:
```
$ cat otus-policy.hcl
path "otus/otus-ro/*" {
    capabilities = ["read", "list"]
}
path "otus/otus-rw/*" {
    capabilities = ["read", "create", "update", "list"]
}
$ kubectl cp -n vault otus-policy.hcl vault-0:/tmp
$ kubectl exec -it vault-0 -n vault -- vault policy write otus-policy /tmp/otus-policy.hcl
Success! Uploaded policy: otus-policy
/ # curl -s --request POST --data '{"bar": "baz"}' --header "X-Vault-Token: $TOKEN" $VAULT_ADDR/v1/otus/otus-rw/config | jq
/ # curl -s --header "X-Vault-Token: $TOKEN" $VAULT_ADDR/v1/otus/otus-rw/config | jq
{
  "request_id": "e5936de9-06f2-d5b4-6c1c-bdbfb22356ed",
  "lease_id": "",
  "renewable": false,
  "lease_duration": 2764800,
  "data": {
    "bar": "baz"
  },
  "wrap_info": null,
  "warnings": null,
  "auth": null
}
```
Запись прошла, чтение подтверждает это.

 - Склонируем vault-guides и подкорректиуем конфиги, ои есть в репозитории
```
$ git clone https://github.com/hashicorp/vault-guides.git
...
$ cd vault-guides/identity/vault-agent-k8s-demo
```

 - Создаём configmap, запускаем pod, выведем configmap для просмотра и проверим, что pod запустился:
```
$ kubectl apply -f configmap.yaml
configmap/example-vault-agent-config created

$ kubectl apply -f example-k8s-spec.yaml
pod/vault-agent-example created

$ kubectl get configmap example-vault-agent-config -o yaml
apiVersion: v1
data:
  vault-agent-config.hcl: |
    # Comment this out if running as sidecar instead of initContainer
    exit_after_auth = true

    pid_file = "/home/vault/pidfile"

    auto_auth {
        method "kubernetes" {
            mount_path = "auth/kubernetes"
            config = {
                role = "otus"
            }
        }

        sink "file" {
            config = {
                path = "/home/vault/.vault-token"
            }
        }
    }

    template {
    destination = "/etc/secrets/index.html"
    contents = <<EOT
    <html>
    <body>
    <p>Some secrets:</p>
    {{- with secret "otus/otus-ro/config" }}
    <ul>
    <li><pre>username: {{ .Data.username }}</pre></li>
    <li><pre>password: {{ .Data.password }}</pre></li>
    </ul>
    {{ end }}
    </body>
    </html>
    EOT
    }
kind: ConfigMap
metadata:
  annotations:
    kubectl.kubernetes.io/last-applied-configuration: |
      {"apiVersion":"v1","data":{"vault-agent-config.hcl":"# Comment this out if running as sidecar instead of initContainer\nexit_after_auth = true\n\npid_file = \"/home/vault/pidfile\"\n\nauto_auth {\n    method \"kubernetes\" {\n        mount_path = \"auth/kubernetes\"\n        config = {\n            role = \"otus\"\n        }\n    }\n\n    sink \"file\" {\n        config = {\n            path = \"/home/vault/.vault-token\"\n        }\n    }\n}\n\ntemplate {\ndestination = \"/etc/secrets/index.html\"\ncontents = \u003c\u003cEOT\n\u003chtml\u003e\n\u003cbody\u003e\n\u003cp\u003eSome secrets:\u003c/p\u003e\n{{- with secret \"otus/otus-ro/config\" }}\n\u003cul\u003e\n\u003cli\u003e\u003cpre\u003eusername: {{ .Data.username }}\u003c/pre\u003e\u003c/li\u003e\n\u003cli\u003e\u003cpre\u003epassword: {{ .Data.password }}\u003c/pre\u003e\u003c/li\u003e\n\u003c/ul\u003e\n{{ end }}\n\u003c/body\u003e\n\u003c/html\u003e\nEOT\n}\n"},"kind":"ConfigMap","metadata":{"annotations":{},"name":"example-vault-agent-config","namespace":"default"}}
  creationTimestamp: "2024-01-05T17:04:46Z"
  name: example-vault-agent-config
  namespace: default
  resourceVersion: "21560144"
  uid: 556b060f-3aa9-419b-8c5d-84abada6d3c3

$ kubectl get pods
NAME                  READY   STATUS    RESTARTS   AGE
vault-agent-example   1/1     Running   0          14s
```

 - Подключимся к поду и выведем index.html, созданный по шаблону и содержащий секреты из vault:
```
$ kubectl exec -it vault-agent-example -- bash
Defaulted container "nginx-container" out of: nginx-container, vault-agent (init)
root@vault-agent-example:/# cat /usr/share/nginx/html/index.html
<html>
<body>
<p>Some secrets:</p>
<ul>
<li><pre>username: otus</pre></li>
<li><pre>password: asajkjkahs</pre></li>
</ul>

</body>
</html>
```

 - Включим движок PKI, путь по умолчанию /pki
```
$ kubectl exec -it -n vault vault-0 -- vault secrets enable pki
Success! Enabled the pki secrets engine at: pki/
$ kubectl exec -it -n vault vault-0 -- vault secrets list
Path          Type         Accessor              Description
----          ----         --------              -----------
cubbyhole/    cubbyhole    cubbyhole_a8f62704    per-token private secret storage
identity/     identity     identity_73a7c494     identity store
otus/         kv           kv_cc043026           n/a
pki/          pki          pki_e3842540          n/a
sys/          system       system_40941c2f       system endpoints used for control, policy and debugging
```

 - Посмотрим настройки, изменим max-lease-ttl и убедимся, что значение изменилось:
```
$ kubectl exec -it -n vault vault-0 -- vault read sys/mounts/pki/tune
Key                  Value
---                  -----
default_lease_ttl    768h
description          n/a
force_no_cache       false
max_lease_ttl        768h
$ kubectl exec -it -n vault vault-0 -- vault secrets tune -max-lease-ttl=87600h pki
Success! Tuned the secrets engine at: pki/
$ kubectl exec -it -n vault vault-0 -- vault read sys/mounts/pki/tune
Key                  Value
---                  -----
default_lease_ttl    768h
description          n/a
force_no_cache       false
max_lease_ttl        87600h
```

 - Создадим корневой сертификат. `CA.crt` нам не пригодится, сертификат лежит в волте, а ключ даже нельзя скачать (параметр `internal`).
```
$ kubectl exec -it -n vault vault-0 -- vault write -field=certificate pki/root/generate/internal common_name="example.com" ttl=87600h > CA.crt
```

 - Пропишем URLs выдающего сертификата (Authority Information Access) и списка отозванных сертификатов (CRL)
```
$ kubectl exec -it -n vault vault-0 -- vault write pki/config/urls issuing_certificates="http://vault.vault:8200/v1/pki/ca" crl_distribution_points="http://vault.vault:8200/v1/pki/crl"
Key                        Value
---                        -----
crl_distribution_points    [http://vault.vault:8200/v1/pki/crl]
enable_templating          false
issuing_certificates       [http://vault.vault:8200/v1/pki/ca]
ocsp_servers               []
```

 - Включим движок PKI для непосредственной выдачи клиентских сертификатов, путь /pki_int, и настроим его аналогично корневому
```
$ kubectl exec -it -n vault vault-0 -- vault secrets enable --path=pki_int pki
Success! Enabled the pki secrets engine at: pki_int/
$ kubectl exec -it -n vault vault-0 -- vault secrets list
Path          Type         Accessor              Description
----          ----         --------              -----------
cubbyhole/    cubbyhole    cubbyhole_a8f62704    per-token private secret storage
identity/     identity     identity_73a7c494     identity store
otus/         kv           kv_cc043026           n/a
pki/          pki          pki_e3842540          n/a
pki_int/      pki          pki_a2d74b3e          n/a
sys/          system       system_40941c2f       system endpoints used for control, policy and debugging
$ kubectl exec -it -n vault vault-0 -- vault secrets tune -max-lease-ttl=87600h pki_int
Success! Tuned the secrets engine at: pki_int/
$ kubectl exec -it -n vault vault-0 -- vault read sys/mounts/pki_int/tune
Key                  Value
---                  -----
default_lease_ttl    768h
description          n/a
force_no_cache       false
max_lease_ttl        87600h
```

 - Создадим запрос на подпись сертификата (CSR) для промежуточного сертификата CA
```
$ kubectl exec -it -n vault vault-0 -- vault write -format=json \
> pki_int/intermediate/generate/internal common_name="example.ru Intermediate Authority" | jq -r '.data.csr' > pki_intermediate.csr
```

 - Скопируем CSR в pod и выпустим сертификат через корневой CA
```
$ kubectl cp pki_intermediate.csr -n vault vault-0:/tmp

$ kubectl exec -it -n vault vault-0 -- vault write -format=json pki/root/sign-intermediate \
> csr=@/tmp/pki_intermediate.csr format=pem_bundle ttl="43800h" | jq -r .data.certificate > intermediate.crt
```

 - Скопируем полученный сертификат в pod и импортируем в pki_int:
```
$ kubectl cp intermediate.crt -n vault vault-0:/tmp

$ kubectl exec -it -n vault vault-0 -- vault write pki_int/intermediate/set-signed certificate=@/tmp/intermediate.crt
WARNING! The following warnings were returned from Vault:

  * This mount hasn't configured any authority information access (AIA)
  fields; this may make it harder for systems to find missing certificates
  in the chain or to validate revocation status of certificates. Consider
  updating /config/urls or the newly generated issuer with this information.

Key                 Value
---                 -----
existing_issuers    <nil>
existing_keys       <nil>
imported_issuers    [0c72e5ef-cccd-3bfa-5f2b-f365a6ed3736 4c31fed3-6f93-2c62-1790-679e8e5196ef]
imported_keys       <nil>
mapping             map[0c72e5ef-cccd-3bfa-5f2b-f365a6ed3736:ed70c9e0-e7cd-262d-92a1-15bea6b6f174 4c31fed3-6f93-2c62-1790-679e8e5196ef:]
```
Выдали предупреждение о том, что не прописаны URL AIA и CRL. Для корневого CA мы их прописали, а для промежуточного - нет. Пропишем и попробуем снова:
```
$ kubectl exec -it -n vault vault-0 -- vault write pki_int/config/urls issuing_certificates="http://vault.vault:8200/v1/pki_int/ca" crl_distribution_points="http://vault.vault:8200/v1/pki_int/crl"
Key                        Value
---                        -----
crl_distribution_points    [http://vault.vault:8200/v1/pki_int/crl]
enable_templating          false
issuing_certificates       [http://vault.vault:8200/v1/pki_int/ca]
ocsp_servers               []

$ kubectl exec -it -n vault vault-0 -- vault write pki_int/intermediate/set-signed certificate=@/tmp/intermediate.crt
Key                 Value
---                 -----
existing_issuers    [0c72e5ef-cccd-3bfa-5f2b-f365a6ed3736 4c31fed3-6f93-2c62-1790-679e8e5196ef]
existing_keys       <nil>
imported_issuers    <nil>
imported_keys       <nil>
mapping             map[0c72e5ef-cccd-3bfa-5f2b-f365a6ed3736:ed70c9e0-e7cd-262d-92a1-15bea6b6f174 4c31fed3-6f93-2c62-1790-679e8e5196ef:]
```
На этот раз предупреждения нет.

 - Создадим роль для выдачи сертификатов
```
$ kubectl exec -it -n vault vault-0 -- vault write pki_int/roles/example-dot-ru \
> allowed_domains="example.ru" allow_subdomains=true max_ttl="720h"
Key                                   Value
---                                   -----
allow_any_name                        false
allow_bare_domains                    false
allow_glob_domains                    false
allow_ip_sans                         true
allow_localhost                       true
allow_subdomains                      true
allow_token_displayname               false
allow_wildcard_certificates           true
allowed_domains                       [example.ru]
allowed_domains_template              false
allowed_other_sans                    []
allowed_serial_numbers                []
allowed_uri_sans                      []
allowed_uri_sans_template             false
allowed_user_ids                      []
basic_constraints_valid_for_non_ca    false
client_flag                           true
cn_validations                        [email hostname]
code_signing_flag                     false
country                               []
email_protection_flag                 false
enforce_hostnames                     true
ext_key_usage                         []
ext_key_usage_oids                    []
generate_lease                        false
issuer_ref                            default
key_bits                              2048
key_type                              rsa
key_usage                             [DigitalSignature KeyAgreement KeyEncipherment]
locality                              []
max_ttl                               720h
no_store                              false
not_after                             n/a
not_before_duration                   30s
organization                          []
ou                                    []
policy_identifiers                    []
postal_code                           []
province                              []
require_cn                            true
server_flag                           true
signature_bits                        256
street_address                        []
ttl                                   0s
use_csr_common_name                   true
use_csr_sans                          true
use_pss                               false
```

 - Попробуем создать сертификат. В методичке есть несколько ошибок, избавимся от них по шагам
```
$ kubectl exec -it -n vault vault-0 -- vault write pki_int/issue/devlab-dot-ru common_name="gitlab.devlab.ru" ttl="24h"
Error writing data to pki_int/issue/devlab-dot-ru: Error making API request.

URL: PUT http://127.0.0.1:8200/v1/pki_int/issue/devlab-dot-ru
Code: 400. Errors:

* unknown role: devlab-dot-ru
command terminated with exit code 2
```
Мы создавали роль `example-dot-ru`, а тут передаём `devlab-dot-ru`. Исправляем
```
$ kubectl exec -it -n vault vault-0 -- vault write pki_int/issue/example-dot-ru common_name="gitlab.devlab.ru" ttl="24h"
Error writing data to pki_int/issue/example-dot-ru: Error making API request.

URL: PUT http://127.0.0.1:8200/v1/pki_int/issue/example-dot-ru
Code: 400. Errors:

* common name gitlab.devlab.ru not allowed by this role
command terminated with exit code 2
```
В роли указано `allowed_domains="example.ru"`, а мы передаём домен `gitlab.devlab.ru`. Исправляем, теперь всё хорошо
```
$ kubectl exec -it -n vault vault-0 -- vault write pki_int/issue/example-dot-ru common_name="gitlab.example.ru" ttl="24h"
Key                 Value
---                 -----
ca_chain            [-----BEGIN CERTIFICATE-----
MIIDqTCCApGgAwIBAgIUBX4X9h49coTEZ7pFnrdK7hxWFHEwDQYJKoZIhvcNAQEL
BQAwFjEUMBIGA1UEAxMLZXhhbXBsZS5jb20wHhcNMjQwMTA2MTAwNzU1WhcNMjkw
MTA0MTAwODI1WjAsMSowKAYDVQQDEyFleGFtcGxlLnJ1IEludGVybWVkaWF0ZSBB
dXRob3JpdHkwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQCpavRUUNwJ
buwK5pdowVRHapmiQuSMARX96wQR4n4DLzwpqYgWuV+im61TdjQsVhQe+3h9UMdf
2z/qujg/uFFhv8v8HsKpXqVmT45wNGUisJ3A11BX+ZxioKRdrXdq05g4+pUBz9cy
Lhc7nlCSBYM606JiBuqrnIUQKU2k+QHdTFO0qOQr9UoBNlhDH8+nouR8+nChdAOS
px9YyPFP4hnYiUItdA22TlwuYy0SrzXTLbMR0MEJQFzV0X5NWIKLXGcPA85kyKj9
3JT8dnkJp4SAZlkLHmemSmBgaPGSQXxR64dChnyM/BAC9Y/zeVguWCzdG4XkUqpS
SWjfSqPm4JhbAgMBAAGjgdgwgdUwDgYDVR0PAQH/BAQDAgEGMA8GA1UdEwEB/wQF
MAMBAf8wHQYDVR0OBBYEFNLiJvKi4516tGgz3bg7Kx+c/cEgMB8GA1UdIwQYMBaA
FEiimrJEXvVweLpXtKJ4pS2H6rczMD0GCCsGAQUFBwEBBDEwLzAtBggrBgEFBQcw
AoYhaHR0cDovL3ZhdWx0LnZhdWx0OjgyMDAvdjEvcGtpL2NhMDMGA1UdHwQsMCow
KKAmoCSGImh0dHA6Ly92YXVsdC52YXVsdDo4MjAwL3YxL3BraS9jcmwwDQYJKoZI
hvcNAQELBQADggEBAKMH5aLR5ZnJPCNhDHGsOXIQswVsC94iaMIWaFnMMxfZqSSP
1fn7MVc89glIft7z/LiM0nXxX7slJEKvobeRsX70BXfQ/RjINbGmwmGTVuu1kopB
LqyekVVRL6+uVymW1BPTlTab4iq647TcXFdy/IMtXQG+vVTIHGkqPcdG9hw7Th0l
lFm4tbEkJLWdF3r7m8i0kuE4zLSzOw3hLLJoTsCLInIQjysRNT8pqSna4iQU0wgA
sQtp7jcX84+7w4I1MlCcKMXsj6BaTRJ+WoXy/sSACeARow3cxtoTR1VvYlbjWVxR
6B2dm5vxodUbN90y1xK7oUFLnrCH/PNUUBtXK+o=
-----END CERTIFICATE----- -----BEGIN CERTIFICATE-----
MIIDqzCCApOgAwIBAgIUPuOht34nWZ/OZCPWgc8UDqiIqOAwDQYJKoZIhvcNAQEL
BQAwFjEUMBIGA1UEAxMLZXhhbXBsZS5jb20wHhcNMjQwMTA2MDk1NTM3WhcNMzQw
MTAzMDk1NjA3WjAWMRQwEgYDVQQDEwtleGFtcGxlLmNvbTCCASIwDQYJKoZIhvcN
AQEBBQADggEPADCCAQoCggEBAK3PzWedriH4yUkdoQzeo3phqm7SZPSqDa0mTK8W
0ekWTCM8pRGrisC4FdkgaR5uIhC3CEnizbKyprrBoru6jrgMAWMdRy0naHFD3oDq
1Y/AEzW3Wt5Q2woHYDrgQPSAr4C8aLdoSbUmViUh0w/NxAPiTsDmiUMWNMH8q/ES
j/J9H+cmyCUqAi3WV4eSCoT3CyG7uT1GxurGEjynJDCvNXQUBxe7v0f4T0X48SKP
BqiJm1ByZjr10NGtQowkGPjNabgjSXoSXFJOnU6fqIBiPbnJILmYNuWBIjTNy1Bd
OFgIh2nmJc4SRW1Id+TemRduYIg5DMCOueHLsMfAMus4j2sCAwEAAaOB8DCB7TAO
BgNVHQ8BAf8EBAMCAQYwDwYDVR0TAQH/BAUwAwEB/zAdBgNVHQ4EFgQUSKKaskRe
9XB4ule0onilLYfqtzMwHwYDVR0jBBgwFoAUSKKaskRe9XB4ule0onilLYfqtzMw
PQYIKwYBBQUHAQEEMTAvMC0GCCsGAQUFBzAChiFodHRwOi8vdmF1bHQudmF1bHQ6
ODIwMC92MS9wa2kvY2EwFgYDVR0RBA8wDYILZXhhbXBsZS5jb20wMwYDVR0fBCww
KjAooCagJIYiaHR0cDovL3ZhdWx0LnZhdWx0OjgyMDAvdjEvcGtpL2NybDANBgkq
hkiG9w0BAQsFAAOCAQEATcLaGPQbAPaxNgBGoxE85mgLEG98uYg2imftHLLuh2Yr
KQYLnwSJj9pe0DDCItV1i3D7Z5XGALl0PTFTmPP0iAoFcgl7aero7Q6k1uQCijpp
yrQJAGSc1mFvh4snBTvtRU2ihKqxmTXAEnh/srM21oSvYIv3wOAZ6DS/1Rp0O7y5
5HzRCAEK1Hln1agsP83Fo+uq+V3gxRFYecjfpCjD2SVCeFfYcZLoIiYzdxNrLqjN
I3FewHSOiUGE4CPmFJL3LBoI4NUfDFHEpwmUZqg5cO9J9mSqLHV/KYTrJsJyB3TN
PSQCDO4A14TzRz9VqQUZFJGyKHUVXiFv9VwA/IcsbQ==
-----END CERTIFICATE-----]
certificate         -----BEGIN CERTIFICATE-----
MIIDZzCCAk+gAwIBAgIUFM/iVi9n5QrRWxfiMJaIrDelkjgwDQYJKoZIhvcNAQEL
BQAwLDEqMCgGA1UEAxMhZXhhbXBsZS5ydSBJbnRlcm1lZGlhdGUgQXV0aG9yaXR5
MB4XDTI0MDEwNjEwMTgzMloXDTI0MDEwNzEwMTkwMVowHDEaMBgGA1UEAxMRZ2l0
bGFiLmV4YW1wbGUucnUwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQCg
BInnXi0v0vvxY8kDaKDOJOWtbwPS8r0VTMUk3l3zGQBRflwGMyyq/g6SJ+nnuTan
a8L60m+TWvlyiCZgCFED6JtAGa4GqaGapxbImB5IxRTjUHoa4+xXQzed8nGbDMUg
guFF+2rLG8ukG0KrV3MaE2vLP3+sfMmDBMntFy8lIYr8qKCZZwycmN56QxJdHWBJ
seKgEpCBDIVhnFcwBXbUfyKrlRWrH7P0mKv+WWyq5zexVma8LtUONhqlhJ62VjoS
WkaEeOf4T8fcxd4ROWOWdIhzPlUKE3ssPns6yyY9PP/3ry0dJb6TSYAt7vD85iAq
x//4lS8PikQltXlu1GdVAgMBAAGjgZAwgY0wDgYDVR0PAQH/BAQDAgOoMB0GA1Ud
JQQWMBQGCCsGAQUFBwMBBggrBgEFBQcDAjAdBgNVHQ4EFgQUCUQhYN8eZG/Qesuj
2HK6BqSfPH8wHwYDVR0jBBgwFoAU0uIm8qLjnXq0aDPduDsrH5z9wSAwHAYDVR0R
BBUwE4IRZ2l0bGFiLmV4YW1wbGUucnUwDQYJKoZIhvcNAQELBQADggEBABK6+6mE
eGGNfgP8tHs4Ok2qOXdMFpRJSGBaje4bAEiPPFTHSW5xJKPsUaXuRCjCAheAKZ80
zFf0yVK+frDVzL5rMF14o72R/uGLH6LzNuxknXrBPbIuytxbSsIoC+v6iteLDGdD
yEY+5e9KDkwK3GlL8SR70Ic8tp7IzEb5+JzsoTD8iPpnvO/e5/ZUAvq+Ft4guNbh
bENfZBGChMhWsdn4DOlS73hfPStNLVxZtolYYPbS+3j3VqRWjr1P8veKY6L8BKXU
VpV8suzwAkbY/WlCI8wL49kx0SM+Ucq3xBI3RdpR0RUB3/IMORMRWpIhBgCzYLCC
RDtYPs0PMTu2Zeg=
-----END CERTIFICATE-----
expiration          1704622741
issuing_ca          -----BEGIN CERTIFICATE-----
MIIDqTCCApGgAwIBAgIUBX4X9h49coTEZ7pFnrdK7hxWFHEwDQYJKoZIhvcNAQEL
BQAwFjEUMBIGA1UEAxMLZXhhbXBsZS5jb20wHhcNMjQwMTA2MTAwNzU1WhcNMjkw
MTA0MTAwODI1WjAsMSowKAYDVQQDEyFleGFtcGxlLnJ1IEludGVybWVkaWF0ZSBB
dXRob3JpdHkwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQCpavRUUNwJ
buwK5pdowVRHapmiQuSMARX96wQR4n4DLzwpqYgWuV+im61TdjQsVhQe+3h9UMdf
2z/qujg/uFFhv8v8HsKpXqVmT45wNGUisJ3A11BX+ZxioKRdrXdq05g4+pUBz9cy
Lhc7nlCSBYM606JiBuqrnIUQKU2k+QHdTFO0qOQr9UoBNlhDH8+nouR8+nChdAOS
px9YyPFP4hnYiUItdA22TlwuYy0SrzXTLbMR0MEJQFzV0X5NWIKLXGcPA85kyKj9
3JT8dnkJp4SAZlkLHmemSmBgaPGSQXxR64dChnyM/BAC9Y/zeVguWCzdG4XkUqpS
SWjfSqPm4JhbAgMBAAGjgdgwgdUwDgYDVR0PAQH/BAQDAgEGMA8GA1UdEwEB/wQF
MAMBAf8wHQYDVR0OBBYEFNLiJvKi4516tGgz3bg7Kx+c/cEgMB8GA1UdIwQYMBaA
FEiimrJEXvVweLpXtKJ4pS2H6rczMD0GCCsGAQUFBwEBBDEwLzAtBggrBgEFBQcw
AoYhaHR0cDovL3ZhdWx0LnZhdWx0OjgyMDAvdjEvcGtpL2NhMDMGA1UdHwQsMCow
KKAmoCSGImh0dHA6Ly92YXVsdC52YXVsdDo4MjAwL3YxL3BraS9jcmwwDQYJKoZI
hvcNAQELBQADggEBAKMH5aLR5ZnJPCNhDHGsOXIQswVsC94iaMIWaFnMMxfZqSSP
1fn7MVc89glIft7z/LiM0nXxX7slJEKvobeRsX70BXfQ/RjINbGmwmGTVuu1kopB
LqyekVVRL6+uVymW1BPTlTab4iq647TcXFdy/IMtXQG+vVTIHGkqPcdG9hw7Th0l
lFm4tbEkJLWdF3r7m8i0kuE4zLSzOw3hLLJoTsCLInIQjysRNT8pqSna4iQU0wgA
sQtp7jcX84+7w4I1MlCcKMXsj6BaTRJ+WoXy/sSACeARow3cxtoTR1VvYlbjWVxR
6B2dm5vxodUbN90y1xK7oUFLnrCH/PNUUBtXK+o=
-----END CERTIFICATE-----
private_key         -----BEGIN RSA PRIVATE KEY-----
MIIEowIBAAKCAQEAoASJ514tL9L78WPJA2igziTlrW8D0vK9FUzFJN5d8xkAUX5c
BjMsqv4Okifp57k2p2vC+tJvk1r5cogmYAhRA+ibQBmuBqmhmqcWyJgeSMUU41B6
GuPsV0M3nfJxmwzFIILhRftqyxvLpBtCq1dzGhNryz9/rHzJgwTJ7RcvJSGK/Kig
mWcMnJjeekMSXR1gSbHioBKQgQyFYZxXMAV21H8iq5UVqx+z9Jir/llsquc3sVZm
vC7VDjYapYSetlY6ElpGhHjn+E/H3MXeETljlnSIcz5VChN7LD57OssmPTz/968t
HSW+k0mALe7w/OYgKsf/+JUvD4pEJbV5btRnVQIDAQABAoIBADfKnVJgEZ01EMbP
JczcdASr9LCNnmW0YJzGkY4TQep6cxP23JsEyLQttGLdK76xYw7okajmKiTUeVin
g8nD3ItiVI765SRJjKDhVR5He3efz3KaIpixkzuxofieCWIoB6sYNvcxe8CpRk1H
e+1FpkoXL2REFX3MXG4kA0t44+UryajV2NpMk8aKE8A9gtmkhrA6WqXl5FUQrU6w
fQCXGBgclTd8gOoIrM0FM2ojAGaUo0S0qygXzKxVpgC023vDPmP4EJIi2D5meRCT
E5blD5tg3CjlXm01PzHdwlwDaY00/5QvWQcuVSJJc9sO/TbqPYIYfxrJO3nRWIeC
Obm70dkCgYEAyqFaSxYERBIvun/hx/6mtPix9OK3IqYlMdPnCfZIOq15M/n9wpRi
B7I7pWEPq8CYX9ohi47LmvlN4EvU5bNrWKUb3eKq9Lva9yxQg4lnQdNwM5xLAzAm
XYK7RDMl4OmVnBgtd5PfmnVg+IdSYyBSV5uZQN+JfgVqByeO1imhYK8CgYEAyin4
pzUf5cqs9pmt//b+uIcwydz9YmT22aqjT/J2IUAiQyrWqigLMRdjAO4x84mQuK4L
prbG0UKdI2bOqiYLJRrNppAQj9jfHric7C0noaI1NMzlHwxSv+BarZw6nkxMV3f/
k/ytXdpMwTspFnprFmt8+nCKjpxSib/lVHcgkTsCgYA5Ptp2ihLMdGLdipFr4gqQ
6A3GhGJ+vHeXmykTjGudgDLUt1S0qx0C1Zy6PTCjMjcaJVMCzWXCM5qHuoS8HDNA
iOzVg9sOZyAWYoOglaoBU83IFuiuTuUX1/4150lVQEiPH9mAhdtPFMg/jmN9M71v
mLr0M/LxEnCA8vEMmhhIawKBgQCUAJQsfYUDqxRjWPD8wmuK1lZOgn3ySe46PmVf
QydegmBTAgqz+arv3qo5ZSimnaCYw7p967O0QWtfHoXQJRflqzDBbxjg5qm6CPfB
I/GusFz5ccOPrmrqVCqujQCRIVSGeLBgPA0D96xXjqMu9KJvgHO3uSqG60S12gnf
g3MRPwKBgDhiXXneiW8My1Spfja1u4QCOetFFWpjpqA82OyoFtqQDk3z7qdA5S/u
YxlKiBTrfE8lwvNQsGvNrRyMp56PYe+XnIAeJw6VPUFgwROBw3fC6bHWWgFGI6uo
L4pMo5e8fYYUTT2eoz4b4cegXWTnbRjDbQlqHYFkL8V6kDddXpot
-----END RSA PRIVATE KEY-----
private_key_type    rsa
serial_number       14:cf:e2:56:2f:67:e5:0a:d1:5b:17:e2:30:96:88:ac:37:a5:92:38
```

 - Проверяем, что нет отозванных сертификатов
```
$ kubectl exec -it -n vault vault-0 -- vault list /pki_int/certs/revoked
No value found at pki_int/certs/revoked
command terminated with exit code 2
```

 - Отзываем сертификат, передавая ранее полученный serial_number
```
$ kubectl exec -it -n vault vault-0 -- vault write pki_int/revoke serial_number=14:cf:e2:56:2f:67:e5:0a:d1:5b:17:e2:30:96:88:ac:37:a5:92:38
Key                        Value
---                        -----
revocation_time            1704536585
revocation_time_rfc3339    2024-01-06T10:23:05.756442733Z
state                      revoked
```

 - Проверяем, что сертификат появился среди отозванных
```
$ kubectl exec -it -n vault vault-0 -- vault list /pki_int/certs/revoked
Keys
----
14:cf:e2:56:2f:67:e5:0a:d1:5b:17:e2:30:96:88:ac:37:a5:92:38
```

## Задание со * (1)

 - Доступ по HTTPS реализуем через ingress. Для этого нам надо запустить ingress контроллер, а также создать ingress для vault.
   Сначала запускаем контроллер, с настройками по умолчанию
```
$ helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx --namespace=ingress-nginx --create-namespace
Release "ingress-nginx" does not exist. Installing it now.
NAME: ingress-nginx
LAST DEPLOYED: Sat Jan  6 15:23:01 2024
NAMESPACE: ingress-nginx
STATUS: deployed
REVISION: 1
TEST SUITE: None
NOTES:
The ingress-nginx controller has been installed.
It may take a few minutes for the load balancer IP to be available.
You can watch the status by running 'kubectl get service --namespace ingress-nginx ingress-nginx-controller --output wide --watch'

An example Ingress that makes use of the controller:
  apiVersion: networking.k8s.io/v1
  kind: Ingress
  metadata:
    name: example
    namespace: foo
  spec:
    ingressClassName: nginx
    rules:
      - host: www.example.com
        http:
          paths:
            - pathType: Prefix
              backend:
                service:
                  name: exampleService
                  port:
                    number: 80
              path: /
    # This section is only required if TLS is to be enabled for the Ingress
    tls:
      - hosts:
        - www.example.com
        secretName: example-tls

If TLS is enabled for the Ingress, a Secret containing the certificate and key must also be provided:

  apiVersion: v1
  kind: Secret
  metadata:
    name: example-tls
    namespace: foo
  data:
    tls.crt: <base64 encoded cert>
    tls.key: <base64 encoded key>
  type: kubernetes.io/tls
```

 - В файл `vault.values.yaml`, блок `server`, добавим настройки ingress. Домен будет vault.local, а сертификат самоподписанный, встроенный в ingress
```
 server:
+  ingress:
+    enabled: true
+    activeService: false
+    ingressClassName: nginx
+    hosts:
+    - host: vault.local
+    tls:
+    - hosts:
+      - vault.local
```

 - Обновим helm vault и проверим, что работает доступ по HTTPS. Для простоты проверять будем на URL /pki/issuers, который не закрыт аутентификацией
```
$ helm upgrade --install vault ./vault-helm --namespace vault --create-namespace --values ...path.../vault.values.yaml
...
$ curl -k -v --resolve vault.local:443:158.160.133.12 -X LIST https://vault.local/v1/pki/issuers
* Added vault.local:443:158.160.133.12 to DNS cache
* Hostname vault.local was found in DNS cache
*   Trying 158.160.133.12:443...
* Connected to vault.local (158.160.133.12) port 443
* ALPN: curl offers h2,http/1.1
* (304) (OUT), TLS handshake, Client hello (1):
* (304) (IN), TLS handshake, Server hello (2):
* (304) (IN), TLS handshake, Unknown (8):
* (304) (IN), TLS handshake, Certificate (11):
* (304) (IN), TLS handshake, CERT verify (15):
* (304) (IN), TLS handshake, Finished (20):
* (304) (OUT), TLS handshake, Finished (20):
* SSL connection using TLSv1.3 / AEAD-AES256-GCM-SHA384
* ALPN: server accepted h2
* Server certificate:
*  subject: O=Acme Co; CN=Kubernetes Ingress Controller Fake Certificate
*  start date: Jan  6 12:23:21 2024 GMT
*  expire date: Jan  5 12:23:21 2025 GMT
*  issuer: O=Acme Co; CN=Kubernetes Ingress Controller Fake Certificate
*  SSL certificate verify result: unable to get local issuer certificate (20), continuing anyway.
* using HTTP/2
* [HTTP/2] [1] OPENED stream for https://vault.local/v1/pki/issuers
* [HTTP/2] [1] [:method: LIST]
* [HTTP/2] [1] [:scheme: https]
* [HTTP/2] [1] [:authority: vault.local]
* [HTTP/2] [1] [:path: /v1/pki/issuers]
* [HTTP/2] [1] [user-agent: curl/8.4.0]
* [HTTP/2] [1] [accept: */*]
> LIST /v1/pki/issuers HTTP/2
> Host: vault.local
> User-Agent: curl/8.4.0
> Accept: */*
>
< HTTP/2 200
< date: Sat, 06 Jan 2024 13:33:02 GMT
< content-type: application/json
< content-length: 422
< cache-control: no-store
< strict-transport-security: max-age=31536000; includeSubDomains
<
{"request_id":"a829a4c3-9403-7bea-2a41-bb28f43c52e4","lease_id":"","renewable":false,"lease_duration":0,"data":{"key_info":{"f59a8dda-8b47-d340-f7c6-1339e6ecca29":{"is_default":true,"issuer_name":"","key_id":"69d53d14-8dff-2c52-c9bb-12162c7f745d","serial_number":"3e:e3:a1:b7:7e:27:59:9f:ce:64:23:d6:81:cf:14:0e:a8:88:a8:e0"}},"keys":["f59a8dda-8b47-d340-f7c6-1339e6ecca29"]},"wrap_info":null,"warnings":null,"auth":null}
* Connection #0 to host vault.local left intact
```

 - А доступ по HTTP не работает, выдаётся перенаправление на HTTPS
```
$ curl -k -v --resolve vault.local:80:158.160.133.12 -X LIST http://vault.local/v1/pki/issuers
* Added vault.local:80:158.160.133.12 to DNS cache
* Hostname vault.local was found in DNS cache
*   Trying 158.160.133.12:80...
* Connected to vault.local (158.160.133.12) port 80
> LIST /v1/pki/issuers HTTP/1.1
> Host: vault.local
> User-Agent: curl/8.4.0
> Accept: */*
>
< HTTP/1.1 308 Permanent Redirect
< Date: Sat, 06 Jan 2024 13:33:23 GMT
< Content-Type: text/html
< Content-Length: 164
< Connection: keep-alive
< Location: https://vault.local/v1/pki/issuers
<
<html>
<head><title>308 Permanent Redirect</title></head>
<body>
<center><h1>308 Permanent Redirect</h1></center>
<hr><center>nginx</center>
</body>
</html>
* Connection #0 to host vault.local left intact
```

## Задание со * (2)

 - Для unseal будем использовать Yandex Cloud KMS, инструкция https://cloud.yandex.ru/ru/docs/kms/tutorials/vault-secret

 - В файл `vault.values.yaml`, блок `server`, добавим настройки image, совместимого с Yandex Cloud KMS.
```
 server:
+  image:
+    repository: cr.yandex/yc/vault
+    tag: latest
```

 - Создадим в Yandex Cloud сервисную учётку `vault-unseal`, ключ для неё и отдельно ключ в KMS
```
$ yc iam service-account create --name vault-unseal
done (1s)
id: aje44ea0c2ct2v41gjhf
folder_id: b1gk2c3sr6uiqjqaehrf
created_at: "2024-01-06T15:28:54.984713048Z"
name: vault-unseal

$ yc iam key create --service-account-name vault-unseal --output vault-unseal-sa-key.json
id: ajeoh0pq3atkmt3isju6
service_account_id: aje44ea0c2ct2v41gjhf
created_at: "2024-01-06T15:31:28.916895764Z"
key_algorithm: RSA_2048

$ yc kms symmetric-key create --name vault-unseal --default-algorithm aes-256
id: abjc2n27l5vpmfqobkh0
folder_id: b1gk2c3sr6uiqjqaehrf
created_at: "2024-01-06T15:32:59Z"
name: vault-unseal
status: ACTIVE
primary_version:
  id: abj63uoth34ni5vjvag0
  key_id: abjc2n27l5vpmfqobkh0
  status: ACTIVE
  algorithm: AES_256
  created_at: "2024-01-06T15:32:59Z"
  primary: true
default_algorithm: AES_256
```

 - Назначим через web-интерфейс роль `kms.keys.encrypterDecrypter` созданой сервисной учётке
 - Создадим в k8s секрет с ключом от сервисной учётки и пробросим его в поды vault, изменяя файл `vault.values.yaml`.
  Также добавим настройку autounseal в vault
```
$ kubectl create secret generic vault-unseal-sa-key -n vault --from-file=vault-unseal-sa-key.json
secret/vault-unseal-sa-key created

$ git diff vault.values.yaml | cat
diff --git a/kubernetes-vault/vault.values.yaml b/kubernetes-vault/vault.values.yaml
index efb68bf..0472ade 100644
--- a/kubernetes-vault/vault.values.yaml
+++ b/kubernetes-vault/vault.values.yaml
@@ -1,4 +1,15 @@
 server:
+  image:
+    repository: cr.yandex/yc/vault
+    tag: latest
+  volumes:
+  - name: vault-unseal-sa-key
+    secret:
+      secretName: vault-unseal-sa-key
+  volumeMounts:
+  - name: vault-unseal-sa-key
+    readOnly: true
+    mountPath: /tmp/vault-unseal
   ingress:
     enabled: true
     activeService: false
@@ -24,6 +35,10 @@ server:
         path = "vault"
         address = "consul-server.consul.svc:8500"
       }
+      seal "yandexcloudkms" {
+        kms_key_id = "abjc2n27l5vpmfqobkh0"
+        service_account_key_file = "/tmp/vault-unseal/vault-unseal-sa-key.json"
+      }

 ui:
   enabled: true
```

 - По очереди перезапустим пассивные поды 2 и 1 и распечатаем их, указывая ключ `-migrate`
```
$ kubectl exec -it -n vault vault-2 -- vault operator unseal -migrate
Unseal Key (will be hidden):
Key                           Value
---                           -----
Recovery Seal Type            shamir
Initialized                   true
Sealed                        true
Total Recovery Shares         5
Threshold                     3
Unseal Progress               1/3
Unseal Nonce                  996c9dd9-2f3d-acc9-5c3a-3f3f203b00b3
Seal Migration in Progress    true
Version                       1.14.1+yckms
Build Date                    2023-08-01T20:32:02Z
Storage Type                  consul
HA Enabled                    true
```

 - Перезапустим активный под 0, он поднимется сразу распечатанный
```
$ kubectl exec -it -n vault vault-0 -- vault status
Key                      Value
---                      -----
Recovery Seal Type       shamir
Initialized              true
Sealed                   false
Total Recovery Shares    5
Threshold                3
Version                  1.14.1+yckms
Build Date               2023-08-01T20:32:02Z
Storage Type             consul
Cluster Name             vault-cluster-6a9f6950
Cluster ID               aee820b5-6c9b-4d48-d27f-6a3711ed8823
HA Enabled               true
HA Cluster               https://vault-2.vault-internal:8201
HA Mode                  standby
Active Node Address      http://172.16.129.90:8200
```

 - Повторим на поде 2, тоже поднялся распечатанный
```
$ kubectl exec -it -n vault vault-2 -- vault status
Key                      Value
---                      -----
Recovery Seal Type       shamir
Initialized              true
Sealed                   false
Total Recovery Shares    5
Threshold                3
Version                  1.14.1+yckms
Build Date               2023-08-01T20:32:02Z
Storage Type             consul
Cluster Name             vault-cluster-6a9f6950
Cluster ID               aee820b5-6c9b-4d48-d27f-6a3711ed8823
HA Enabled               true
HA Cluster               https://vault-0.vault-internal:8201
HA Mode                  standby
Active Node Address      http://172.16.128.57:8200
```

## Задание со * (3)

 - Будем настраивать выдачу временных реквизитов доступа для MongoDB (логина и пароля) по документации https://developer.hashicorp.com/vault/tutorials/db-credentials/database-mongodb

 - Запустим оператор mongodb
```
$ helm repo add mongodb https://mongodb.github.io/helm-charts
"mongodb" has been added to your repositories

$ helm install community-operator mongodb/community-operator --namespace mongodb --create-namespace
NAME: community-operator
LAST DEPLOYED: Sat Jan  6 20:49:14 2024
NAMESPACE: mongodb
STATUS: deployed
REVISION: 1
TEST SUITE: None
```

 - Скачаем манифест https://raw.githubusercontent.com/mongodb/mongodb-kubernetes-operator/master/config/samples/mongodb.com_v1_mongodbcommunity_cr.yaml,
 подредактируем его и применим, затем дождёмся поднятия базы
```
$ kubectl apply -f mongodb.com_v1_mongodbcommunity_cr.yaml --namespace mongodb
mongodbcommunity.mongodbcommunity.mongodb.com/example-mongodb created
secret/my-user-password created

$ kubectl get mdbc -n mongodb
NAME              PHASE     VERSION
example-mongodb   Running   6.0.5
```

 - Включим в vault движок для создания временных паролей, затем настроим его и создадим роль
```
$ kubectl exec -it -n vault vault-2 -- vault secrets enable -path=mongodb database
Success! Enabled the database secrets engine at: mongodb/

$ kubectl exec -it -n vault vault-2 -- vault write mongodb/config/mongo-test \
  plugin_name=mongodb-database-plugin \
  allowed_roles="tester" \
  connection_url="mongodb://{{username}}:{{password}}@example-mongodb-0.example-mongodb-svc.mongodb.svc.cluster.local:27017,example-mongodb-1.example-mongodb-svc.mongodb.svc.cluster.local:27017,example-mongodb-2.example-mongodb-svc.mongodb.svc.cluster.local:27017/admin?replicaSet=example-mongodb&ssl=false" \
  username="my-user" password="<your-password-here>"
Success! Data written to: mongodb/config/mongo-test

$ kubectl exec -it -n vault vault-2 -- vault write mongodb/roles/tester \
    db_name=mongo-test \                                                                                                                                                                                                             creation_statements='{ "db": "admin", "roles": [{ "role": "readWrite" }, {"role": "read", "db": "foo"}] }' \
    default_ttl="1h" \
    max_ttl="24h"
Success! Data written to: mongodb/roles/tester

$ kubectl exec -it -n vault vault-2 -- vault list mongodb/roles
Keys
----
tester
```

 - Запросим временные логин и пароль
```
$ kubectl exec -it -n vault vault-2 -- vault read mongodb/creds/tester
Key                Value
---                -----
lease_id           mongodb/creds/tester/YtD0hfWNwwrQkk3T9oiZjBM4
lease_duration     1h
lease_renewable    true
password           rBBmq8X6-FXFsmyIkVey
username           v-root-tester-gsVNQImBwyiiVCYZ5aF7-1704566592
```

 - Проверим их
```
$ kubectl exec -it -n mongodb example-mongodb-0 -- mongosh --username v-root-tester-gsVNQImBwyiiVCYZ5aF7-1704566592 --password rBBmq8X6-FXFsmyIkVey
Defaulted container "mongod" out of: mongod, mongodb-agent, mongod-posthook (init), mongodb-agent-readinessprobe (init)
Warning: Could not access file: EACCES: permission denied, mkdir '/data/db/.mongodb'
Current Mongosh Log ID:	65999fa7da66f5672cea9a89
Connecting to:		mongodb://<credentials>@127.0.0.1:27017/?directConnection=true&serverSelectionTimeoutMS=2000&appName=mongosh+1.8.2
Using MongoDB:		6.0.5
Using Mongosh:		1.8.2

For mongosh info see: https://docs.mongodb.com/mongodb-shell/


To help improve our products, anonymous usage data is collected and sent to MongoDB periodically (https://www.mongodb.com/legal/privacy-policy).
You can opt-out by running the disableTelemetry() command.


Error: Could not open history file.
REPL session history will not be persisted.
example-mongodb [direct: primary] test> show dbs;
admin  220.00 KiB
```

 - Проверим, что случайный пароль не подходит
```
$ kubectl exec -it -n mongodb example-mongodb-0 -- mongosh --username v-root-tester-gsVNQImBwyiiVCYZ5aF7-1704566592 --password rBBmq8X6-FXFsmyIkVeyXXX
Defaulted container "mongod" out of: mongod, mongodb-agent, mongod-posthook (init), mongodb-agent-readinessprobe (init)
Warning: Could not access file: EACCES: permission denied, mkdir '/data/db/.mongodb'
Current Mongosh Log ID:	65999fc591521b6d0537865d
Connecting to:		mongodb://<credentials>@127.0.0.1:27017/?directConnection=true&serverSelectionTimeoutMS=2000&appName=mongosh+1.8.2
MongoServerError: Authentication failed.
command terminated with exit code 1
```

# Выполнено ДЗ №12 (storage)

 - [*] Основное ДЗ
 - [*] Задание со *

## В процессе сделано:

### Установка и проверка [CSI Hostpath Driver](https://github.com/kubernetes-csi/csi-driver-host-path)

 - Создадим обычный self-hosted кластер с помощью kubeadm, подробности опускаю

 - Будем руководствоваться [инструкцией](https://github.com/kubernetes-csi/csi-driver-host-path/blob/master/docs/deploy-1.17-and-later.md)

 - Установим CRDs из https://github.com/kubernetes-csi/external-snapshotter, файл прилагается:
```
$ ./install-crds.sh
customresourcedefinition.apiextensions.k8s.io/volumesnapshotclasses.snapshot.storage.k8s.io configured
customresourcedefinition.apiextensions.k8s.io/volumesnapshotcontents.snapshot.storage.k8s.io configured
customresourcedefinition.apiextensions.k8s.io/volumesnapshots.snapshot.storage.k8s.io configured
serviceaccount/snapshot-controller created
clusterrole.rbac.authorization.k8s.io/snapshot-controller-runner configured
clusterrolebinding.rbac.authorization.k8s.io/snapshot-controller-role configured
role.rbac.authorization.k8s.io/snapshot-controller-leaderelection created
rolebinding.rbac.authorization.k8s.io/snapshot-controller-leaderelection created
deployment.apps/snapshot-controller created
```

 - Установим сам драйвер
```
$ git clone https://github.com/kubernetes-csi/csi-driver-host-path.git
...
$ cd csi-driver-host-path/deploy/kubernetes-latest
$ ./deploy.sh
applying RBAC rules
curl https://raw.githubusercontent.com/kubernetes-csi/external-provisioner/v3.6.3/deploy/kubernetes/rbac.yaml --output /tmp/tmp.4wpISxSMzp/rbac.yaml --silent --location
kubectl apply --kustomize /tmp/tmp.4wpISxSMzp
serviceaccount/csi-provisioner created
...
```

 - Создадим storage class
```
$ kubectl apply -f csi-storageclass.yaml
storageclass.storage.k8s.io/csi-hostpath-sc created
$ kubectl get storageclass
NAME              PROVISIONER           RECLAIMPOLICY   VOLUMEBINDINGMODE   ALLOWVOLUMEEXPANSION   AGE
csi-hostpath-sc   hostpath.csi.k8s.io   Delete          Immediate           true                   49m
```

 - Создадим PVC
```
$ kubectl apply -f csi-pvc.yaml
persistentvolumeclaim/storage-pvc created
$ kubectl get pvc
NAME          STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS      AGE
storage-pvc   Bound    pvc-7b36eaa9-dc35-4401-860f-55282935f95d   1Gi        RWO            csi-hostpath-sc   48m
```

 - Создадим pod
```
$ kubectl apply -f csi-app.yaml
pod/storage-pod created
```

 - Ради интереса посмотрим, куда попадут данные. Запишем их в поде и найдём на файловой системе:
```
$ kubectl exec -it storage-pod -- sh -c 'echo privet > /data/qwe'

root@worker-12:/home/ubuntu# mount | grep csi
/dev/vda2 on /var/lib/kubelet/pods/5cbc7a1c-a8dd-48fc-bf1a-0f874149a797/volumes/kubernetes.io~csi/pvc-7b36eaa9-dc35-4401-860f-55282935f95d/mount type ext4 (rw,relatime,errors=remount-ro)

root@worker-12:/home/ubuntu# ls -la /var/lib/kubelet/pods/5cbc7a1c-a8dd-48fc-bf1a-0f874149a797/volumes/kubernetes.io~csi/pvc-7b36eaa9-dc35-4401-860f-55282935f95d/mount/
total 12
drwxr-xr-x 2 root root 4096 Feb  4 19:44 .
drwxr-x--- 3 root root 4096 Feb  4 19:15 ..
-rw-r--r-- 1 root root    7 Feb  4 19:44 qwe

root@worker-12:/home/ubuntu# cat /var/lib/kubelet/pods/5cbc7a1c-a8dd-48fc-bf1a-0f874149a797/volumes/kubernetes.io~csi/pvc-7b36eaa9-dc35-4401-860f-55282935f95d/mount/qwe
privet
```

## Задание со *

### Установка и проверка работоспособности ISCSI CSI driver for Kubernetes, а также снимков LVM

 - Будем использовать тот же кластер. Я не стал создавать отдельную сеть для iSCSI, т.к. Yandex cloud не позволяет добавлять интерфейсы обычным виртуалкам, а только специально подготовленным. Есть виртуалка с NAT, но там старая версия Ubuntu. Создадим виртуалку, отдельный диск и присоединим его к виртуалке.
```
root@iscsi-12:/home/ubuntu# dmesg -T | tail
...
[Sun Feb  4 20:17:32 2024] virtio_blk virtio2: [vdb] 10485760 512-byte logical blocks (5.37 GB/5.00 GiB)
```

 - Установим targetcli-fb и lvm2
```
root@iscsi-12:/home/ubuntu# apt-get install -y targetcli-fb lvm2
...
```

 - В LVM создадим физический диск, группу томов iscsi и логический том lvol0:
```
root@iscsi-12:/home/ubuntu# pvcreate /dev/vdb
  Physical volume "/dev/vdb" successfully created.

root@iscsi-12:/home/ubuntu# vgcreate iscsi /dev/vdb
  Volume group "iscsi" successfully created

root@iscsi-12:/home/ubuntu# lvcreate -l100%VG iscsi
  Logical volume "lvol0" created.
```

 - Добавим логический том lvol0 в iSCSI по найденной в сети [инструкции Astra linux](https://wiki.astralinux.ru/brest/latest/sozdanie-i-nastrojka-hranilishch-lvm-dlya-testovogo-stenda-263056923.html)
```
root@iscsi-12:/home/ubuntu# targetcli
targetcli shell version 2.1.51
Copyright 2011-2013 by Datera, Inc and others.
For help on commands, type 'help'.

/> ls
o- / ......................................................................................................................... [...]
  o- backstores .............................................................................................................. [...]
  | o- block .................................................................................................. [Storage Objects: 0]
  | o- fileio ................................................................................................. [Storage Objects: 0]
  | o- pscsi .................................................................................................. [Storage Objects: 0]
  | o- ramdisk ................................................................................................ [Storage Objects: 0]
  o- iscsi ............................................................................................................ [Targets: 0]
  o- loopback ......................................................................................................... [Targets: 0]
  o- vhost ............................................................................................................ [Targets: 0]
  o- xen-pvscsi ....................................................................................................... [Targets: 0]

/> /backstores/block create storage01 /dev/iscsi/lvol0
Created block storage object storage01 using /dev/iscsi/lvol0.

/> ls
o- / ......................................................................................................................... [...]
  o- backstores .............................................................................................................. [...]
  | o- block .................................................................................................. [Storage Objects: 1]
  | | o- storage01 .............................................................. [/dev/iscsi/lvol0 (5.0GiB) write-thru deactivated]
  | |   o- alua ................................................................................................... [ALUA Groups: 1]
  | |     o- default_tg_pt_gp ....................................................................... [ALUA state: Active/optimized]
  | o- fileio ................................................................................................. [Storage Objects: 0]
  | o- pscsi .................................................................................................. [Storage Objects: 0]
  | o- ramdisk ................................................................................................ [Storage Objects: 0]
  o- iscsi ............................................................................................................ [Targets: 0]
  o- loopback ......................................................................................................... [Targets: 0]
  o- vhost ............................................................................................................ [Targets: 0]
  o- xen-pvscsi ....................................................................................................... [Targets: 0]

/> /iscsi create
Created target iqn.2003-01.org.linux-iscsi.iscsi-12.x8664:sn.08ed7ab3e592.
Created TPG 1.
Global pref auto_add_default_portal=true
Created default portal listening on all IPs (0.0.0.0), port 3260.

/> ls
o- / ......................................................................................................................... [...]
  o- backstores .............................................................................................................. [...]
  | o- block .................................................................................................. [Storage Objects: 1]
  | | o- storage01 .............................................................. [/dev/iscsi/lvol0 (5.0GiB) write-thru deactivated]
  | |   o- alua ................................................................................................... [ALUA Groups: 1]
  | |     o- default_tg_pt_gp ....................................................................... [ALUA state: Active/optimized]
  | o- fileio ................................................................................................. [Storage Objects: 0]
  | o- pscsi .................................................................................................. [Storage Objects: 0]
  | o- ramdisk ................................................................................................ [Storage Objects: 0]
  o- iscsi ............................................................................................................ [Targets: 1]
  | o- iqn.2003-01.org.linux-iscsi.iscsi-12.x8664:sn.08ed7ab3e592 ........................................................ [TPGs: 1]
  |   o- tpg1 ............................................................................................... [no-gen-acls, no-auth]
  |     o- acls .......................................................................................................... [ACLs: 0]
  |     o- luns .......................................................................................................... [LUNs: 0]
  |     o- portals .................................................................................................... [Portals: 1]
  |       o- 0.0.0.0:3260 ..................................................................................................... [OK]
  o- loopback ......................................................................................................... [Targets: 0]
  o- vhost ............................................................................................................ [Targets: 0]
  o- xen-pvscsi ....................................................................................................... [Targets: 0]

/> /iscsi/iqn.2003-01.org.linux-iscsi.iscsi-12.x8664:sn.08ed7ab3e592/tpg1/luns/ create /backstores/block/storage01
Created LUN 0.

/> ls
o- / ......................................................................................................................... [...]
  o- backstores .............................................................................................................. [...]
  | o- block .................................................................................................. [Storage Objects: 1]
  | | o- storage01 ................................................................ [/dev/iscsi/lvol0 (5.0GiB) write-thru activated]
  | |   o- alua ................................................................................................... [ALUA Groups: 1]
  | |     o- default_tg_pt_gp ....................................................................... [ALUA state: Active/optimized]
  | o- fileio ................................................................................................. [Storage Objects: 0]
  | o- pscsi .................................................................................................. [Storage Objects: 0]
  | o- ramdisk ................................................................................................ [Storage Objects: 0]
  o- iscsi ............................................................................................................ [Targets: 1]
  | o- iqn.2003-01.org.linux-iscsi.iscsi-12.x8664:sn.08ed7ab3e592 ........................................................ [TPGs: 1]
  |   o- tpg1 ............................................................................................... [no-gen-acls, no-auth]
  |     o- acls .......................................................................................................... [ACLs: 0]
  |     o- luns .......................................................................................................... [LUNs: 1]
  |     | o- lun0 .......................................................... [block/storage01 (/dev/iscsi/lvol0) (default_tg_pt_gp)]
  |     o- portals .................................................................................................... [Portals: 1]
  |       o- 0.0.0.0:3260 ..................................................................................................... [OK]
  o- loopback ......................................................................................................... [Targets: 0]
  o- vhost ............................................................................................................ [Targets: 0]
  o- xen-pvscsi ....................................................................................................... [Targets: 0]
```

 - Установим iSCSI CSI driver по [инструкции](https://github.com/kubernetes-csi/csi-driver-iscsi/blob/master/docs/install-csi-driver-master.md)
```
root@master-12:/home/ubuntu# curl -skSLO https://raw.githubusercontent.com/kubernetes-csi/csi-driver-iscsi/master/deploy/install-driver.sh

root@master-12:/home/ubuntu# cat install-driver.sh | bash -s master
Installing iscsi.csi.k8s.io CSI driver, version: master ...
csidriver.storage.k8s.io/iscsi.csi.k8s.io created
daemonset.apps/csi-iscsi-node created
configmap/configmap-csi-iscsiadm created
iscsi.csi.k8s.io CSI driver installed successfully.
```

 - Убедимся в том, что драйвер установлен:
```
$ kubectl get csidriver
NAME                  ATTACHREQUIRED   PODINFOONMOUNT   STORAGECAPACITY   TOKENREQUESTS   REQUIRESREPUBLISH   MODES                  AGE
hostpath.csi.k8s.io   true             true             false             <unset>         false               Persistent,Ephemeral   129m
iscsi.csi.k8s.io      false            false            false             <unset>         false               Persistent,Ephemeral   7m53s
```

 - Создадим использующий его storage class
```
root@master-12:/home/ubuntu# cat iscsi-storageclass.yaml
---
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: csi-iscsi
provisioner: iscsi.csi.k8s.io

$ kubectl apply -f iscsi-storageclass.yaml
storageclass.storage.k8s.io/csi-iscsi created
```

 - Создадим статический том, указав в манифесте помимо названия драйвера и свойств тома IP адрес виртуалки с iSCSI и полученный ранее в targetcli IQN (iSCSI Qualified Name)
```
root@master-12:/home/ubuntu# cat iscsi-pv.yaml
---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: iscsi-pv
  labels:
    name: data-iscsi
spec:
  storageClassName: csi-iscsi
  accessModes:
    - ReadWriteOnce
  capacity:
    storage: 1Gi
  csi:
    driver: iscsi.csi.k8s.io
    volumeHandle: iscsi-data-id
    volumeAttributes:
      targetPortal: "172.16.0.35:3260"
      portals: "[]"
      iqn: "iqn.2003-01.org.linux-iscsi.iscsi-12.x8664:sn.08ed7ab3e592"
      lun: "0"
      iscsiInterface: "default"
      discoveryCHAPAuth: "true"
      sessionCHAPAuth: "false"

$ kubectl apply -f iscsi-pv.yaml
persistentvolume/iscsi-pv created
```

 - Создадим заявку на том
```
root@master-12:/home/ubuntu# cat iscsi-pvc.yaml
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: iscsi-pvc
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
  storageClassName: csi-iscsi
  selector:
    matchExpressions:
      - key: name
        operator: In
        values: ["data-iscsi"]

$ kubectl apply -f iscsi-pvc.yaml
persistentvolumeclaim/iscsi-pvc created

$ kubectl get pvc
NAME          STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS      AGE
iscsi-pvc     Bound    iscsi-pv                                   1Gi        RWO            csi-iscsi         22s
storage-pvc   Bound    pvc-7b36eaa9-dc35-4401-860f-55282935f95d   1Gi        RWO            csi-hostpath-sc   117m
```

 - Создадим pod, использующий том. Это будет nginx
```
root@master-12:/home/ubuntu# cat iscsi-pod.yaml
---
apiVersion: v1
kind: Pod
metadata:
  name: iscsi-nginx
spec:
  containers:
  - image: nginx
    name: nginx
    volumeMounts:
    - mountPath: /var/www
      name: iscsi-volume
  volumes:
  - name: iscsi-volume
    persistentVolumeClaim:
      claimName: iscsi-pvc

$ kubectl apply -f iscsi-pod.yaml
pod/iscsi-nginx created
```

 - Pod не стартует, посмотрим почему
```
$ kubectl describe pod iscsi-nginx
...
Events:
  Type     Reason       Age                   From               Message
  ----     ------       ----                  ----               -------
  Normal   Scheduled    5m22s                 default-scheduler  Successfully assigned default/iscsi-nginx to worker-12
  Warning  FailedMount  71s (x10 over 5m22s)  kubelet            MountVolume.SetUp failed for volume "iscsi-pv" : rpc error: code = Internal desc = exit status 127
```

 - Нужно установить open-iscsi (логи csi-iscsi-node-xxx не сохранились)
```
root@worker-12:/home/ubuntu# apt-get install -y open-iscsi
...
```

 - Посмотрим снова статус пода и логи на виртуалке с iSCSI
```
$ kubectl describe pod iscsi-nginx
...
Events:
  Type     Reason       Age                   From               Message
  ----     ------       ----                  ----               -------
  Normal   Scheduled    14m                   default-scheduler  Successfully assigned default/iscsi-nginx to worker-12
  Warning  FailedMount  4m18s (x13 over 14m)  kubelet            MountVolume.SetUp failed for volume "iscsi-pv" : rpc error: code = Internal desc = exit status 127
  Warning  FailedMount  12s (x2 over 2m15s)   kubelet            MountVolume.SetUp failed for volume "iscsi-pv" : rpc error: code = Internal desc = failed to find device path: [], last error seen: failed to sendtargets to portal 172.16.0.35:3260, err: exit status 24

root@iscsi-12:/home/ubuntu# dmesg -T | tail
...
[Sun Feb  4 21:23:48 2024] iSCSI Initiator Node: iqn.1993-08.org.debian:01:239cc8b88e59 is not authorized to access iSCSI target portal group: 1.
[Sun Feb  4 21:23:48 2024] iSCSI Login negotiation failed.
```

 - Нужно дать права виртуалке, на которой работает pod. Узнаем InitiatorName и пропишем его в iSCSI:
```
root@worker-12:/home/ubuntu# cat /etc/iscsi/initiatorname.iscsi
## DO NOT EDIT OR REMOVE THIS FILE!
## If you remove this file, the iSCSI daemon will not start.
## If you change the InitiatorName, existing access control lists
## may reject this initiator.  The InitiatorName must be unique
## for each iSCSI initiator.  Do NOT duplicate iSCSI InitiatorNames.
InitiatorName=iqn.1993-08.org.debian:01:239cc8b88e59

root@iscsi-12:/home/ubuntu# targetcli
targetcli shell version 2.1.51
Copyright 2011-2013 by Datera, Inc and others.
For help on commands, type 'help'.

/> /iscsi/iqn.2003-01.org.linux-iscsi.iscsi-12.x8664:sn.08ed7ab3e592/tpg1/acls/ create iqn.1993-08.org.debian:01:239cc8b88e59
Created Node ACL for iqn.1993-08.org.debian:01:239cc8b88e59
Created mapped LUN 0.

/> ls
o- / ......................................................................................................................... [...]
  o- backstores .............................................................................................................. [...]
  | o- block .................................................................................................. [Storage Objects: 1]
  | | o- storage01 ................................................................ [/dev/iscsi/lvol0 (5.0GiB) write-thru activated]
  | |   o- alua ................................................................................................... [ALUA Groups: 1]
  | |     o- default_tg_pt_gp ....................................................................... [ALUA state: Active/optimized]
  | o- fileio ................................................................................................. [Storage Objects: 0]
  | o- pscsi .................................................................................................. [Storage Objects: 0]
  | o- ramdisk ................................................................................................ [Storage Objects: 0]
  o- iscsi ............................................................................................................ [Targets: 1]
  | o- iqn.2003-01.org.linux-iscsi.iscsi-12.x8664:sn.08ed7ab3e592 ........................................................ [TPGs: 1]
  |   o- tpg1 ............................................................................................... [no-gen-acls, no-auth]
  |     o- acls .......................................................................................................... [ACLs: 1]
  |     | o- iqn.1993-08.org.debian:01:239cc8b88e59 ............................................................... [Mapped LUNs: 1]
  |     |   o- mapped_lun0 ............................................................................. [lun0 block/storage01 (rw)]
  |     o- luns .......................................................................................................... [LUNs: 1]
  |     | o- lun0 .......................................................... [block/storage01 (/dev/iscsi/lvol0) (default_tg_pt_gp)]
  |     o- portals .................................................................................................... [Portals: 1]
  |       o- 0.0.0.0:3260 ..................................................................................................... [OK]
  o- loopback ......................................................................................................... [Targets: 0]
  o- vhost ............................................................................................................ [Targets: 0]
  o- xen-pvscsi ....................................................................................................... [Targets: 0]
```

 - Снова посмотрим логи на виртуалке с iSCSI, уже лучше:
```
root@iscsi-12:/home/ubuntu# dmesg -T | tail
...
[Sun Feb  4 21:31:57 2024] iSCSI/iqn.1993-08.org.debian:01:239cc8b88e59: Unsupported SCSI Opcode 0xa3, sending CHECK_CONDITION.
```

 - Теперь том смонтирован в поде с nginx:
```
$ kubectl exec -it iscsi-nginx -- df -h
Filesystem      Size  Used Avail Use% Mounted on
overlay          20G  5.8G   13G  31% /
tmpfs            64M     0   64M   0% /dev
tmpfs           3.9G     0  3.9G   0% /sys/fs/cgroup
/dev/sda        4.9G   24K  4.9G   1% /var/www
/dev/vda2        20G  5.8G   13G  31% /etc/hosts
shm              64M     0   64M   0% /dev/shm
tmpfs           7.7G   12K  7.7G   1% /run/secrets/kubernetes.io/serviceaccount
tmpfs           3.9G     0  3.9G   0% /proc/acpi
tmpfs           3.9G     0  3.9G   0% /proc/scsi
tmpfs           3.9G     0  3.9G   0% /sys/firmware

$ kubectl exec -it iscsi-nginx -- ls -la /var/www
total 28
drwxr-xr-x 3 root root  4096 Feb  4 21:31 .
drwxr-xr-x 1 root root  4096 Feb  4 21:32 ..
drwx------ 2 root root 16384 Feb  4 21:31 lost+found
```

 - Создадим файл index.html и проверим его curl'ом
```
$ kubectl exec -it iscsi-nginx -- sh -c 'echo privet > /var/www/index.html'
```

 - Nginx не видит файл, т.к. использует другую директорию, `/usr/share/nginx/html`. Поменяем манифест и применим снова. После этого запрос curl'ом показывает новый файл:
```
$ kubectl apply -f iscsi-pod.yaml --force
pod/iscsi-nginx configured

$ kubectl get pods -o wide | grep nginx
iscsi-nginx             1/1     Running   0              44s    10.0.1.215   worker-12   <none>           <none>

root@master-12:/home/ubuntu# curl -s 10.0.1.215
privet
```

 - Создадим снимок логического тома lvol0:
```
root@iscsi-12:/home/ubuntu# lvcreate -L 5G -s -n lvol0-snap /dev/mapper/iscsi-lvol0
  Volume group "iscsi" has insufficient free space (0 extents): 1280 required.
```
Нет места в группе томов iscsi.
```
root@iscsi-12:/home/ubuntu# vgs
  VG    #PV #LV #SN Attr   VSize  VFree
  iscsi   1   1   0 wz--n- <5.00g    0
```

 - Увеличим размер диска в консоли Yandex cloud до 10ГБ
```
root@iscsi-12:/home/ubuntu# dmesg -T | tail
...
[Sat Feb 10 12:10:40 2024] virtio_blk virtio2: [vdb] new size: 20971520 512-byte logical blocks (10.7 GB/10.0 GiB)
[Sat Feb 10 12:10:40 2024] vdb: detected capacity change from 5368709120 to 10737418240
```
Диск расширен, vdb стал 10ГБ:
```
root@iscsi-12:/home/ubuntu# lsblk
NAME          MAJ:MIN RM SIZE RO TYPE MOUNTPOINT
vda           252:0    0  15G  0 disk
├─vda1        252:1    0   1M  0 part
└─vda2        252:2    0  15G  0 part /
vdb           252:16   0  10G  0 disk
└─iscsi-lvol0 253:0    0   5G  0 lvm
```

 - Но группа томов iscsi по прежнему 5ГБ, расширим и её
```
root@iscsi-12:/home/ubuntu# pvdisplay
  --- Physical volume ---
  PV Name               /dev/vdb
  VG Name               iscsi
  PV Size               5.00 GiB / not usable 4.00 MiB
  Allocatable           yes (but full)
  PE Size               4.00 MiB
  Total PE              1279
  Free PE               0
  Allocated PE          1279
  PV UUID               nzBVwR-zfm2-7qxu-SBA6-P3T4-wJda-DOBHcs

root@iscsi-12:/home/ubuntu# pvresize /dev/vdb
  Physical volume "/dev/vdb" changed
  1 physical volume(s) resized or updated / 0 physical volume(s) not resized

root@iscsi-12:/home/ubuntu# pvdisplay
  --- Physical volume ---
  PV Name               /dev/vdb
  VG Name               iscsi
  PV Size               <10.00 GiB / not usable 3.00 MiB
  Allocatable           yes
  PE Size               4.00 MiB
  Total PE              2559
  Free PE               1280
  Allocated PE          1279
  PV UUID               nzBVwR-zfm2-7qxu-SBA6-P3T4-wJda-DOBHcs

root@iscsi-12:/home/ubuntu# vgs
  VG    #PV #LV #SN Attr   VSize   VFree
  iscsi   1   1   0 wz--n- <10.00g 5.00g
```

 - Теперь снова пробуем создать снимок
```
root@iscsi-12:/home/ubuntu# lvcreate -L 5G -s -n lvol0-snap /dev/mapper/iscsi-lvol0
  Logical volume "lvol0-snap" created.

root@iscsi-12:/home/ubuntu# lvs
  LV         VG    Attr       LSize  Pool Origin Data%  Meta%  Move Log Cpy%Sync Convert
  lvol0      iscsi owi-aos--- <5.00g
  lvol0-snap iscsi swi-a-s---  5.00g      lvol0  0.00
```
Успешно

 - Изменим файлы: удалим старый `index.html` и создадим `new_file.txt`
```
$ kubectl exec -it iscsi-nginx -- sh -c 'cd /usr/share/nginx/html; rm index.html; echo new > new_file.txt; ls -la'
total 28
drwxr-xr-x 3 root root  4096 Feb 10 12:20 .
drwxr-xr-x 3 root root  4096 Jan 31 23:54 ..
drwx------ 2 root root 16384 Feb  4 21:31 lost+found
-rw-r--r-- 1 root root     4 Feb 10 12:20 new_file.txt
```

 - Удалим pod, pvc и pv
```
$ kubectl delete pod iscsi-nginx
pod "iscsi-nginx" deleted

$ kubectl delete pvc iscsi-pvc
persistentvolumeclaim "iscsi-pvc" deleted

$ kubectl delete pv iscsi-pv
persistentvolume "iscsi-pv" deleted
```

 - Удалим том из iSCSI
```
root@iscsi-12:/home/ubuntu# targetcli
targetcli shell version 2.1.51
Copyright 2011-2013 by Datera, Inc and others.
For help on commands, type 'help'.

/> /iscsi delete iqn.2003-01.org.linux-iscsi.iscsi-12.x8664:sn.08ed7ab3e592
Deleted Target iqn.2003-01.org.linux-iscsi.iscsi-12.x8664:sn.08ed7ab3e592.

/> /backstores/block delete storage01
Deleted storage object storage01.

/> ls
o- / ......................................................................................................................... [...]
  o- backstores .............................................................................................................. [...]
  | o- block .................................................................................................. [Storage Objects: 0]
  | o- fileio ................................................................................................. [Storage Objects: 0]
  | o- pscsi .................................................................................................. [Storage Objects: 0]
  | o- ramdisk ................................................................................................ [Storage Objects: 0]
  o- iscsi ............................................................................................................ [Targets: 0]
  o- loopback ......................................................................................................... [Targets: 0]
  o- vhost ............................................................................................................ [Targets: 0]
  o- xen-pvscsi ....................................................................................................... [Targets: 0]
```

 - Сольём снимок и том:
```
root@iscsi-12:/home/ubuntu# lvconvert --merge /dev/iscsi/lvol0-snap
  Merging of volume iscsi/lvol0-snap started.
  iscsi/lvol0: Merged: 100.00%
```

 - После слияния снимок пропал:
```
root@iscsi-12:/home/ubuntu# lvs
  LV    VG    Attr       LSize  Pool Origin Data%  Meta%  Move Log Cpy%Sync Convert
  lvol0 iscsi -wi-a----- <5.00g
```

 - Снова добавим логический том lvol0 в iSCSI
```
root@iscsi-12:/home/ubuntu# targetcli
targetcli shell version 2.1.51
Copyright 2011-2013 by Datera, Inc and others.
For help on commands, type 'help'.

/> /backstores/block create storage01 /dev/iscsi/lvol0
Created block storage object storage01 using /dev/iscsi/lvol0.

/> /iscsi create
Created target iqn.2003-01.org.linux-iscsi.iscsi-12.x8664:sn.5e212abf5d26.
Created TPG 1.
Global pref auto_add_default_portal=true
Created default portal listening on all IPs (0.0.0.0), port 3260.

/> /iscsi/iqn.2003-01.org.linux-iscsi.iscsi-12.x8664:sn.5e212abf5d26/tpg1/luns create /backstores/block/storage01
Created LUN 0.

/> iscsi/iqn.2003-01.org.linux-iscsi.iscsi-12.x8664:sn.5e212abf5d26/tpg1/acls create iqn.1993-08.org.debian:01:239cc8b88e59
Created Node ACL for iqn.1993-08.org.debian:01:239cc8b88e59
Created mapped LUN 0.

/> ls
o- / ......................................................................................................................... [...]
  o- backstores .............................................................................................................. [...]
  | o- block .................................................................................................. [Storage Objects: 1]
  | | o- storage01 ................................................................ [/dev/iscsi/lvol0 (5.0GiB) write-thru activated]
  | |   o- alua ................................................................................................... [ALUA Groups: 1]
  | |     o- default_tg_pt_gp ....................................................................... [ALUA state: Active/optimized]
  | o- fileio ................................................................................................. [Storage Objects: 0]
  | o- pscsi .................................................................................................. [Storage Objects: 0]
  | o- ramdisk ................................................................................................ [Storage Objects: 0]
  o- iscsi ............................................................................................................ [Targets: 1]
  | o- iqn.2003-01.org.linux-iscsi.iscsi-12.x8664:sn.5e212abf5d26 ........................................................ [TPGs: 1]
  |   o- tpg1 ............................................................................................... [no-gen-acls, no-auth]
  |     o- acls .......................................................................................................... [ACLs: 1]
  |     | o- iqn.1993-08.org.debian:01:239cc8b88e59 ............................................................... [Mapped LUNs: 1]
  |     |   o- mapped_lun0 ............................................................................. [lun0 block/storage01 (rw)]
  |     o- luns .......................................................................................................... [LUNs: 1]
  |     | o- lun0 .......................................................... [block/storage01 (/dev/iscsi/lvol0) (default_tg_pt_gp)]
  |     o- portals .................................................................................................... [Portals: 1]
  |       o- 0.0.0.0:3260 ..................................................................................................... [OK]
  o- loopback ......................................................................................................... [Targets: 0]
  o- vhost ............................................................................................................ [Targets: 0]
  o- xen-pvscsi ....................................................................................................... [Targets: 0]
```

 - Заменим в iscsi-pv.yaml IQN на новый `iqn.2003-01.org.linux-iscsi.iscsi-12.x8664:sn.5e212abf5d26`
```
$ kubectl apply -f iscsi-pv.yaml
persistentvolume/iscsi-pv created

$ kubectl apply -f iscsi-pvc.yaml
persistentvolumeclaim/iscsi-pvc created

$ kubectl apply -f iscsi-pod.yaml
pod/iscsi-nginx created
```

 - Pod не стартует. Смотрим логи iSCSI:
```
root@iscsi-12:/home/ubuntu# dmesg -T | tail
...
[Sat Feb 10 13:21:54 2024] Unable to locate Target IQN: iqn.2003-01.org.linux-iscsi.iscsi-12.x8664:sn.08ed7ab3e592 in Storage Node
[Sat Feb 10 13:21:54 2024] iSCSI Login negotiation failed.
```

 - Идут обращения со старым IQN. Гугл говорит что надо разлогиниться. Последуем совету
```
root@worker-12:/home/ubuntu# iscsiadm -m session
tcp: [1] 172.16.0.35:3260,1 iqn.2003-01.org.linux-iscsi.iscsi-12.x8664:sn.08ed7ab3e592 (non-flash)

root@worker-12:/home/ubuntu# iscsiadm --mode node --targetname iqn.2003-01.org.linux-iscsi.iscsi-12.x8664:sn.08ed7ab3e592 --portal 172.16.0.35:3260 --logout
Logging out of session [sid: 1, target: iqn.2003-01.org.linux-iscsi.iscsi-12.x8664:sn.08ed7ab3e592, portal: 172.16.0.35,3260]
Logout of [sid: 1, target: iqn.2003-01.org.linux-iscsi.iscsi-12.x8664:sn.08ed7ab3e592, portal: 172.16.0.35,3260] successful.
```

 - Pod стартовал. Посмотрим, какие файлы есть в томе
```
$ kubectl exec -it iscsi-nginx -- sh -c 'cd /usr/share/nginx/html; ls -la'
total 28
drwxr-xr-x 3 root root  4096 Feb  4 21:36 .
drwxr-xr-x 3 root root  4096 Jan 31 23:54 ..
-rw-r--r-- 1 root root     7 Feb  4 21:36 index.html
drwx------ 2 root root 16384 Feb  4 21:31 lost+found

$ kubectl get pods -o wide | grep nginx
iscsi-nginx             1/1     Running   0              100s    10.0.1.250   worker-12   <none>           <none>

$ curl -s 10.0.1.250
privet
```
Всё хорошо, восстановлены старые данные на момент до снимка.
