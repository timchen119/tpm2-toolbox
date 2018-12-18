# tpm2

Set of utilities and a daemon to deal with TPM 2.0 chips built into a wide range of todays devices.

The snap will invoke a TPM 2.0 software simulator daemon from IBM and tpm2-abrmd TPM2 access broker & resource management daemon by default.

## Example usage

Please run these examples under your home directory.

### Without TPM2 H/W

```bash
$ tpm2-simulator.takeownership -V -c
$ tpm2-simulator.nvpcrlist -L sha256:0 -o pcr0.bin
$ tpm2-simulator.createpolicy -P -L sha256:0 -F pcr0.bin -f policy.digest
$ tpm2-simulator.createprimary -H o -g 0x000B -G 0x0001 -C primary.context
$ tpm2-simulator.create -g 0x000B -G 0x0008 -u obj.pub -r obj.priv -c primary.context -L policy.digest -A 0x492 -I- <<< "MYSECRET"
$ tpm2-simulator.load -u obj.pub -r obj.priv -c primary.context -n load.name -C load.context

$ tpm2-simulator.unseal -c load.context -L 0xB:0 -F pcr0.bin
```

### With TPM2 H/W

```bash
$ sudo TPM2TOOLS_TCTI_NAME=device TPM2TOOLS_DEVICE_FILE=/dev/tpm0 tpm2-simulator.takeownership -V -c

$ sudo TPM2TOOLS_TCTI_NAME=device TPM2TOOLS_DEVICE_FILE=/dev/tpm0 tpm2-simulator.nvpcrlist -L sha256:0 -o pcr0.bin
$ sudo TPM2TOOLS_TCTI_NAME=device TPM2TOOLS_DEVICE_FILE=/dev/tpm0 tpm2-simulator.createpolicy -P -L sha256:0 -F pcr0.bin -f policy.digest
$ sudo TPM2TOOLS_TCTI_NAME=device TPM2TOOLS_DEVICE_FILE=/dev/tpm0 tpm2-simulator.createprimary -H o -g 0x000B -G 0x0001 -C primary.context
$ sudo TPM2TOOLS_TCTI_NAME=device TPM2TOOLS_DEVICE_FILE=/dev/tpm0 tpm2-simulator.create -g 0x000B -G 0x0008 -u obj.pub -r obj.priv -c primary.context -L policy.digest -A 0x492 -I- <<< "MYSECRET"
$ sudo TPM2TOOLS_TCTI_NAME=device TPM2TOOLS_DEVICE_FILE=/dev/tpm0 tpm2-simulator.load -u obj.pub -r obj.priv -c primary.context -n load.name -C load.context

$ sudo TPM2TOOLS_TCTI_NAME=device TPM2TOOLS_DEVICE_FILE=/dev/tpm0 tpm2-simulator.unseal -c load.context -L 0xB:0 -F pcr0.bin
```

Export TPM2TOOLS_TCTI_NAME and TPM2TOOLS_DEVICE_FILE and use sudo -E will work too.
