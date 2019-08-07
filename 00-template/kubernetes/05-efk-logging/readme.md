# Loggin with ElasticSearch - FluentBit - Kibana

We are using an umbrella helm chart here created by akomljen-charts https://raw.githubusercontent.com/komljen/helm-charts/master/charts/

Have  a look at efk-values.yaml and change values if necessary. However in this repository, all the best practices settings have been applied.

Log retention period of ElasticSearch here is 7 days. You can change this up looking at efk-values.yaml

Default PVC size is 100Gi, you can change that too by looking at efk-values.yaml

After everything is done. run the followng.

```sh install.sh```

