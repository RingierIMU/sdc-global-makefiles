SHELL := /bin/bash
TIMESTAMP := $(shell date +%Y-%m-%d_%H-%M-%S)
MYSQL_CREDS := $(if $(MYSQL_ALLOW_EMPTY_PASSWORD),-uroot,-uroot -p)
MYSQL_DATABASE ?= sdc
COVERAGE_THRESHOLD ?= 90

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

test-no-cover:
	pip install pytest mock pytest-mock pytest-console-scripts;
	pytest;

db-refresh:
	mysql -h127.0.0.1 ${MYSQL_CREDS} -e "DROP DATABASE IF EXISTS "${MYSQL_DATABASE}";";
	mysql -h127.0.0.1 ${MYSQL_CREDS} -e "CREATE DATABASE "${MYSQL_DATABASE}";";
	mysql -h127.0.0.1 ${MYSQL_CREDS} "${MYSQL_DATABASE}" < tests/db/schema.sql;

lint:
	pip install pylint;
	find . -type f -name "*.py" | xargs pylint --ignored-modules=pyspark,awsglue --extension-pkg-whitelist=pyspark,awsglue;

redis-flush:
	sudo apt-get install redis-tools;
	redis-cli FLUSHALL;

test-dependant:
	$(eval VERSION := $(shell grep ${PACKAGE_NAME}== requirements.txt | grep -Eo '[0-9]+([.][0-9]+)([.][0-9]+)?'))
	sed -i 's#${PACKAGE_NAME}==${VERSION}#git+https://lucidlogic:${GIT_ACCESS_TOKEN}@github.com/${REPO_NAME}/@${BRANCH_NAME}#g' requirements.txt
	make install-requirements;
	make hard-refresh;
	make test;

test-dependant-no-db:
	$(eval VERSION := $(shell grep ${PACKAGE_NAME}== requirements.txt | grep -Eo '[0-9]+([.][0-9]+)([.][0-9]+)?'))
	sed -i 's#${PACKAGE_NAME}==${VERSION}#git+https://lucidlogic:${GIT_ACCESS_TOKEN}@github.com/${REPO_NAME}/@${BRANCH_NAME}#g' requirements.txt
	make install-requirements;
	make test;
