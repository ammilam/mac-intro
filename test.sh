#! /bin/bash
export USERNAME=ammilam
export EMAIL=andrewmichaelmilam@gmail.com
export REPO=mac-intro
sed "s/USERNAME/$USERNAME/g; s/EMAIL/$EMAIL/g; s/REPO/$REPO/g" ./flux/flux.yaml > test.yaml