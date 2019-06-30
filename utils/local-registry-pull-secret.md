# Create pull secret for new registry

1. Add credential information of local registry into the `pull-secret.json` file
 
```
# Example user and password
# NOTE: use the '-n' to generate a valid encrypted password
echo -n "dummy:dummy" | base64 -w0
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

2. Test the registry is operational

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

