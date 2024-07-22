SPLITD_URL := https://github.com/splitio/splitd/releases/download/v1.4.0/splitd-darwin-arm-1.4.0.bin

.PHONY: start_splitd

SPLITD ?= $(shell which splitd || which ./splitd || \
            (wget --no-check-certificate -O splitd $(SPLITD_URL) && \
	      chmod +x splitd && echo ./splitd))


start_splitd:
	SPLITD_CONF_FILE=support/splitd.yaml $(SPLITD)
