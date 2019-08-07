# NFS Client for Kubernetes

This plugin enables dynamic provisioning for Kubernetes with an NFS server.

## Install client
 
```
helm install --name nfs-client --namespace kube-system  stable/nfs-client-provisioner \ 
--set nfs.server=<nfs-ip> \
--set nfs.path=<server-path>
```

an example of the above which has the nfs server ip of 10.225.100.21 hosted in the path /data would look like this.

```
helm install --name nfs-client --namespace kube-system  stable/nfs-client-provisioner \ 
--set nfs.server=10.225.100.21 \
--set nfs.path=/data 
```


## Setup Storage class

After the client has been installed, run the following to setup a storage class for dynamic provisioning.

kubectl patch sc nfs-client  -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'