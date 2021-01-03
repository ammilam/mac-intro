grafana:
  ingress:
    enabled: true
    annotations:
      kubernetes.io/ingress.class: "nginx"
      nginx.ingress.kubernetes.io/affinity: cookie
      nginx.ingress.kubernetes.io/affinity-mode: persistent
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
prometheus:
  ingress:
    enabled: true
    annotations:
      kubernetes.io/ingress.class: "nginx"
      nginx.ingress.kubernetes.io/affinity: cookie
      nginx.ingress.kubernetes.io/affinity-mode: persistent
  service:
    type: NodePort
    nodePort: 30090
  # prometheusSpec:
  #   containers:
  #   - name: stackdriver-sidecar
  #     image: gcr.io/stackdriver-prometheus/stackdriver-prometheus-sidecar:0.8.0
  #     imagePullPolicy: Always
  #     args:
  #       - --stackdriver.project-id=${PROJECT_ID}
  #       - --prometheus.wal-directory=/prometheus/wal
  #     ports:
  #       - name: stackdriver
  #         containerPort: 9091
  #     volumeMounts:
  #       - name: prometheus-prometheus-operator-prometheus-db
  #         mountPath: /prometheus