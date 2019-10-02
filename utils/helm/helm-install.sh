#!/bin/bash
##############################################################
# UPDATE TO MATCH YOUR ENVIRONMENT
##############################################################

export TILLER_NAMESPACE=tiller
TILLER_TEST_NAMESPACE="${TILLER_NAMESPACE}-smoketest"

export HELM_HOST=":44134"
HELM_VERSION=v2.14.1    # https://github.com/helm/helm/releases
AIRGAP_REG='bastion.shift.zone:5000'
AUTH_JSON_FILE='pull-secret-2.json'

# If using registry that requires user/password authentication
# USE_AUTH_REGISTRY=""     #set to "" to disable
# REG_USER=dummy
# REG_PASSWORD=dummy 

##############################################################
# DO NOT MODIFY AFTER THIS LINE
##############################################################
usage() {
    echo -e "Usage: $0 [ build_tiller | install_tiller | init_helm | smoketest ]"
    echo -e "\t\t(extras) [ get_helm  | clean_test | uninstall_tiller | uninstall_helm | mirror ]"
}

get_helm() {
    if [ ! -f helm-${HELM_VERSION}-linux-amd64.tar.gz ]; then
        echo "Downloading Helm ${HELM_VERSION} binaries"
        curl -O https://get.helm.sh/helm-${HELM_VERSION}-linux-amd64.tar.gz
    else 
        echo "Found Helm package 'helm-${HELM_VERSION}-linux-amd64.tar.gz' in current dirrectory."
    fi
    echo "Opening Helm package into current directory"
    tar -xzf helm-${HELM_VERSION}-linux-amd64.tar.gz
}

build_tiller() {
    get_helm 
    if [ -z "${KUBECONFIG}"]; then
        echo "ERROR: Set KUBECONFIG environment variable. (i.e. 'export KUBECONFIG=`pwd`/ocp4poc/auth/kubeconfig' )"
    else
        echo "Building container for Tiller ${HELM_VERSION}"
        cp ./utils/Dockerfile.tiller ./Dockerfile.tiller 
        # note: using "|" instead of "/" to correctly handle directories
        sed -i 's|PATH_TO_KUBECONFIG|'"${KUBECONFIG}"'|g' ./Dockerfile.tiller

        podman build -f ./Dockerfile.tiller -t tiller:${HELM_VERSION}
        rm ./Dockerfile.tiller
    fi
}

mirror() {
    echo "Mirroring Tiller ${HELM_VERSION} (NOTE: Upstream image does not support customizations)"
    skopeo copy --authfile=${AUTH_JSON_FILE} docker://gcr.io/kubernetes-helm/tiller:${HELM_VERSION} docker://${AIRGAP_REG}/kubernetes-helm/tiller:${HELM_VERSION}
}

install_tiller() {
    echo "Installing and starting poc-tiller.service"
    cp -f ./utils/poc-tiller.service /etc/systemd/system/poc-tiller.service
    sed -i 's/tiller:v2.14.1/tiller:'"${HELM_VERSION}"'/g' /etc/systemd/system/poc-tiller.service
    systemctl daemon-reload
    systemctl restart poc-tiller
    sleep 3 # give time to start
    podman logs poc-tiller
    podman ps

    echo "Creating Tiller Namespace: ${TILLER_NAMESPACE}"
    oc new-project ${TILLER_NAMESPACE}
    oc process -f ./utils/tiller-rbac.yaml -p TILLER_NAMESPACE="${TILLER_NAMESPACE}" -p HELM_VERSION=${HELM_VERSION} | oc create -f -
}

uninstall_tiller() {
    echo "Unisntalling poc-tiller.service"
    systemctl stop poc-tiller
    rm -f /etc/systemd/system/poc-tiller.service
    systemctl daemon-reload

    echo "Removing Tiller Namespace: ${TILLER_NAMESPACE}"
    oc delete project ${TILLER_NAMESPACE}
}

# install_tiller_legacy_mode() {
#     echo "Downloading OCP Tiller Template"
#     curl -O https://raw.githubusercontent.com/openshift/origin/master/examples/helm/tiller-template.yaml

#     if [ ${AIRGAP_REG} ]; then
#         echo "Modify OCP Tiller Template to use local registry ${AIRGAP_REG}"
#         sed -i 's/gcr.io/'"${AIRGAP_REG}"'/g' tiller-template.yaml
#     fi

#     echo "Creating Tiller Namespace: ${TILLER_NAMESPACE}"
#     oc new-project ${TILLER_NAMESPACE}

#     # if [ ${USE_AUTH_REGISTRY} ]; then
#     #     echo -e "\nCreating new pull secret"
#     #     oc create secret docker-registry external-registry \
#     #     --docker-server=${AIRGAP_REG} \
#     #     --docker-username=${REG_USER} --docker-password=${REG_PASSWORD} \
#     #     --docker-email=noemail@example.com

#     #     echo "Link pull secret to ServiceAccounts"
#     #     oc create serviceaccount tiller

#     #     oc secrets link --for=pull sa/tiller    external-registry
#     #     oc secrets link --for=pull sa/default   external-registry
#     #     oc secrets link --for=pull sa/deployer  external-registry
#     #     oc secrets link --for=pull sa/builder   external-registry

#     #     echo -e "Done\n"
#     # fi


#     echo "Deploying Tiller from local registry"
#     oc process -f ./tiller-template.yaml -p TILLER_NAMESPACE="${TILLER_NAMESPACE}" -p HELM_VERSION=${HELM_VERSION} | oc create -f -

#     # DEBUG
#     oc delete deployment tiller 

#     echo -e "\nMonitor deployment"
#     # oc rollout status deployment tiller
#     oc get pod,deployment,rs -o wide
# }

# uninstall_legacy() {
#     echo "Removing Tiller Deployment from ${TILLER_NAMESPACE}"
#     oc delete deployment tiller -n ${TILLER_NAMESPACE}
#     rm -fr $HOME/.helm 
# }

init_helm() {

    echo "Initializing HELM environment"
    tar -xzf helm-${HELM_VERSION}-linux-amd64.tar.gz
    ./linux-amd64/helm init --client-only --history-max 200

    echo -e "\n#########################################################\n"
    echo "NOTE: Remember to 'export TILLER_NAMESPACE=${TILLER_NAMESPACE}'"
    echo "NOTE: Helm client binary at: `pwd`/linux-amd64/helm"
    echo -e "\n#########################################################"

}

uninstall_helm() {
    echo "Removing HELM_HOME and binaries"
    rm -f ./linux-amd64/helm ./linux-amd64/tiller
    rm -fr $HOME/.helm 
}

test_helm() {
    echo "NOTE: Remember to 'export TILLER_NAMESPACE=${TILLER_NAMESPACE}' to be able to use HELM"
    echo "NOTE: Helm client at: `pwd`/linux-amd64/helm"

    ./linux-amd64/helm version 

    echo "Creating namespace for testing: ${TILLER_TEST_NAMESPACE}"

    ./oc new-project ${TILLER_TEST_NAMESPACE}
    ./oc policy add-role-to-user edit "system:serviceaccount:${TILLER_NAMESPACE}:tiller" -n ${TILLER_TEST_NAMESPACE}

    echo "Deploying a demo app (NOTE: Expect release <name> not found)"
    ./linux-amd64/helm  install https://raw.githubusercontent.com/jim-minter/nodejs-ex/helm/helm/nodejs-0.1.tgz -n nodejs-ex

    ./oc get all -o wide 
}

clean_test() {
    echo "Removing Tiller namespace: ${TILLER_TEST_NAMESPACE}"
    oc delete project ${TILLER_TEST_NAMESPACE}
    rm -fr $HOME/.helm 
}

# Capture First param
key="$1"

case $key in
    get_helm)
        get_helm
        ;;
    build_tiller|build)
        build_tiller
        ;;
    mirror)
        mirror
        ;;
    install_tiller)
        install_tiller
        ;;
    uninstall_tiller)
        uninstall_tiller
        ;;
    init_helm)
        init_helm
        ;;
    uninstall_helm)
        uninstall_helm
        ;;
    clean_test)
        clean_test
        ;;
    smoketest)
        test_helm
        ;;
    *)
        usage
        ;;
esac
##############################################################
# END OF FILE
##############################################################