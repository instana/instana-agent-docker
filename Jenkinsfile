#!groovy

DOCKER_REGISTRY_INTERNAL = "containers.instana.io"
SLACK_CHANNEL = "tech-sre-status"

currentBuild.displayName = "#${BUILD_NUMBER}:${env.INSTANA_AGENT_RELEASE}"

node {
  stage ('Checkout Git Repo') {
    deleteDir()
    checkout scm
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
        publishImage("${DOCKER_REGISTRY_INTERNAL}/instana/release/agent/rhel")
      }
    }
  }
  
  cleanUp()
  slackSend channel: "#${SLACK_CHANNEL}", color: "#389a07", message: "Successfully build Instana agent docker ${INSTANA_AGENT_RELEASE} \n(<${env.BUILD_URL}|Open>)"
}

def buildImage(name, context) {
  try {
    sh """
      docker build ./${context} --build-arg FTP_PROXY=${INSTANA_AGENT_KEY} --no-cache -t instana/agent/${name}:${INSTANA_AGENT_RELEASE}
    """
  } catch(e) {
    slackSend channel: "#${SLACK_CHANNEL}",
                color: "#ff5d00",
              message: """
      Failed to build Instana agent docker image for ${name}-${INSTANA_AGENT_RELEASE}.
      Reason: ${e.message}
      (<${env.BUILD_URL}|Open>)
      """
    cleanUp()
    throw e;
  }
}

def publishImage(name) {
  try {
    sh """
      echo "docker tag ${name}:${INSTANA_AGENT_RELEASE}"
      echo "docker tag ${name}:latest"
      echo "docker push ${name}:${INSTANA_AGENT_RELEASE}"
      echo "docker push ${name}:latest"
    """
  } catch(e) {
    slackSend channel: "#${SLACK_CHANNEL}",
                color: "#ff5d00",
              message: """
      Failed to push Instana agent docker image for ${name}-${INSTANA_AGENT_RELEASE}.
      Reason: ${e.message}
      (<${env.BUILD_URL}|Open>)
    """
    cleanUp()
    throw e;
  } 
}

def cleanUp() {
  sh """
    docker images --format='{{.Repository}} {{.ID}}' | grep -E '.*instana.*agent.*' | xargs docker rmi | true
  """
}
