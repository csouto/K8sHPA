# Kubernetes and HPA
I deployed a simple hello world web app using Flask and instrumented the code to generate custom metrics with the Prometheus official library. I configured Prometheus to scrape the number of HTTP requests per second and used [Prometheus Adapter](https://github.com/helm/charts/tree/master/stable/prometheus-adapter) to pass theses values to the Horizontal Pod Autoscaler (that will scale the number of pods based on that metric).   

To see it in action (the password was emailed to you!): 
- [Grafana](http://34.200.243.150:32575/)
- [Web-server](http://34.200.243.150/)  
  
  

The manifest files are [here](https://github.com/csouto/K8sHPA/tree/master/manifests), and if you want to deploy it yourself just clone this repository and follow the instructions below.

For this task I decided to build a single-node cluster from scratch on an EC2 instance running Ubuntu 18.04. 
To bootstrap your environment please paste this  [script](https://github.com/csouto/K8sHPA/blob/master/bootstrap.sh) on your user-data field or SSH into the server and run it.



## Walkthrough
I used Helm to do the heavy lifting, to install it just run this script:

```shell
curl -L https://git.io/get_helm.sh | bash
```

and use the following commands to deploy Tiller:
```shell
kubectl -n kube-system create serviceaccount tiller

kubectl create clusterrolebinding tiller \
  --clusterrole=cluster-admin \
  --serviceaccount=kube-system:tiller

helm init --service-account tiller
```
Let's deploy the Hello World app:
```shell
kubectl apply -f manifests/web/
```
The next step creates Persistent Volumes for Prometheus and Grafana:
```shell
kubectl apply -f ../manifests/volumes/
```
  
  

#### To deploy the resources, ` cd ` into the helm directory and use the following commands to install charts ####    
**Nginx-Ingress:**
```shell
helm install stable/nginx-ingress --name ing -f values-ingress.yaml
```


**Prometheus:**
```shell
helm install stable/prometheus --name mon -f values-prometheus.yaml
````
  
*Store Prometheus service name:*
```shell
export PROM=$(kubectl get service --namespace default -l "app=prometheus,component=server" -o jsonpath="{.items[0].metadata.name}")
```



**Prometheus-Adapter:**

*First set the correct prometheus server on configuration:*
```shell
sed -i s/urlprom/$PROM/ values-adapter.yaml
```
then install:
```shell
helm install stable/prometheus-adapter --name int -f values-adapter.yaml
````


**Grafana:**  

*Configure the Prometheus server on a ConfigMap template:*
```shell
sed -i s/urlprom/$PROM/ datasource.yaml
```

Create the ConfigMap:
```shell
kubectl apply -f datasource.yaml
```
and install Grafana:
```shell
helm install stable/grafana --name ds -f values-grafana.yaml
```
  
Finally the Ingress resource:
```shell
kubectl apply -f manifests/ing-web-ingress.yaml
```
  
  
and the Horizontal Pod Autoscaler:
```shell
kubectl apply -f manifests/hpa.yaml
```  
  
  In this scenario Grafana was expose using a NodePort, check the port with `kubectl get svc --namespace default -l "app=grafana" -o jsonpath="{.items[0].spec.ports[0].nodePort}"`.
  Please use your browser to access it using this port and the external IP of your EC2 instance to import this [dashboard](https://github.com/csouto/K8sHPA/blob/master/dashboard.json).  Get password by running ` kubectl get secret --namespace default ds-grafana -o jsonpath="{.data.admin-password}" | base64 --decode ; echo`
  
Now hopefully everything is configured! Just generate some traffic to <*instance ip*> on port 80 and use grafana or `kubectl describe hpa ` to check it!
