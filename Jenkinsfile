pipeline {
#     agent { docker { image 'perl:threaded' } }
    agent { any }
    stages {
        stage('check') {
            steps {
                sh 'perl -V'
            }
        }

        stage('build Mir') {
            steps {
                sh 'cd src/Mir && perl Makefile.PL && cpan .'
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
