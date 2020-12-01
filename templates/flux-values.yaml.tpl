git:
  url: ssh://git@github.com/${USERNAME}/${REPO}.git
  path: releases
  pollInterval: 1m
  user: ${USERNAME}
  email: ${EMAIL}
  secretName: flux-ssh
  label: flux
sync:
  state: git
  timeout: 1m
registry:
  disableScanning: false
syncGarbageCollection:
  enabled: true
