all: install.sh


install.sh: bootstrap.sh functions.sh proxy_setup.sh machine.env *.py *.service
	echo '#!/bin/sh' > $@
	echo 'mkdir -p /tmp/install && cd /tmp/install' >> $@
	echo '(base64 -d | tar xz) <<EOF' >> $@
	tar cvz $^ | base64 -w 120 >> $@
	echo 'EOF' >> $@
	echo '# You can override settings for host/github-user/email' >> $@
	echo '# ./bootstrap.sh <host.dea.gadevs.ga> <github-user> <email>' >> $@
	echo './bootstrap.sh' >> $@
	chmod 755 $@

clean:
	rm -f install.sh


lxc-clean:
	sudo lxc stop uu 2> /dev/null || echo "Already stopped"
	sudo lxc restore uu ubuntu-clean
	sudo lxc start uu

lxc-run: lxc-files
	sudo lxc exec uu -- /root/install.sh

lxc-files: install.sh
	sudo lxc file push install.sh uu/root/


.PHONY: all tar clean lxc-clean lxc-files lxc-start lxc-run
