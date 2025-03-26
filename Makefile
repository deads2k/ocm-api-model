#
# Copyright (c) 2019 Red Hat, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

# Determine the operating system
ifeq ($(OS), Windows_NT)
	UNAME := windows
else
	UNAME := $(shell uname|tr '[:upper:]' '[:lower:]')
	ifeq ($(UNAME),darwin)
	else ifeq ($(UNAME),linux)
	else
        # Unsupported OS
        # this block uses spaces instead of tabs so that we can do proper indentation enforcement
        $(error This Makefile only supports Linux, macOS (Darwin), and Windows.)
	endif
endif

ifneq (, $(shell command -v shasum))
SHA256CMD := shasum -a 256 --check
else ifneq (, $(shell command -v sha256sum))
SHA256CMD := sha256sum --check
else
$(error "please install 'shasum' or 'sha256sum'")
endif

goimports_version:=v0.4.0

.PHONY: check
check: metamodel
	./metamodel check --model=model

.PHONY: openapi
openapi: metamodel
	./metamodel generate openapi --model=model --output=openapi

clientapi: metamodel goimports-install
	./metamodel generate go \
		--model=model \
		--generators=types,builders,json \
		--base=github.com/openshift-online/ocm-api-model/clientapi \
		--output=clientapi
	pushd clientapi; go mod tidy; popd

metamodel:
	go build github.com/openshift-online/ocm-api-metamodel/cmd/metamodel

# Enforce indentation by tabs. License contains 2 spaces, so reject 3+.
lint:
	find -name '*.model' -print0 | xargs -0 sh -c '! egrep --with-filename --line-number "^(   |\t+ )" "$$@"'

.PHONY: clean
clean:
	rm -rf \
		metamodel \
		openapi \
		clientapi/accesstransparency \
        clientapi/accountsmgmt \
        clientapi/addonsmgmt \
        clientapi/arohcp \
        clientapi/authorizations \
        clientapi/clustersmgmt \
        clientapi/helpers \
        clientapi/jobqueue \
        clientapi/osdfleetmgmt \
        clientapi/servicelogs \
        clientapi/servicemgmt \
        clientapi/statusboard \
        clientapi/webrca \
		$(NULL)

.PHONY: goimports-install
goimports-install:
	@GOBIN=$(LOCAL_BIN_PATH) go install golang.org/x/tools/cmd/goimports@$(goimports_version)

