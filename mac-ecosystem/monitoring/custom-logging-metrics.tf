
# Custom logging metric of flux fatal log lines
resource "google_logging_metric" "gke_flux_fatal_metric" {
  name    = "gke-flux-fatal-count"
  project = var.gke_project_id
  filter  = "resource.type=\"k8s_container\" AND resource.labels.container_name=\"flux\" AND textPayload=~\"fatal\""
  metric_descriptor {
    metric_kind  = "DELTA"
    value_type   = "INT64"
    display_name = "gke-flux-fatal-count"
    labels {
      key         = "error"
      value_type  = "STRING"
      description = "type of error"
    }
    labels {
      key         = "component"
      value_type  = "STRING"
      description = "action being taken"
    }
  }
  label_extractors = {
    component = "REGEXP_EXTRACT(textPayload, \"component=(.*?)=\")"
    error     = "REGEXP_EXTRACT(textPayload, \"err=\\\\\\\"([^:]+):\")"
  }
}