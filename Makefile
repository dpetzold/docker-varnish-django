all: build push

build:
	docker build --rm -t dpetzold/docker-varnish-django .

push:
	docker push dpetzold/docker-varnish-django
