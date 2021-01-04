
terraform {
  backend "gcs"{
    bucket      = "one-last-test-project-terraform-state"
    prefix      = "sandbox"
    credentials = "account.json"
  }
}

