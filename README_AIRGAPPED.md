# THIS IS AN UNSUPPORTED PROCEDURE IN OCP 4.1.0

# THIS IS AN UNSUPPORTED PROCEDURE IN OCP 4.1.0

# THIS IS AN UNSUPPORTED PROCEDURE IN OCP 4.1.0

# THIS IS AN UNSUPPORTED PROCEDURE IN OCP 4.1.0

# THIS IS AN UNSUPPORTED PROCEDURE IN OCP 4.1.0

1. Clone this repo to the Bastion Node


- Edit `install-config.yaml` with the pull secrets of your local registry:

```
apiVersion: v1
baseDomain: example.com 
compute:
- hyperthreading: Enabled   
  name: worker
  replicas: 0 
controlPlane:
  hyperthreading: Enabled   
  name: master 
  replicas: 3 
metadata:
  name: ocp4poc 
networking:
  clusterNetworks:
  - cidr: 10.128.0.0/14 
    hostPrefix: 23 
  networkType: OpenShiftSDN
  serviceNetwork: 
  - 172.30.0.0/16
platform:
  none: {}
pullSecret: '{"auths": {"registry.ocp4poc.example.com:5000": {
      "auth": "ZHVtbXk6ZHVtbXk=",
      "email": "noemail@example.com"
    }}}' 
sshKey: 'ssh-rsa ...'
```
- Edit `./utils/registries.conf` to include the local regiestries with self-signed certs under the `[registries.insecure]` section.


- Copy teamplate MachineConfigs for local registry configuration
    ```
    cp  ./utils/98-master-registries-UPDATETHIS.yaml  ./utils/98-master-registries.yaml
    cp  ./utils/98-worker-registries-UPDATETHIS.yaml  ./utils/98-worker-registries.yaml
    ```
- Edit the storage section of both `98-...` files

  - Replace `<BASE64_REGISTRIES_CONF_FILE_HERE>` by the base64 output of .`/utils/registries.conf`
    ```
    cat ./utils/registries.conf | base64
    ```

  - Replace `<BASE64_REGISTRY_CA_HERE>` with the base64 output of your self-signed cert of the registry
    ```
    cat /etc/pki/ca-trust/source/anchors/registry.ocp4poc.example.com | base64
    ```
  - Update `path` section for the certificate name to match the FQDN of the local registry
    ```
    "path": "/etc/pki/ca-trust/source/anchors/registry.ocp4poc.example.com.crt"
    ```
- Create special folder (fake root) to inject the files into the `bootstrap.ign`

    ```
    mkdir -p ./utils/patch-node/etc/containers
    mkdir -p ./utils/patch-node/etc/pki/ca-trust/source/anchors

    cp ./utils/registries.conf ./utils/patch-node/etc/containers
    cp /etc/docker-distribution/registry/certs/domain.crt ./utils/patch-node/etc/pki/ca-trust/source/anchors/registry.ocp4poc.example.com.crt
    ```

    The end result should look something like this:

    ```
    tree ./utils/patch-node/
    ./utils/patch-node/
    └── etc
        ├── containers
        │   └── registries.conf
        └── pki
            └── ca-trust
                └── source
                    └── anchors
                        └── registry.ocp4poc.example.com.crt
    ```

- Proceed with standard UPI installation ***using*** the `./poc.sh` script

  1. Execute `poc.sh` script:
      ```
      ./poc.sh clean

      ./poc.sh ignition

      ./poc.sh custom

      ./poc.sh prep_ign
      ```
  2. Power up the Bootstrap Node and PXE install the RHCOS
  3. Power up the Master Nodes and PXE install the RHCOS
      ```
      # Monitor bootstrap progress:
      ./poc.sh bootstrap
      ```
  4. Once bootstrap complete, shutdown Bootstrap Node
  5. Power up the Worker Nodes and PXE install 
      ```
      # Monitor OCP install
      ./poc.sh install
      ```
  6. Monitor CSR requests from the Worker Nodes and accept the certificates

      NOTE: There are two CSR's per Node that need to be accepted.
      ```
      $ export KUBECONFIG=./ocp4poc/auth/kubeconfig

      $ ./oc get csr

      $ ./oc adm certificate approve <crt-name>
      ```