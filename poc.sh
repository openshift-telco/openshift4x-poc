#!/bin/bash

##############################################################
# UPDATE TO MATCH YOUR ENVIRONMENT
##############################################################

OCP_RELEASE=4.1.0
RHCOS_BUILD=4.1.0
WEBROOT=/usr/share/nginx/html
TFTPROOT=/var/lib/tftpboot
POCDIR=ocp4poc

#############################################################
# EXPERIMENTAL
##############################################################

#LAST_3_OCP_RELEASES=$(curl -s https://quay.io/api/v1/repository/${UPSTREAM_REPO}/ocp-release/tag/\?limit=3\&page=1\&onlyActiveTags=true | jq -r '.tags[].name')

AIRGAP_REG='registry.ocp4poc.example.com:5000'
AIRGAP_REPO='ocp4/openshift4'
UPSTREAM_REPO='openshift-release-dev'   ## or 'openshift'
AIRGAP_SECRET_JSON='pull-secret-2.json'
#export OPENSHIFT_INSTALL_RELEASE_IMAGE_OVERRIDE=${AIRGAP_REG}/${AIRGAP_REPO}:${OCP_RELEASE}

##############################################################
# DO NOT MODIFY AFTER THIS LINE
##############################################################

usage() {
    echo -e "Usage: $0 [ clean | ignition | custom | prep_ign | bootstrap | install | approve ] "
    echo -e "\t\t(extras) [ get_images | prep_installer | prep_images ]"
}

get_images() {
    mkdir images ; cd images 
    curl -J -L -O https://mirror.openshift.com/pub/openshift-v4/dependencies/rhcos/4.1/${RHCOS_BUILD}/rhcos-${RHCOS_BUILD}-x86_64-installer-initramfs.img
    curl -J -L -O https://mirror.openshift.com/pub/openshift-v4/dependencies/rhcos/4.1/${RHCOS_BUILD}/rhcos-${RHCOS_BUILD}-x86_64-installer-kernel
    curl -J -L -O https://mirror.openshift.com/pub/openshift-v4/dependencies/rhcos/4.1/${RHCOS_BUILD}/rhcos-${RHCOS_BUILD}-x86_64-installer.iso
    curl -J -L -O https://mirror.openshift.com/pub/openshift-v4/dependencies/rhcos/4.1/${RHCOS_BUILD}/rhcos-${RHCOS_BUILD}-x86_64-metal-bios.raw.gz
    curl -J -L -O https://mirror.openshift.com/pub/openshift-v4/dependencies/rhcos/4.1/${RHCOS_BUILD}/rhcos-${RHCOS_BUILD}-x86_64-metal-uefi.raw.gz

    # Not applicable for bare-metal deployment
    ##curl -J -L -O https://mirror.openshift.com/pub/openshift-v4/dependencies/rhcos/4.1/${RHCOS_BUILD}/rhcos-${RHCOS_BUILD}-x86_64-vmware.ova

    curl -J -L -O https://mirror.openshift.com/pub/openshift-v4/clients/ocp/${OCP_RELEASE}/openshift-client-linux-${OCP_RELEASE}.tar.gz 
    curl -J -L -O https://mirror.openshift.com/pub/openshift-v4/clients/ocp/${OCP_RELEASE}/openshift-install-linux-${OCP_RELEASE}.tar.gz

    cd ..
    tree images
}

install_tools() {
    echo -e "NOTE: Tools used by $0 are not installed by this script. Manually install one of the following options:"
    echo -e "\nWith NGINX LB:\n\t yum -y install tftp-server dnsmasq syslinux-tftpboot tree python36 jq oniguruma nginx"

    echo -e "\t Note: May need EPEL repo: rpm -Uvh https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm"
    echo -e "\nWith HAProxy LB:\n\t yum -y install tftp-server dnsmasq syslinux-tftpboot tree python36 jq oniguruma haproxy\n"

    echo "Downloading `filestranspiler`"
    curl -o ./utils/filetranspile https://raw.githubusercontent.com/ashcrow/filetranspiler/master/filetranspile
    chmod +x ./utils/filetranspile
}

mirror () {
    echo "WARNING: This is an unsupported procedure"
    oc adm -a ${AIRGAP_SECRET_JSON} release new --from-release=quay.io/${UPSTREAM_REPO}/ocp-release:${OCP_RELEASE} \
    --mirror=${AIRGAP_REG}/${AIRGAP_REPO} --to-image=${AIRGAP_REG}/${AIRGAP_REPO}:${OCP_RELEASE}
}

clean() {
    echo "Removing installation folder"
    rm -fr ${POCDIR}
}

ignition() {
    echo "Creating and populating installation folder"
    mkdir ${POCDIR}
    cp ./install-config.yaml ${POCDIR}
    echo "Generating ignition files"
    ./openshift-install create ignition-configs --dir=${POCDIR}
}

customizations () {
    echo "Create backup or restore previous Ignition files"

    if [[ -f ${POCDIR}/bootstrap.ign-bkup ]]; then
        # Restore backup
        cp -f ${POCDIR}/bootstrap.ign-bkup ${POCDIR}/bootstrap.ign
        cp -f ${POCDIR}/master.ign-bkup ${POCDIR}/master.ign
        cp -f ${POCDIR}/worker.ign-bkup ${POCDIR}/worker.ign
    else
        # Create backup
        cp ${POCDIR}/bootstrap.ign ${POCDIR}/bootstrap.ign-bkup
        cp ${POCDIR}/master.ign ${POCDIR}/master.ign-bkup
        cp ${POCDIR}/worker.ign ${POCDIR}/worker.ign-bkup
    fi

    echo "Generate manifests to apply customizations"
    ./openshift-install create manifests --dir=${POCDIR}
  
    cp ./utils/10-worker-nm-workaround.yaml ./${POCDIR}/openshift/
    cp ./utils/10-master-nm-workaround.yaml ./${POCDIR}/openshift/

    if [[ -z "${OPENSHIFT_INSTALL_RELEASE_IMAGE_OVERRIDE}"]]; then 
        cp ./utils/98-worker-registries.yaml ./${POCDIR}/openshift/
        cp ./utils/98-master-registries.yaml ./${POCDIR}/openshift/
    fi

    echo "Generating new Ignition Configs"
    ./openshift-install create ignition-configs --dir=${POCDIR}

     echo "Update Bootstrap Ignition to apply NM patch"
    ./utils/patch-systemd-units.py -i ./${POCDIR}/bootstrap.ign-bkup -p ./utils/nm-patch.json > ./${POCDIR}/bootstrap.ign-patch 
    ./utils/filetranspile -i ./${POCDIR}/bootstrap.ign-patch -f ./utils/patch-node > ./${POCDIR}/bootstrap.ign
}

prep_installer () {
    echo "Uncompressing installer and client binaries"
    tar -xzf ./images/openshift-client-linux-${OCP_RELEASE}.tar.gz
    tar -xaf ./images/openshift-install-linux-${OCP_RELEASE}.tar.gz
}

prep_images () {
    echo "Copying RHCOS OS Images to ${WEBROOT}"
    mkdir ${WEBROOT}/metal/
    cp -f ./images/rhcos-${RHCOS_BUILD}-x86_64-metal-bios.raw.gz ${WEBROOT}/metal/
    cp -f ./images/rhcos-${RHCOS_BUILD}-x86_64-metal-uefi.raw.gz ${WEBROOT}/metal/
    tree ${WEBROOT}/metal/

    echo "Copying RHCOS PXE Boot Images to ${TFTPROOT}"
    mkdir ${TFTPROOT}/rhcos/
    cp ./images/rhcos-${RHCOS_BUILD}-x86_64-installer-initramfs.img ${TFTPROOT}/rhcos/rhcos-initramfs.img
    cp ./images/rhcos-${RHCOS_BUILD}-x86_64-installer-kernel ${TFTPROOT}/rhcos/rhcos-kernel
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
    sleep 3
    ./oc get csr 
}

# Capture First param
key="$1"

case $key in
    tools)
        install_tools
        ;;
    get_images)
        get_images
        ;;
    mirror)
        mirror
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