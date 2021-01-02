git:
  url: ssh://git@github.com/${USERNAME}/${REPO}.git
  path: releases
  pollInterval: 1m
  user: ${USERNAME}
  email: ${EMAIL}
  secretName: flux-ss
  label: flux
sync:
  state: git
  timeout: 1m
registry:
  disableScanning: true
syncGarbageCollection:
  enabled: true
