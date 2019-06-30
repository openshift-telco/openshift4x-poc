# Setting local container registry with self-signed CA

NOTE: RHEL `rhel-7-server-extras-rpms` repo is required for these RPMs.

1. Install registry dependencies:

```
yum install -y docker-distribution skopeo podman

Please note if you are using RHEL7 subscriptions following packages needs to be manually pre-installed in order to have podman and httpd-tools

libnet-1.1.6-7.el7.x86_64.rpm
python-IPy-0.75-6.el7.noarch.rpm
apr-util-1.5.2-6.el7.x86_64.rpm

```

2. Setup registry configuration

  - Generate the required certificate file for the docker-distribution service.
  Note: Ensure you use the registry FQDN as the CN when generating the certificates.

    ```
    mkdir /etc/docker-distribution/certs
    cd /etc/docker-distribution/certs
    openssl req -newkey rsa:4096 -nodes -sha256 -keyout domain.key -x509 -days 365 -out domain.crt
    ```

  - Generate htpasswd based authentication
    ```
    htpasswd -cB /etc/docker-distribution/registry/htpasswd dummy dummy
    ```
     
  - Backup of the existing configuration file `/etc/docker-distribution/registry/config.yml`
  
    ```
    mv /etc/docker-distribution/registry/config.yml /root/original-docker-distribution-config.xml
    ```    

  - Create new `/etc/docker-distribution/registry/config.yml` with content similar to:
    ```
    version: 0.1
    log:
      fields:
        service: registry
    storage:
        cache:
            blobdescriptor: inmemory
        filesystem:
            rootdirectory: /opt/registry
    auth:
        htpasswd:
          realm: basic-realm
          # bcrpt formatted passwords
          path: /etc/docker-distribution/registry/htpasswd
    http:
        addr: :5000
        host: https://bastion.example.com:5000
        secret: myverysecretregistry
        tls:
          certificate: /etc/docker-distribution/registry/certs/domain.crt
          key:         /etc/docker-distribution/registry/certs/domain.key

    log:
      accesslog:
        disabled: false
      level: info
      formatter: text
      fields:
        service: registry
        environment: staging
    ```
     

- Notes:
  - Replace the "host" line appropriately with the FQDN
  - Replace the "secret" with a random value
  - Replace the rootdirectory as required
  - Indentation should be properly maintained
  - The password format of /etc/docker-distribution/registry_passwd must be bcrypt


3. Start the `docker-distribution.service` and add port 5000 to the internal and public zone

    ```
    systemctl start docker-distribution

    firewall-cmd --add-port=5000/tcp --zone=internal --permanent
    firewall-cmd --add-port=5000/tcp --zone=public --permanent
    firewall-cmd --reload
    ```

4. Verify whether the docker registry is up using the curl command

    ```
    curl -u dummy:dummy -k https://bastion.example.com:5000/v2/_catalog

    # NOTE: It should list an empty repository
    ```

## Next steps:

1. Create [pull secret](local-registry-pull-secret.md) for Container Registry and run test

2. (optional) Configure [Container Registry](local-registry-dedicated-disk.md) with dedicated storage

3. (optional) Configure [docker client](local-registry-docker-client.md) to use local registry

NOTE 1: This is an RPM deployment. If prefer a Containerized deployment refer to [local-registry.md](local-registry.md)


