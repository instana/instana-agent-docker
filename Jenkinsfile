#!groovy

DOCKER_REGISTRY_INTERNAL = "containers.instana.io"

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
          buildImage("dynamic", "dynamic")
      }
    }

    stage ('Build RHEL Agent Docker Image') {
      if (env.RHEL.toBoolean()) {
          println "Building rhel agent docker image"
          buildImage("rhel", "rhel")
      }
    }

    stage('Push Images to Docker Registry') {
      // Push docker images to prerelease
      println "Pushing images to prerelease"
      if (env.STATIC.toBoolean()) {
          println "Push static agent docker image to prerelease"
          publishImage("${DOCKER_REGISTRY_INTERNAL}/instana/prerelease/agent/static")
      }

      if (env.DYNAMIC.toBoolean()) {
          println "Push dynamic agent docker image to prerelease"
          publishImage("${DOCKER_REGISTRY_INTERNAL}/instana/prerelease/agent/dynamic")
      }

      if (env.RHEL.toBoolean()) {
          println "Push rhel agent docker image to prerelease"
          publishImage("${DOCKER_REGISTRY_INTERNAL}/instana/prerelease/agent/rhel")
      }

      // Push docker images to release
      if ("${PUBLISH}" == "YES") {
        println "Pushing images to release"
        if (env.STATIC.toBoolean()) {
          println "Push static agent docker image to release"
          publishImage("instana/agent-static")
          publishImage("${DOCKER_REGISTRY_INTERNAL}/instana/release/agent/static")
      }

        if (env.DYNAMIC.toBoolean()) {
            println "Push dynamic agent docker image to release"
            publishImage("instana/agent")
            publishImage("${DOCKER_REGISTRY_INTERNAL}/instana/release/agent/dynamic")
        }

        if (env.RHEL.toBoolean()) {
            println "Push rhel agent docker image to release"
            publishImage("instana/agent-rhel")
            publishImage("${DOCKER_REGISTRY_INTERNAL}/instana/release/agent/rhel)
        }
      }
    }
}

def buildImage(name, context) {
  sh """
      docker build ./${context} --build-arg FTP_PROXY=${INSTANA_AGENT_KEY} --no-cache -t instana/agent/${name}:${INSTANA_AGENT_RELEASE}
    """
}

def publishImage(name) {
  sh """
      echo "docker tag ${name}:${INSTANA_AGENT_RELEASE}"
      echo "docker tag ${name}:latest"
      echo "docker push ${name}:${INSTANA_AGENT_RELEASE}"
      echo "docker push ${name}:latest"
    """
}


