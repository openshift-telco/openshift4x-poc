#!/bin/bash

key="$1"

OCP_RELEASE=4.1.0-rc.5
RHCOS_BUILD=410.8.20190516.0
WEBROOT=/usr/share/nginx/html/
POCDIR=ocp4poc

usage() {
    echo -e "Usage: $0 [ clean | ignition | custom | prep | bootstrap | install ] "
    echo -e "\t\t(extras) [ tools | images | prep_images ]"
}

get_images() {
    mkdir images ; cd images 
    curl -J -L -O https://mirror.openshift.com/pub/openshift-v4/dependencies/rhcos/4.1/latest/rhcos-${RHCOS_BUILD}-installer-initramfs.img
    curl -J -L -O https://mirror.openshift.com/pub/openshift-v4/dependencies/rhcos/4.1/latest/rhcos-${RHCOS_BUILD}-installer-kernel
    curl -J -L -O https://mirror.openshift.com/pub/openshift-v4/dependencies/rhcos/4.1/latest/rhcos-${RHCOS_BUILD}-installer.iso
    curl -J -L -O https://mirror.openshift.com/pub/openshift-v4/dependencies/rhcos/4.1/latest/rhcos-${RHCOS_BUILD}-metal-bios.raw.gz
    curl -J -L -O https://mirror.openshift.com/pub/openshift-v4/dependencies/rhcos/4.1/latest/rhcos-${RHCOS_BUILD}-metal-uefi.raw.gz
    ##curl -J -L -O https://mirror.openshift.com/pub/openshift-v4/dependencies/rhcos/4.1/latest/rhcos-${RHCOS_BUILD}-vmware.ova

    curl -J -L -O https://mirror.openshift.com/pub/openshift-v4/clients/ocp/latest/openshift-client-linux-${OCP_RELEASE}.tar.gz 
    curl -J -L -O https://mirror.openshift.com/pub/openshift-v4/clients/ocp/latest/openshift-install-linux-${OCP_RELEASE}.tar.gz

    cd ..
}

install_tools() {
#    rpm -Uvh https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
#    yum -y jq oniguruma nginx 
    # Download utility to customize Ignition file
    curl -O https://raw.githubusercontent.com/ashcrow/filetranspiler/master/filetranspile
}

clean() {
    echo "Removing installation folder and leases"
    rm -fr ${POCDIR}
#    systemctl stop dnsmasq
#    rm -f /var/lib/dnsmasq/dnsmasq.leases
#    systemctl start dnsmasq
}

ignition() {
    echo "Creating and populating installation folder"
    mkdir ${POCDIR}
    cp ./install-config.yaml ${POCDIR}
    echo "Generating ignition files"
    ./openshift-install create ignition-configs --dir=${POCDIR}
}

customizations() {
    echo "Update Ignition files to create local user"
    if [[ -f ${POCDIR}/bootstrap.ign-bkup ]]; then
        cp -f ${POCDIR}/bootstrap.ign-bkup ${POCDIR}/bootstrap.ign
        cp -f ${POCDIR}/master.ign-bkup ${POCDIR}/master.ign
        cp -f ${POCDIR}/worker.ign-bkup ${POCDIR}/worker.ign
    else
        cp ${POCDIR}/bootstrap.ign ${POCDIR}/bootstrap.ign-bkup
        cp ${POCDIR}/master.ign ${POCDIR}/master.ign-bkup
        cp ${POCDIR}/worker.ign ${POCDIR}/worker.ign-bkup
    fi

    mv ${POCDIR}/bootstrap.ign ${POCDIR}/bootstrap.ign-original
    mv ${POCDIR}/master.ign ${POCDIR}/master.ign-original
    mv ${POCDIR}/worker.ign ${POCDIR}/worker.ign-original

    # Update Bootstrap with custom network settings
    ./utils/patch-nm-bootstrap.py
    ./filetranspile -i ${POCDIR}/bootstrap.ign-with-patch -f fake-root-bootstrap -o ${POCDIR}/bootstrap.ign

    # Update Master nodes config with local user and custom network configs
    jq -s '.[0] * .[1]' ${POCDIR}/master.ign-original   utils/nm-patch.json > ${POCDIR}/master.ign-with-patch
    jq -s '.[0] * .[1]' ${POCDIR}/master.ign-with-patch utils/add-local-user.json > ${POCDIR}/master.ign-with-user
    ./filetranspile -i ${POCDIR}/master.ign-with-user -f fake-root -o ${POCDIR}/master.ign
    
    # Update Worker nodes config with local user and custom network configs
    jq -s '.[0] * .[1]' ${POCDIR}/worker.ign-original   utils/nm-patch.json > ${POCDIR}/worker.ign-with-patch
    jq -s '.[0] * .[1]' ${POCDIR}/worker.ign-with-patch utils/add-local-user.json > ${POCDIR}/worker.ign-with-user
    ./filetranspile -i ${POCDIR}/worker.ign-with-user -f fake-root -o ${POCDIR}/worker.ign
}

prep_images () {
    cp -f images/rhcos-${RHCOS_BUILD}-metal-bios.raw.gz ${WEBROOT}/metal/
    cp -f images/rhcos-${RHCOS_BUILD}-metal-uefi.raw.gz ${WEBROOT}/metal/
    tree ${WEBROOT}/metal/
}

prep () {
    echo "Installing Ignition files into web path"
    cp -f ${POCDIR}/*.ign ${WEBROOT}
    tree ${WEBROOT}
}

bootstrap () {
    echo "Assuming PXE boot process in progress"
    ./openshift-install wait-for bootstrap-complete --dir=${POCDIR} --log-level debug
    echo "Enable cluster credentials: 'export KUBECONFIG=${POCDIR}/auth/kubeconfig'"
    export KUBECONFIG=${POCDIR}/auth/kubeconfig
}

install () {
    echo "Assuming PXE boot process in progress"
    ./openshift-install wait-for install-complete --dir=${POCDIR} --log-level debug
}

case $key in
    tools)
        install_tools
        ;;
    images)
        get_images
        ;;
    clean)
        clean
        ;;
    ignition)
        ignition
        ;;
    custom|customizations)
        customizations
        ;;
    prep)
        prep
        ;;
    prep_images)
        prep_images
        ;;
    bootstrap)
        bootstrap
        ;;
    install)
        install
        ;;
    *)
        usage
        ;;
esac
