# Proxy Server Test Setup

This terraform config sets up:
* An AWS EC2 VM as a workstation
* An AWS EC2 VM as a proxy server
* An AWS EC2 VM which can only be accessed through the proxy server

## Components

### Workstation

The Workstation is configured to only send outbound traffic to the Proxy Server.

### Proxy Server

The Proxy Server is configured as a Proxy using [squid](http://www.squid-cache.org/)

### Server only Available through Proxy Server

This is a simple AWS EC2 instance which only accepts traffic from the Proxy Server.

## Usage

To use this config you will need:
* Terraform installed
* An AWS AMI Access Key
* An AWS AMI Secret Key

Clone this repo from GitHub

```bash
$ git clone http://github.com/nellshamrell/tf_proxy
cd tf_proxy
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

Take a look at what changes will be made to your infrastucture 