v := 0.1
deb_file := "dea-devbox-$(v).deb"

all: $(deb_file)

sync:
	mkdir -p _build/
	rsync -av rootfs/ _build/

deb_files: _build/DEBIAN/postinst _build/DEBIAN/control

_build/DEBIAN/postinst: deb/postinst
	mkdir -p _build/DEBIAN
	cp $< $@

_build/DEBIAN/control: deb/control.jinja2
	mkdir -p _build/DEBIAN
	jinja2 --format ini -D version=$(v) $< /dev/null > $@

$(deb_file): deb_files sync
	fakeroot dpkg-deb --build _build/ $@

clean:
	rm -rf _build

.PHONY: all sync clean deb_files


