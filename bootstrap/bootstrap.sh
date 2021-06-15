#!/bin/sh

#setup cluster and switch context
k3d cluster create c3 -a 1 --api-port 6443 --port 8080:80@loadbalancer --port 8443:443@loadbalancer
kubectl config use-context k3d-c3

#install helm, create manager namespace
namespace=cluster-management
helm -n fleet-system install --create-namespace --wait \
    fleet-crd https://github.com/rancher/fleet/releases/download/v0.3.3/fleet-crd-0.3.3.tgz
helm -n fleet-system install --create-namespace --wait \
    fleet https://github.com/rancher/fleet/releases/download/v0.3.3/fleet-0.3.3.tgz
kubectl create namespace $namespace

#create deploy key for git repo
kubectl create secret generic c3-repo-deploy-key -n $namespace --from-file=ssh-privatekey=./c3-repo-deploy-key.key --type=kubernetes.io/ssh-auth 

#create ca-pem for cluster-agents
kubectl config view -o json --raw  | jq -j '.clusters[] | select(.name == ("k3d-c3")) | .cluster."certificate-authority-data"'  | base64 -d  > ../c3-ca.pem

#add git repo
kubectl apply -f bootstrap.yaml