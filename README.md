# Proxy Server Test Setup

**NOTE: This is intended for testing, development, or demo processes only**

This terraform config sets up:
* An AWS EC2 VM as a workstation
* An AWS EC2 VM as a proxy server
* An AWS EC2 VM which can only be accessed through the proxy server

## Components

* Workstation
* Proxy Server
* Server only Available through Proxy Server

### Workstation

The Workstation is where you will connect to the Proxy Server

### Proxy Server

The Proxy Server is configured as a Proxy using [squid](http://www.squid-cache.org/)

### Server Behind Proxy

This is a simple AWS EC2 instance (running Apache2) which only accepts http and https traffic from the Proxy Server. (As this is meant to be a development or demo environment, it does still accept SSH traffic from anywhere with the appropriate key)

## Usage

To use this config you will need:
* Terraform installed
* An AWS AMI Access Key
* An AWS AMI Secret Key

Clone this repo from GitHub

```bash
$ git clone http://github.com/nellshamrell/tf_proxy
$ cd tf_proxy
```

Then create a file to hold the values for the variables needed by this config:

```bash
$ cp terraform_values_example.tfvars terraform_values.tfvars
```

Open up terraform_values.tfvars and fill in the appropriate values.

Now, initialize terraform with 

```bash
$ terraform init
```

Take a look at what changes will be made to your infrastucture with:

```bash
$ terraform plan
```

When you are ready, go ahead and spin up the infrastructure with:

```bash
$ terraform apply
```

This will take a bit to set up.

When config is complete, you will see some output which looks like this:

```bash
proxy_server_ip = 34.221.179.84
server_behind_proxy_ip = 35.167.0.233
workstation_ip = 34.215.150.118
```

### Testing Whether the Proxy is Working

To verify that the proxy is working, ssh into each server in a separate shell.

In the **Proxy Server**, run:

```bash
$ sudo tail -f /var/log/squid/access.log
```

This will show any traffic coming into the proxy server.

In the **Workstation Server**, run:

```bash
$ curl http://server_behind_proxy_ip
```

You will see the Apache2 default page returned.

Now take a look back at the **Proxy Server**, you should see an entry in the log showing the request coming from the Workstation Server into the Server Behind the Proxy.

If you want to make certain that the Server Behind the Proxy really is only accepting requests from the Proxy server, run the curl command from another machine that is not a part of this set up. You should see the request just hang.

Enjoy your new proxy environment!