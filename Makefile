MOUNT_ROOT=$(shell pwd)
DOCKER_IMAGE=benchmark-node:latest

SWIFT_EXECUTABLE?=GetProduct
SWIFT_PROJECT_PATH?=./swift-rest-api
LAMBDA_FUNCTION_NAME?=GetProduct
LAMBDA_HANDLER?=$(SWIFT_EXECUTABLE).handler

docker_build:
	docker build --tag $(DOCKER_IMAGE) .

docker_bash:
	docker run \
			-it \
			--rm \
			--volume "$(MOUNT_ROOT)/:/src" \
			--workdir "/src" \
			$(DOCKER_IMAGE) \
			/bin/bash