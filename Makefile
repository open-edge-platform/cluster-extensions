# SPDX-FileCopyrightText: (C) 2024 Intel Corporation
# SPDX-License-Identifier: Apache-2.0

PROJECT_NAME := extensions
SUBPROJECTS  := pkg/edgedns-coredns pkg/kubevirt-helper pkg/intel-gpu-debug
VENV_NAME	 := venv_$(PROJECT_NAME)
SCRIPTS_DIR  := ./ci_scripts
LINT_DIRS    := pkg/...

# build virtualenv
$(VENV_NAME): requirements.txt
	python3 -m venv $@ ;\
  . ./$@/bin/activate; set -u ;\
  python -m pip install --upgrade pip ;\
  python -m pip install -r requirements.txt

YAML_IGNORE        := manifest, $(VENV_NAME)

all: build lint test
	@# Help: Runs build, lint, test stages

docker-build:
	@# Help: Runs docker build stage
	@echo "---MAKEFILE DOCKER BUILD---"
	for dir in $(SUBPROJECTS); do $(MAKE) -C $$dir docker-build; done
	@echo "---END MAKEFILE DOCKER BUILD---"

docker-push:
	@# Help: Runs docker push stage
	@echo "---MAKEFILE DOCKER PUSH---"
	for dir in $(SUBPROJECTS); do $(MAKE) -C $$dir docker-push; done
	@echo "---END MAKEFILE DOCKER PUSH---"

helm-build:
	@# Help: Builds the updated or added helm charts
	@echo "---START Helm Build---"
	$(SCRIPTS_DIR)/helm_build.sh
	@echo "---END Helm Build---"

helm-push:
	@# Help: Pushes the built helm charts
	@echo "---START Helm Push---"
	$(SCRIPTS_DIR)/helm_push.sh
	@echo "---END Helm Push---"

artifact-publish: ## only runs in CI
	@# Help: Publishes the deployment package and manifest file
	@echo "---START DP Publish---"
	$(SCRIPTS_DIR)/publish_dp.sh
	@echo "---END DP Publish---"
	@echo "---START Manifest Publish---"
	$(SCRIPTS_DIR)/publish_manifest.sh
	@echo "---END Manifest Publish---"

lint: yamllint mdlint helmlint go-lint ## Runs lint stage
	@# Help: Runs lint stage
	@echo "---MAKEFILE LINT---"
	@for dir in $(SUBPROJECTS); do $(MAKE) -C $$dir lint; done
	@echo "---END MAKEFILE LINT---"

license: $(VENV_NAME) ## Check licensing with the reuse tool
	. ./$</bin/activate; set -u ;\
	reuse --version ;\
	reuse --root . lint
list:
	@# Help: displays make targets
	help

clean:
	@# Help: Runs clean stage in all subprojects
	@echo "---MAKEFILE CLEAN---"
	for dir in $(SUBPROJECTS); do $(MAKE) -C $$dir clean; done
	@echo "---END MAKEFILE CLEAN---"

clean-all:
	@# Help: Runs clean-all stage in all subprojects
	@echo "---MAKEFILE CLEAN-ALL---"
	for dir in $(SUBPROJECTS); do $(MAKE) -C $$dir clean-all; done
	@echo "---END MAKEFILE CLEAN-ALL---"

define make-subproject-target
$1-%:
	@# Help: runs $1 subproject's $$* task
	$$(MAKE) -C $1 $$*
endef

$(foreach subproject,$(SUBPROJECTS),$(eval $(call make-subproject-target,$(subproject))))

help:
	@printf "%-20s %s\n" "Target" "Description"
	@printf "%-20s %s\n" "------" "-----------"
	@make -pqR : 2>/dev/null \
        | awk -v RS= -F: '/^# File/,/^# Finished Make data base/ {if ($$1 !~ "^[#.]") {print $$1}}' \
        | sort \
        | egrep -v -e '^[^[:alnum:]]' -e '^$@$$' \
        | xargs -I _ sh -c 'printf "%-20s " _; make _ -nB | (grep -i "^# Help:" || echo "") | tail -1 | sed "s/^# Help: //g"'

YAML_FILES := $(shell find . -path './venv_extensions' -prune -o -type f \( -name '*.yaml' -o -name '*.yml' \) -print )

yamllint: $(VENV_NAME) ## lint YAML files
	. ./$</bin/activate; set -u ;\
  yamllint --version ;\
  yamllint -s $(YAML_FILES)

mdlint: ## link MD files
    # download tool from https://github.com/igorshubovych/markdownlint-cli
	markdownlint --version ;\
	markdownlint "**/*.md" --ignore "CODE_OF_CONDUCT.md" --ignore "SECURITY.md" --ignore "CONTRIBUTING.md" --ignore "ci/*"

go-lint: $(OUT_DIR) ## Run go lint                                                                                
	golangci-lint --version
	golangci-lint run $(LINT_DIRS) --timeout 10m --config .golangci.yml

HELM_CHARTS := $(shell find . -type f -name 'Chart.yaml' -exec dirname {} \;)
.PHONY: helmlint
helmlint: ## lint helm charts
	@echo "Linting helm charts"
	set -e ;\
	$(foreach file,$(HELM_CHARTS),\
		helm lint $(file) ;\
    )
