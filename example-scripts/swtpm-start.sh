#!/bin/sh

TPMSTATE_PATH=$(mktemp --directory --tmpdir=$HOME tpmstate-XXXXXXXXXX)
SOCK_PATH=$(mktemp --dry-run --tmpdir=$HOME tpm-XXXXXXXXXX --suffix=.sock)

cleanup() {
  echo "clean up swtpm"
  rm -rf $TPMSTATE_PATH
  rm -f $SOCK_PATH
}
trap cleanup INT TERM EXIT

echo "start swtpm with TPM state path $TPMSTATE_PATH and socket path $SOCK_PATH"
sh -c "$SNAP/bin/swtpm $@ socket --tpmstate dir=$TPMSTATE_PATH --tpm2 --ctrl type=unixio,path=$SOCK_PATH"
