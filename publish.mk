SHELL := /bin/bash

update-version:
	$(eval VERSION := $(shell grep version= setup.py | grep -Eo '[0-9]+([.][0-9]+)([.][0-9]+)?'))
	sed -i 's#${VERSION}#$(REF:refs/tags/v%=%)#g' setup.py
