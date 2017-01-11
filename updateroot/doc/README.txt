updateroot is an initramfs module that allows you to update
the root filesystem before changing to it.

Each updateroot= on the kernel command line will be downloaded
and extracted over the top of the root filesystem.  Support is
present for gzip, xz or no compression as long as urls end in
.tar.gz, .tgz, .tar.xz, .txz or .tar.

Any files in a .updateroot/ directory inside the tarball that
are executable will be executed inside the target before
init is started.

To demo this, first install the cloud-initramfs-updateroot and
cloud-initramfs-rooturl packages.  That will update your initramfs
to have these modules.

$ sudo dpkg -i cloud-initramfs-updateroot_*.deb clodu-initramfs-rooturl*.deb
update-initramfs: Generating /boot/initrd.img-4.4.0-23-generic
$ sudo update-initramfs -u -k $(uname -r)

# make local copies for permissions and shorter cmdline
$ sudo cat /boot/vmlinu?-$(uname -r) > kernel
$ cp /boot/initrd.img-$(uname -r) initrd

# create 'seed.tar' with a nocloud seed
$ cat > user-data <<EOF
#cloud-config
password: passw0rd
chpasswd: { expire: False }
ssh_pwauth: True
EOF
$ echo "instance-id: $(uuidgen || echo i-abcdefg)" > meta-data
$ cloud-localds --disk-format=tar-seed-local seed.tar user-data meta-data

# download the latest xenial squashfs
$ iurl="http://cloud-images.ubuntu.com/daily/server/xenial/20160523"
$ wget "$iurl/xenial-server-cloudimg-amd64.squashfs"

# serve those files on a python simple web server note that
# 10.0.2.2 works for the host address in a qemu user mode networking
$ python -m SimpleHTTPServer 9999 &
$ burl="http://10.0.2.2:9999"

# set cmdline variable
$ cmdline="root=$burl/xenial-server-cloudimg-amd64.squashfs"
$ cmdline="$cmdline updateroot=$burl/seed.tar"
$ cmdline="$cmdline overlayroot=tmpfs"
$ cmdline="$cmdline console=ttyS0 -v"

# now boot a qemu guest with no disks and 1G memory.
$ qemu-system-x86_64 -enable-kvm \
   -device virtio-net-pci,netdev=net00 \
   -netdev type=user,id=net00 \
   -m 1G -nographic -kernel kernel -initrd initrd \
   -append "$cmdline"

The system should boot to a login prompt and let you in as 'ubuntu:passw0rd'

Log in and you'll see something like:

$ df -h /
Filesystem      Size  Used Avail Use% Mounted on
overlayroot     497M   59M  438M  12% /

$ egrep "(/media|overlay)" /proc/mounts 
/dev/loop0 /media/root-ro squashfs ro,relatime 0 0
tmpfs-root /media/root-rw tmpfs rw,relatime 0 0
overlayroot / overlayfs rw,relatime,lowerdir=/media/root-ro,upperdir=/media/root-rw//overlay,workdir=/media/root-rw//overlay-workdir 0 0

