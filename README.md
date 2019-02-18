# tpm2-toolbox

Set of utilities and a daemon to deal with TPM 2.0 chips built into a wide range of todays devices.

The snap will invoke a TPM 2.0 software simulator daemon from IBM and tpm2-abrmd TPM2 access broker & resource management daemon by default.

## Example usage

Please run these examples under your home directory.

TIP: 

Install local build snap
```bash
sudo snap install tpm2-toolbox*.snap --dangerous
sudo snap connect tpm2-toolbox:tpm
```

To manually setup alias with "tpm2_", you can use the following command to setup snap alias:

```bash
$ for binary in /snap/tpm2-toolbox/current/bin/tpm2_*; do command=$(basename $binary | cut -c 6-); sudo snap alias tpm2-toolbox.$(echo $command | sed 's/_/-/g') tpm2_$command; done
```

Use tpm2_clear to clear the TPM:
```bash
$ sudo tpm2_clear -T device:/dev/tpmrm0
```

To test if your TPM2 H/W works:
```bash
$ sudo tpm2-toolbox.pcrlist -T device:/dev/tpmrm0
```

### Without TPM2 H/W

```bash
$ tpm2-toolbox.pcrlist --sel-list sha256:0 --out-file pcr0.bin
$ tpm2-toolbox.createpolicy --policy-pcr --set-list sha256:0 --pcr-input-file pcr0.bin --policy-file policy.digest
$ tpm2-toolbox.createprimary -a o --halg sha256 --kalg rsa -o primary.context
$ tpm2-toolbox.create --halg 0x000B --pubfile obj.pub --privfile obj.priv --context-parent primary.context -L policy.digest --object-attributes 0x492 -I- <<< "MYSECRET"
$ tpm2-toolbox.load --pubfile obj.pub --privfile obj.priv --context-parent primary.context --name load.name --out-context load.context

$ tpm2-toolbox.unseal -c load.context --set-list 0xB:0 --pcr-input-file pcr0.bin
```

### With TPM2 H/W

```bash
$ sudo tpm2-toolbox.pcrlist --sel-list sha256:0 --out-file pcr0.bin -T device:/dev/tpmrm0
$ sudo tpm2-toolbox.createpolicy --policy-pcr --set-list sha256:0 --pcr-input-file pcr0.bin --policy-file policy.digest -T device:/dev/tpmrm0
$ sudo tpm2-toolbox.createprimary -a o --halg sha256 --kalg rsa -o primary.context -T device:/dev/tpmrm0
$ sudo tpm2-toolbox.create --halg 0x000B --pubfile obj.pub --privfile obj.priv --context-parent primary.context -L policy.digest --object-attributes 0x492 -I- <<< "MYSECRET" -T device:/dev/tpmrm0
$ sudo tpm2-toolbox.load --pubfile obj.pub --privfile obj.priv --context-parent primary.context --name load.name --out-context load.context -T device:/dev/tpmrm0

$ sudo tpm2-toolbox.unseal -c load.context --set-list 0xB:0 --pcr-input-file pcr0.bin -T device:/dev/tpmrm0
```

export TPM2TOOLS_TCTI=device:/dev/tpmrm0 and run commands `sudo -E` will work too.

### Example on Extended Authorization (EA) Policies

check test-eapolicy.sh in the repo.

### Example to test swtpm with KVM/QEMU

Start a seperate `swtpm` process:
```
$ tpm2-toolbox.swtpm-start
```
Make sure your login user is being added in the `kvm` group:
```
$ sudo adduser `id -un` kvm
```
You need logout to make the change or you can use `newgrp` to change the group in current login session
```
$ newgrp kvm
```

Run kvm with swtpm as chardev, for example
```
$ kvm -smp 2 -m 512 \
  -net user -net nic -redir tcp:8022::22 \
  -smbios type=1,serial=1234567 \
  -device nec-usb-xhci,id=xhci -device usb-storage,bus=xhci.0,drive=stick,removable=on \
  -drive if=pflash,format=raw,readonly,file=/usr/share/OVMF/OVMF_CODE.fd \
  -drive if=none,id=stick,format=raw,file=ubuntu-core-16-amd64.img \
  -chardev socket,id=chrtpm,path=$HOME/tpm-*.sock -tpmdev emulator,id=tpm0,chardev=chrtpm -device tpm-tis,tpmdev=tpm0 \
  -hda testdisk.raw -nographic
```
