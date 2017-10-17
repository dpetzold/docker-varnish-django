PROJECT_VERSION := $(shell git rev-parse --short HEAD)
PROJECT_IMAGE := gcr.io/${PROJECT_ID}/varnish:${PROJECT_VERSION}
 
all: build push deploy

build:
	docker build -t ${PROJECT_IMAGE} .

push: build
	gcloud docker -- push ${PROJECT_IMAGE}

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
	  -e VARNISH_BACKEND_HOST=localhost \
	  -e VARNISH_BACKEND_PORT=8000 \
	  -it gcr.io/${PROJECT_ID}/varnish:${PROJECT_VERSION}
