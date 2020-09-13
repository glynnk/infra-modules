# variables.tf

variable "root" {
  description = "The specification for base provisions before provisioning any specific environment"
  type = object({
    name    = string   # this will be the name used for the registry and the bucket
    domain  = string   # the root domain for all environments (e.g. mydomain.com)
  })
  default = {
    name    = "root"
    domain  = null
  }
}

