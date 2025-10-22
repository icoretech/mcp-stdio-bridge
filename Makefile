REG ?= ghcr.io
ORG ?= icoretech
IMG ?= mcp-stdio-bridge
IMAGE ?= $(REG)/$(ORG)/$(IMG)
PLATFORMS ?= linux/amd64,linux/arm64
TAG ?= dev

.PHONY: build push all

build:
	docker buildx build --platform $(PLATFORMS) -t $(IMAGE):$(TAG) --load .

push:
	docker buildx build --platform $(PLATFORMS) -t $(IMAGE):$(TAG) --push .

all: build
