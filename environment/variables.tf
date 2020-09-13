
variable "environment" {
  description = "The Specification of an Environment"
  type = object({
    name    = string                   # a name for the environment            
    region  = string                   # the region to provision this environment the resources in.
    domain  = string                   # the root domain (e.g. mydomain.com).
    token   = string                   # your digitalocean personal access token
    email   = string                   # support email address (also used for certificates)
    cluster = object({
      default_node_pool_size = number  # number of nodes in the default pool
      app_node_pool_size_min = number  # min autoscaling nodes
      app_node_pool_size_max = number  # max autoscaling nodes
      auto_upgrade           = bool    # whether to conduct automatic upgrades of not
      kubernetes_version     = string  # the version of kubernetes to provision 
    })
  })
  default = {
    name    = null
    region  = null
    domain  = null
    token   = null
    email   = null
    cluster = {
      default_node_pool_size = 2      
      app_node_pool_size_min = 1      
      app_node_pool_size_max = 5      
      auto_upgrade           = true   
      kubernetes_version     = "1.18.8-do.0"
    }
  }
}

