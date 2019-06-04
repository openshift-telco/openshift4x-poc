#!/bin/bash

##############################################################
# UPDATE TO MATCH YOUR ENVIRONMENT
##############################################################

# OCP_RELEASE=$(curl -s https://quay.io/api/v1/repository/openshift-release-dev/ocp-release/tag/\?limit=1\&page=1\&onlyActiveTags=true | jq -r '.tags[].name')
OCP_RELEASE=4.1.0
RHCOS_BUILD=4.1.0-x86_64
WEBROOT=/usr/share/nginx/html
TFTPROOT=/var/lib/tftpboot
POCDIR=ocp4poc

##############################################################
# DO NOT MODIFY AFTER THIS LINE
##############################################################

usage() {
    echo -e "Usage: $0 [ clean | ignition | custom | prep_ign | bootstrap | install | approve ] "
    echo -e "\t\t(extras) [ tools | images | prep_installer | prep_images ]"
}

get_images() {
    mkdir images ; cd images 
    curl -J -L -O https://mirror.openshift.com/pub/openshift-v4/dependencies/rhcos/4.1/4.1.0/rhcos-${RHCOS_BUILD}-installer-initramfs.img
    curl -J -L -O https://mirror.openshift.com/pub/openshift-v4/dependencies/rhcos/4.1/4.1.0/rhcos-${RHCOS_BUILD}-installer-kernel
    curl -J -L -O https://mirror.openshift.com/pub/openshift-v4/dependencies/rhcos/4.1/4.1.0/rhcos-${RHCOS_BUILD}-installer.iso
    curl -J -L -O https://mirror.openshift.com/pub/openshift-v4/dependencies/rhcos/4.1/4.1.0/rhcos-${RHCOS_BUILD}-metal-bios.raw.gz
    curl -J -L -O https://mirror.openshift.com/pub/openshift-v4/dependencies/rhcos/4.1/4.1.0/rhcos-${RHCOS_BUILD}-metal-uefi.raw.gz

    # Not applicable for bare-metal deployment
    ##curl -J -L -O https://mirror.openshift.com/pub/openshift-v4/dependencies/rhcos/4.1/4.1.0/rhcos-${RHCOS_BUILD}-vmware.ova

    curl -J -L -O https://mirror.openshift.com/pub/openshift-v4/clients/ocp/${OCP_RELEASE}/openshift-client-linux-${OCP_RELEASE}.tar.gz 
    curl -J -L -O https://mirror.openshift.com/pub/openshift-v4/clients/ocp/${OCP_RELEASE}/openshift-install-linux-${OCP_RELEASE}.tar.gz

    cd ..
    tree images
}

install_tools() {
    echo -e "NOTE: Tools used by $0 are not installed by this script. Manually install one of the following options:"
    echo -e "\nIf using NGINX:\n\t yum -y install tftp-server dnsmasq syslinux-tftpboot tree python36 jq oniguruma nginx"
    echo -e "\t Note: May need EPEL repo: rpm -Uvh https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm"
    echo -e "\nIf using HTTPD:\n\t yum -y install tftp-server dnsmasq syslinux-tftpboot tree python36 jq oniguruma httpd\n"
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
    echo "Update Ignition files to apply NM patch and create local user"
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
    cp ${POCDIR}/bootstrap.ign-with-patch ${POCDIR}/bootstrap.ign

    # Update Master nodes config with local user and custom network configs
    jq -s '.[0] * .[1]' ${POCDIR}/master.ign-original   utils/nm-patch.json > ${POCDIR}/master.ign-with-patch
    jq -s '.[0] * .[1]' ${POCDIR}/master.ign-with-patch utils/add-local-user.json > ${POCDIR}/master.ign-with-user
    cp ${POCDIR}/master.ign-with-user ${POCDIR}/master.ign
    
    # Update Worker nodes config with local user and custom network configs
    jq -s '.[0] * .[1]' ${POCDIR}/worker.ign-original   utils/nm-patch.json > ${POCDIR}/worker.ign-with-patch
    jq -s '.[0] * .[1]' ${POCDIR}/worker.ign-with-patch utils/add-local-user.json > ${POCDIR}/worker.ign-with-user
    cp ${POCDIR}/worker.ign-with-user ${POCDIR}/worker.ign
}

prep_installer () {
    echo "Uncompressing installer and client binaries"
    tar -xzf ./images/openshift-client-linux-${OCP_RELEASE}.tar.gz
    tar -xaf ./images/openshift-install-linux-${OCP_RELEASE}.tar.gz
}

prep_images () {
    echo "Copying RHCOS OS Images to ${WEBROOT}"
    mkdir ${WEBROOT}/metal/
    cp -f ./images/rhcos-${RHCOS_BUILD}-metal-bios.raw.gz ${WEBROOT}/metal/
    cp -f ./images/rhcos-${RHCOS_BUILD}-metal-uefi.raw.gz ${WEBROOT}/metal/
    tree ${WEBROOT}/metal/

    echo "Copying RHCOS PXE Boot Images to ${TFTPROOT}"
    mkdir ${TFTPROOT}/rhcos/
    cp ./images/rhcos-410.8.20190516.0-installer-initramfs.img ${TFTPROOT}/rhcos/rhcos-initramfs.img
    cp ./images/rhcos-410.8.20190516.0-installer-kernel ${TFTPROOT}/rhcos/rhcos-kernel
    tree ${TFTPROOT}/rhcos/
}

prep_ign () {
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

approve () {
    export KUBECONFIG=${POCDIR}/auth/kubeconfig
    ./oc get csr
    ./oc get csr -ojson | jq -r '.items[] | select(.status == {} ) | .metadata.name' | xargs ./oc adm certificate approve
    ./oc get csr 
}

# Capture First param
key="$1"

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
    prep_ign)
        prep_ign
        ;;
    prep_installer)
        prep_installer
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
    approve)
        approve
        ;;
    *)
        usage
        ;;
esac

##############################################################
# END OF FILE
##############################################################