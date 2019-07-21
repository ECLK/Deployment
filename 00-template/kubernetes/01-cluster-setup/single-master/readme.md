## Kubernetes Single Master Installation Guide

### Step 1

Configure all the nodes with 
```sh kubernetes-install.sh```

### Step 2

Kubeadm Init on master

Before continuing, Please configure the following in kubeadm-config.yaml

#### Configure API SANs
In order for your k8s API to work with kubectl and other applications with https it is essential that you enable the following in kubeadm config.
```
apiServer:
  certSANs:
  - 127.0.0.1
  - <loadbalancer internal ip>
  - <loadbalancer external ip>
  - <subdomain for api (eg: kubernetes.ecdev.lk)>
```

#### Configure Subnets
Have a look at pod subnet and service subnet. Make sure these subnets do not coincide with the subnets that exist in your external network. These are the default configuration. You can change as you see fit for your environment.
Please note that if you change podSubnet, you have to change the subnet in ```calico.yaml``` as well. To do that, open calico.yaml and search for ```CALICO_IPV4POOL_CIDR```
```
networking:
  dnsDomain: cluster.local
  podSubnet: 192.168.100.0/20
  serviceSubnet: 10.225.101.0/24
```

#### Setup Master with Kubeadm
When you have reviewed all of the above, please proceed with the following command.
Please save up the cluster join command on a secure place as you will require it later on to connect worker nodes.

```kubeadm init --config kubeadm-config.yaml```

Output:
Your Kubernetes control-plane has initialized successfully!

To start using your cluster, you need to run the following as a regular user:

  mkdir -p $HOME/.kube
  sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
  sudo chown $(id -u):$(id -g) $HOME/.kube/config

You should now deploy a pod network to the cluster.
Run "kubectl apply -f [podnetwork].yaml" with one of the options listed at:
  https://kubernetes.io/docs/concepts/cluster-administration/addons/

Then you can join any number of worker nodes by running the following on each as root:

kubeadm join 10.225.100.130:6443 --token <some-token> \
    --discovery-token-ca-cert-hash <some-hash-value>

### Step 3
Better to run this as a non root user.

Setup Kubectl
```
  mkdir -p $HOME/.kube
  sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
  sudo chown $(id -u):$(id -g) $HOME/.kube/config
```


### Step 4

Setup CNI - Calico

```kubectl apply -f calico-rbac.yaml```
```kubectl apply -f calico.yaml```

### Step 5

Join other worker nodes
To do this, ssh into each of the other worker nodes and run the command that you saved up in step 2. It would look like the following
```
kubeadm join 10.225.100.130:6443 --token <some-token> \
    --discovery-token-ca-cert-hash <some-hash-value>
```

