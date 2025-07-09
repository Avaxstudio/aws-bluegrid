pipeline {
  agent any

  tools {
    maven 'Maven3'
  }

  environment {
    SLACK_WEBHOOK = credentials('gs-rest-slack-hook')
  }

  stages {
    stage('Build') {
      steps {
        sh './mvnw clean package'
      }
    }
    stage('Run') {
      steps {
        sh 'nohup java -jar target/*.jar &'
      }
    }
  }

  post {
    always {
      sh "pkill -f 'java -jar' || true"
    }
    success {
      sh 'bash monitor.sh &'
      sh """
      curl -X POST -H 'Content-type: application/json' \
      --data '{\"text\": \":white_check_mark: Build succeeded for *${env.JOB_NAME}* (#${env.BUILD_NUMBER})\"}' \
      "${env.SLACK_WEBHOOK}"
      """
    }
    failure {
      sh """
      curl -X POST -H 'Content-type: application/json' \
      --data '{\"text\": \":x: Build FAILED for *${env.JOB_NAME}* (#${env.BUILD_NUMBER})\"}' \
      "${env.SLACK_WEBHOOK}"
      """
    }
  }
}
