MODULES = growroot rescuevol overlayroot
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

# vi: ts=4 noexpandtab syntax=make
