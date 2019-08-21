#!groovy

DOCKER_REGISTRY_INTERNAL = "containers.instana.io"

STATIC_IMAGE_NAME = "instana/agent/static"
DYNAMIC_IMAGE_NAME = "instana/agent/dynamic"
RHEL_IMAGE_NAME = "instana/agent/rhel"

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
      buildImage(STATIC_IMAGE_NAME, "static")
    }
  }

  stage ('Build Dynamic Agent Docker Image') {
    if (env.DYNAMIC.toBoolean()) {
      println "Building dynamic agent docker image"
      buildImage(DYNAMIC_IMAGE_NAME, "dynamic")
    }
  }

  stage ('Build RHEL Agent Docker Image') {
    if (env.RHEL.toBoolean()) {
      println "Building rhel agent docker image"
      buildImage(RHEL_IMAGE_NAME, "rhel")
    }
  }

  stage('Push Images to Docker Registry') {
    // Push docker images to prerelease
    println "Pushing images to prerelease"
    if (env.STATIC.toBoolean()) {
      println "Push static agent docker image to prerelease"
      publishImage(STATIC_IMAGE_NAME, "${DOCKER_REGISTRY_INTERNAL}/instana/prerelease/agent/static")
    }

    if (env.DYNAMIC.toBoolean()) {
      println "Push dynamic agent docker image to prerelease"
      publishImage(DYNAMIC_IMAGE_NAME, "${DOCKER_REGISTRY_INTERNAL}/instana/prerelease/agent/dynamic")
    }

    if (env.RHEL.toBoolean()) {
      println "Push rhel agent docker image to prerelease"
      publishImage(RHEL_IMAGE_NAME, "${DOCKER_REGISTRY_INTERNAL}/instana/prerelease/agent/rhel")
    }

    // Push docker images to release
    if ("${PUBLISH}" == "YES") {
      println "Pushing images to release"
      if (env.STATIC.toBoolean()) {
        println "Push static agent docker image to release"
        publishImage(STATIC_IMAGE_NAME, "instana/agent-static")
        publishImage(STATIC_IMAGE_NAME, "${DOCKER_REGISTRY_INTERNAL}/instana/release/agent/static")
      }

      if (env.DYNAMIC.toBoolean()) {
        println "Push dynamic agent docker image to release"
        publishImage(DYNAMIC_IMAGE_NAME, "instana/agent")
        publishImage(DYNAMIC_IMAGE_NAME, "${DOCKER_REGISTRY_INTERNAL}/instana/release/agent/dynamic")
      }

      if (env.RHEL.toBoolean()) {
        println "Push rhel agent docker image to release"
        publishImage(RHEL_IMAGE_NAME, "instana/agent-rhel")
        publishImage(RHEL_IMAGE_NAME, "${DOCKER_REGISTRY_INTERNAL}/instana/release/agent/rhel")
      }
    }
  }
  
  cleanUp()
  slackSend channel: "#${SLACK_CHANNEL}", color: "#389a07", message: "Successfully build Instana agent docker ${INSTANA_AGENT_RELEASE} \n(<${env.BUILD_URL}|Open>)"
}

def buildImage(name, context) {
  try {
    sh """
      docker build ./${context} --build-arg FTP_PROXY=${INSTANA_AGENT_KEY} --no-cache -t ${name}:${INSTANA_AGENT_RELEASE}
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

def publishImage(sourceName, targetName) {
  try {
    sh """
      docker tag ${sourceName}:${INSTANA_AGENT_RELEASE} ${targetName}:${INSTANA_AGENT_RELEASE}
      docker tag ${sourceName}:${INSTANA_AGENT_RELEASE} ${targetName}:latest
      echo "docker push ${targetName}:${INSTANA_AGENT_RELEASE}"
      echo "docker push ${targetName}:latest"
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
  println "Cleaning up docker images"
  sh '''
    images=$(docker images --format='{{.Repository}} {{.ID}}' | grep -E '.*instana.*agent.*' | cut -d ' ' -f 2)
    if [[ ! -z "${images}" ]]; then 
      docker rmi ${images}
    fi
  '''
}
