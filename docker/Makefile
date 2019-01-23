all: dea-build-deb

dea-build-deb: Dockerfile.build-deb
	docker build -t $@ --file $< .

dea-ssl: Dockerfile.ssl
	pip3 wheel --no-deps -w . ..
	docker build -t $@ --file $< .

debug-ssl: dea-ssl
	./docker-ssl

clean:
	docker rmi dea-build-deb

.PHONY: all clean dea-build-deb
