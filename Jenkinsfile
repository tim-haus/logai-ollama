pipeline {
    parameters {
      string(name: 'AGENT', description: 'Target agent to run against.')
      string(name: 'OLLAMA_MODEL', defaultValue: '', description: 'Model to use for the Ollama query. Leave blank to use the config.yml definition.')
      string(name: 'OLLAMA_SERVER', defaultValue: '', description: 'Ollama server address. Leave blank to use the config.yml definition.')
      choice(name: 'LOG_TYPE', choices: ['journalctl', 'file'], description: 'The type of log we\'re capturing.')
      string(name: 'LOG_FILE', defaultValue: '/var/logs/systemlog', description: 'Log file path. Unused if LOG_TYPE is "file".')
    }
    agent any

    stages {
        stage('Checkout') {
            steps {
                checkout([
                  $class: 'GitSCM',
                  branches: [[name: '*/main']],
                  userRemoteConfigs: [[url: 'git@github.com:tim-haus/logai-ollama.git']]
                ])
            }
        }
        stage('Analyze Log') {
          agent {
            label "${params.AGENT}"
          }
          steps {
            script {
            def cmd = "ruby ./query_ai.rb --type ${params.LOG_TYPE}"
            if (params.LOG_TYPE == 'file') {
                cmd += " --file ${params.LOG_FILE}"
            }
            if (params.OLLAMA_MODEL == '') {
                cmd += " --model ${params.OLLAMA_MODEL}"
            }
            if (params.OLLAMA_SERVER == '') {
                cmd += " --server ${params.OLLAMA_SERVER}"
            }
            echo "Running Command: ${cmd}"
            sh cmd
        }
          }
        }
    }
}
