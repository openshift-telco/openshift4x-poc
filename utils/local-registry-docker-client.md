# Configuring the Docker client
1. Configure docker client with self-signed certificate
   
   - Create the directory under certs.d depending on the FQDN that you have configured while creating the certificate

    ```
    mkdir -p /etc/docker/certs.d/<FQDN>:5000

    #example 
    mkdir -p /etc/docker/certs.d/bastion.example.com:5000

    ```

2. Copy the `domain.crt` to the new directory

    ```
    cp /etc/docker-distribution/certs/domain.crt /etc/docker/certs.d/bastion.example.com\:5000/domain.crt  

    # NOTE: replace the bastion.example.com with the FQDN of local registry
    ```

3. Trust this certificate

    ```
    cp /etc/docker-distribution/certs/domain.crt    /etc/pki/ca-trust/source/anchors/bastion.example.com.crt   

    # NOTE: must be named with the FQDN of the registry

    update-ca-trust 

    ```

4.   Add the newly created registry to the `/etc/containers/registries.conf`

  ```
  registries:
    - registry.access.redhat.com
    - bastion.example.com:5000  
  ```

5.   Restart the docker-distribution service

  ```
  systemctl restart docker-distribution 

  ```


## Troubleshooting
- If needed, to test or debug the registry configuration run
  ```
  /usr/bin/registry serve /etc/docker-distribution/registry/config.yml
  ```