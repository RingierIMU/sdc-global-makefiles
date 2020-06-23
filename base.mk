SHELL := /bin/bash

install-requirements:
	python -m pip install --upgrade pip;
	pip install -r requirements.txt;

install-local-requirements:
	python -m pip install --upgrade pip;
	pip install -r requirements.txt -t ./;

update-submodule:
	git submodule update --remote --merge
