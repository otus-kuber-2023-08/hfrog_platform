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
