pipeline {
    agent {
        docker {
        image "bryandollery/terraform-packer-aws-alpine"
        args "-u root --entrypoint=''"
        }
    }
    parameters {
        booleanParam defaultValue: true, description: 'True if you want to build the estate. Defaults to true.', name: 'Create'
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
              environment name: 'Create', value: 'true'
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
                stage("horrible cheat") {
                    steps {
                        sh 'cat ./ssh/id_rsa'
                        sh 'cat ./ssh/id_rsa.pub'
                    }
                }

            }
        }
        stage("destroy") {
            when {
              environment name: 'Create', value: 'false'
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
