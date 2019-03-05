v := 0.1.3
deb_file := "dea-devbox-$(v).deb"

all: $(deb_file)

sync:
	mkdir -p _build/
	rsync -av rootfs/ _build/

wheels:
	pip3 wheel --no-deps -w ./_build/usr/share/dea/wheels/ .

deb_files: _build/DEBIAN/postinst _build/DEBIAN/control

./_xar/bin/pip3:
	mkdir -p _xar
	python3 -m venv _xar

_xar_env: ./_xar/bin/pip3
	$< install git+https://github.com/facebookincubator/xar.git@e80d9ede6767f4c06f478c1b3f0bb3b4cb50072d
	$< install .

_build/usr/bin/dea-tool.xar: _xar_env setup.py
	./_xar/bin/python3 setup.py bdist_xar --xar-compression-algorithm=zstd --dist-dir=_build/usr/bin/

xars: _build/usr/bin/dea-tool.xar
	(cd _build/usr/bin/; ln -s dea-tool.xar ec2env; ln -s dea-tool.xar ec2update_dns)

_build/DEBIAN/postinst: deb/postinst
	mkdir -p _build/DEBIAN
	cp $< $@

_build/DEBIAN/control: deb/control.jinja2
	mkdir -p _build/DEBIAN
	jinja2 --format ini -D version=$(v) $< /dev/null > $@

$(deb_file): deb_files sync wheels xars
	fakeroot dpkg-deb --build _build/ $@

upload: $(deb_file)
	deb-s3 upload -c bionic --s3-region ap-southeast-2 --bucket dea-devbox-apt $<

ami:
	cd ami && packer build devbox.json

clean:
	rm -rf _build _xar

distclean: clean
	rm -f $(deb_file)

.PHONY: all sync clean distclean upload deb_files wheels ami _xar_env xar


