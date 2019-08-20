#!groovy

node {

    stage ('Checkout Git Repo') {
        deleteDir()
        checkout scm
        // Debug
        sh "git status"
    }

    stage ('Build Static Agent Docker Image') {
      if (env.STATIC.toBoolean()) {
          println "Building static agent docker image"
          buildImage("static", "static")
      }
    }

    stage ('Build Dynamic Agent Docker Image') {
      if (env.DYNAMIC.toBoolean()) {
          println "Building dynamic agent docker image"
      }
    }

    stage ('Build RHEL Agent Docker Image') {
      if (env.RHEL.toBoolean()) {
          println "Building rhel agent docker image"
      }
    }

    stage('Push Docker Registry') {
      println "Pushing images to prerelease"

      if("${PUBLISH}" != "YES") {
        println "Pushing images to release"
      }
    }
}

def buildImage(name, context) {
  sh """
        docker build ./${context} --build-arg FTP_PROXY=${INSTANA_AGENT_KEY} --no-cache -t instana/agent/${name}:${INSTANA_AGENT_RELEASE}
      """
}


