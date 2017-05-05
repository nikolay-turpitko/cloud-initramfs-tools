rooturl is an initramfs module that allows you to download
a url to a tmpfs and run that as your root.

The supported file types are tar, tar.gz, tar.xz and squashfs.

Ie, you might have a root like that found at
  http://cloud-images.ubuntu.com/

An example booting squashfs image can be done like:

  qemu-system-x86_64 -enable-kvm 
     -device virtio-net-pci,netdev=net00 \
     -netdev type=user,id=net00 \
     -m 1G -nographic \
     -kernel kernel -initrd initrd \
     -append "root=http://10.0.2.2:9999/xenial-server-cloudimg-amd64.squashfs console=ttyS0 -v overlayroot=tmpfs break=bottom,init"
