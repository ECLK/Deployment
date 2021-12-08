# Prometheus

## Setup Namespace 

```kubectl create ns monitoring```

## Install Prometheus Opertaor

Have a look at values.yaml before to configure the settings you want. Currently, monitoring data is retained for 60 days.

```helm install stable/prometheus-operator prom-operator --values values.yaml --namespace monitoring```

