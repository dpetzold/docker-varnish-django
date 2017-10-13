PROJECT_VERSION := $(shell git rev-parse --short HEAD)

all: build push deploy

build:
	docker build -t gcr.io/${PROJECT_ID}/varnish:${PROJECT_VERSION} .

push:
	gcloud docker -- push gcr.io/${PROJECT_ID}/varnish:${PROJECT_VERSION}

update:
	sed -ri "s/varnish:(\w{7})/varnish:${PROJECT_VERSION}/" ../../kubernetes_django_admin/templates/varnish.yaml

apply:
	kubectl apply -f ../../kubernetes_django_admin/templates/varnish.yaml

deploy: update apply

run:
	docker run \
	  -e ALLOWED_HOSTS="petzold.io derrickpetzold.com" \
	  -e ADMIN_URL="^admin/" \
	  -e HEALTH_CHECK_URL="/200/" \
	  -e VARNISH_NAMED_BACKEND=localhost \
	  -it dpetzold/docker-varnish-django bash
