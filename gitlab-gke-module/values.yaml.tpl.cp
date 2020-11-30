# Default values for gitlab/gitlab chart

## NOTICE
# Due to the scope and complexity of this chart, all possible values are
# not documented in this file. Extensive documentation for these values
# and more can be found at https://gitlab.com/gitlab-org/charts/gitlab/

## Advanced Configuration
# Documentation for advanced configuration can be found under doc/advanced
# - external PostgreSQL
# - external Gitaly
# - external Redis
# - external NGINX
# - PersistentVolume configuration
# - external Object Storage providers

## The global properties are used to configure multiple charts at once.
## Extended documenation at doc/charts/globals.md
global:
  ## GitLab operator is Alpha. Not for production use.
  operator:
    enabled: false
    rollout:
      # Enables automatic pause for deployment rollout. This must be set to `true` to fix
      # Helm's issue with 3-way merge. See:
      #   https://gitlab.com/gitlab-org/charts/gitlab/issues/1262
      #   https://github.com/helm/helm/issues/3805
      autoPause: true

  ## Supplemental Pod labels. Will not be used for selectors.
  pod:
    labels: {}

  ## doc/installation/deployment.md#deploy-the-community-edition
  edition: ee

  ## doc/charts/globals.md#gitlab-version
  # gitlabVersion: master

  ## doc/charts/globals.md#application-resource
  application:
    create: false
    links: []
    allowClusterRoles: true
  ## doc/charts/globals.md#configure-host-settings
  hosts:
    domain: ${DOMAIN}
    https: true
    gitlab: {}
    externalIP: ${INGRESS_IP}
    ssh: ~

  ## doc/charts/globals.md#configure-ingress-settings
  ingress:
    configureCertmanager: true
    annotations: {}
    enabled: true
    tls: {}
    #   enabled: true
    #   secretName:

  gitlab:
    ## Enterprise license for this GitLab installation
    ## Secret created according to doc/installation/secrets.md#initial-enterprise-license
    ## If allowing shared-secrets generation, this is OPTIONAL.
    license: {}
      # secret: RELEASE-gitlab-license
      # key: license

  ## Initial root password for this GitLab installation
  ## Secret created according to doc/installation/secrets.md#initial-root-password
  ## If allowing shared-secrets generation, this is OPTIONAL.
  initialRootPassword: {}
    # secret: RELEASE-gitlab-initial-root-password
    # key: password

  ## doc/charts/globals.md#configure-postgresql-settings
  psql:
    password:
      secret: gitlab-pg
      key: password
    host: ${DB_PRIVATE_IP}
    port: 5432
    username: gitlab
    database: gitlabhq_production

  redis:
    password:
      enabled: false
    host: ${REDIS_PRIVATE_IP}

  ## doc/charts/globals.md#configure-gitaly-settings
  gitaly:
    enabled: true
    authToken: {}
      # secret:
      # key:
    # serviceName:
    internal:
      names: ['default']
    external: []
    service:
      name: gitaly
      type: ClusterIP
      externalPort: 8075
      internalPort: 8075
      tls:
        externalPort: 8076
        internalPort: 8076
    tls:
      enabled: false
      # secretName:

  praefect:
    enabled: false
    authToken: {}
    autoMigrate: true
    gitalyReplicas: 3
    dbSecret: {}
    psql:
      sslMode: 'disable'

  ## doc/charts/globals.md#configure-minio-settings
  minio:
    enabled: true
    credentials: {}
      # secret:

  ## doc/charts/globals.md#configure-grafana-integration
  grafana:
    enabled: false

  ## doc/charts/globals.md#configure-appconfig-settings
  ## Rails based portions of this chart share many settings
  ## doc/charts/globals.md#configure-appconfig-settings
  ## Rails based portions of this chart share many settings
  appConfig:
    ## doc/charts/globals.md#general-application-settings
    enableUsagePing: false

    ## doc/charts/globals.md#lfs-artifacts-uploads-packages
    backups:
      bucket: ${PROJECT_ID}-gitlab-backups
    lfs:
      bucket: ${PROJECT_ID}-git-lfs
      connection:
        secret: gitlab-rails-storage
        key: connection
    artifacts:
      bucket: ${PROJECT_ID}-gitlab-artifacts
      connection:
        secret: gitlab-rails-storage
        key: connection
    uploads:
      bucket: ${PROJECT_ID}-gitlab-uploads
      connection:
        secret: gitlab-rails-storage
        key: connection
    packages:
      bucket: ${PROJECT_ID}-gitlab-packages
      connection:
        secret: gitlab-rails-storage
        key: connection

    ## doc/charts/globals.md#pseudonymizer-settings
    pseudonymizer:
      bucket: ${PROJECT_ID}-gitlab-pseudo
      connection:
        secret: gitlab-rails-storage
        key: connection

  ## doc/charts/geo.md
  geo:
    enabled: false
    # Valid values: primary, secondary
    role: primary
    ## Geo Secondary only
    # nodeName allows multiple instances behind a load balancer.
    nodeName: # defaults to `gitlab.gitlab.host`
    # PostgreSQL connection details only needed for `secondary`
    psql:
      password: {}
        # secret:
        # key:
      # host: postgresql.hostedsomewhere.else
      # port: 123
      # username: gitlab_replicator
      # database: gitlabhq_geo_production
      # ssl:
        # secret:
        # clientKey:
        # clientCertificate:
        # serverCA:

  ## doc/charts/gitlab/kas/index.md
  kas:
    enabled: false

  ## doc/charts/globals.md#configure-gitlab-shell-settings
  shell:
    authToken: {}
      # secret:
      # key:
    hostKeys: {}
      # secret:

  ## Rails application secrets
  ## Secret created according to doc/installation/secrets.md#gitlab-rails-secret
  ## If allowing shared-secrets generation, this is OPTIONAL.
  railsSecrets: {}
    # secret:

  ## Rails generic setting, applicable to all Rails-based containers
  rails:
    bootsnap: # Enable / disable Shopify/Bootsnap cache
      enabled: true

  ## doc/charts/globals.md#configure-registry-settings
  registry:
    bucket: registry
    certificate: {}
      # secret:
    httpSecret: {}
      # secret:
      # key:
    # https://docs.docker.com/registry/notifications/#configuration
    notifications: {}
      # endpoints:
      #   - name: FooListener
      #     url: https://foolistener.com/event
      #     timeout: 500ms
      #     threshold: 10
      #     backoff: 1s
      #     headers:
      #       FooBar: ['1', '2']
      #       Authorization:
      #         secret: gitlab-registry-authorization-header
      #       SpecificPassword:
      #         secret: gitlab-registry-specific-password
      #         key: password
      # events: {}

  pages:
    enabled: false
    accessControl: false
    path:
    host:
    port:
    https: false
    externalHttp: false
    externalHttps: false
    artifactsServer: false
    objectStore:
      enabled: false
      bucket: gitlab-pages
      # proxy_download: true
      connection: {}
        # secret:
        # key:
    apiSecret: {}
      # secret:
      # key:

  ## GitLab Runner
  ## Secret created according to doc/installation/secrets.md#gitlab-runner-secret
  ## If allowing shared-secrets generation, this is OPTIONAL.
  runner:
    registrationToken: {}
      # secret:

  ## doc/installation/deployment.md#outgoing-email
  ## Outgoing email server settings
  smtp:
    enabled: false
    address: smtp.mailgun.org
    port: 2525
    user_name: ""
    ## doc/installation/secrets.md#smtp-password
    password:
      secret: ""
      key: password
    # domain:
    authentication: "plain"
    starttls_auto: false
    openssl_verify_mode: "peer"

  ## doc/installation/deployment.md#outgoing-email
  ## Email persona used in email sent by GitLab
  email:
    from: ''
    display_name: GitLab
    reply_to: ''
    subject_suffix: ''
    smime:
      enabled: false
      secretName: ""
      keyName: "tls.key"
      certName: "tls.crt"

  ## Timezone for containers.
  time_zone: UTC

  ## Global Service Annotations and Labels
  service:
    labels: {}
    annotations: {}

  ## Global Deployment Annotations
  deployment:
    annotations: {}

  antiAffinity: soft

  ## doc/installation/secrets.md#gitlab-workhorse-secret
  workhorse: {}
    # secret:
    # key:

  ## doc/charts/globals.md#configure-webservice
  webservice:
    workerTimeout: 60

  ## doc/charts/globals.md#custom-certificate-authorities
  # configuration of certificates container & custom CA injection
  certificates:
    image:
      repository: registry.gitlab.com/gitlab-org/build/cng/alpine-certificates
      tag: 20191127-r2
    customCAs: []
    # - secret: custom-CA
    # - secret: more-custom-CAs

  ## kubectl image used by hooks to carry out specific jobs
  kubectl:
    image:
      repository: registry.gitlab.com/gitlab-org/build/cng/kubectl
      tag: 1.13.12
      pullSecrets: []
    securityContext:
      # in most base images, this is `nobody:nogroup`
      runAsUser: 65534
      fsGroup: 65534
  busybox:
    image:
      repository: busybox
      tag: latest

  ## docs/charts/globals.md#service-accounts
  serviceAccount:
    enabled: false
    create: true
    annotations: {}
    ## Name to be used for serviceAccount, otherwise defaults to chart fullname
    # name:



## Settings to for the Let's Encrypt ACME Issuer
certmanager-issuer:
  email: ${CERT_MANAGER_EMAIL}

## Installation & configuration of jetstack/cert-manager
## See requirements.yaml for current version
certmanager:
  createCustomResource: true
  nameOverride: cert-manager
  # Install cert-manager chart. Set to false if you already have cert-manager
  # installed or if you are not using cert-manager.
  install: true
  # Other cert-manager configurations from upstream
  # See https://github.com/jetstack/cert-manager/blob/master/deploy/charts/cert-manager/README.md#configuration
  rbac:
    create: false
  webhook:
    enabled: false

## doc/charts/nginx/index.md
## doc/architecture/decisions.md#nginx-ingress
## Installation & configuration of charts/nginx
nginx-ingress:
  enabled: true
  tcpExternalConfig: "true"
  controller:
    config:
      hsts-include-subdomains: "false"
      server-name-hash-bucket-size: "256"
      enable-vts-status: "true"
      use-http2: "true"
      ssl-ciphers: "ECDHE-RSA-AES256-GCM-SHA384:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-SHA384:ECDHE-RSA-AES128-SHA256:ECDHE-RSA-AES256-SHA:ECDHE-RSA-AES128-SHA:AES256-GCM-SHA384:AES128-GCM-SHA256:AES256-SHA256:AES128-SHA256:AES256-SHA:AES128-SHA:!aNULL:!eNULL:!EXPORT:!DES:!MD5:!PSK:!RC4"
      ssl-protocols: "TLSv1.3 TLSv1.2"
      server-tokens: "false"
    extraArgs:
      force-namespace-isolation: ""
    service:
      externalTrafficPolicy: "Local"
    resources:
      requests:
        cpu: 100m
        memory: 100Mi
    publishService:
      enabled: true
    replicaCount: 2
    minAvailable: 1
    scope:
      enabled: true
    stats:
      enabled: true
    metrics:
      enabled: true
      service:
        annotations:
          gitlab.com/prometheus_scrape: "true"
          gitlab.com/prometheus_port: "10254"
          prometheus.io/scrape: "true"
          prometheus.io/port: "10254"
  defaultBackend:
    minAvailable: 1
    replicaCount: 1
    resources:
      requests:
        cpu: 5m
        memory: 5Mi
  rbac:
    create: false
  serviceAccount:
    create: true

## Installation & configuration of stable/prometheus
## See requirements.yaml for current version
prometheus:
  install: false

## Configuration of Redis
## doc/architecture/decisions.md#redis
## doc/charts/redis
redis:
  install: false

## Instllation & configuration of stable/prostgresql
## See requirements.yaml for current version
postgresql:
  postgresqlUsername: gitlab
  # This just needs to be set. It will use a second entry in existingSecret for postgresql-postgres-password
  postgresqlPostgresPassword: bogus
  install: false
  postgresqlDatabase: gitlabhq_production
  image:
    tag: 11.9.0
  usePasswordFile: true
  existingSecret: 'bogus'
  initdbScriptsConfigMap: 'bogus'
  master:
    extraVolumeMounts:
      - name: custom-init-scripts
        mountPath: /docker-entrypoint-preinitdb.d/init_revision.sh
        subPath: init_revision.sh
    podAnnotations:
      postgresql.gitlab/init-revision: "1"
  metrics:
    enabled: true
    ## Optionally define additional custom metrics
    ## ref: https://github.com/wrouesnel/postgres_exporter#adding-new-metrics-via-a-config-file

gitlab-runner:
  install: ${GITLAB_RUNNER_INSTALL}
  rbac:
    create: true
  runners:
    locked: false
    cache:
      cacheType: gcs
      gcsBucketName: ${PROJECT_ID}-runner-cache
      secretName: google-application-credentials
      cacheShared: true
      gcsCacheInsecure: true

registry:
  enabled: true
  storage:
    secret: gitlab-registry-storage
    key: storage
    extraKey: gcs.json


## Automatic shared secret generation
## doc/installation/secrets.md
## doc/charts/shared-secrets
shared-secrets:
  enabled: true
  rbac:
    create: true


## Settings for individual sub-charts under GitLab
## Note: Many of these settings are configurable via globals
gitlab:
  ## doc/charts/gitlab/task-runner
  task-runner:
    replicas: 1
    antiAffinityLabels:
      matchLabels:
        app: 'gitaly'
