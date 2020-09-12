# state.tf
# Remote state
terraform {
  backend "s3" {
    endpoint                    = join(".", slice(split(".", var.root.tfstate), 1, length(slice(split(".", var.root.tfstate)))))
    region                      = "eu-west-1"           # not used since it's a DigitalOcean spaces bucket
    key                         = format("root-%s.tfstate", var.root.name)
    bucket                      = split(".", var.root.tfstate)[0]

    skip_credentials_validation = true
    skip_metadata_api_check     = true
  }
}
