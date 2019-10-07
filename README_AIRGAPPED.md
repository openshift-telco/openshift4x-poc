# Disconnected/Airgapped Install with OCP4.2+

Preparing the installation configuration file for Disconnected/AirGapped install:

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
- Include the certificate for your local registries at `additionalTrustBundle` in the `install-config.yaml`
    ```
    additionalTrustBundle: | 
    -----BEGIN CERTIFICATE-----
    YOUR CERTIFICATE BUNDLE HERE
    -----END CERTIFICATE-----
    ```
- Update `install-config.yaml` with the information of the local registry and specifying the original source for the content: (required for correctly interpreting the release metadata)
    ```
    imageContentSources: 
    - mirrors:
      - registry.ocp4poc.example.com:5000/<repo_name>/release
        source: quay.io/openshift-release-dev/ocp-release
    ```

## Next Steps

Follow the regular UPI installation procedure.


