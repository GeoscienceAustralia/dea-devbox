all: install.sh


install.sh: bootstrap.sh functions.sh dea-*.sh proxy_setup.sh *.py *.service
	echo '#!/bin/sh' > $@
	echo 'mkdir -p /opt/dea && cd /opt/dea && (base64 -d | tar xz) <<EOF' >> $@
	tar cvz $^ | base64 -w 150 >> $@
	echo 'EOF' >> $@
	echo './bootstrap.sh' >> $@
	chmod 755 $@

clean:
	rm -f install.sh

local-test:
	sudo cp functions.sh dea-*.sh /opt/dea/
	sudo systemctl stop jupyterhub
	sudo cp jupyterhub_config.py /etc/jupyterhub/jupyterhub_config.py
	sudo systemctl start jupyterhub

lxc-clean:
	sudo lxc stop uu 2> /dev/null || echo "Already stopped"
	sudo lxc restore uu ubuntu-clean
	sudo lxc start uu

lxc-run: lxc-files
	sudo lxc exec uu -- /root/install.sh

lxc-files: install.sh
	sudo lxc file push install.sh uu/root/


.PHONY: all tar clean lxc-clean lxc-files lxc-start lxc-run local-test
