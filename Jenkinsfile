/*
 * (C) Copyright 2019 Nuxeo (http://nuxeo.com/) and others.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 * Contributors:
 *     Gildas Lefevre <glefevre@nuxeo.com>
 */

void setBuildStatus(context, message, state) {
    step([
        $class: 'GitHubCommitStatusSetter',
        contextSource: [$class: 'ManuallyEnteredCommitContextSource', context: context],
        errorHandlers: [[$class: 'ChangingBuildStatusErrorHandler', result: 'UNSTABLE']],
        reposSource: [$class: 'ManuallyEnteredRepositorySource', url: env.GIT_URL],
        statusResultSource: [$class: 'ConditionalStatusResultSource', results: [[$class: 'AnyBuildResult', message: message, state: state]]]
    ]);
}

def pullRequestLabels = []

def containerScript = ""

pipeline {
    options {
        skipDefaultCheckout()
        disableConcurrentBuilds()
        buildDiscarder(logRotator(daysToKeepStr: '60', numToKeepStr: '60', artifactNumToKeepStr: '1'))
    }
    agent {
        kubernetes {
            yamlMergeStrategy override()
            yamlFile 'Jenkinsfile-pod.yaml'
        }
    }
    stages {
        stage('Prepare workspace') {
            steps {
                container('maven') {
                    script {
                        def scmvars = checkout scm: [
                            $class: 'GitSCM',
                            branches: scm.branches,
                            doGenerateSubmoduleConfigurations: false,
                            extensions: [[$class: 'SubmoduleOption',
                                          disableSubmodules: false,
                                          parentCredentials: true,
                                          recursiveSubmodules: true,
                                          reference: '',
                                          trackingSubmodules: false],
                                         [$class: 'LocalBranch', localBranch: '**']],
                            submoduleCfg: [],
                            userRemoteConfigs: scm.userRemoteConfigs
                        ]
                        scmvars.each {key, val ->
                            env.setProperty(key, val)
                        }
                    }
                    sh 'make noop'
                }
            }
        }
        stage('Build maven repository') {
            steps {
                setBuildStatus('maven-repository', 'build maven repository', 'PENDING')
                container('maven') {
                    sh 'make maven-repository'
                }
            }
            post {
                success {
                    setBuildStatus('maven-repository', 'build maven repository', 'SUCCESS')
                }
                failure {
                    setBuildStatus('maven-repository', 'build maven repository', 'FAILURE')
                }
            }
        }
        stage('Build maven artifacts') {
            steps {
                setBuildStatus('maven-packages', 'build nodejs and install maven packages', 'PENDING')
                container('maven') {
                    sh 'make maven-packages'
                }
            }
            post {
                success {
                    setBuildStatus('maven-packages', 'build nodejs and install maven packages', 'SUCCESS')
                }
                failure {
                    setBuildStatus('maven-packages', 'build nodejs and install maven packages', 'FAILURE')
                }
            }
        }
        stage('Publish nexus maven packages') {
            steps {
                setBuildStatus('nexus-maven-packages', 'nexus maven packages', 'PENDING')
                container('maven') {
                    sh 'make nexus-maven-packages'
                }
            }
            post {
                success {
                    setBuildStatus('nexus-maven-packages', 'nexus maven packages', 'SUCCESS')
                }
                failure {
                    setBuildStatus('nexus-maven-packages', 'nexus maven packages', 'FAILURE')
                }
            }
        }
    }
}



// Local Variables:
// indent-tabs-mode: nil
// End:
