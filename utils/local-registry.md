# Setting local container registry with self-signed CA

NOTE: RHEL `rhel-7-server-extras-rpms` repo is required for these RPMs.

1. Insall registry dependencies:

```
yum install -y docker-distribution skopeo podman
```

2. Setup registry configuration


  - Generate Self-signed certs or obtain cets from your organizations CA

    ```
    mkdir -p certs

    openssl req \
    -newkey rsa:4096 -nodes -sha256 -keyout certs/domain.key \
    -x509 -days 365 -out certs/domain.crt

    cp certs/domain.crt /etc/pki/ca-trust/source/anchors/bastion.example.com.crt
    update-ca-trust

    cp -r certs /etc/docker-distribution/registry/
    ```

  - Edit registry configuration
    ```
    --  etc/docker-distribution/registry/config.yml

    version: 0.1
    log:
        #level: debug
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
          # bcrpt formated passwords
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

  - Generate `htpasswd` file (Note: must use `bcrypt` encrypted passwords)

    ```
    htpasswd -Bbc htpasswd dummy dummy

    -- cat /etc/docker-distribution/registry/htpasswd
    dummy:$2y$11$dWVvIw.udulD610HO1H3Z.kfzhGBzaHV9Pc703bWxNpMXVQMOg42e
    ```

3.   Start and enable Docker Registry

```
systemctl enable docker-distribution
systemctl restart docker-distribution
systemctl status docker-distribution

firewall-cmd --add-port=5000/tcp --zone=internal --permanent
firewall-cmd --add-port=5000/tcp --zone=public --permanent
firewall-cmd --reload
```

**Note:** You can test the registry configuration running `/usr/bin/registry serve /etc/docker-distribution/registry/config.yml`


4. Add credential information of local registry into the `pull-secret.json` file
 
```
# Example user and password
echo -n 'dummy:dummy' | base64
ZHVtbXk6ZHVtbXk=

# Edit pull-secret.json
vi pull-secret.json

  ...
  "auths": {
    "registry.example.com:5000": {
       "auth": "ZHVtbXk6ZHVtbXk=",
       "email": "noemail@example.com"
    },
    ...
```

5. Test the registry is operational

```
#####################################
# Test login to the registry
#####################################

$ podman login bastion.example.com:5000
Username: dummy
Password:
Login Succeeded!

#####################################
# Test pushing a container image
#####################################

# Get an image
$ podman pull registry.access.redhat.com/ubi8/ubi-minimal
Trying to pull registry.access.redhat.com/ubi8/ubi-minimal...Getting image source signatures
Copying blob sha256:ed6b7e8623ef8ca893d44d01fc88999684cc0209bc48cd71c6b5a696ed1d60f5
 32.50 MB / ? [-------------------------------------------------=----------] 3s
Copying blob sha256:5b86d995ed7f224d4e810d76a4a7a87702338f37abbd7df916f99e1549e1f68d
 1.41 KB / ? [-----------------------------------------=-------------------] 0s
Copying config sha256:3bfa511b67f82778ace94aaedb7da39d353f33eabc9ae24abad47805b6cef9c3
 4.28 KB / 4.28 KB [========================================================] 0s
Writing manifest to image destination
Storing signatures
3bfa511b67f82778ace94aaedb7da39d353f33eabc9ae24abad47805b6cef9c3

# Tag image with local registry
$ podman tag registry.access.redhat.com/ubi8/ubi-minimal:latest bastion.example.com:5000/ubi8/ubi-minimal:latest

# Push image to local registry
$ podman push bastion.example.com:5000/ubi8/ubi-minimal:latest
Getting image source signatures
Copying blob sha256:62373019ab2eec9b927fd44c87720cd05f675888d11903581e60edeec3d985c2
 87.44 MB / 87.44 MB [=====================================================] 10s
Copying blob sha256:44d5dd834e48e686666301fbc4478baecb1e68ec5eb289b80c096f78da30977d
 20.00 KB / 20.00 KB [======================================================] 0s
Copying config sha256:3bfa511b67f82778ace94aaedb7da39d353f33eabc9ae24abad47805b6cef9c3
 4.28 KB / 4.28 KB [========================================================] 0s
Writing manifest to image destination
Storing signatures
```

# (optional) Using Dedicate Disk for registry

1. Create partition in disk
   
```
fdisk /dev/sdb
 type (t): 8e
```

2. Create physical volume

```
pvcreate /dev/sdb1
```

3. Create volume group  

```
vgcreate vg_registry /dev/sdb1

vgs 
```

4. Create logical volume

```
lvcreate -l 100%FREE -n lv_registry vg_registry

lvdisplay vg_registry/lv_registry
```

5. Format logical volume
```
mkfs.ext4 /dev/vg_registry/lv_registry
```

6. Identify devices UUID
```
blkid /dev/vg_registry/lv_registry

[root@bastion ~]# blkid /dev/vg_registry/lv_registry
/dev/vg_registry/lv_registry: UUID="60c3366b-1c3d-41da-bf62-7e00d88d3f0b" TYPE="ext4"

```

7. /etc/fstab

```
UUID=<uuid-here>    /opt/registry   ext4    defaults    0 0
```
