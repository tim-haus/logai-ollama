pipeline {
    parameters {
      choice(name: 'LOG_TYPE', choices: ['journalctl', 'file'], description: 'The type of log we\'re capturing.')
      string(name: 'LOG_FILE', defaultValue: '/var/logs/systemlog', description: 'Log file path. Unused if LOG_TYPE is "file".')
    }
    agent any

    stages {
        stage('Checkout') {
            steps {
                // Git Checkout here
            }
        }
        stage('Analyze Log') {
          steps {
            sh 'ruby ./query_ai.rb'
          }
        }
    }
}
