#!/bin/sh

sh -c "$SNAP/usr/sbin/tpm2-abrmd --allow-root --tcti=mssim:host=localhost,port=2321"
