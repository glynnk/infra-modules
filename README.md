# infra-modules
Need a quick development k8s cluster that's not going to break the bank?

This is Terraform specification for a Kubernetes based Infrastructure Specification.

The target hosting service is DigitalOcean.

## Prerequisites
  1. An account with [DigitalOcean](https://www.digitalocean.com). Create, and take note of, [your personal access token](https://cloud.digitalocean.com/account/api/tokens).
  2. An [S3 space created](https://cloud.digitalocean.com/spaces) on the account (for saving terraform state), taking
     note of the SPACES\_ACCESS\_KEY\_ID and SPACES\_SECRET\_ACCESS\_KEY for it.
  3. [terraform](https://releases.hashicorp.com/terraform/) version >1.22 installed.

## Project Setup
Create a git repo and add a `.gitignore` file with the following lines:
```
.terraform/
*.tfstate
```

There are 2 modules that cover infrastructures with different uses. The first is call **root.**
It is used to create some basic things like a container registry for your images and to
set up a domain that will be used to create records for any subsequent **environments** you
wish to create. We also need to ensure that terraform is storing and retrivinf state from
a remote location, in this case, an S3 space that you've already created on digitalocean.

The second module is the **environment**. It provisions a VPV with a kubernetes cluster and
some basic cluster installations that make everything work with routing, DNS records, load
balancing etc. It also installs a metrics suite for monitoring things deployed on kubernetes
and a frontend to create visualisations/dashboards with the data. After provisioning, you can
find the UIs for these at:
  - `http://prometheus.<environment.name>.<environment.domain>`
  - `ttp://grafana.<environment.name>.<environment.domain>`

The reason why **environment** is a separate module is so that you can create and destroy
environments according as you need them, while holding onto some basic infrastructure like
the container registry and your domain between these create and destroy processes - saving
you lots of money while not loosing the ability to recreate everything from CI.

Each of the following subsection details a file to create in your repo.

TL;DR -> [see here for an example repo setup](https://github.com/glynnk/infra)

#### main/remote-state.tf
Set up remote state for the main infrastructure
```
# remote-state.tf
terraform {
  backend "s3" {
    endpoint = "ams3.digitaloceanspaces.com"   # this is a region-specific digitalocean endpoint
    region   = "eu-west-1"                     # not used since it's a DigitalOcean spaces bucket
    bucket   = "myspace"                       # the name of the S3 space/bucket
    key      = "main.tfstate"                  # the name of the state file to save state in

    skip_credentials_validation = true
    skip_metadata_api_check     = true
  }
}
```

#### main/main.tf
This module creates the domain and container registry.
You need to own the domain! [Get a free one](https://www.freenom.com/en/index.html?lang=en) at minimum.
```
# main/main.tf

module "main" {
  source = "github.com/glynnk/infra-modules//root?ref=1.1.0"
  root   = {
    name    = "main"                # a name to give this instance of the module
    domain  = "mydomain.com"        # a domain that you own for which A-records will be set up for each k8s environment
  }
}
```


#### dev/remote-state.tf
Set up remote state for the dev infrastructure.
```
# remote-state.tf
terraform {
  backend "s3" {
    endpoint = "ams3.digitaloceanspaces.com"   # this is a region-specific digitalocean endpoint
    region   = "eu-west-1"                     # not used since it's a DigitalOcean spaces bucket
    bucket   = "myspace"                       # the name of the S3 space/bucket
    key      = "dev.tfstate"                   # the name of the state file to save state in

    skip_credentials_validation = true
    skip_metadata_api_check     = true
  }
}
```

#### dev/main.tf
This module created a Virtual Private Cloud, provisioned into which will be a
kubernetes cluster, into which will be installed:
  1. An [nginx ingress](https://github.com/kubernetes/ingress-nginx) controller (which will create a Load Balancer for incoming traffic)
  2. [ExternalDNS](https://github.com/kubernetes-sigs/external-dns), which will aitomatically manage your DNS records as you create, update and delete Ingresses and Services on the cluster.
  2. [Prometheus Operator](https://github.com/prometheus-operator/prometheus-operator) for metrics
  3. [Grafana](https://grafana.com) for metrics presentation
```
# dev/main.tf

module "dev" {
  source = "github.com/glynnk/infra-modules//environment?ref=1.1.0"
  environment = {
    name    = "dev"                   # a name to give this k8s environment
    region  = "ams3"                  # the region in which to create the VPC
    domain  = "mydomain.com"          # the domain for which to add an A record for this environment.
    token   = var.do_access_token     # your digitalocean personal access token
    cluster = {
      default_node_pool_size = 2      # the number of nodes in the default pool
      app_node_pool_size_min = 1      # minimum number of autoscaling nodes in the secondary pool
      app_node_pool_size_max = 5      # maximum number of autoscaling nodes in the secondary pool
      auto_upgrade           = true            # auto-upgrade kubernetes when a new version is available?
      kubernetes_version     = "1.18.8-do.0"   # version of kubernetes to provision (see digitalocean.com for a list of supported version numbers)
    }
  }
}

```

## Provisioning
Export the following environment variables with their corresponding values:
  - DIGITALOCEAN\_ACCESS\_TOKEN ([your personal access token](https://cloud.digitalocean.com/account/api/tokens))
  - TF\_VAR\_do\_access\_token  ([your personal access token](https://cloud.digitalocean.com/account/api/tokens)) - duplication needed for configuring external-dns
  - SPACES\_ACCESS\_KEY\_ID     ([of the S3 space created above](https://cloud.digitalocean.com/spaces))
  - SPACES\_SECRET\_ACCESS\_KEY ([of the S3 space created above](https://cloud.digitalocean.com/spaces))

With the `main/` directory as the current directory, run the following sequece of commands:
```
  $ terraform init \
     -backend-config="access_key=$SPACES_ACCESS_KEY_ID" \
     -backend-config="secret_key=$SPACES_SECRET_ACCESS_KEY"
  $ terraform plan         # see what would happen on your digital ocean account if you run 'terraform apply'
  $ terraform apply        # apply the changes to your digitalocean account
```

Repeat the process for the 'dev/' directory. To add another environment, say 'prod', create a directory
beside the others and call it 'prod'. Copy 'dev/main.tf' in there and change everywhere it says 'dev' to
'prod'. Repeat the set of commands above from the 'prod' directory.

## Destroy
The 'main' infrastructure holds your registry images, so you may want to think twice about destroying it.

If you are just after cloning your project or pulling changes from it, you must run the 'terraform init'
command above again. To destroy any created infrastructure, cd to the respective directory and issue the
follwing command:
```
  $ terraform destroy
```

