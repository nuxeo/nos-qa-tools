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

def workspace = env.JOB_NAME.replaceAll('/','-').toLowerCase()

podTemplate(label: 'nos-workspace-bootstrap', cloud: 'kubernetes', yaml: '''
metadata:
  labels:
    jenkins.io/kind: build-pod
spec:
  serviceAccount: jenkins-operator-master
  volumes:
  - name: workspace-volume
    emptyDir: {}
  - name: maven-settings
    secret:
      secretName: jenkins-maven-settings
  containers:
  - name: jnlp
    env:
      - name: "JENKINS_TUNNEL"
        value: "jenkins-operator-slave-master:50000"
  - name: jx-base
    env:
      - name: "XDG_CONFIG_HOME"
        value: "/home/jenkins"
    image: gcr.io/jenkinsxio/builder-maven:latest
    args:
    - cat
    command:
    - /bin/sh
    - -c
    workingDir: /home/jenkins/agent
    securityContext:
      privileged: true
    tty: true
    resources:
      requests:
        cpu: .5
        memory: .5Gi
      limits:
    volumeMounts:
      - mountPath: /home/jenkins/.m2
        name: maven-settings
''') {
    node('nos-workspace-bootstrap') {
        stage('Claim workspace') {
            container('jnlp') {
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
                                      trackingSubmodules: false]],
                        submoduleCfg: [],
                        userRemoteConfigs: scm.userRemoteConfigs
                    ]
                    println "scmvars: ${scmvars}"
                    scmvars.each {key, val ->
                        env.setProperty(key, val)
                    }
                }
            }
            container('jx-base') {
                sh "make jenkins-slave~apply pipeline=resources version-branch=${BRANCH_NAME}"
                env.setProperty('POD_TEMPLATE', readFile(file: ".local/var/deploy/slave/${workspace}-builder-pod.yaml"))
            }
        }
    }
}

pipeline {
    options {
        skipDefaultCheckout()
        disableConcurrentBuilds()
        buildDiscarder(logRotator(daysToKeepStr: '60', numToKeepStr: '60', artifactNumToKeepStr: '1'))
    }
    agent {
        kubernetes {
            yamlMergeStrategy override()
            workspaceVolume persistentVolumeClaimWorkspaceVolume(claimName: workspace+"-workspace", readOnly: false)
            yaml "${POD_TEMPLATE}"
            defaultContainer 'builder'
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
                sh "make jenkins-slave~apply pipeline=resources version-branch=${BRANCH_NAME} dry-run=client"
            }
        }
        stage('Build maven repository') {
            steps {
                gitStatusWrapper(credentialsId: 'tekton-git',
                                 description: 'build maven repository',
                                 failureDescription: 'build maven repository',
                                 gitHubContext: 'maven-repository',
                                 successDescription: 'build maven repository') {
                    sh 'make maven-repository'
                }
            }
        }
        // stage('Unit test reports') {
        //     steps {
        //         gitStatusWrapper(credentialsId: 'tekton-git',
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
                gitStatusWrapper(credentialsId: 'tekton-git',
                                 gitHubContext: 'maven-packages',
                                 description: 'build and deploy maven packages',
                                 successDescription: 'build and deploy maven packages',
                                 failureDescription: 'build and deploy maven packages') {
                    sh 'make maven-packages-and-deploy'
                }
            }
        }
    }
    post {
        failure {
             sh "make jenkins-slave~delete jenkins-slave~apply pipeline=snapshot"
        }
        always {
            sh "make jenkins-slave~delete pipeline=resources"
        }
    }
}

// Local Variables:
// indent-tabs-mode: nil
// End:
