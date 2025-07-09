pipeline {
    agent any

    environment {
        APP_IMAGE = 'gs-rest-service'
        APP_CONTAINER = 'test-app'
        HOST_PORT = '777'
        CONTAINER_PORT = '8080'
        SLACK_WEBHOOK = credentials('gs-rest-slack-hook')
        SLACK_WEBHOOK_MONITOR = credentials('gs-rest-monitor-hook')
    }

    stages {
        stage('Notify Start') {
            steps {
                sh """
                    curl -X POST -H 'Content-type: application/json' \\
                    --data '{"text": ":rocket: Build started for *${env.JOB_NAME}* (#${env.BUILD_NUMBER})"}' \\
                    "${env.SLACK_WEBHOOK}"
                """
            }
        }

        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Build Docker Image') {
            steps {
                sh "docker build -t ${APP_IMAGE} ."
            }
        }

        stage('Notify Test Complete') {
            steps {
                sh """
                    curl -X POST -H 'Content-type: application/json' \\
                    --data '{"text": ":microscope: Tests completed for *${env.JOB_NAME}* (#${env.BUILD_NUMBER})"}' \\
                    "${env.SLACK_WEBHOOK}"
                """
            }
        }

        stage('Notify Test Results') {
            steps {
                script {
                    def testSummary = sh(
                        script: "mvn -B surefire-report:report-only | tee test_output.txt",
                        returnStdout: true
                    ).trim()

                    def filtered = sh(
                        script: "tail -n 30 test_output.txt | grep -E 'Tests run:|Failures:|Errors:|Skipped:' || echo 'No test summary found'",
                        returnStdout: true
                    ).trim()

                    def escaped = filtered.replace('"', '\\"').replace('\n', '\\n')

                    sh """
                        curl -X POST -H 'Content-type: application/json' \\
                        --data '{"text": ":bar_chart: *Test summary for* ${env.JOB_NAME} (#${env.BUILD_NUMBER}):\\n${escaped}"}' \\
                        "${env.SLACK_WEBHOOK}"
                    """
                }
            }
        }

        stage('Run Application') {
            steps {
                sh "docker run -d -p ${HOST_PORT}:${CONTAINER_PORT} --name ${APP_CONTAINER} ${APP_IMAGE}"
            }
        }
    }

    post {
    always {
        sh "docker rm -f ${APP_CONTAINER} || true"
    }

    success {
        sh 'bash monitor.sh &'

        sh """
            curl -X POST -H 'Content-type: application/json' \\
            --data '{"text": ":white_check_mark: Build succeeded for *${env.JOB_NAME}* (#${env.BUILD_NUMBER})"}' \\
            "${env.SLACK_WEBHOOK}"
        """
    }

    failure {
        sh """
            curl -X POST -H 'Content-type: application/json' \\
            --data '{"text": ":x: Build FAILED for *${env.JOB_NAME}* (#${env.BUILD_NUMBER})"}' \\
            "${env.SLACK_WEBHOOK}"
        """
    }
}

}
