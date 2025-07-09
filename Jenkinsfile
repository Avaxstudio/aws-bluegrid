pipeline {
  agent any

  environment {
    SLACK_WEBHOOK = credentials('gs-rest-slack-hook')
    SLACK_WEBHOOK_MONITOR = credentials('gs-rest-monitor-hook')
  }

  stages {
    stage('Build') {
      steps {
        dir('complete') {
          sh './mvnw clean package'
        }
      }
    }

    stage('Run') {
      steps {
        dir('complete') {
          sh 'nohup java -jar target/*.jar &'
        }
      }
    }
  }

  post {
    always {
      sh "pkill -f 'java -jar' || true"
    }

    success {
      // ✅ Obaveštenje u glavni kanal
      sh """
      curl -X POST -H 'Content-type: application/json' \
      --data '{\"text\": \":white_check_mark: Build succeeded for *${env.JOB_NAME}* (#${env.BUILD_NUMBER})\"}' \
      "${env.SLACK_WEBHOOK}"
      """

      // 🛰️ Pokretanje monitoringa
      sh 'bash complete/monitor.sh &'

      // 📡 Obaveštenje u monitoring kanal
      sh """
      curl -X POST -H 'Content-type: application/json' \
      --data '{\"text\": \":satellite: Monitoring script started for build #${env.BUILD_NUMBER}\"}' \
      "${env.SLACK_WEBHOOK_MONITOR}"
      """
    }

    failure {
      // ❌ Obaveštenje u glavni kanal
      sh """
      curl -X POST -H 'Content-type: application/json' \
      --data '{\"text\": \":x: Build FAILED for *${env.JOB_NAME}* (#${env.BUILD_NUMBER})\"}' \
      "${env.SLACK_WEBHOOK}"
      """
    }
  }
}
