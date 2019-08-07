# HELM Setup

## Client Setup

If you local PC or bastion host or whatever the server you are running doesn't have the helm client installed, install it by running

```sh client-config.sh```


## Server Config

When the helm client is running on the machine, run the following,
Make sure kubectl is connected to the correct cluster here as well.

```sh server-config.sh```