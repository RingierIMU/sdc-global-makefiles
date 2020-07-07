SHELL := /bin/bash

install-requirements:
	python -m pip install --upgrade pip;
	pip install -r requirements.txt;

install-local-requirements:
	python -m pip install --upgrade pip;
	pip install -r requirements.txt -t ./;
	if [ -f "uninstall.txt" ]; then
	  pip uninstall -r uninstall.txt -y;
	fi

update-submodule:
	git submodule update --remote --merge

auto-lint:
	pip install --upgrade autopep8
	mkdir -p .git/hooks
	curl https://gist.githubusercontent.com/lucidlogic/ef3de91857197512944bcde82c5fdb03/raw/7d3e880e53f68935b50093fc0c9cfebf7a6669f7/pre-commit --output .git/hooks/pre-commit
	chmod +x .git/hooks/pre-commit
