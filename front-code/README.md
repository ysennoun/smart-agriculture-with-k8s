# front-code

## Project setup
```
npm install
```

### Compiles and hot-reloads for development
```
npm run serve
```

### Compiles and minifies for production
```
npm run build
```

### Run your unit tests
```
npm run test:unit
```

### Run your end-to-end tests
```
npm run test:e2e
```

### Lints and fixes files
```
npm run lint
```

### Customize configuration
See [Configuration Reference](https://cli.vuejs.org/config/).

npm install i -g @vue/cli
cd d3-vue-example
npm install bootstrap-vue bootstrap axios
npm install vue-chartjs chart.js --save
npm install leaflet vue2-leaflet --save
npm install vuex --save

npm run serve


docker build -f Dockerfile -t eu.gcr.io/ysennoun-iot/vue .
docker push eu.gcr.io/ysennoun-iot/vue

kubectl create deployment hello-node --image=eu.gcr.io/ysennoun-iot/vue
kubectl expose deployment hello-node --type=LoadBalancer --port=8080

docker build -f Dockerfile -t eu.gcr.io/ysennoun-iot/toto . && docker push eu.gcr.io/ysennoun-iot/toto
kubectl create deployment toto --image=eu.gcr.io/ysennoun-iot/toto
kubectl expose deployment toto --type=LoadBalancer --port=8080



docker build -f Dockerfile-flask -t eu.gcr.io/ysennoun-iot/flask-hello . && docker push eu.gcr.io/ysennoun-iot/flask-hello
kubectl create deployment flask-hello --image=eu.gcr.io/ysennoun-iot/flask-hello
kubectl expose deployment flask-hello --type=LoadBalancer --port=8080


docker build -f Dockerfile-flask -t eu.gcr.io/ysennoun-iot/flask-hello . && docker push eu.gcr.io/ysennoun-iot/flask-hello
kubectl apply -f flask-hello.yaml
