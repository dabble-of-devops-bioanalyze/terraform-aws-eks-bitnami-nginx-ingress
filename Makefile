SHELL := /bin/bash

# List of targets the `readme` target should call before generating the readme
export README_DEPS ?= docs/targets.md docs/terraform.md

-include $(shell curl -sSL -o .build-harness "https://git.io/build-harness"; echo .build-harness)

## Lint terraform code
lint:
	$(SELF) terraform/install terraform/get-modules terraform/get-plugins terraform/lint terraform/validate

dodo-readme:
	wget https://raw.githubusercontent.com/Dabble-of-DevOps-BioHub/biohub-info/master/docs/README.md.gotmpl -O /tmp/README.md.gotmpl
	# make init
	make README_TEMPLATE_FILE=/tmp/README.md.gotmpl readme