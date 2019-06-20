# THIS IS AN UNSUPPORTED PROCEDURE IN OCP 4.1.0

# THIS IS AN UNSUPPORTED PROCEDURE IN OCP 4.1.0

# THIS IS AN UNSUPPORTED PROCEDURE IN OCP 4.1.0

- Clone ***this*** repo to the Bastion Node


- Edit `install-config.yaml` with the pull secrets of your local registry:

    ```
    <snip>

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

  - Replace `<BASE64_REGISTRIES_CONF_FILE_HERE>` by the base64 (as a single string) output of .`/utils/registries.conf` 
    ```
    cat ./utils/registries.conf | base64 -w 0
    ```

  - Replace `<BASE64_REGISTRY_CA_HERE>` with the base64 (as a single string) output of your self-signed cert of the registry
    ```
    cat /etc/pki/ca-trust/source/anchors/registry.ocp4poc.example.com | base64 -w 0
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


## Setup PXE Boot Configurations

1. Download RHCOS images.

  - Running `./poc.sh images` download all the images to `./images` on your current directory. It should be similar to this list (versions may be different):
  
    ```
    images/
    ├── openshift-client-linux-4.1.0.tar.gz
    ├── openshift-install-linux-4.1.0.tar.gz
    ├── rhcos-4.1.0-x86_64-installer-initramfs.img
    ├── rhcos-4.1.0-x86_64-installer.iso
    ├── rhcos-4.1.0-x86_64-installer-kernel
    ├── rhcos-4.1.0-x86_64-metal-bios.raw.gz
    └── rhcos-4.1.0-x86_64-metal-uefi.raw.gz
    ```

2. Open the `openshift-client-linux-4.1.0.tar.gz` and the `openshift-install-linux-4.1.0.tar.gz` into your current directory. This will provide the `openshift-installer`, `oc` and `kubectl` binaries.
   
3. Copy RHCOS PXE images and RHCOS images into the corresponding folders
   
```
./poc.sh prep_images
```

5. Uncompress installer and client binaries into current directory

```
./poc.sh prep_installer
```

## Proceed with standard UPI installation ***using*** the `./poc.sh` script

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


# THIS IS AN UNSUPPORTED PROCEDURE IN OCP 4.1.0

# THIS IS AN UNSUPPORTED PROCEDURE IN OCP 4.1.0

# THIS IS AN UNSUPPORTED PROCEDURE IN OCP 4.1.0
