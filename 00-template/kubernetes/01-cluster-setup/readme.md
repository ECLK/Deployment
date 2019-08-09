
## Configuring the templates

### Guide on Kubernetes Architectures

[1]: Single Master Node Cluster
[2]: Highly Available Cluster
[3]: Complex Cluster

### Setup kubeadm configuration

Before continuing, Please configure the following in kubeadm-config.yaml in the templates

#### Configure API SANs
In order for your k8s API to work with kubectl and other applications with https it is essential that you enable the following in kubeadm config. 
```
apiServer:
  certSANs:
  - 127.0.0.1
  - ${LB_PRIVATE_IP}
  - ${LB_PUBLIC_IP}
  - ${LB_DNS_NAME}
```
${LB_PRIVATE_IP} = Private IP address of the Loadbalancer
${LB_PUBLIC_IP} = Public IP address of the loadbalancer
${LB_DNS_NAME} = Public DNS name of the LB. Adviced to put even a demo one if a DNS does not exist because it is going to be a bit messy when you have to redo this again (eg: kubernetes.ecdev.lk)

#### Configure Subnets
Have a look at pod subnet and service subnet. Make sure these subnets do not coincide with the subnets that exist in your external network. These are the default configuration. You can change as you see fit for your environment.
Please note that if you change podSubnet, you have to change the subnet in ```calico.yaml``` as well. To do that, open calico.yaml and search for ```CALICO_IPV4POOL_CIDR```
```
networking:
  dnsDomain: cluster.local
  podSubnet: 192.168.100.0/20
  serviceSubnet: 10.225.101.0/24
```
 
 
#### Setup Kubectl
After successfully running kubeadm init, this is how you enable kubectl in Master nodes
```
  mkdir -p $HOME/.kube
  sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
  sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

 
## Tear Down the cluster

In every node run
```kubeadm reset```