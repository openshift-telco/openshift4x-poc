#!/bin/bash

##############################################################
# UPDATE TO MATCH YOUR ENVIRONMENT
##############################################################

OCP_RELEASE=4.2.0-0.nightly-2019-10-01-210901
RHCOS_BUILD=4.2.0-0.nightly-2019-08-28-152644
RHCOS_IMAGE_BASE=42.80.20190828.2

# ancillary services
WEBROOT=/opt/nginx/html
TFTPROOT=/var/lib/tftpboot
POCDIR=ocp4poc

#############################################################
# EXPERIMENTAL
##############################################################

#LAST_3_OCP_RELEASES=$(curl -s https://quay.io/api/v1/repository/${UPSTREAM_REPO}/ocp-release/tag/\?limit=3\&page=1\&onlyActiveTags=true | jq -r '.tags[].name')

AIRGAP_REG='registry.ocp4poc.example.com:5000'
AIRGAP_REPO='ocp4/openshift4'

UPSTREAM_REPO='openshift-release-dev'   ## or 'openshift'
RELEASE_NAME='ocp-release'
AIRGAP_SECRET_JSON='pull-secret-2.json'

# THIS SHOULD NOT BE NEEDED FOR OCP 4.2+
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
    curl -J -L -O https://mirror.openshift.com/pub/openshift-v4/dependencies/rhcos/pre-release/${RHCOS_BUILD}/rhcos-${RHCOS_IMAGE_BASE}-installer-initramfs.img
    curl -J -L -O https://mirror.openshift.com/pub/openshift-v4/dependencies/rhcos/pre-release/${RHCOS_BUILD}/rhcos-${RHCOS_IMAGE_BASE}-installer-kernel
    curl -J -L -O https://mirror.openshift.com/pub/openshift-v4/dependencies/rhcos/pre-release/${RHCOS_BUILD}/rhcos-${RHCOS_IMAGE_BASE}-metal-bios.raw.gz

    #curl -J -L -O https://mirror.openshift.com/pub/openshift-v4/dependencies/rhcos/pre-release/${RHCOS_BUILD}/rhcos-${RHCOS_IMAGE_BASE}-metal-uefi.raw.gz
    #curl -J -L -O https://mirror.openshift.com/pub/openshift-v4/dependencies/rhcos/pre-release/${RHCOS_BUILD}/rhcos-${RHCOS_IMAGE_BASE}-installer.iso
    #curl -J -L -O https://mirror.openshift.com/pub/openshift-v4/dependencies/rhcos/pre-release/${RHCOS_BUILD}/rhcos-${RHCOS_IMAGE_BASE}-openstack.qcow2
    #curl -J -L -O https://mirror.openshift.com/pub/openshift-v4/dependencies/rhcos/pre-release/${RHCOS_BUILD}/rhcos-${RHCOS_IMAGE_BASE}-qemu.qcow2
    #curl -J -L -O https://mirror.openshift.com/pub/openshift-v4/dependencies/rhcos/pre-release/${RHCOS_BUILD}/rhcos-${RHCOS_IMAGE_BASE}-vmware.ova

    curl -J -L -O https://mirror.openshift.com/pub/openshift-v4/clients/ocp-dev-preview/${OCP_RELEASE}/openshift-client-linux-${OCP_RELEASE}.tar.gz 
    curl -J -L -O https://mirror.openshift.com/pub/openshift-v4/clients/ocp-dev-preview/${OCP_RELEASE}/openshift-install-linux-${OCP_RELEASE}.tar.gz

    cd ..
    tree images
}

install_tools() {
    echo -e "NOTE: Tools used by $0 are not installed by this script. Manually install one of the following options:"
    echo -e "\nWith NGINX LB:\n\t yum -y install tftp-server dnsmasq syslinux-tftpboot tree python36 jq oniguruma"

    echo -e "\t Note: May need EPEL repo: rpm -Uvh https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm"
    echo -e "\nWith HAProxy LB:\n\t yum -y install tftp-server dnsmasq syslinux-tftpboot tree python36 jq oniguruma\n"

    echo "Downloading `filestranspiler`"
    curl -o ./utils/filetranspile https://raw.githubusercontent.com/ashcrow/filetranspiler/master/filetranspile
    chmod +x ./utils/filetranspile
}

mirror () {
    echo "Mirroring from Quay into Local Registry"
    # 4.2
    # Note: This option keep old metadata references to quay.io
   ./oc adm release mirror -a ${AIRGAP_SECRET_JSON} --insecure=true --from=quay.io/${UPSTREAM_REPO}/${RELEASE_NAME}:${OCP_RELEASE} \
   --to-release-image=${AIRGAP_REG}/${AIRGAP_REPO}:${OCP_RELEASE} --to=${AIRGAP_REG}/${AIRGAP_REPO}

# Unsupported procedure for OCP 4.1
#     echo "WARNING: This is an unsupported procedure"
#    ./oc adm release new -a ${AIRGAP_SECRET_JSON} --insecure --from-release=quay.io/${UPSTREAM_REPO}/ocp-release:${OCP_RELEASE} \
#    --mirror=${AIRGAP_REG}/${AIRGAP_REPO} --to-image=${AIRGAP_REG}/${AIRGAP_REPO}:${OCP_RELEASE}

    #echo "Retrieve `openshift-install` from local container repository"
    # NOTE: This `openshift-install` binary does not requires the env variable
    ./oc adm --insecure=true -a ${AIRGAP_SECRET_JSON} release extract --command='openshift-install' ${AIRGAP_REG}/${AIRGAP_REPO}:${OCP_RELEASE}
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
    if [[ ! -f ./utils/filetranspile ]]; then   
        echo "Missing customization tool. Downloading `filestranspiler`"
        curl -o ./utils/filetranspile https://raw.githubusercontent.com/ashcrow/filetranspiler/master/filetranspile
        chmod +x ./utils/filetranspile
    fi

    echo "Generate manifests to apply customizations"
    ./openshift-install create manifests --dir=${POCDIR}
  
    # workaround be applied to the initial ignition files
    cp -r ./customizations/*.yaml ./${POCDIR}/openshift/

    echo "Generating new Ignition Configs"
    ./openshift-install create ignition-configs --dir=${POCDIR}

    # echo "Create backup of Ignition files to apply additional customizations"
    # mv ${POCDIR}/master.ign    ${POCDIR}/master.ign-bkup
    # mv ${POCDIR}/worker.ign    ${POCDIR}/worker.ign-bkup

    # echo "Updating Master and Workers Ignition files with NetworkManager patch"
    # jq -s '.[0] * .[1]' ${POCDIR}/master.ign-bkup ./utils/nm-patch.json > ${POCDIR}/master.ign
    # jq -s '.[0] * .[1]' ${POCDIR}/worker.ign-bkup ./utils/nm-patch.json > ${POCDIR}/worker.ign

    # echo "Updating Bootstrap Ignition file to apply NetworkManager patch"
    # mv ${POCDIR}/bootstrap.ign ${POCDIR}/bootstrap.ign-bkup
    #./utils/patch-systemd-units.py -i ./${POCDIR}/bootstrap.ign-bkup -p ./utils/nm-patch.json > ./${POCDIR}/bootstrap.ign

    # Check if there are additional configuration customizations for bootstrap.ign
    if [[ -d ./customizations/bootstrap ]]; then
        echo "Found bootstrap customization directory. Encoding additional configuration files into bootstrap.ign"
        mv ${POCDIR}/bootstrap.ign ${POCDIR}/bootstrap.ign-bkup
        ./utils/filetranspile -i ./${POCDIR}/bootstrap.ign-bkup -f ./customizations/bootstrap  > ./${POCDIR}/bootstrap.ign
    fi

    # Check if there are additional configuration customizations for master.ign
    if [[ -d ./customizations/master ]]; then
        echo "Found master customization directory. Encoding additional configuration files into master.ign"
        mv ${POCDIR}/master.ign ${POCDIR}/master.ign-bkup
        ./utils/filetranspile -i ./${POCDIR}/master.ign-bkup -f ./customizations/master  > ./${POCDIR}/master.ign
    fi

    # Check if there are additional configuration customizations for worker.ign
    if [[ -d ./customizations/worker ]]; then
        echo "Found worker customization directory. Encoding additional configuration files into worker.ign"
        mv ${POCDIR}/worker.ign ${POCDIR}/worker.ign-bkup
        ./utils/filetranspile -i ./${POCDIR}/worker.ign-bkup -f ./customizations/worker  > ./${POCDIR}/worker.ign
    fi
  
    echo "Customizations done."
}

prep_installer () {
    echo "Uncompressing installer and client binaries"
    tar -xzf ./images/openshift-client-linux-${OCP_RELEASE}.tar.gz
    tar -xaf ./images/openshift-install-linux-${OCP_RELEASE}.tar.gz
}

prep_images () {
    echo "Copying RHCOS OS Images to ${WEBROOT}"
    mkdir ${WEBROOT}/metal/
    cp -f ./images/rhcos-${RHCOS_IMAGE_BASE}-metal-bios.raw.gz ${WEBROOT}/metal/
    #cp -f ./images/rhcos-${RHCOS_IMAGE_BASE}-metal-uefi.raw.gz ${WEBROOT}/metal/
    tree ${WEBROOT}/metal/

    echo "Copying RHCOS PXE Boot Images to ${TFTPROOT}"
    mkdir ${TFTPROOT}/rhcos/
    cp ./images/rhcos-${RHCOS_IMAGE_BASE}-installer-initramfs.img ${TFTPROOT}/rhcos/rhcos-initramfs.img
    cp ./images/rhcos-${RHCOS_IMAGE_BASE}-installer-kernel ${TFTPROOT}/rhcos/rhcos-kernel
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
    get_images|images)
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
