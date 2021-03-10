git:
  url: ssh://git@github.com/${USERNAME}/${REPO}.git
  path: mac-ecosystem/releases
  pollInterval: 1m
  user: ${USERNAME}
  email: ${EMAIL}
  secretName: flux-ssh
  label: flux
  branch: main
sync:
  state: git
  timeout: 1m
registry:
  disableScanning: true
syncGarbageCollection:
  enabled: true