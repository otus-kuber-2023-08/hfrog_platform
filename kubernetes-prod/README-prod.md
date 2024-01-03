
# Выполнено ДЗ №14

 - [*] Основное ДЗ
 - [*] Задание со *

## В процессе сделано:

- Создадим виртуалки в Yandex облаке
- Создадим файл `/etc/sysctl.d/90-k8s.conf` с содержимым
```
net.ipv4.ip_forward = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
```
- Применим его командой `systemctl restart systemd-sysctl.service`
- Создадим файл `/etc/modules-load.d/br_netfilter.conf` с содержимым
```
br_netfilter
```
- Применим его командой `systemctl restart systemd-modules-load.service`
- Установим containerd командой `apt-get install -y containerd`
- Установим сертификаты и GPG командой `apt-get install -y apt-transport-https ca-certificates curl gpg`
- Создадим директорию `/etc/apt/keyrings`, которая автоматически не создаётся в нашей Ubuntu 20.04, скачаем и добавим ключ apt. Будем ставить k8s версии 1.27
```
mkdir /etc/apt/keyrings && curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.27/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
```
- Добавим репозиторий в sources list
```
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.27/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list
```
- Обновим каталог и установим пакеты k8s
```
apt-get update && apt-get install -y kubelet kubeadm kubectl
```
- Инициализируем кластер
```
kubeadm init --pod-network-cidr=10.244.0.0/16
```
- установим сетевой плагин, пусть будет flannel
```
export KUBECONFIG=/etc/kubernetes/admin.conf
kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
```
- проверим состояние кластера
```
# kubectl cluster-info
Kubernetes control plane is running at https://192.168.10.32:6443
CoreDNS is running at https://192.168.10.32:6443/api/v1/namespaces/kube-system/services/kube-dns:dns/proxy

To further debug and diagnose cluster problems, use 'kubectl cluster-info dump'.
# kubectl get nodes -o wide
NAME                   STATUS   ROLES           AGE    VERSION   INTERNAL-IP     EXTERNAL-IP   OS-IMAGE             KERNEL-VERSION      CONTAINER-RUNTIME
epdafe7638tgp2v3fogt   Ready    control-plane   2m6s   v1.27.9   192.168.10.32   <none>        Ubuntu 20.04.6 LTS   5.4.0-169-generic   containerd://1.7.2
```
- Повторим процедуру подготовки, исключая `kubeadm init`, на двух других виртуалках
- Добавим их в кластер командой, которая была выдана в конце `kubeadm init` на первой виртуалке
```
kubeadm join 192.168.10.32:6443 --token n4wej0.1e4rp2rrhnb5nm6z --discovery-token-ca-cert-hash sha256:914da9690401bbcc32299170e04ca9abf9278361ade8277f3739b5a62984607c
```
- Проверим состояние узлов
```
# kubectl get nodes -o wide
NAME                   STATUS   ROLES           AGE     VERSION   INTERNAL-IP     EXTERNAL-IP   OS-IMAGE             KERNEL-VERSION      CONTAINER-RUNTIME
epdafe7638tgp2v3fogt   Ready    control-plane   18m     v1.27.9   192.168.10.32   <none>        Ubuntu 20.04.6 LTS   5.4.0-169-generic   containerd://1.7.2
epdcug159cfsku1nb2gf   Ready    <none>          5m20s   v1.27.9   192.168.10.25   <none>        Ubuntu 20.04.6 LTS   5.4.0-169-generic   containerd://1.7.2
epdlkp53jlle647v1ohm   Ready    <none>          21s     v1.27.9   192.168.10.7    <none>        Ubuntu 20.04.6 LTS   5.4.0-169-generic   containerd://1.7.2
```
- Создадим тестовый деплоймент с первой виртуалки, см. файл `deploy.yaml` и проверим его
```
# kubectl apply -f deploy.yaml
deployment.apps/nginx-deployment created
# kubectl get pods -o wide
NAME                                READY   STATUS    RESTARTS   AGE    IP           NODE                   NOMINATED NODE   READINESS GATES
nginx-deployment-5cf6fcbc8f-8jhsh   1/1     Running   0          104s   10.244.2.3   epdlkp53jlle647v1ohm   <none>           <none>
nginx-deployment-5cf6fcbc8f-9blct   1/1     Running   0          104s   10.244.2.2   epdlkp53jlle647v1ohm   <none>           <none>
nginx-deployment-5cf6fcbc8f-bplj7   1/1     Running   0          104s   10.244.1.2   epdcug159cfsku1nb2gf   <none>           <none>
nginx-deployment-5cf6fcbc8f-c9vb4   1/1     Running   0          103s   10.244.1.3   epdcug159cfsku1nb2gf   <none>           <none>
# curl 10.244.2.3
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
<style>
    body {
        width: 35em;
        margin: 0 auto;
        font-family: Tahoma, Verdana, Arial, sans-serif;
    }
</style>
</head>
<body>
<h1>Welcome to nginx!</h1>
<p>If you see this page, the nginx web server is successfully installed and
working. Further configuration is required.</p>

<p>For online documentation and support please refer to
<a href="http://nginx.org/">nginx.org</a>.<br/>
Commercial support is available at
<a href="http://nginx.com/">nginx.com</a>.</p>

<p><em>Thank you for using nginx.</em></p>
</body>
</html>
```
- Обновим мастер, это первая виртуалка, до 1.28
```
# rm /etc/apt/keyrings/kubernetes-apt-keyring.gpg && curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.28/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
# echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.28/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list
deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.28/deb/ /
# apt-get update && apt-get install -y kubelet kubeadm kubectl
# kubeadm upgrade plan
[upgrade/config] Making sure the configuration is correct:
[upgrade/config] Reading configuration from the cluster...
[upgrade/config] FYI: You can look at this config file with 'kubectl -n kube-system get cm kubeadm-config -o yaml'
[preflight] Running pre-flight checks.
[upgrade] Running cluster health checks
[upgrade] Fetching available versions to upgrade to
[upgrade/versions] Cluster version: v1.27.9
[upgrade/versions] kubeadm version: v1.28.5
I0101 20:09:19.767676   12310 version.go:256] remote version is much newer: v1.29.0; falling back to: stable-1.28
[upgrade/versions] Target version: v1.28.5
[upgrade/versions] Latest version in the v1.27 series: v1.27.9

Components that must be upgraded manually after you have upgraded the control plane with 'kubeadm upgrade apply':
COMPONENT   CURRENT       TARGET
kubelet     3 x v1.27.9   v1.28.5

Upgrade to the latest stable version:

COMPONENT                 CURRENT   TARGET
kube-apiserver            v1.27.9   v1.28.5
kube-controller-manager   v1.27.9   v1.28.5
kube-scheduler            v1.27.9   v1.28.5
kube-proxy                v1.27.9   v1.28.5
CoreDNS                   v1.10.1   v1.10.1
etcd                      3.5.9-0   3.5.9-0

You can now apply the upgrade by executing the following command:

	kubeadm upgrade apply v1.28.5

_____________________________________________________________________


The table below shows the current state of component configs as understood by this version of kubeadm.
Configs that have a "yes" mark in the "MANUAL UPGRADE REQUIRED" column require manual config upgrade or
resetting to kubeadm defaults before a successful upgrade can be performed. The version to manually
upgrade to is denoted in the "PREFERRED VERSION" column.

API GROUP                 CURRENT VERSION   PREFERRED VERSION   MANUAL UPGRADE REQUIRED
kubeproxy.config.k8s.io   v1alpha1          v1alpha1            no
kubelet.config.k8s.io     v1beta1           v1beta1             no
_____________________________________________________________________

# kubeadm upgrade apply v1.28.5
...
[upgrade/successful] SUCCESS! Your cluster was upgraded to "v1.28.5". Enjoy!

[upgrade/kubelet] Now that your control plane is upgraded, please proceed with upgrading your kubelets if you haven't already done so.
```
- Проверим состояние узлов
```
# kubectl get node -o wide
NAME                   STATUS   ROLES           AGE   VERSION   INTERNAL-IP     EXTERNAL-IP   OS-IMAGE             KERNEL-VERSION      CONTAINER-RUNTIME
epdafe7638tgp2v3fogt   Ready    control-plane   36m   v1.27.9   192.168.10.32   <none>        Ubuntu 20.04.6 LTS   5.4.0-169-generic   containerd://1.7.2
epdcug159cfsku1nb2gf   Ready    <none>          23m   v1.27.9   192.168.10.25   <none>        Ubuntu 20.04.6 LTS   5.4.0-169-generic   containerd://1.7.2
epdlkp53jlle647v1ohm   Ready    <none>          18m   v1.27.9   192.168.10.7    <none>        Ubuntu 20.04.6 LTS   5.4.0-169-generic   containerd://1.7.2
```
Версия на мастере не изменилась.
- Перезапустим kubelet и проверим снова
```
# systemctl restart kubelet
# kubectl get node -o wide
NAME                   STATUS   ROLES           AGE   VERSION   INTERNAL-IP     EXTERNAL-IP   OS-IMAGE             KERNEL-VERSION      CONTAINER-RUNTIME
epdafe7638tgp2v3fogt   Ready    control-plane   38m   v1.28.5   192.168.10.32   <none>        Ubuntu 20.04.6 LTS   5.4.0-169-generic   containerd://1.7.2
epdcug159cfsku1nb2gf   Ready    <none>          25m   v1.27.9   192.168.10.25   <none>        Ubuntu 20.04.6 LTS   5.4.0-169-generic   containerd://1.7.2
epdlkp53jlle647v1ohm   Ready    <none>          20m   v1.27.9   192.168.10.7    <none>        Ubuntu 20.04.6 LTS   5.4.0-169-generic   containerd://1.7.2
```
Теперь всё хорошо. Версии компонентов мастера тоже в норме, это можно посмотреть в логах через `crictl logs`, а также посредством команд и describe
```
# kubeadm version
kubeadm version: &version.Info{Major:"1", Minor:"28", GitVersion:"v1.28.5", GitCommit:"506050d61cf291218dfbd41ac93913945c9aa0da", GitTreeState:"clean", BuildDate:"2023-12-19T13:40:52Z", GoVersion:"go1.20.12", Compiler:"gc", Platform:"linux/amd64"}
# kubelet --version
Kubernetes v1.28.5
# kubectl version
Client Version: v1.28.5
Kustomize Version: v5.0.4-0.20230601165947-6ce0bf390ce3
Server Version: v1.28.5
# kubectl get pods -n kube-system
NAME                                           READY   STATUS    RESTARTS        AGE
coredns-5d78c9869d-4mt8r                       1/1     Running   0               45m
coredns-5d78c9869d-brpxh                       1/1     Running   0               45m
etcd-epdafe7638tgp2v3fogt                      1/1     Running   0               7m23s
kube-apiserver-epdafe7638tgp2v3fogt            1/1     Running   1 (7m32s ago)   7m26s
kube-controller-manager-epdafe7638tgp2v3fogt   1/1     Running   0               7m24s
kube-proxy-fpsw7                               1/1     Running   0               10m
kube-proxy-mzkt6                               1/1     Running   0               10m
kube-proxy-zj9hl                               1/1     Running   0               10m
kube-scheduler-epdafe7638tgp2v3fogt            1/1     Running   0               7m21s
# kubectl describe pod kube-apiserver-epdafe7638tgp2v3fogt -n kube-system | grep v1.2[0-9]
    Image:         registry.k8s.io/kube-apiserver:v1.28.5
  Normal  Pulled   9m28s (x2 over 9m30s)  kubelet  Container image "registry.k8s.io/kube-apiserver:v1.28.5" already present on machine
```
- Подготовим первый рабочий узел к обновлению: выселим с него поды, игнорируя daemonsets
```
# kubectl drain epdcug159cfsku1nb2gf --ignore-daemonsets
node/epdcug159cfsku1nb2gf cordoned
Warning: ignoring DaemonSet-managed Pods: kube-flannel/kube-flannel-ds-9qc55, kube-system/kube-proxy-mzkt6
evicting pod default/nginx-deployment-5cf6fcbc8f-c9vb4
evicting pod default/nginx-deployment-5cf6fcbc8f-bplj7
pod/nginx-deployment-5cf6fcbc8f-bplj7 evicted
pod/nginx-deployment-5cf6fcbc8f-c9vb4 evicted
node/epdcug159cfsku1nb2gf drained
# kubectl get node -o wide
NAME                   STATUS                     ROLES           AGE   VERSION   INTERNAL-IP     EXTERNAL-IP   OS-IMAGE             KERNEL-VERSION      CONTAINER-RUNTIME
epdafe7638tgp2v3fogt   Ready                      control-plane   51m   v1.28.5   192.168.10.32   <none>        Ubuntu 20.04.6 LTS   5.4.0-169-generic   containerd://1.7.2
epdcug159cfsku1nb2gf   Ready,SchedulingDisabled   <none>          37m   v1.27.9   192.168.10.25   <none>        Ubuntu 20.04.6 LTS   5.4.0-169-generic   containerd://1.7.2
epdlkp53jlle647v1ohm   Ready                      <none>          32m   v1.27.9   192.168.10.7    <none>        Ubuntu 20.04.6 LTS   5.4.0-169-generic   containerd://1.7.2
# kubectl get pods -A --field-selector spec.nodeName=epdcug159cfsku1nb2gf
NAMESPACE      NAME                    READY   STATUS    RESTARTS   AGE
kube-flannel   kube-flannel-ds-9qc55   1/1     Running   0          39m
kube-system    kube-proxy-mzkt6        1/1     Running   0          16m
```
- Обновим пакеты на рабочем узле, запустим `kubeadm upgrade node`, после чего перезапустим kubelet и проверим состояние узлов
```
# kubeadm upgrade node
[upgrade] Reading configuration from the cluster...
[upgrade] FYI: You can look at this config file with 'kubectl -n kube-system get cm kubeadm-config -o yaml'
[preflight] Running pre-flight checks
[preflight] Skipping prepull. Not a control plane node.
[upgrade] Skipping phase. Not a control plane node.
[upgrade] Backing up kubelet config file to /etc/kubernetes/tmp/kubeadm-kubelet-config4141848450/config.yaml
[kubelet-start] Writing kubelet configuration to file "/var/lib/kubelet/config.yaml"
[upgrade] The configuration for this node was successfully updated!
[upgrade] Now you should go ahead and upgrade the kubelet package using your package manager.
# systemctl restart kubelet
# kubectl get nodes -o wide
NAME                   STATUS                     ROLES           AGE   VERSION   INTERNAL-IP     EXTERNAL-IP   OS-IMAGE             KERNEL-VERSION      CONTAINER-RUNTIME
epdafe7638tgp2v3fogt   Ready                      control-plane   56m   v1.28.5   192.168.10.32   <none>        Ubuntu 20.04.6 LTS   5.4.0-169-generic   containerd://1.7.2
epdcug159cfsku1nb2gf   Ready,SchedulingDisabled   <none>          42m   v1.28.5   192.168.10.25   <none>        Ubuntu 20.04.6 LTS   5.4.0-169-generic   containerd://1.7.2
epdlkp53jlle647v1ohm   Ready                      <none>          37m   v1.27.9   192.168.10.7    <none>        Ubuntu 20.04.6 LTS   5.4.0-169-generic   containerd://1.7.2
```
Узел обновлён.
- Вернём на него возможность принимать нагрузку. Работающие поды переезжать не будут.
```
# kubectl uncordon epdcug159cfsku1nb2gf
```
- Обновим таким же образом второй рабочий узел и проверим состояние узлов
```
# kubectl get nodes -o wide
NAME                   STATUS   ROLES           AGE   VERSION   INTERNAL-IP     EXTERNAL-IP   OS-IMAGE             KERNEL-VERSION      CONTAINER-RUNTIME
epdafe7638tgp2v3fogt   Ready    control-plane   66m   v1.28.5   192.168.10.32   <none>        Ubuntu 20.04.6 LTS   5.4.0-169-generic   containerd://1.7.2
epdcug159cfsku1nb2gf   Ready    <none>          53m   v1.28.5   192.168.10.25   <none>        Ubuntu 20.04.6 LTS   5.4.0-169-generic   containerd://1.7.2
epdlkp53jlle647v1ohm   Ready    <none>          48m   v1.28.5   192.168.10.7    <none>        Ubuntu 20.04.6 LTS   5.4.0-169-generic   containerd://1.7.2
```
- Проверим, что nginx по прежнему работает
```
# kubectl get pods -o wide
NAME                                READY   STATUS    RESTARTS   AGE     IP           NODE                   NOMINATED NODE   READINESS GATES
nginx-deployment-5cf6fcbc8f-274kb   1/1     Running   0          4m41s   10.244.1.7   epdcug159cfsku1nb2gf   <none>           <none>
nginx-deployment-5cf6fcbc8f-4xs2m   1/1     Running   0          4m41s   10.244.1.8   epdcug159cfsku1nb2gf   <none>           <none>
nginx-deployment-5cf6fcbc8f-lw9c4   1/1     Running   0          4m41s   10.244.1.6   epdcug159cfsku1nb2gf   <none>           <none>
nginx-deployment-5cf6fcbc8f-nrtsx   1/1     Running   0          4m41s   10.244.1.5   epdcug159cfsku1nb2gf   <none>           <none>
# curl 10.244.1.7
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
<style>
    body {
        width: 35em;
        margin: 0 auto;
        font-family: Tahoma, Verdana, Arial, sans-serif;
    }
</style>
</head>
<body>
<h1>Welcome to nginx!</h1>
<p>If you see this page, the nginx web server is successfully installed and
working. Further configuration is required.</p>

<p>For online documentation and support please refer to
<a href="http://nginx.org/">nginx.org</a>.<br/>
Commercial support is available at
<a href="http://nginx.com/">nginx.com</a>.</p>

<p><em>Thank you for using nginx.</em></p>
</body>
</html>
```
- Установим k8s через kubespray, для этого развернём виртуалку с Ubuntu 22.04, с python 3.10, и установим локально.
  Если ставить через публичный адрес, то kubespray запускает etcd на публичном адресе, и он не работает.
```
# git clone https://github.com/kubernetes-sigs/kubespray.git
# apt-get install -y python3-venv
# VENVDIR=kubespray-venv
# python3 -m venv $VENVDIR
# source $VENVDIR/bin/activate
(kubespray-venv) root@master-1:/home/ubuntu# cd kubespray
(kubespray-venv) root@master-1:/home/ubuntu/kubespray# pip install -U -r requirements.txt
...
(kubespray-venv) root@master-1:/home/ubuntu/kubespray# cp -rfp inventory/sample inventory/mycluster
(kubespray-venv) root@master-1:/home/ubuntu/kubespray# vi inventory/mycluster/inventory.ini
(kubespray-venv) root@master-1:/home/ubuntu/kubespray# cat inventory/mycluster/inventory.ini
[all]
master-1 ansible_host=192.168.10.7 etcd_member_name=etcd1

[kube_control_plane]
master-1

[etcd]
master-1

[kube_node]
master-1

[calico_rr]

[k8s_cluster:children]
kube_control_plane
kube_node
calico_rr
(kubespray-venv) root@master-1:/home/ubuntu/kubespray# ansible-playbook -i inventory/mycluster/inventory.ini --user=ubuntu --become --become-user=root cluster.yml
...
(kubespray-venv) root@master-1:/home/ubuntu/kubespray# kubectl get nodes -o wide
NAME       STATUS   ROLES           AGE     VERSION   INTERNAL-IP    EXTERNAL-IP   OS-IMAGE             KERNEL-VERSION      CONTAINER-RUNTIME
master-1   Ready    control-plane   3m46s   v1.28.5   192.168.10.7   <none>        Ubuntu 22.04.3 LTS   5.15.0-91-generic   containerd://1.7.11
(kubespray-venv) root@master-1:/home/ubuntu/kubespray# kubectl get pods -A
NAMESPACE     NAME                                      READY   STATUS    RESTARTS   AGE
kube-system   calico-kube-controllers-648dffd99-59htn   1/1     Running   0          2m46s
kube-system   calico-node-45pt4                         1/1     Running   0          3m9s
kube-system   coredns-77f7cc69db-5hmc9                  1/1     Running   0          2m25s
kube-system   dns-autoscaler-595558c478-rw2nd           1/1     Running   0          2m20s
kube-system   kube-apiserver-master-1                   1/1     Running   1          4m17s
kube-system   kube-controller-manager-master-1          1/1     Running   2          4m13s
kube-system   kube-proxy-htwng                          1/1     Running   0          3m27s
kube-system   kube-scheduler-master-1                   1/1     Running   1          4m16s
kube-system   nodelocaldns-625sz                        1/1     Running   0          2m17s
```
- Проверим работоспособность при помощи того же `deploy.yaml`
```
# kubectl apply -f deploy.yaml
deployment.apps/nginx-deployment created
# kubectl get pods -o wide
NAME                                READY   STATUS    RESTARTS   AGE   IP               NODE       NOMINATED NODE   READINESS GATES
nginx-deployment-54b6986c8c-c9dxj   1/1     Running   0          84s   10.233.118.133   master-1   <none>           <none>
nginx-deployment-54b6986c8c-dpl2m   1/1     Running   0          84s   10.233.118.134   master-1   <none>           <none>
nginx-deployment-54b6986c8c-wlxbj   1/1     Running   0          84s   10.233.118.135   master-1   <none>           <none>
nginx-deployment-54b6986c8c-znj8g   1/1     Running   0          84s   10.233.118.132   master-1   <none>           <none>
# curl 10.233.118.133
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
...
```

## Задание со *

- Установим кластер на виртуалках в облаке Yandex при помощи GitHub Actions, terraform и kubeadm. 
  Все необходимые файлы скопированы из рабочего репозитория https://github.com/hfrog/otus-k8s и приложены.
  В `workflows` описания GitHub workflow, отдельно terraform и k8s-cluster, оба запускаются вручную.
  В `terraform` манифест, в `scripts` - скрипты установки. Результирующая конструкция автоматически разворачивает кластер
  и требует только настроенных секретов, среди которых секреты для доступа к облаку Yandex, ключи и др., а также ручного подтверждения выполнения
  некоторых задач (job) в workflows. Также используется одна переменная K8S_VERSION, установлена в 1.28.
  Ниже вывод списка узлов, а также проверка работоспособности деплоймента nginx
```
$ kubectl --kubeconfig=admin.conf get nodes -o wide
NAME       STATUS   ROLES           AGE   VERSION   INTERNAL-IP     EXTERNAL-IP   OS-IMAGE             KERNEL-VERSION      CONTAINER-RUNTIME
master-1   Ready    control-plane   17m   v1.28.5   192.168.10.15   <none>        Ubuntu 20.04.6 LTS   5.4.0-169-generic   containerd://1.7.2
master-2   Ready    control-plane   15m   v1.28.5   192.168.10.33   <none>        Ubuntu 20.04.6 LTS   5.4.0-169-generic   containerd://1.7.2
master-3   Ready    control-plane   13m   v1.28.5   192.168.10.18   <none>        Ubuntu 20.04.6 LTS   5.4.0-169-generic   containerd://1.7.2
worker-1   Ready    <none>          13m   v1.28.5   192.168.10.32   <none>        Ubuntu 20.04.6 LTS   5.4.0-169-generic   containerd://1.7.2
worker-2   Ready    <none>          13m   v1.28.5   192.168.10.9    <none>        Ubuntu 20.04.6 LTS   5.4.0-169-generic   containerd://1.7.2
$ kubectl --kubeconfig=admin.conf apply -f deploy.yaml
deployment.apps/nginx-deployment created
```
Дальше непосредственно на узле, т.к. с ноута нет доступ до сети подов.
```
root@master-1:/etc# kubectl get pods -o wide
NAME                                READY   STATUS    RESTARTS   AGE   IP           NODE       NOMINATED NODE   READINESS GATES
nginx-deployment-54b6986c8c-9b76v   1/1     Running   0          12m   10.244.4.3   worker-2   <none>           <none>
nginx-deployment-54b6986c8c-rzrmk   1/1     Running   0          12m   10.244.3.2   worker-1   <none>           <none>
nginx-deployment-54b6986c8c-vhwsj   1/1     Running   0          12m   10.244.4.2   worker-2   <none>           <none>
nginx-deployment-54b6986c8c-xsl9t   1/1     Running   0          12m   10.244.3.3   worker-1   <none>           <none>
root@master-1:/etc# curl -s 10.244.4.3 | head
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
<style>
    body {
        width: 35em;
        margin: 0 auto;
        font-family: Tahoma, Verdana, Arial, sans-serif;
    }
root@master-1:/etc# curl -s 10.244.3.2 | head
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
<style>
    body {
        width: 35em;
        margin: 0 auto;
        font-family: Tahoma, Verdana, Arial, sans-serif;
    }
```
Работает.

- Некоторые особенности:
  * состояние терраформа хранится в Yandex Object Storage, там же хранится файл с IP адресами, который используют многие скрипты
  * отдельным сервером, но этим же терраформом и скриптами, развёрнут балансировщик на haproxy для apiserver. При добавлении мастеров его конфигурация автоматически меняется.
    Для него запрашивается статический IP адрес, также через terraform.
  * etcd оставлен в том виде, в котором его создаёт kubeadm, то есть без изменения сертификатов, listen-client-urls и advertise-client-urls. Решил остановиться на достигнутом.
  * В принципе, думаю что коллекцию полукостыльных скриптов можно переписать красивее на ансибле, но решил оставить так.
    Главная цель была научиться ставить кластер с помощью kubeadm, а также попробовать terraform с облаком Yandex.

