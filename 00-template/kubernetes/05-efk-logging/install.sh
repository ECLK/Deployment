#!/bin/bash

kubectl create ns logging

helm repo add akomljen-charts https://raw.githubusercontent.com/komljen/helm-charts/master/charts/
helm install --name es-operator  --namespace logging  akomljen-charts/elasticsearch-operator
helm install --name efk --namespace logging akomljen-charts/efk --values=./efk-values.yaml