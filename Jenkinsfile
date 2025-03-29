pipeline {
    agent {
        label 'terraform'  // Run on the worker node
    }

    environment {
        AWS_ACCESS_KEY_ID     = credentials('aws_access_key')
        AWS_SECRET_ACCESS_KEY = credentials('aws_secret_key')
        AWS_REGION            = 'ap-south-1'          // Hardcoded region
        S3_BUCKET_NAME        = '34th-cherry-bucket'       // Hardcoded S3 bucket name
        TF_STATE_BUCKET       = 'my-terraform-state'  // S3 bucket for storing state
        DYNAMODB_TABLE        = 'my-terraform-lock'   // DynamoDB for state locking
    }

    stages {
        stage('Setup AWS Credentials') {
            steps {
                echo 'Setting up AWS credentials...'
                sh '''
                mkdir -p ~/.aws
                cat <<EOT > ~/.aws/credentials
                [default]
                aws_access_key_id = ${AWS_ACCESS_KEY_ID}
                aws_secret_access_key = ${AWS_SECRET_ACCESS_KEY}
                EOT

                cat <<EOT > ~/.aws/config
                [default]
                region = ${AWS_REGION}
                EOT

                chmod 600 ~/.aws/credentials ~/.aws/config
                '''
            }
        }

        stage('Clone Repository') {
            steps {
                echo 'Cloning GitHub repository...'
                git branch: 'main', url: 'https://github.com/supriya16-git/terraform-auto.git'
            }
        }

        stage('Terraform Init & Apply') {
            steps {
                echo 'Initializing and applying Terraform...'
                dir('Terraform') {
                    sh '''
                    terraform init -backend-config="bucket=${TF_STATE_BUCKET}" \
                                   -backend-config="key=jenkins-terraform.tfstate" \
                                   -backend-config="region=${AWS_REGION}" \
                                   -backend-config="dynamodb_table=${DYNAMODB_TABLE}"

                    terraform apply -auto-approve
                    '''
                }
            }
        }

        stage('Fetch Public IP & Create Inventory') {
            steps {
                echo 'Fetching public IP and creating inventory...'
                script {
                    def public_ip = sh(script: '''
                        cd Terraform
                        terraform output -raw instance_ip
                    ''', returnStdout: true).trim()

                    if (public_ip == null || public_ip == "") {
                        error("Failed to fetch public IP. Check your Terraform output configuration.")
                    }

                    echo "Public IP: ${public_ip}"
            
                    // Correct inventory format with new public IP
                   writeFile file: '/home/ubuntu/automation/Ansible/inventory.ini', text: "[webserver]\n${public_ip} ansible_user=ubuntu"
                 }
            }
      }

      stage('Checkout Code') {
          steps {
              checkout scm
              }
          }

      stage('Run Ansible Playbook') {
          steps {
              echo 'Running Ansible Playbook...'
              dir('automation/Ansible') {
                  sh '''
                  echo "Current Directory:"
                  pwd
                  echo "Listing Files:"
                  ls -l
                  ansible-playbook -i inventory.ini playbook.yml
                  '''
                }  
            }
        }

        stage('Create S3 Bucket') {
            steps {
                echo 'Creating S3 bucket...'
                sh '''
                aws s3 mb s3://${S3_BUCKET_NAME}
                '''
            }
        }
    }

    post {
        always {
            echo 'Cleaning workspace...'
            cleanWs()
        }
    }
}

