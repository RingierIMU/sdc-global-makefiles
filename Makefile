SHELL := /bin/bash
TIMESTAMP := $(shell date +%Y-%m-%d_%H-%M-%S)
MYSQL_CREDS := $(if $(MYSQL_ALLOW_EMPTY_PASSWORD),-uroot,-uroot -p)
MYSQL_DATABASE ?= sdc
COVERAGE_THRESHOLD ?= 90
COVERAGE_TOTAL ?= `jq '.totals.percent_covered?' coverage.json`
UNAME := $(shell uname -m)

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

checkout-dependant:
	git clone https://lucidlogic:${GIT_ACCESS_TOKEN}@github.com/RingierIMU/${REPO_NAME}.git
	cd ${REPO_NAME}
	VERSION=$(grep ${PACKAGE_NAME}== requirements.txt | grep -Eo '[0-9]+([.][0-9]+)?');
	sed -i 's#${PACKAGE_NAME}==$VERSION#git+ssh://git@github.com/${{ github.repository }}/@${{ github.head_ref }}#g' requirements.txt
