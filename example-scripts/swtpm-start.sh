#!/bin/sh

BASE_TEMPLATE=$(mktemp --dry-run --tmpdir="$HOME" tpm-XXXXXXXXXX)
TPMSTATE_PATH="$BASE_TEMPLATE.tpmstate"
SOCK_PATH="$BASE_TEMPLATE.sock"
LOG_PATH="$BASE_TEMPLATE.log"

mkdir -p "$TPMSTATE_PATH"

cleanup() {
  echo "clean up swtpm"
  rm -rf "$TPMSTATE_PATH"
  rm -f "$SOCK_PATH"
  rm -f "$LOG_PATH"
}
trap cleanup INT TERM EXIT

echo "start swtpm with TPM state path $TPMSTATE_PATH and socket path $SOCK_PATH"
sh -c "$SNAP/usr/local/bin/swtpm $* socket --tpmstate dir=$TPMSTATE_PATH --tpm2 --ctrl type=unixio,path=$SOCK_PATH --log file=$LOG_PATH,level=9"
