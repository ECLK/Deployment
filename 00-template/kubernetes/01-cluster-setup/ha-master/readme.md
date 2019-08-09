## Kubernetes HA Master Installation Guide

### Step 1 : Install prerequisie libraries and settings

#### Step 1.1 install the tools and libraries

Set Kubetentes Version
```export K8S_VERSION=1.15.2-00```

If there are newer versions available, you can find the versions using the following command
```apt list -a kubeadm```

Configure all the nodes with 
```sh prerequisites-kubernetes.sh```
#### Step 1.2 Enable the loadbalancer

In the loadbalancer VM you have provisioned, please install haproxy looking at the loadbalancer section in this repository.

After installation, edit /etc/haproxy/haproxy.cfg and edit the following.

1. under defaults, remove mode http and replace with mode tcp
2. under defaults, remove log httplog and replace with log tcplog
3. Create a new block as following
   ```
   listen kube_api_server
   bind *:6443
   server master1 <master0-ip>:6443 check
   server master2 <master1-ip>:6443 check
   server master3 <master2-ip>:6443 check
   ```
4. Add a stat server
   ```
   listen stats
    mode http
    bind *:7000
    stats enable
    stats uri /
   ```

### Step 2: Initialize the main master

Please note that in HA Master setup, you ONLY have to config all of this in ONE Master. Not all the masters.

Before continuing, Please configure the following in kubeadm-config.yaml
#### Step 2.1: Set up kubernetes version
as per the previous step, you have to put the kuberntees version in the kubeadm-config.yaml file.
```
kubernetesVersion: <kubernetes-version>
```
You can do so like following. If the $K8S_VERSION is 1.14.2-00, then the k8s version would be v1.14.2
```
sed -i "s/<kubernetes-version>/v1.14.2/g"  kubeadm-config.yaml
```

#### Step 2.2: Configure API SANs
In order for your k8s API to work with kubectl and other applications with https it is essential that you enable the following in kubeadm config.
```
apiServer:
  certSANs:
  - 127.0.0.1
  - <loadbalancer_internal_ip>
  - <loadbalancer_external_ip>
  - <loadbalancer_subdomain> (eg: kubernetes.ecdev.lk)
```
to make this easier, what you can do is, first copy the kubeadm-config.yaml to the VM and run the following
```
export  LB_PRIVATE_IP=<loadbalancer internal ip>
export  LB_PUBLIC_IP=<loadbalancer external ip>
export  LB_DNS_NAME=<loadbalancer subdomain>

sed -i "s/<loadbalancer_internal_ip>/$LB_PRIVATE_IP/g"  kubeadm-config.yaml
sed -i "s/<loadbalancer_external_ip>/$LB_PUBLIC_IP/g"  kubeadm-config.yaml
sed -i "s/<loadbalancer_subdomain>/$LB_PUBLIC_IP/g"  kubeadm-config.yaml
```

Additionally in this archictecture, you have to setup your controlPlaneEndpoint too. But not to worry, the above sed command automatically replaces this value as well.
```
controlPlaneEndpoint: <loadbalancer_internal_ip>
```

#### Step 2.3: Configure Subnets
Have a look at pod subnet and service subnet. Make sure these subnets do not coincide with the subnets that exist in your external network. These are the default configuration. You can change as you see fit for your environment.
Please note that if you change podSubnet, you have to change the subnet in ```calico.yaml``` as well. To do that, open calico.yaml and search for ```CALICO_IPV4POOL_CIDR```
```
networking:
  dnsDomain: cluster.local
  podSubnet: 192.168.100.0/20
  serviceSubnet: 10.225.101.0/24
```

#### Step 2.4: Setup one Master in HA Cluster with Kubeadm
When you have reviewed all of the above, please proceed with the following command.
Please save up the cluster join command on a secure place as you will require it later on to connect worker nodes.

Please note that you don't have to run this command on ALL of the masters. you need to run this in  ONLY ONE MASTER
```kubeadm init --config kubeadm-config.yaml --upload-certs```

Output:
Your Kubernetes control-plane has initialized successfully!

To start using your cluster, you need to run the following as a regular user:

  mkdir -p $HOME/.kube
  sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
  sudo chown $(id -u):$(id -g) $HOME/.kube/config

You should now deploy a pod network to the cluster.
Run "kubectl apply -f [podnetwork].yaml" with one of the options listed at:
  https://kubernetes.io/docs/concepts/cluster-administration/addons/

You can now join any number of the control-plane node running the following command on each as root:

  kubeadm join 192.168.197.19:6443 --token <some-token> \
    --discovery-token-ca-cert-hash <some-hash-value> \
    --control-plane --certificate-key <some-key-value>

Please note that the certificate-key gives access to cluster sensitive data, keep it secret!
As a safeguard, uploaded-certs will be deleted in two hours; If necessary, you can use 
"kubeadm init phase upload-certs --upload-certs" to reload certs afterward.

Then you can join any number of worker nodes by running the following on each as root:

kubeadm join 192.168.197.19:6443 --token <some-token> \
    --discovery-token-ca-cert-hash <some-hash-value>

NOTE: Please save the above tokens

#### Step 2.5 Setup kubectl on the main Master

Setup Kubectl
```
  mkdir -p $HOME/.kube
  sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
  sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

### Step 4: Setup CNI  on  main Master

Setup CNI - Calico

```kubectl apply -f calico-rbac.yaml```
```kubectl apply -f calico.yaml```

NOTE: this template is tried and tested on kubernetes v1.14.2 
If issues arise on newer versions, please visit 
https://docs.projectcalico.org/v3.8/getting-started/kubernetes/.

Make sure the download the yamls and override the podcidr as mentioned in step 2.3

### Step 5: Join addditonal nodes to the control plane

Using the saved tokens produced by step 2.4 
On the other master nodes you have run the following,
```
  kubeadm join 192.168.197.19:6443 --token <some-token> \
    --discovery-token-ca-cert-hash <some-hash-value> \
    --control-plane --certificate-key <some-key-value>
```
repeat step 3 to config kubectl too in these new masters

### Step 6: Check the health of replicated etcd cluster

run the following. Repeat the process with all the ips of the masters you have in the cluster. You should get an output saying cluster is healthy
```
etcdctl \
--cert-file /etc/kubernetes/pki/etcd/peer.crt \
--key-file /etc/kubernetes/pki/etcd/peer.key \
--ca-file /etc/kubernetes/pki/etcd/ca.crt \
--endpoints https://<master0-ip>:2379 cluster-health
```

### Step 7: Check the health of the k8s cluster
``` kubectl get nodes```

Additionally, reboot the masters and see if they get back up and running when it comes back on.

### Step 8: Join worker nodes to control plane

Join other worker nodes
To do this, ssh into each of the other worker nodes and run the command that you saved up in step 2. It would look like the following
```
kubeadm join 10.225.100.130:6443 --token <some-token> \
    --discovery-token-ca-cert-hash <some-hash-value>
```

 