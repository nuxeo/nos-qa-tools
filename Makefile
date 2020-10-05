this-mk:=$(lastword $(MAKEFILE_LIST))
this-dir:=$(realpath $(dir $(this-mk)))
top-dir:=$(this-dir)

#__ORIGINAL_SHELL:=$(SHELL)
#SHELL=$(warning Building $@$(if $<, (from $<))$(if $?, ($? newer)))$(TIME) $(__ORIGINAL_SHELL) -x

include make.d/workspace.mk

# stages targets

noop: ## do nothing, setup make cache rules
noop: ; @:

workspace: ## setup workspace, including npm and environment variables

maven-clean: ## clean target folders
maven-clean:
	mvn clean

maven-repository: ## download maven dependencies
maven-repository:
	mvn -V -B -nsu de.qaware.maven:go-offline-maven-plugin:resolve-dependencies

maven-packages: ## compile java and node sources, build and install packages locally
maven-packages:
	mvn -V -B -o -nsu -T0.8C -DskipTests install

nexus-maven-packages: ## deploy maven packages in nexus
	mvn -V -B -nsu deploy

unit-test-reports: ## run unit tests and generate reports
unit-test-reports:
	mvn -V -B -o -nsu -T0.8C -fae test

