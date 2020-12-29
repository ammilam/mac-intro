alertmanager:
  enabled: false
coreDns:
  enabled: false
defaultRules:
  create: false
  rules:
    alertmanager: false
    etcd: false
    general: false
    k8s: false
    kubeApiserver: false
    kubePrometheusNodeAlerting: false
    kubePrometheusNodeRecording: false
    kubeScheduler: false
    kubernetesAbsent: false
    kubernetesApps: false
    kubernetesResources: false
    kubernetesStorage: false
    kubernetesSystem: false
    node: false
    prometheus: false
    prometheusOperator: false
grafana:
  service:
    type: LoadBalancer
    loadBalancerIP: ${GRAFANAIP}
  image:
    repository: grafana/grafana
    tag: 7.2.0
  additionalDataSources:
  adminPassword: prom-operator
  enabled: true
  grafana.ini:
    auth.anonymous:
      enabled: true
    log:
      filters: ldap:debug
      level: error
  sidecar:
    dashboards:
      enabled: true
      label: grafana_dashboard
      annotations: {}
    datasources:
      enabled: true
      defaultDatasourceEnabled: true
kubeApiServer:
  enabled: true
kubeControllerManager:
  enabled: false
kubeDns:
  enabled: false
kubeEtcd:
  enabled: false
kubeProxy:
  enabled: false
kubeScheduler:
  enabled: false
kubeStateMetrics:
  enabled: false
kubelet:
  enabled: false
nodeExporter:
  enabled: false
prometheus:
  ingress:
    enabled: false
