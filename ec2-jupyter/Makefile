all: install.sh


install.sh: bootstrap.sh proxy_setup.sh machine.env *.py *.service
	echo '#!/bin/sh' > $@
	echo 'mkdir -p /tmp/install && cd /tmp/install' >> $@
	echo -n 'echo ' >> $@
	tar cvz $@ $^ | base64 -w 0 >> $@
	echo '\\' >> $@
	echo ' | base64 -d|tar xz' >> $@
	echo './bootstrap.sh' >> $@
	chmod 755 $@

clean:
	rm -f install.sh


lxc-clean:
	sudo lxc stop uu || echo "Already stopped"
	sudo lxc restore uu ubuntu-clean
	sudo lxc start uu

lxc-run: lxc-files
	sudo lxc exec uu -- /root/install.sh

lxc-files: install.sh
	sudo lxc file push install.sh uu/root/


.PHONY: all tar clean lxc-clean lxc-files lxc-start lxc-run
