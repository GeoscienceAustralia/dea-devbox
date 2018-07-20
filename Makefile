v := 0.1
deb_file := "dea-devbox-$(v).deb"

all: $(deb_file)

sync:
	mkdir -p _build/
	rsync -av rootfs/ _build/

wheels:
	pip wheel --no-deps -w ./_build/usr/share/dea/wheels/ .

deb_files: _build/DEBIAN/postinst _build/DEBIAN/control

_build/DEBIAN/postinst: deb/postinst
	mkdir -p _build/DEBIAN
	cp $< $@

_build/DEBIAN/control: deb/control.jinja2
	mkdir -p _build/DEBIAN
	jinja2 --format ini -D version=$(v) $< /dev/null > $@

$(deb_file): deb_files sync wheels
	fakeroot dpkg-deb --build _build/ $@

upload: $(deb_file)
	deb-s3 upload -c bionic --s3-region ap-southeast-2 --bucket dea-devbox-apt $<

clean:
	rm -rf _build

distclean: clean
	rm $(deb_file)

.PHONY: all sync clean distclean upload deb_files wheels


