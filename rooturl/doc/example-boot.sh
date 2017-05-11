#!/bin/bash
set -e
rel=${1:-xenial}
ftype=${2}
if [ -z "$ftype" ]; then
  case "$rel" in
    precise|trusty) ftype="-root.tar.xz";;
    *) ftype=".squashfs";;
  esac
fi
name="rooturl-$rel"

which cloud-localds >/dev/null || missing="cloud-image-utils"
which lxc >/dev/null || missing="${missing} lxc"
[ -z "$missing" ] ||
   { echo "Please apt-get install -qy $missing"; exit 1; }

mkdir -p $rel

if ! [ -e "$rel/kernel" -a -e "$rel/initrd" ]; then
lxc launch ubuntu-daily:$rel "$name"
trap "lxc delete --force $name" EXIT
lxc exec "$name" -- sh -s <<"EOF"
set -e
while [ ! -e /run/cloud-init/result.json ]; do
   echo -n .
   sleep 1
done
echo "manual_add_modules squashfs" > /etc/initramfs-tools/hooks/squashfs
apt-get update -q
apt-get install -qy cloud-initramfs-rooturl linux-image-virtual </dev/null
cd /tmp
for i in /boot/vmlinu?-*; do
  [ -f "$i" -a "${i%.signed}" != "$i" ] || continue
done
cp $i kernel
for i in /boot/initrd.*; do
  [ -f "$i" ] || continue
done
cp $i initrd
EOF
lxc file pull $name/tmp/kernel $rel/kernel
lxc file pull $name/tmp/initrd $rel/initrd
fi

burl="http://cloud-images.ubuntu.com/daily/server"
file="$rel-server-cloudimg-amd64${ftype}"
cd $rel
if ! [ -e "$file" ]; then
   wget "$burl/$rel/current/$file" -O "$file.tmp"
   mv "$file.tmp" "$file"
fi

if [ ! -e "user-data" ]; then
    cat > "user-data" <<EOF
#cloud-config
password: passw0rd
chpasswd: { expire: False }
ssh_pwauth: True
EOF
fi

if [ ! -e "meta-data" ]; then
   echo "instance-id: $(uuidgen || echo i-abcdefg)" > "meta-data"
fi

if [ ! -e "seed.img" ]; then
   cloud-localds seed.img user-data meta-data
fi

port=9999
cat > "boot" <<EOF
#!/bin/sh
file=\${1:-"${file}"}
port=\${2:-${port}}
EOF
cat >> "boot" <<"EOF"
cmdline="root=http://10.0.2.2:${port}/$file console=ttyS0"
case "$file" in
   *squashfs) cmdline="${cmdline} overlayroot=tmpfs";;
esac

which python >/dev/null && python=python || python=python3
$python -m SimpleHTTPServer $port &
kid=$!
trap "kill -9 $kid" EXIT

set -x
qemu-system-x86_64 -enable-kvm \
  -device virtio-net-pci,netdev=net00 \
  -netdev type=user,id=net00 \
  -drive "if=virtio,file=seed.img,format=raw" \
  -m 1G -nographic \
  -kernel kernel -initrd initrd \
  -append "$cmdline"
EOF
chmod 755 "boot"

cat <<EOF
Now, do:
   cd $rel
   ./boot
EOF
