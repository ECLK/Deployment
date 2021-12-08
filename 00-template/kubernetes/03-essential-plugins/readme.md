# Essential Software that needs to be installed in K8s


#addrepo - helm repo add stable https://charts.helm.sh/stable

## nginx ingress

```kubectl create ns nginx-ingress```
```
helm install nginx-ingress stable/nginx-ingress --namespace nginx-ingress  \
--set rbac.create=true \
--set controller.service.type=NodePort \
--set controller.metrics.enabled=true \
--set controller.stats.enabled=true 
```

Have a look at nginx-ingress.md for a sample of an ingress with nginx ingress.

## metrics server


``` kubectl create ns monitoring```
```
helm install metrics-server stable/metrics-server --namespace monitoring \
--set "args[0]=--logtostderr,args[1]=--kubelet-preferred-address-types=InternalIP,args[2]=--kubelet-insecure-tls" 
```

To check if the metrics are working, please try the following command after about 10 mins.

 ```kubectl get --raw "/apis/metrics.k8s.io/v1beta1/nodes"```

## k8s Dashboard

```
helm install kubernetes-dashboard stable/kubernetes-dashboard \
--set rbac.clusterAdminRole=true --namespace kube-system
```

```
kubectl create clusterrolebinding dashboard-admin -n kube-system --clusterrole=cluster-admin --serviceaccount=kube-system:kubernetes-dashboard 
```

NOTES:
*********************************************************************************
*** PLEASE BE PATIENT: kubernetes-dashboard may take a few minutes to install ***
*********************************************************************************

Get the Kubernetes Dashboard URL by running:
  export POD_NAME=$(kubectl get pods -n default -l "app=kubernetes-dashboard,release=kubernetes-dashboard" -o jsonpath="{.items[0].metadata.name}")
  echo https://127.0.0.1:8443/
  kubectl -n default port-forward $POD_NAME 8443:8443

## Cert Manager

#addrepo - helm repo add jetstack https://charts.jetstack.io

kubectl create ns cert-manager

helm install cert-manager jetstack/cert-manager --namespace cert-manager --version v1.4.4
  
 kubectl apply -f cluster-issuer.yaml
