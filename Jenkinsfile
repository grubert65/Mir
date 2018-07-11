pipeline {
    agent { docker { image 'perl:threaded' } }
    stages {
        stage('check') {
            steps {
                sh 'perl -V'
            }
        }

        stage('build Makefile') {
            steps {
                sh 'perl Makefile.PL'
            }
        }

        stage('build') {
            steps {
                sh 'make'
            }
        }

        stage('test') {
            steps {
                sh 'make test'
            }
        }
    }
}
