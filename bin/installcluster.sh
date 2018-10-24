#!/bin/bash
. .env
## cluster switch
# https://kubernetes.io/docs/tasks/access-application-cluster/configure-access-multiple-clusters/ 

function jumpto
{
    label=$1
    cmd=$(sed -n "/$label:/{:a;n;p;ba};" $0 | grep -v ':$')
    eval "$cmd"
    exit
}

start=${1:-"start"}

jumpto $start

start:

command -v az >/dev/null 2>&1 || { echo "I require az but it's not installed.  Aborting." >&2; exit 1; }
command -v draft >/dev/null 2>&1 || { echo "I require draft but it's not installed. c.f. https://github.com/Azure/draft/releases  Aborting." >&2; exit 1; }

command -v kubectl >/dev/null 2>&1 || { echo "I require kubectl but it's not installed.\n $ az acs kubernetes install-cli \n Aborting." >&2; exit 1; }
command -v minikube >/dev/null 2>&1 || { echo "I require minikube for local dev but it's not installed.  checking microk8s." >&2; }
command -v microk8s.kubectl >/dev/null 2>&1 || { echo "I require microk8s.kubectl for local dev but it's not installed.  Aborting." >&2; exit 1; }
# helm

GROUPID=`az group show -g $RG -o tsv --query 'id'`
echo $GROUPID
if [ -z "$GROUPID" ]; then
echo '$RG not created'
# az group create $RG
else

  echo "Do you wish to delete this group"
  select yn in "Yes" "No"; do
    case $yn in
        Yes ) az group delete -n ${RG};break;;
        No ) jumpto clustercreated;break;;
    esac
  done


fi

## az aks get-versions -l westeurope -o json | jpterm -m expression
# az aks get-versions -l westeurope -o json --query 'orchestrators[?upgrades==null]'
LATESTKUBEVERSION=`az aks get-versions -l $LOC -o tsv --query 'orchestrators[?upgrades==null].orchestratorVersion'`
echo "Latest kube version is $LATESTKUBEVERSION - installing ${K8VERSION} ok"
echo "Do you wish to install this kluster"
select yn in "Yes" "No"; do
    case $yn in
        Yes ) break;;
        No ) exit;;
    esac
done
# if local set
## speedy local build
echo "Local"
select yn in "local" "remote"; do
    case $yn in
        local ) LOCAL=true; break;;
        remote ) break;;
    esac
done
if [ -z "$LOCAL" ]; then
  # ? test for existence first #todo
  az group create -n $RG -l $LOC;
  az aks create -n $KUBENAME -l $LOC -g $RG -k $K8VERSION --node-count $NODE_COUNT --ssh-key-value $SSH -u ${USERBASE}user;
  az aks get-credentials -n $KUBENAME -g $RG

else 
  echo "test" + "$LOCAL";
  ## minikube
#  eval $(minikube docker-env);
# minikube addons enable ingress
#  minikube start;
microk8s.kubectl enable dns dashboard ingress #registry
#snap disable microk8s

fi

clustercreated:


exit
