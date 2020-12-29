#!/bin/sh

for binary in /snap/tpm2-toolbox/current/usr/bin/tpm2_*; do command=$(basename $binary | cut -c 6-); sudo snap alias tpm2-toolbox.$(echo $command | sed 's/_/-/g') tpm2_$command; done
