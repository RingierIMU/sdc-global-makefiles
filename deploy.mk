SHELL := /bin/bash
AWS_CLI_URL="https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip"
MESSAGE ?= 'none'

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

	@if [ ${ERROR} ]; then\
		echo ${ERROR};exit 1; \
	fi

publish-lambda:
	$(eval VERSION := $(shell aws lambda publish-version --function-name  ${FUNCTION_NAME} --description "$(shell echo '${MESSAGE}' | cut -c1-250)" --query 'Version' --output text))
	aws lambda update-alias --function-name  ${FUNCTION_NAME} --name master --function-version ${VERSION}

update-glue:
	aws s3 cp ./scripts/${SCRIPT} s3://prod-recommendation/horizon/alice/scripts/${SCRIPT}
	aws glue update-job --job-name ${JOB_NAME} --job-update Role=AWSGlueServiceRole,Command="{Name=glueetl,ScriptLocation=s3://prod-recommendation/horizon/alice/scripts/${SCRIPT},PythonVersion=3}"
