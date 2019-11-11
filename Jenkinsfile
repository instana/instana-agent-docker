#!groovy

def getNextPatchVersion(def saasVersion, def masterBuildNumber) {
  def versionBaseDir = '/mnt/efs/data/instana-version'
  def patchMarkerFile = "${versionBaseDir}/agent-docker/${saasVersion}.number"

  if(fileExists("${patchMarkerFile}")) {
    def patchVersionNumberProp = readProperties file: patchMarkerFile
    
    def patchVersionNumber
    if (patchVersionNumberProp.masterBuildNumber != masterBuildNumber) {
      def currentPatchNumber = patchVersionNumberProp.value as Integer
      def nextPatchVersionNumber = currentPatchNumber + 1
      new File(patchMarkerFile).write(
        """value=${nextPatchVersionNumber}
        masterBuildNumber=${masterBuildNumber}
        """) 
      patchVersionNumber = nextPatchVersionNumber 
    } else {
      patchVersionNumber = patchVersionNumberProp.value as Integer
    }

    return "1.${saasVersion}.${patchVersionNumber}"
  } else {
    new File(patchMarkerFile).write(
      """value=0
    masterBuildNumber=${masterBuildNumber}
    """)
    return "1.${saasVersion}.0"
  }
}

node {
  
  def DOCKER_REGISTRY_INTERNAL = "containers.instana.io"

  def STATIC_IMAGE_NAME = "instana/agent/static"
  def DYNAMIC_IMAGE_NAME = "instana/agent/dynamic"
  def RHEL_IMAGE_NAME = "instana/agent/rhel"

  def SLACK_CHANNEL = "tech-agent-delivery"

  def releaseVersion = getNextPatchVersion(env.INSTANA_SAAS_RELEASE, env.MASTER_BUILD_NUMBER)
  currentBuild.displayName = "#${BUILD_NUMBER}:${releaseVersion}"

  stage ('Checkout Git Repo') {
    deleteDir()
    checkout scm
  }

  stage ('Build Static Agent Docker Image') {
    if (env.STATIC.toBoolean()) {
      println "Building static agent docker image"
      buildImage(STATIC_IMAGE_NAME, "static", releaseVersion, "${DYNAMIC_IMAGE_NAME}:${releaseVersion}")
    }
  }

  stage ('Build Dynamic Agent Docker Image') {
    if (env.DYNAMIC.toBoolean()) {
      println "Building dynamic agent docker image"
      buildImage(DYNAMIC_IMAGE_NAME, "dynamic", releaseVersion, null)
    }
  }

  stage ('Build RHEL Agent Docker Image') {
    if (env.RHEL.toBoolean()) {
      println "Building rhel agent docker image"
      buildImage(RHEL_IMAGE_NAME, "rhel", releaseVersion, null)
    }
  }

  stage('Push Images to Docker Registry') {
    // Push docker images to prerelease
    println "Pushing images to prerelease"
    if (env.STATIC.toBoolean()) {
      println "Push static agent docker image to prerelease"
      publishImage(STATIC_IMAGE_NAME, "${DOCKER_REGISTRY_INTERNAL}/instana/prerelease/agent/static", releaseVersion)
    }

    if (env.DYNAMIC.toBoolean()) {
      println "Push dynamic agent docker image to prerelease"
      publishImage(DYNAMIC_IMAGE_NAME, "${DOCKER_REGISTRY_INTERNAL}/instana/prerelease/agent/dynamic", releaseVersion)
    }

    if (env.RHEL.toBoolean()) {
      println "Push rhel agent docker image to prerelease"
      publishImage(RHEL_IMAGE_NAME, "${DOCKER_REGISTRY_INTERNAL}/instana/prerelease/agent/rhel", releaseVersion)
    }
  }

  if (!env.DYNAMIC.toBoolean()) {
      cleanUp()
  }
  
  slackSend channel: "#${SLACK_CHANNEL}", color: "#389a07", message: "Successfully build Instana agent docker ${releaseVersion} \n(<${env.BUILD_URL}|Open>)"
}

def buildImage(name, context, releaseVersion, cacheFromImage) {
  def cacheFlag = cacheFromImage != null ? "--cache-from ${cacheFromImage}" : "--no-cache"
  try {
    sh """
      cp -r ./util ./${context}/
      docker build --pull ./${context} ${cacheFlag} --build-arg FTP_PROXY=${INSTANA_AGENT_KEY} -t ${name}:${releaseVersion}
    """
  } catch(e) {
    slackSend channel: "#${SLACK_CHANNEL}",
                color: "#ff5d00",
              message: """
      Failed to build Instana agent docker image for ${name}-${releaseVersion}.
      Reason: ${e.message}
      (<${env.BUILD_URL}|Open>)
      """
    cleanUp()
    throw e;
  }
}

def publishImage(sourceName, targetName, releaseVersion) {
  try {
    sh """
      docker tag ${sourceName}:${releaseVersion} ${targetName}:${releaseVersion}
      docker tag ${sourceName}:${releaseVersion} ${targetName}:latest
      docker push ${targetName}:${releaseVersion}
      docker push ${targetName}:latest
    """
  } catch(e) {
    slackSend channel: "#${SLACK_CHANNEL}",
                color: "#ff5d00",
              message: """
      Failed to push Instana agent docker image for ${name}-${releaseVersion}.
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
    IMAGES=$(docker images --format='{{.Repository}} {{.ID}}' | grep -E '.*instana.*agent.*' | cut -d ' ' -f 2 | uniq | tr '\n' ' ' | sed -e 's/[[:space:]]*$//')
    docker rmi --force $IMAGES
  '''
}
