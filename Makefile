WEBROOT=/var/www/html/
POCDIR=ocp4poc

all:
	@echo "Usage: make [ clean | ignition | custom | pre | bootstrap | install ] "


tools:
	rpm -Uvh https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
	yum -y jq oniguruma

clean:
	@echo "Removing installation folder"
	rm -fr ${POCDIR}

cleandnsmasq:
	systemctl stop  dnsmasq 
	rm -fr /var/lib/dnsmasq/dnsmaq.leases
	systemctl start dnsmasq

ignition:
	@echo "Creating and populating installation folder"
	mkdir ${POCDIR}
	cp ./install-config.yaml ${POCDIR}
	@echo "Generating ignition files"
	./openshift-install create ignition-configs --dir=${POCDIR}

custom:
	@echo "Update Ignition files to create local user"
	#mv ${POCDIR}/master.ign ${POCDIR}/master.ign-original
	#jq -s '.[0] * .[1]' ${POCDIR}/master.ign-original utils/add-local-user.json > ${POCDIR}/master.ign
	#mv ${POCDIR}/worker.ign ${POCDIR}/worker.ign-original
	#jq -s '.[0] * .[1]' ${POCDIR}/worker.ign-original utils/add-local-user.json > ${POCDIR}/worker.ign

pre:
	@echo "Installing Ignition files into web path"
	cp -f ${POCDIR}/*.ign ${WEBROOT}

bootstrap:
	@echo "Assuming PXE boot process in progress"
	./openshift-install wait-for bootstrap-complete --dir=${POCDIR} --log-level debug
	@echo "Enable cluster credentials: 'export KUBECONFIG=${POCDIR}/auth/kubeconfig'"
	export KUBECONFIG=${POCDIR}/auth/kubeconfig

install:
	@echo "Assuming PXE boot process in progress"
	./openshift-install wait-for install-complete --dir=${POCDIR} --log-level debug

