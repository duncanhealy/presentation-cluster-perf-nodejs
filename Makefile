HOST=http://localhost:8081/
LOC=westeurope
CRVER=nodejs
DEBUG=''
BROWS := $(shell command -v firefox --browser 2> /dev/null)
getcreds:
	az aks get-credentials -g present-perf-uksouth -n perfpresent-perf-uksouth
artillery:
	./node_modules/.bin/artillery quick --count 10 -n 20 ${HOST}
test-art: createtest
	./node_modules/.bin/artillery test.yaml

install-microk8s:
	snap install microk8s --classic --beta
	snap alias microk8s.kubectl mk

install-node-edge:
	sudo snap install node --edge --classic

install-node-stable:
	sudo snap install node --channel=10/stable --classic
install-client-revealmd:
	sudo npm i -g reveal-md
print-pdf:
	reveal-md Readme.md --print slides.pdf
install-client-benchrest:
	sudo npm i -g bench-rest
test-bench:
	bench-rest
test-k6: ##2587 ## dashboard
	k6 run --out influxdb=http://localhost:8086/resultsdb script.js
unix-core-dump:
# sudo gcore pid
# |/usr/share/apport/apport %p %s %c %d %P ## default core pattern
	echo "/tmp/core-%e-%s-%u-%g-%p-%t" | sudo tee /proc/sys/kernel/core_pattern
	echo "kernel.yama.ptrace_scope=0" | sudo tee -a /etc/sysctl.conf # Append config line
	sudo sysctl -p # Apply changes
	sudo npm install -g llnode
	ulimit -c unlimited
unix-tune:
	sysctl -a | grep maxfiles  # display maxfiles and maxfilesperproc  defaults 12288 and 10240
	sudo sysctl -w kern.maxfiles=25000
	sudo sysctl -w kern.maxfilesperproc=24500
	sysctl -a | grep somax # display max socket setting, default 128
	sudo sysctl -w kern.ipc.somaxconn=20000  # set
	ulimit -S -n       # display soft max open files, default 256
	ulimit -H -n       # display hard max open files, default unlimited
	ulimit -S -n 20000  # set soft max open files

k8-draft-config:
	draft config set registry ${CRVER}.azurecr.io
	draft config set container-builder local # acrbuild
	draft config set resource-group-name ${CRVER}
#	draft config set registry ${CRVER}${CONTAINERDOMAIN}
k8-docker-secret:
	# kubectl create secret -n kube-system docker-registry docker-cloud-auth \
  	# --docker-server hub.docker.com \
	# --docker-username $CR \
 	# --docker-password $DOCKERCLOUDAPIPASS \
	# --docker-email $EMAIL
k8-registry-create:
	az group create --name ${CRVER} --location=${LOC}
	az acr create --resource-group ${CRVER} --name ${CRVER} --sku Basic
	#az configure --defaults acr=$CRVER # $REGSERVER
	az acr login -n ${CRVER} -g ${CRVER}
	#ACR_LOGIN_SERVER=$(az acr show --name $CRVER --query loginServer --output tsv)
	#ACR_REGISTRY_ID=$(az acr show --name $CRVER --query id --output tsv)
	#SERVICE_PRINCIPAL_NAME=${CRVER}READER
	#SP_PASSWD=$(az ad sp create-for-rbac --name $SERVICE_PRINCIPAL_NAME --role Reader --scopes $ACR_REGISTRY_ID --query password --output tsv)

k8-install-tiller:
	kubectl create serviceaccount tiller --namespace kube-system 
	kubectl create clusterrolebinding tiller-cluster-rule --clusterrole=cluster-admin --serviceaccount=kube-system:tiller
	kubectl patch deploy --namespace kube-system tiller-deploy -p '{"spec":{"template":{"spec":{"serviceAccount":"tiller"}}}}'

test-site:
	./node_modules/.bin/artillery quick --count 50 -n 50 http://localhost:3000/echo

test: test-site
	echo "done"
bench-site-%:
	echo "testing for $*"
	./node_modules/.bin/artillery dino
	DEBUG='' ./node_modules/.bin/artillery run --quiet -o report/$*.json artillery.yaml > temp/testout.txt
	cat report/$*.json
	./node_modules/.bin/artillery report report/$*.json
	${BROWS} report/$*.json.html

linkerd-top:
	linkerd -n emojivoto top deployments
linkerd-tap:
	linkerd -n emojivoto tap deployments
linkerd-stat:
	linkerd -n emojivoto stat deployments
