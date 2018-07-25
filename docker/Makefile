all: dea-build-deb

dea-build-deb: Dockerfile.build-deb
	docker build -t $@ --file $< .

clean:
	docker rmi dea-build-deb

.PHONY: all clean dea-build-deb
