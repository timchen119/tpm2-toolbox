# tpm2-toolbox

Set of utilities and a daemon to deal with TPM 2.0 chips built into a wide range of todays devices.

The snap will invoke a TPM 2.0 software simulator daemon from IBM and tpm2-abrmd TPM2 access broker & resource management daemon by default.

If you don't have a TPM 2.0 hardware, you can test the commands thorugh abrmd to the TPM 2.0 software simulator daemon.

Or you can start a KVM/QEMU image with swtpm to test your system.

If you already have a TPM 2.0 hardware, you can also use this snap to connect to the hardware with in-kernel RM or direct access the device.

## Install the snap

```bash
$ sudo snap install tpm2-toolbox
$ sudo snap connect tpm2-toolbox:tpm
```

# Notice

The latest stable channel of tpm2-toolbox includes tpm2-tools 4.0.x,
The edge channel always includes the latest master branch of tpm2-tools, please use the
following commands to install:

```bash
$ sudo snap install tpm2-toolbox --edge
```

## Example usage

Use tpm2_clear to clear the TPM:
```bash
$ sudo tpm2-toolbox.clear -T device:/dev/tpmrm0
```

To test if your TPM2 H/W works:

For kernel version 4.11+:
```bash
$ sudo tpm2-toolbox.pcrread -T device:/dev/tpmrm0
```

For kernel older than 4.11:
```bash
$ sudo tpm2-toolbox.pcrread -T device:/dev/tpm0
```

### Tips
To manually setup the commands alias to start with "tpm2_", you can use the following command to setup snap alias:

```bash
$ /snap/tpm2-toolbox/current/bin/alias-tpm2-tools.sh
```

### Without TPM2 H/W

```bash
$ tpm2-toolbox.pcrread sha256:0 --output pcr0.bin
$ tpm2-toolbox.createpolicy --policy-pcr --pcr-list sha256:0 --pcr pcr0.bin --policy policy.digest
$ tpm2-toolbox.createprimary --hierarchy o --hash-algorithm sha256 --key-algorithm rsa --key-context primary.context
$ tpm2-toolbox.create --hash-algorithm sha256 --public obj.pub --private obj.priv --parent-context primary.context --policy policy.digest --attributes 0x492 --sealing-input - <<< "MYSECRET"
$ tpm2-toolbox.load --public obj.pub --private obj.priv --parent-context primary.context --name load.name --key-context load.context

$ tpm2-toolbox.unseal --object-contex load.context --auth pcr:sha256:0=pcr0.bin
```

### With TPM2 H/W

```bash
$ sudo tpm2-toolbox.pcrread sha256:0 --output pcr0.bin --tcti device:/dev/tpmrm0
$ sudo tpm2-toolbox.createpolicy --policy-pcr --pcr-list sha256:0 --pcr pcr0.bin --policy policy.digest --tcti device:/dev/tpmrm0
$ sudo tpm2-toolbox.createprimary --hierarchy o --hash-algorithm sha256 --key-algorithm rsa --key-context primary.context --tcti device:/dev/tpmrm0
$ sudo tpm2-toolbox.create --hash-algorithm sha256 --public obj.pub --private obj.priv --parent-context primary.context --policy policy.digest --attributes 0x492 --sealing-input - <<< "MYROOTSECRET" --tcti device:/dev/tpmrm0
$ sudo tpm2-toolbox.load --public obj.pub --private obj.priv --parent-context primary.context --name load.name --key-context load.context --tcti device:/dev/tpmrm0

$ sudo tpm2-toolbox.unseal --object-contex load.context --auth pcr:sha256:0=pcr0.bin --tcti device:/dev/tpmrm0
```

export TPM2TOOLS_TCTI=device:/dev/tpmrm0 and run commands `sudo -E` will work too.

### Example on Extended Authorization (EA) Policies

check test-eapolicy.sh in the repo.

### Example to test swtpm with KVM/QEMU

Start a seperate `swtpm` process:
```
$ tpm2-toolbox.swtpm-start &
```

Make sure your login user is being added in the `kvm` group:
```
$ sudo adduser `id -un` kvm
```
You need logout to make the change or you can use `newgrp` to change the group in current login session
```
$ newgrp kvm
```

Run kvm with swtpm as chardev, for example you can invoke an Ubuntu Core 16 image
with kvm and swtpm to have a Ubuntu Core system with TPM 2.0 emulated.

```
$ sudo apt install ovmf
$ wget http://cdimage.ubuntu.com/ubuntu-core/16/stable/ubuntu-core-16-amd64.img.xz
$ xz -d ubuntu-core-16-amd64.img.xz
$ kvm -smp 2 -m 512 \
  -net user -net nic -redir tcp:8022::22 \
  -smbios type=1,serial=1234567 \
  -device nec-usb-xhci,id=xhci -device usb-storage,bus=xhci.0,drive=stick,removable=on \
  -drive if=pflash,format=raw,readonly,file=/usr/share/OVMF/OVMF_CODE.fd \
  -drive if=none,id=stick,format=raw,file=ubuntu-core-16-amd64.img \
  -chardev socket,id=chrtpm,path=$(ls $HOME/snap/tpm2-toolbox/current/tpm-*.sock) \
  -tpmdev emulator,id=tpm0,chardev=chrtpm -device tpm-tis,tpmdev=tpm0 \
  -nographic
```

Finish the console-conf to setup your account, after that you can ssh to local 8022 port
and you will have a Ubuntu Core 16 system with TPM2.
```
$ ssh yourname@127.0.0.1 -p 8022
```
