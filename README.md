# infra-modules
A Terraform specification for a Kubernetes-Based Infrastructure Specification.

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

#### main/main.tf
This module creates the domain and container registry.
You need to own the domain![Get a free one](https://www.freenom.com/en/index.html?lang=en) at minimum.
```
# main/main.tf

module "main" {
  source = "github.com/glynnk/infra-modules?ref=1.0.4//root"
  root   = {
    name    = "main"                                 # a name to give this instance of the module
    tfstate = "myspace.ams3.digitaloceanspaces.com"  # the url for the S3 storage space in which state will be maintained
    domain  = "mydomain.com"                         # a domain that you own for which A-records will be set up for each k8s environment
  }
}

```
#### dev/main.tf
This module created a Virtual Private Cloud, provisioned into which will be a
kubernetes cluster, into which will be installed:
  1. An [nginx ingress](https://github.com/kubernetes/ingress-nginx) controller (which will create a Load Balancer)
  2. [Prometheus Operator](https://github.com/prometheus-operator/prometheus-operator) for metrics
  3. [Grafana](https://grafana.com) for metrics presentation
```
# dev/main.tf

module "dev" {
  source = "github.com/glynnk/infra-modules?ref=v1.0.0//environment"
  environment = {
    name    = "dev"                                  # a name to give this k8s environment
    region  = "ams3"                                 # the region in which to create the VPC
    domain  = "mydomain.com"                         # the domain for which to add an A record for this environment.
    tfstate = "myspace.ams3.digitaloceanspaces.com"  # the url for the S3 storage space in which state will be maintained
    cluster = {
      default_node_pool_size = 2                     # the number of nodes in the default pool
      app_node_pool_size_min = 1                     # minimum number of autoscaling nodes in the secondary pool
      app_node_pool_size_max = 5                     # maximum number of autoscaling nodes in the secondary pool
      auto_upgrade           = true                  # auto-upgrade kubernetes when a new version is available?
      kubernetes_version     = "1."                  # version of kubernetes to provision (the example here gets the latest)
    }
  }
}

```

## Provisioning
Export the following environment variables with their corresponding values:
  - DIGITALOCEAN\_ACCESS\_TOKEN ([your personal access token](https://cloud.digitalocean.com/account/api/tokens))
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

