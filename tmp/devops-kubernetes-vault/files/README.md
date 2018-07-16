# vault-init

In order to build vault-init inside our current CI/CD pipeline,
we have adopted the _prior to multi-stage_ builds as we locked to a version
of docker due to running on Kubernetes.

To build within our ci, please do the following:
```sh
> ./builder.sh
```
This script has abstracted most of the steps needed to perform something simlar
to multi stage builds.

Once we have gotten to a stage of multi-stage builds within our CI environment,
we can simply run the following:

```sh
> docker build --no-cache --pull -t vault-init:latest -f vault-init.Dockerfile
```
