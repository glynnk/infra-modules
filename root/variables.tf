# variables.tf

variable "root" {
  description = "The specification for base provisions before provisioning any specific environment"
  type = object({
    name           = string   # this will be the name used for the registry and the bucket
    tfstate        = string   # the location of the S3 storage space in which state will be maintained
    domain         = string   # the root domain for all environments (e.g. mydomain.com)
  })
  default = {
    name     = "root"
    tfstate  = null
    domain   = null
  }
}

