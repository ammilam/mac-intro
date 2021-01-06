resource "google_monitoring_alert_policy" "flux_fatal_alert_policy" {
  enabled      = "true"
  project      = var.monitoring_project_id
  display_name = "flux-fatal-alert-policy"
  documentation {
    content   = "Flux has been deployed intentionally broken, \nin order to fix this simply correct git.secretName under mac-ecosystem/templates/values-files/flux-values.yaml.tpl to 'flux-ssh'. \nAfter making the correction re-run ./setup.sh again to apply the fix."
    mime_type = "text/markdown"
  }
  combiner = "OR"
  conditions {
    condition_threshold {
      aggregations {
        alignment_period     = "60s"
        cross_series_reducer = "REDUCE_MAX"
        per_series_aligner   = "ALIGN_MEAN"
        group_by_fields      = ["resource.label.namespace_name"]
      }

      comparison      = "COMPARISON_GT"
      duration        = "0s"
      filter          = "metric.type=\"logging.googleapis.com/user/${google_logging_metric.gke_flux_fatal_metric.name}\" resource.type=\"k8s_container\""
      threshold_value = "0"

      trigger {
        count   = "1"
        percent = "0"
      }
    }

    display_name = "Flux Fatal Alert"
  }

  notification_channels = [google_monitoring_notification_channel.emails.name]
  depends_on = [
    google_logging_metric.gke_flux_fatal_metric,
    time_sleep.wait_for_logging_metric,
  ]
}

resource "time_sleep" "wait_for_logging_metric" {
  create_duration  = "30s"
  destroy_duration = "10s"
  depends_on       = [google_logging_metric.gke_flux_fatal_metric]
}
resource "google_monitoring_notification_channel" "emails" {
  display_name = var.username
  type         = "email"
  project      = var.monitoring_project_id
  labels = {
    email_address = var.email_address
  }

}