MODULES = growroot rescuevol overlayroot dyn-netconf
INITRAMFS_D = /usr/share/initramfs-tools
IRD = $(DESTDIR)/$(INITRAMFS_D)
ULIB_PRE = $(DESTDIR)/usr/lib/cloud-initramfs-

build:

install:
	mkdir -p "$(IRD)/hooks" "$(IRD)/scripts" "$(DESTDIR)/etc"
	set -e; for d in $(MODULES); do \
		[ -d "$$d/hooks" ] || continue ; \
		install "$$d/hooks"/* "$(IRD)/hooks" ; \
		done
	set -e ; for d in $(MODULES); do \
		for sd in $$d/scripts/*; do \
			[ -d $$sd ] || continue; \
			td="$(IRD)/scripts/$${sd##*/}"; \
			mkdir -p "$$td" ; \
			install "$$sd"/* "$$td"; \
		done; done
	set -e; for d in $(MODULES); do \
		[ -d "$$d/etc" ] || continue ; \
		install -m 644 "$$d/etc"/* "$(DESTDIR)/etc" ; \
		done
	set -e; for d in $(MODULES); do \
		[ -d "$$d/tools" ] || continue ; \
		mkdir -p "$(ULIB_PRE)$$d/" && \
		install "$$d/tools"/* "$(ULIB_PRE)$$d/" ; \
		done
	mkdir -p "$(DESTDIR)/usr/sbin" "$(DESTDIR)/usr/share/man/man8"
	install -m 755 "overlayroot/usr/sbin/overlayroot-chroot" "$(DESTDIR)/usr/sbin"
	install -m 644 "overlayroot/usr/share/man/man8/overlayroot-chroot.8" "$(DESTDIR)/usr/share/man/man8"

# vi: ts=4 noexpandtab syntax=make
