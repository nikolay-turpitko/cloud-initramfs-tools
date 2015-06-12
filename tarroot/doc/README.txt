tarroot is an initramfs module that allows you to download
a url to a tmpfs and run that as your root.

It supports multiple urls to allow for use of a single
base root with changing secondary roots.

Ie, you might have a root like that found at
  http://cdimage.ubuntu.com/ubuntu-core/releases/

And then have a small tarball with just an 'etc/shadow' that
sets the root password for login.

An example kernel command line might look like:
   root=http://192.168.1.131:9999/core.tar.gz,http://192.168.1.131:9999/root-passwd.tar.gz
