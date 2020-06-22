SHELL := /bin/bash
TIMESTAMP := $(shell date +%Y-%m-%d_%H-%M-%S)
MYSQL_CREDS := $(if $(MYSQL_ALLOW_EMPTY_PASSWORD),-uroot,-uroot -p)
MYSQL_DATABASE ?= sdc
COVERAGE_THRESHOLD ?= 90
REPO_NAME ?= ''
UNAME := $(shell uname -m)
CURRENT_DIR= $(shell pwd)
AWS_CLI_URL="https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip"
MESSAGE ?= 'none'

build:
	make install-requirements;
	make hard-refresh;
	make test;
	make lint;

hard-refresh:
	make db-refresh;
	make redis-flush;

test:
	pip install pytest mock pytest-mock coverage;
	coverage run -m pytest;
	coverage report --fail-under=${COVERAGE_THRESHOLD}

install-requirements:
	python -m pip install --upgrade pip;
	pip install -r requirements.txt;

install-local-requirements:
	python -m pip install --upgrade pip;
	pip install -r requirements.txt -t ./;

db-refresh:
	mysql -h127.0.0.1 ${MYSQL_CREDS} -e "DROP DATABASE IF EXISTS "${MYSQL_DATABASE}";";
	mysql -h127.0.0.1 ${MYSQL_CREDS} -e "CREATE DATABASE "${MYSQL_DATABASE}";";
	mysql -h127.0.0.1 ${MYSQL_CREDS} "${MYSQL_DATABASE}" < tests/db/schema.sql;

lint:
	pip install pylint;
	find . -type f -name "*.py" | xargs pylint;

redis-flush:
	sudo apt-get install redis-tools;
	redis-cli FLUSHALL;

test-dependant:
	sed -i 's#${PACKAGE_NAME}==${VERSION}#git+https://lucidlogic:${ACCESS_TOKEN}@github.com/${REPO_NAME}/@${BRANCH_NAME}#g' requirements.txt
	make install-requirements;
	make hard-refresh;
	make test;

test-dependant-no-db:
	sed -i 's#${PACKAGE_NAME}==${VERSION}#git+https://lucidlogic:${ACCESS_TOKEN}@github.com/${REPO_NAME}/@${BRANCH_NAME}#g' requirements.txt
	make install-requirements;
	make test;

update-submodule:
	git submodule update --remote --merge

install-aws-cli:
	curl $(AWS_CLI_URL) -o "awscliv2.zip"
	unzip awscliv2.zip
	sudo ./aws/install
	aws --version

update-lambda:
	aws lambda update-function-code --function-name  ${FUNCTION_NAME} --zip-file fileb://lambda.zip

invoke:
	aws lambda invoke --function-name  ${FUNCTION_NAME} --payload ${PAYLOAD} ./response.json

check-response:
	$(eval ERROR := $(shell jq 'select(.errorMessage != null) | .errorMessage' ./response.json))

	if [ ${ERROR} ]; then\
		echo ${ERROR};exit 1; \
	fi

publish-lambda:
	$(eval VERSION := $(shell aws lambda publish-version --function-name  ${FUNCTION_NAME} --description "${MESSAGE:0:250}" --query 'Version' --output text))
	aws lambda update-alias --function-name  ${FUNCTION_NAME} --name master --function-version ${VERSION}

update-version:
	$(eval VERSION := $(shell grep version= setup.py | grep -Eo '[0-9]+([.][0-9]+)([.][0-9]+)?'));
	$(eval REMOVE="refs/tags/v");
	$(eval NEW_VERSION=${REF//$(REMOVE)/})
	sed -i "s#${VERSION}#${NEW_VERSION}#g" setup.py

init:
	ln -s make/Makefile ../Makefile
