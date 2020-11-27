

resource "random_id" "suffix" {
  byte_length = 2
}

resource "google_container_cluster" "primary" {
  name               = "example-cluster-${random_id.suffix.hex}"
  location           = "us-central1"
  project            = var.project
  initial_node_count = 3

  master_auth {
    username = ""
    password = ""


  }

  node_config {


    labels = {
      foo = "bar"
    }

    tags = ["foo", "bar"]
  }

}