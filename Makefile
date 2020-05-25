#    Copyright 2019 (c) Andrea Scuderi - https://github.com/swift-sprinter

#    Licensed under the Apache License, Version 2.0 (the "License");
#    you may not use this file except in compliance with the License.
#    You may obtain a copy of the License at

#        http://www.apache.org/licenses/LICENSE-2.0

#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS,
#    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#    See the License for the specific language governing permissions and
#    limitations under the License.

# Use this tag to build a customized local image

SWIFT_VERSION?=nightly-amazonlinux2
LAYER_VERSION?=nightly-amazonlinux2
DOCKER_OS?=amazonlinux2

# SWIFT_VERSION?=5.2.3-bionic
# LAYER_VERSION?=5-2-3-bionic
# DOCKER_OS=bionic

DOCKER_TAG=nio-swift:$(SWIFT_VERSION)
SWIFT_DOCKER_IMAGE=$(DOCKER_TAG)
SWIFT_LAMBDA_LIBRARY=nio-swift-lambda-runtime-$(LAYER_VERSION)
SWIFT_CONFIGURATION=release

BUILD_PATH=.build
SERVERLESS_BUILD=build
SERVERLESS_LAYER=swift-lambda-runtime

# Configuration

# HelloWorld Example Configuration
SWIFT_EXECUTABLE?=Products
SWIFT_PROJECT_PATH?=Products
LAMBDA_FUNCTION_NAME?=Products
LAMBDA_HANDLER?=$(SWIFT_EXECUTABLE).handler

# Internals
LAMBDA_ZIP=lambda.zip
SHARED_LIBS_FOLDER=swift-shared-libs
LAYER_ZIP=swift-lambda-runtime-$(LAYER_VERSION).zip
ROOT_BUILD_PATH=./build
LAYER_BUILD_PATH=$(ROOT_BUILD_PATH)
LAMBDA_BUILD_PATH=$(ROOT_BUILD_PATH)

# use this for local development
MOUNT_ROOT=$(shell pwd)
DOCKER_PROJECT_PATH=$(SWIFT_PROJECT_PATH)
ROOT_BUILD_PATH=./.build
LAYER_BUILD_PATH=$(ROOT_BUILD_PATH)/layer
LAMBDA_BUILD_PATH=$(ROOT_BUILD_PATH)/lambda
LOCAL_LAMBDA_PATH=$(ROOT_BUILD_PATH)/local
LOCALSTACK_TMP=$(ROOT_BUILD_PATH)/.tmp
TMP_BUILD_PATH=$(ROOT_BUILD_PATH)/tmp
DATETIME=$(shell date +'%y%m%d-%H%M%S')
DOCKER_FOLDER=docker
BOOTSTRAP=$(DOCKER_FOLDER)/$(SWIFT_VERSION)/bootstrap
			
docker_build:
	docker build --tag $(DOCKER_TAG) docker/$(SWIFT_VERSION)/.

build_lambda:
	docker run \
			--rm \
			--volume "$(MOUNT_ROOT)/:/src" \
			--workdir "/src/$(DOCKER_PROJECT_PATH)" \
			$(SWIFT_DOCKER_IMAGE) \
			/bin/bash -c "swift build --configuration $(SWIFT_CONFIGURATION)"

cp_lambda_to_sls_build_local: create_build_directory
	docker run \
			--rm \
			--volume "$(MOUNT_ROOT)/:/src" \
			--workdir "/src/$(DOCKER_PROJECT_PATH)" \
			$(SWIFT_DOCKER_IMAGE) \
			/bin/bash -c "swift build -c $(SWIFT_CONFIGURATION) --show-bin-path | tr '\n' '/' > $(BUILD_PATH)/path.txt; echo '$(SWIFT_EXECUTABLE)' >> $(BUILD_PATH)/path.txt |  cat $(BUILD_PATH)/path.txt | xargs cp -t ../$(SERVERLESS_BUILD); rm $(BUILD_PATH)/path.txt"

create_build_directory:
	if [ ! -d "$(LAMBDA_BUILD_PATH)" ]; then mkdir -p $(LAMBDA_BUILD_PATH); fi
	if [ ! -d "$(LAYER_BUILD_PATH)" ]; then mkdir -p $(LAYER_BUILD_PATH); fi
	if [ ! -d "$(SERVERLESS_BUILD)" ]; then mkdir -p $(SERVERLESS_BUILD); fi

package_lambda: create_build_directory build_lambda
	zip -r -j $(LAMBDA_BUILD_PATH)/$(LAMBDA_ZIP) $(SWIFT_PROJECT_PATH)/$(BUILD_PATH)/$(SWIFT_CONFIGURATION)/$(SWIFT_EXECUTABLE)

package_layer: create_build_directory
	$(eval SHARED_LIBRARIES := $(shell cat docker/$(SWIFT_VERSION)/swift-shared-libraries.txt | tr '\n' ' '))
	mkdir -p $(SHARED_LIBS_FOLDER)/lib
ifeq '$(DOCKER_OS)' 'xenial'
	docker run \
			--rm \
			--volume "$(shell pwd)/:/src" \
			--workdir "/src" \
			$(SWIFT_DOCKER_IMAGE) \
			cp /lib64/ld-linux-x86-64.so.2 $(SHARED_LIBS_FOLDER)
endif
	docker run \
			--rm \
			--volume "$(shell pwd)/:/src" \
			--workdir "/src" \
			$(SWIFT_DOCKER_IMAGE) \
			cp -t $(SHARED_LIBS_FOLDER)/lib $(SHARED_LIBRARIES)
	cp $(BOOTSTRAP) $(SHARED_LIBS_FOLDER)
	cd $(SHARED_LIBS_FOLDER); pwd; zip -r ../$(LAYER_BUILD_PATH)/$(LAYER_ZIP) bootstrap lib

cp_layer_to_sls_build_local: create_build_directory
	if [ ! -d "./$(SERVERLESS_BUILD)/$(SERVERLESS_LAYER)" ]; then mkdir -p ./$(SERVERLESS_BUILD)/$(SERVERLESS_LAYER); fi
	cp -R ./$(SHARED_LIBS_FOLDER)/. ./$(SERVERLESS_BUILD)/$(SERVERLESS_LAYER)
