# tpm2

Set of utilities and a daemon to deal with TPM 2.0 chips built into a wide range of todays devices.

The snap will invoke a TPM 2.0 software simulator daemon from IBM and tpm2-abrmd TPM2 access broker & resource management daemon by default.

## Example usage

Please run these examples under your home directory.

TIP: 

Install local build snap
```bash
sudo snap install tpm2-simulator*.snap --dangerous
sudo snap connect tpm2-simulator:tpm
```

To manually setup alias with "tpm2_", you can use the following command to setup snap alias:

```bash
$ for binary in /snap/tpm2-simulator/current/bin/tpm2_*; do command=$(basename $binary | cut -c 6-); sudo snap alias tpm2-simulator.$(echo $command | sed 's/_/-/g') tpm2_$command; done
```

Use tpm2_clear to clear the TPM:
```bash
$ tpm2_clear -T device:/dev/tpmrm0
```

### Without TPM2 H/W

```bash
$ tpm2-simulator.pcrlist --sel-list sha256:0 --out-file pcr0.bin
$ tpm2-simulator.createpolicy --policy-pcr --set-list sha256:0 --pcr-input-file pcr0.bin --policy-file policy.digest
$ tpm2-simulator.createprimary -a o --halg sha256 --kalg rsa -o primary.context
$ tpm2-simulator.create --halg 0x000B --pubfile obj.pub --privfile obj.priv --context-parent primary.context -L policy.digest --object-attributes 0x492 -I- <<< "MYSECRET"
$ tpm2-simulator.load --pubfile obj.pub --privfile obj.priv --context-parent primary.context --name load.name --out-context load.context

$ tpm2-simulator.unseal -c load.context --set-list 0xB:0 --pcr-input-file pcr0.bin
```

### With TPM2 H/W

```bash
$ sudo tpm2-simulator.pcrlist --sel-list sha256:0 --out-file pcr0.bin -T device:/dev/tpmrm0
$ sudo tpm2-simulator.createpolicy --policy-pcr --set-list sha256:0 --pcr-input-file pcr0.bin --policy-file policy.digest -T device:/dev/tpmrm0
$ sudo tpm2-simulator.createprimary -a o --halg sha256 --kalg rsa -o primary.context -T device:/dev/tpmrm0
$ sudo tpm2-simulator.create --halg 0x000B --pubfile obj.pub --privfile obj.priv --context-parent primary.context -L policy.digest --object-attributes 0x492 -I- <<< "MYSECRET" -T device:/dev/tpmrm0
$ sudo tpm2-simulator.load --pubfile obj.pub --privfile obj.priv --context-parent primary.context --name load.name --out-context load.context -T device:/dev/tpmrm0

$ sudo tpm2-simulator.unseal -c load.context --set-list 0xB:0 --pcr-input-file pcr0.bin -T device:/dev/tpmrm0
```

export TPM2TOOLS_TCTI=device:/dev/tpmrm0 and run commands `sudo -E` will work too.

### Example on Extended Authorization (EA) Policies

check test_eapolicy.sh in the repo.
