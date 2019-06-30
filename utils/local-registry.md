# Containerized local Container Registry Server

The following instructions use `/opt/registry` for the locations of the volumes of the container registry.

1. Create folders for registry 
    ```
    mkdir -p /opt/registry/{auth,certs,data}
    ```

2. Generate self-signed certificate 
    ```
    cd /opt/registry/certs
    openssl req -newkey rsa:4096 -nodes -sha256 -keyout domain.key -x509 -days 365 -out domain.crt
    ```

3. Generate username and password (must use bcrpt formated passwords) 
    ```
    htpasswd -cB /opt/registry/auth/htpasswd dummy dummy
    ```
4. Install and run the `poc-registry.service`:
    ```
    cp ./utils/poc-registry.service /etc/systemd/system/poc-registry.service

    systemctl daemon-reload

    systemctl start poc-registry
    systemctl status poc-registry
    systemctl enable poc-registry
    ```

5. (if needed) Add port 5000 to the internal and public zone

    ```
    firewall-cmd --add-port=5000/tcp --zone=internal --permanent
    firewall-cmd --add-port=5000/tcp --zone=public   --permanent
    firewall-cmd --reload
    ```

6. Verify whether the docker registry is up using the curl command

    ```
    curl -u dummy:dummy -k https://bastion.example.com:5000/v2/_catalog

    # NOTE: It should list an empty repository
    ```

## Next steps:

1. Create [pull secret](local-registry-pull-secret.md) for Container Registry and run test

2. (optional) Configure [Container Registry](local-registry-dedicated-disk.md) with dedicated storage

3. (optional) Configure [docker client](local-registry-docker-client.md) to use local registry

NOTE 1: This is a containerized deployment. If prefer an RPM installation refer to [local-registry-rpm.md](local-registry-rpm.md)