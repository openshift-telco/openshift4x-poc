# Setting local container registry with self-signed CA

NOTE: RHEL `rhel-7-server-extras-rpms` repo is required for these RPMs.

1. Insall registry dependencies:

```
yum install -y docker-distribution skopeo podman

Please note if you are using RHEL7 subscriptions following packages needs to be manually pre-installed in order to have podman and httpd-tools

libnet-1.1.6-7.el7.x86_64.rpm
python-IPy-0.75-6.el7.noarch.rpm
apr-util-1.5.2-6.el7.x86_64.rpm

```

2. Setup registry configuration


  -  Generate the required certificate file for the docker-distribution service.
  Note: Ensure you use the registry FQDN as the CN when generating the certificates.

    ```
   
      mkdir /etc/docker-distribution/certs
   cd /etc/docker-distribution/certs
   openssl req -newkey rsa:4096 -nodes -sha256 -keyout domain.key -x509 -days 365 -out domain.crt
   
   
    ```

  - Generate htpasswd based authentication
    ```
     htpasswd -cB /etc/docker-distribution/registry_passwd dummy dummy
     
    ```

  -  Take a backup of the existing configuration file and replace it with the following contents and Add the below contents to the file /etc/docker-distribution/registry/config.yml

    ```
     mv /etc/docker-distribution/registry/config.yml /root/original-docker-distribution-config.xml
     
     
     
     version: 0.1
log:
  fields:
    service: registry
    environment: development
storage:
    cache:
        layerinfo: inmemory
    filesystem:
        rootdirectory: /opt/docker-registry
    delete:
        enabled: true
http:
    addr: :5000
    tls:
      certificate: /etc/docker-distribution/certs/domain.crt
      key: /etc/docker-distribution/certs/domain.key
    host: https://registry-internal:5000
    secret: testsecret
    relativeurls: false
auth:
    htpasswd:
      realm: basic-realm
      path: /etc/docker-distribution/registry_passwd
     


Note
Replace the "host" line appropriately with the FQDN
Replace the "secret" with a random value
Replace the rootdirectory as required
Indentation should be properly maintained
The password format of /etc/docker-distribution/registry_passwd must be bcrypt


    ```

3.   Start the docker-distribution service and add port 5000 to the internal and public zone

```
systemctl start docker-distribution

firewall-cmd --add-port=5000/tcp --zone=internal --permanent
firewall-cmd --add-port=5000/tcp --zone=public --permanent
firewall-cmd --reload
```

4.   Verify whether the docker registry is up using the curl command

```
curl -u dummy:dummy -k https://registry-internal:5000/v2/_catalog


Note
Replace the "registry-internal" with FWDN of your local registry
It should list an empty repository

```

5.   Docker client configuration

```
 mkdir /etc/docker/certs.d/<FQDN>:5000

   example 
   mkdir /etc/docker/certs.d/registry-internal:5000

```

6.   Copy the domain.crt

```
 cp /etc/docker-distribution/certs/domain.crt /etc/docker/certs.d/registry-internal\:5000/domain.crt  
 
 [example. replace the registry-internal with the FQDN of local registry]

```

7.   Trust this certificate

```
cp /etc/docker-distribution/certs/domain.crt    /etc/pki/ca-trust/source/anchors/registry-internal.crt   

[replace registry-internal appropriately with the FQDN of loca registry!!!!]

update-ca-trust 

```

8.   Add the newly created registry to the /etc/containers/registries.conf

```
registries:
  - registry.access.redhat.com
  - registry-internal:5000  
  
  
Note:
Create the directory under certs.d depending on the FQDN that you have configured while creating the certificate
Replace the registry-internal appropriately

```

9.   Restart the docker-distribution service

```
systemctl restart docker-distribution 

```


**TROUBLESHOOTING:** If needed, to test or debug the registry configuration run
```
/usr/bin/registry serve /etc/docker-distribution/registry/config.yml
```


1. Add credential information of local registry into the `pull-secret.json` file
 
```
# Example user and password
# NOTE: use the '-n' to generate a valid encrypted password
echo -n "dummy:dummy" | base64
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
