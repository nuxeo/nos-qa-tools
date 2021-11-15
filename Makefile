this-mk:=$(lastword $(MAKEFILE_LIST))
this-dir:=$(realpath $(dir $(this-mk)))
top-dir:=$(this-dir)

maven~%: cmd  = mvn
maven~%: args  = $(version-mvn-jgitver-opts)
maven~%: args += -Dnexus-profile=$(call version-if-release,packages-private,team-private)
maven~%: args += -V -B -fae -nsu
maven~%: args += $(call make.if-trace,-X)
maven~%: args += $(if $(online),,-o)

include make.d/workspace.mk
include make.d/version.mk
include make.d/version-mvn.mk
include make.d/kustomizes/make.mk

# stages targets

workspace: ## setup workspace, including npm and environment variables

maven~clean: ## clean target folders
maven~clean:
	$(cmd) $(args) clean

maven~repository: ## download maven dependencies
maven~repository:
	$(cmd) $(args) de.qaware.maven:go-offline-maven-plugin:resolve-dependencies

maven~repository: online=true

maven~packages: ## compile java and node sources, build and install packages locally
maven~packages:
	$(cmd) $(args) -DskipTests install

maven~packages-and-deploy: ## deploy maven packages in nexus
	$(cmd) $(args) deploy -DskipTest 

maven~packages-and-deploy: online=true

maven~test:
	$(cmd) $(args) deploy test

unit-test-reports: ## run unit tests and generate reports
unit-test-reports: maven~test
