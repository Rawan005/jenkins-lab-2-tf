pipeline {
    agent {
        docker {
        image "bryandollery/terraform-packer-aws-alpine"
        args "-u root --entrypoint=''"
        }
    }
    environment {
        CREDS = credentials('bryan_aws_creds')
        AWS_ACCESS_KEY_ID = "${CREDS_USR}"
        AWS_SECRET_ACCESS_KEY = "${CREDS_PSW}"
        OWNER = "bryan"
        PROJECT_NAME = 'web-server'
        AWS_PROFILE="kh-labs"
        TF_NAMESPACE="bryan"
    }
    stages {
        stage("init") {
            steps {
                sh 'make init'
            }
        }
        stage("workspace") {
            when {
              environment name: 'TF_NAMESPACE', value: 'bryan'
            }
            steps {
                sh """
                terraform workspace list | grep jenkins-lab-2
                if [[ \$? -ne 0 ]]; then
                    terraform workspace new jenkins-lab-2
                fi
                terraform workspace select jenkins-lab-2
                make init
                """
            }
        }
        stage("create"){
            when {
                anyOf {
                    triggeredBy 'UpstreamCause'
                    triggeredBy 'SCMTrigger'
                }
            }
            stages {
                stage("plan") {
                    steps {
                        sh 'make plan'
                    }
                }
                stage("apply") {
                    steps {
                        sh 'make apply'
                    }
                }
                stage('preserve keys') {
                    archiveArtifacts artifacts: 'ssh/*', defaultExcludes: false, onlyIfSuccessful: true
                }
            }
        }
        stage("destroy") {
            when {
                triggeredBy 'TimerTrigger'
            }
            stages {
                stage("down") {
                    steps {
                        sh 'make down'
                    }
                }
            }
        }
    }
}
