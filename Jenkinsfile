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

bootstrapTemplate = readTrusted('Jenkinsfile-pod.yaml')
env.setProperty('POD_TEMPLATE', bootstrapTemplate)

pipeline {
    options {
        skipDefaultCheckout()
        disableConcurrentBuilds()
        buildDiscarder(logRotator(daysToKeepStr: '60', numToKeepStr: '60', artifactNumToKeepStr: '1'))
    }
    agent {
        kubernetes {
            yamlMergeStrategy override()
            yaml "${POD_TEMPLATE}"
            defaultContainer 'maven'
        }
    }
    stages {
        stage('Prepare workspace') {
            steps {
                checkout scm: [
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
            }
        }
        stage('Build maven repository') {
            steps {
                gitStatusWrapper(credentialsId: 'pipeline-git-github',
                                 description: 'build maven repository',
                                 failureDescription: 'build maven repository',
                                 gitHubContext: 'maven-repository',
                                 successDescription: 'build maven repository') {
                    sh 'make maven~repository'
                }
            }
        }
        // stage('Unit test reports') {
        //     steps {
        //         gitStatusWrapper(credentialsId: 'pipeline-git-github',
        //                          gitHubContext: 'unit-test-reports',
        //                          description: 'run unit tests and generate reports',
        //                          successDescription: 'run unit tests and generate reports',
        //                          failureDescription: 'run unit tests and generate reports') {
        //             catchError(buildResult: 'FAILURE', stageResult: 'FAILURE') {
        //                 sh 'make unit-test-reports'
        //             }
        //         }
        //     }
        //     post {
        //         always {
        //             junit testResults: '**/target/surefire-reports/*.xml, **/target/failsafe-reports/*.xml'
        //         }
        //     }
        // }
        stage('Build maven artifacts') {
            steps {
                gitStatusWrapper(credentialsId: 'pipeline-git-github',
                                 gitHubContext: 'maven-packages-and-deploy',
                                 description: 'build and deploy maven packages',
                                 successDescription: 'build and deploy maven packages',
                                 failureDescription: 'build and deploy maven packages') {
                    sh 'make maven~packages-and-deploy'
                }
            }
        }
    }
}

// Local Variables:
// indent-tabs-mode: nil
// End:
