ifeq ($(shell uname -s),Darwin)
OS=darwin
else ifeq ($(OS),Linux)
OS=linux
endif

ARCH := $(shell uname -p)

SPLITD_VERSION := 1.4.0
SPLITD_URL := https://github.com/splitio/splitd/releases/download/v1.4.0/splitd-${OS}-${ARCH}-${SPLITD_VERSION}.bin

SPLITD ?= $(shell which splitd || which ./splitd || \
            (wget --no-check-certificate -O splitd $(SPLITD_URL) && \
	      chmod +x splitd && echo ./splitd))

.PHONY: start_splitd
start_splitd: support/splitd.yaml
	SPLITD_CONF_FILE=support/splitd.yaml $(SPLITD)

support/splitd.yaml: support/splitd.yaml.tmpl
	@export \
		  SPLITD_APIKEY="$(SPLITD_APIKEY)" \
		  && cat $< | envsubst > $@

.PHONY: clean
clean:
	rm -vf ./splitd
	rm -vf support/splitd.yaml
