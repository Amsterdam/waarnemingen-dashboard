#!groovy
def PROJECT_NAME = "waarnemingen-dashboard"
def SLACK_CHANNEL = '#waarnemingen-deployments'
def PLAYBOOK = 'deploy.yml'
def CMDB_ID = 'app_waarnemingen-dashboard'
def SLACK_MESSAGE = [
    "title_link": BUILD_URL,
    "fields": [
        ["title": "Project","value": PROJECT_NAME],
        ["title":"Branch", "value": BRANCH_NAME, "short":true],
        ["title":"Build number", "value": BUILD_NUMBER, "short":true]
    ]
]

pipeline {
    agent any

    environment {
        SHORT_UUID = sh( script: "uuidgen | cut -d '-' -f1", returnStdout: true).trim()
        COMPOSE_PROJECT_NAME = "${PROJECT_NAME}-${env.SHORT_UUID}"
        VERSION = env.BRANCH_NAME.replace('master', 'latest')
    }

    stages {
        stage('Test') {
            steps {
                sh 'make test'
            }
        }

        stage('Build') {
            steps {
                sh 'make build'
            }
        }

        stage('Push') {
            when {
                anyOf {
                    buildingTag()
                    branch 'master'
                }
            }
            steps {
                retry(3) {
                    sh 'make push'
                }
            }
        }

        stage('Deploy to acceptance') {
            when {
                tag pattern: "^(?i)\\d+\\.\\d+\\.\\d+(-rc.*)", comparator: "REGEXP"
            }
            steps {
                sh 'VERSION=acceptance make push'
                build job: 'Subtask_Openstack_Playbook', parameters: [
                    string(name: 'PLAYBOOK', value: PLAYBOOK),
                    string(name: 'INVENTORY', value: "acceptance"),
                    string(
                        name: 'PLAYBOOKPARAMS',
                        value: "-e 'deployversion=${VERSION} cmdb_id=${CMDB_ID}'"
                    )
                ], wait: true
            }
        }

        stage('Deploy to production') {
            when { 
                tag pattern: "^(?i)\\d+\\.\\d+\\.\\d+(?!-rc.*)", comparator: "REGEXP"
            }
            steps {
                sh 'VERSION=production make push'
                build job: 'Subtask_Openstack_Playbook', parameters: [
                    string(name: 'PLAYBOOK', value: PLAYBOOK),
                    string(name: 'INVENTORY', value: "production"),
                    string(
                        name: 'PLAYBOOKPARAMS',
                        value: "-e 'deployversion=${VERSION} cmdb_id=${CMDB_ID}'"
                    )
                ], wait: true

                slackSend(channel: SLACK_CHANNEL, attachments: [SLACK_MESSAGE <<
                    [
                        "color": "#36a64f",
                        "title": "Deploy to production succeeded :rocket:",
                    ]
                ])
            }
        }

    }
    post {
        always {
            sh 'make clean'
        }
        failure {
            slackSend(channel: SLACK_CHANNEL, attachments: [SLACK_MESSAGE <<
                [
                    "color": "#D53030",
                    "title": "Build failed :fire:",
                ]
            ])
        }
    }
}

