
terraform {
  backend "gcs" {
    bucket      = "named-nomad-300702-terraform-state"
    prefix      = "sandbox"
    credentials = "account.json"
  }
}

