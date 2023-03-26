#    Copyright 2023 (c) Andrea Scuderi - https://github.com/swift-sprinter

#    Licensed under the Apache License, Version 2.0 (the "License");
#    you may not use this file except in compliance with the License.
#    You may obtain a copy of the License at

#        http://www.apache.org/licenses/LICENSE-2.0

#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS,
#    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#    See the License for the specific language governing permissions and
#    limitations under the License.

SWIFT_VERSION=5.7.3

SWIFT_DOCKER_IMAGE=swift-amazonlinux2-builder:$(SWIFT_VERSION)
SWIFT_CONFIGURATION=release

# Internals
LAMBDA_ARCHIVE_PATH=./$(DOCKER_BUILD_PATH)

MOUNT_ROOT=$(shell pwd)
DOCKER_BUILD_PATH=build
DOCKER_PROJECT_PATH=Products
			
docker_build:
	docker build --tag $(SWIFT_DOCKER_IMAGE) .

archive_lambda: create_build_directory
	docker run \
			--rm \
			--volume "$(MOUNT_ROOT)/:/src" \
			--workdir "/src/$(DOCKER_PROJECT_PATH)" \
			$(SWIFT_DOCKER_IMAGE) \
			/bin/bash -c "swift package archive -c $(SWIFT_CONFIGURATION) --verbose --output-path /src/$(DOCKER_BUILD_PATH)"

docker_bash:
	docker run \
			-it \
			--rm \
			--volume "$(MOUNT_ROOT):/src" \
			--workdir "/src/" \
			$(SWIFT_DOCKER_IMAGE) \
			/bin/bash

create_build_directory:
	if [ ! -d "$(LAMBDA_ARCHIVE_PATH)" ]; then mkdir -p $(LAMBDA_ARCHIVE_PATH); fi