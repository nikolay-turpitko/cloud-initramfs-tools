rooturl is an initramfs module that allows you to download
a url to a tmpfs and run that as your root.

The supported file types are tar, tar.gz, tar.xz and squashfs.
For tar formats, it supports multiple urls to allow for use of a single
base root with changing secondary roots.

Ie, you might have a root like that found at
  http://cdimage.ubuntu.com/ubuntu-core/releases/

And then have a small tarball with just an 'etc/shadow' that
sets the root password for login.

An example kernel command line might look like:
   root=http://192.168.1.131:9999/core.tar.gz,http://192.168.1.131:9999/root-passwd.tar.gz

An example booting squashfs image can be done like:

  qemu-system-x86_64 -enable-kvm 
     -device virtio-net-pci,netdev=net00 \
     -netdev type=user,id=net00 \
     -m 1G -nographic \
     -kernel kernel -initrd initrd \
     -append "root=http://10.0.2.2:9999/xenial-server-cloudimg-amd64.squashfs console=ttyS0 -v overlayroot=tmpfs break=bottom,init
