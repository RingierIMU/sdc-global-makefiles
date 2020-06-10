SHELL := /bin/bash
TIMESTAMP := $(shell date +%Y-%m-%d_%H-%M-%S)
MYSQL_CREDS := $(if $(MYSQL_ALLOW_EMPTY_PASSWORD),-uroot,-uroot -p)
MYSQL_DATABASE ?= sdc
COVERAGE_THRESHOLD ?= 90
REPO_NAME ?= ''
UNAME := $(shell uname -m)
CURRENT_DIR= $(shell pwd)

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

get-notify-merge-json:
	@echo '{
            \"channel\":\"G010246RK26\",
            \"attachments\":[
              {
                \"text\":\"${USER} triggered a deploy of `master` for commit `"${MESSAGE}"` (`${SHA}`) to *Lambda Production*. :excited:" \",
                \"color\":\"#4d91f7\",
                \"title\":\"${REPO}\"
              }
            ]
          }'

init:
	ln -s make/Makefile ../Makefile
