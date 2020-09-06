# Some coomon infrastructure is required to be hared between enviroenments
# This consists of:
#   - a root domain (e.g. mydomain.com)
#   - a bucket to store terraform state in
#   - an image registry for making images available to environments

variable "root" {
  description = "The specification for base provisions before provisioning any specific environment"
  type = object({
    name           = string   # this will be the name used for the registry and the bucket
    bucket_region  = string   # the region that the state bucket is to be provisioned in.
    domain         = string   # the root domain for all enviornments (e.g. mydomain.com)
  })
  default = {
    name           = "root"
    bucket_region  = "ams3"
    domain         = null
  }
}

