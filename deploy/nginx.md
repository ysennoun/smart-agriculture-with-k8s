kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/nginx-0.30.0/deploy/static/mandatory.yaml
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/nginx-0.30.0/deploy/static/provider/cloud-generic.yaml
helm install ingress-nginx stable/nginx-ingress --set rbac.create=true

# no istio !

kubectl run sise --image=quay.io/openshiftlabs/simpleservice:0.5.0 --port=9876

kubectl get services -n ingress-nginx => get ip address
curl -v -H "Host: my-nginx.foo.org" 35.198.132.47:80

