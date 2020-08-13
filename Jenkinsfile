pipeline {
    agent {
        docker {
        image "bryandollery/terraform-packer-aws-alpine"
        args "-u root --entrypoint=''"
        }
    }
    parameters {
        booleanParam defaultValue: false, description: 'True if you want to destroy the estate. Defaults to false.', name: 'Destroy'
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
        stage("create"){
            when {
              environment name: 'Destroy', value: 'false'
            }
            stage("init") {
                steps {
                    sh 'make init'
                }
            }
            stage("workspace") {
                steps {
                    sh """
                    terraform workspace select jenkins-lab-2
                    if [[ \$? -ne 0 ]]; then
                    terraform workspace new jenkins-lab-2
                    fi
                    make init
                    """
                }
            }
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
        stage("destroy") {
            when {
              environment name: 'Destroy', value: 'true'
            }
            stage("workspace") {
                steps {
                    sh """
                    make init
                    terraform workspace select jenkins-lab-2
                    if [[ \$? -ne 0 ]]; then
                    terraform workspace new jenkins-lab-2
                    fi
                    make init
                    """
                }
            }
            stage("down") {
                steps {
                    sh 'make down'
                }
            }
        }
    }
}
