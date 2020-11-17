pipeline {
  agent {
    kubernetes true
  }

  stages {
    stage('Hello World') {
      steps {
        echo "Hello world!!"
        sh 'env'
      }
    }
  }
}
