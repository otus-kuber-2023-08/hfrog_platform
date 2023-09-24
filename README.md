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

 - проверим, что у `bob` есть доступ к кластеру, непример на просмотр подов в namespace `kube-system`, а у `dave` - нет:
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
