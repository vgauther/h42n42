# Makefile (racine)
PROJECT := h42n42
IMAGE   := h42n42:dev
NAME    := h42n42_dev

.PHONY: all build run stop logs sh clean

all: run

build:
	docker build -t $(IMAGE) .

run: build
	docker run --rm -it --name $(NAME) \
	  -p 8080:8080 \
	  $(IMAGE)

stop:
	- docker stop $(NAME)

logs:
	- docker logs -f $(NAME)

sh:
	docker run --rm -it --name $(NAME)_sh \
	  -p 8080:8080 \
	  $(IMAGE) /bin/bash

clean:
	- docker rm -f $(NAME) 2>/dev/null || true
	- docker rmi $(IMAGE) 2>/dev/null || true
