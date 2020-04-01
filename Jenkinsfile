#!groovy

def SLACK_CHANNEL = "tech-agent-delivery"

node {

  def DOCKER_REGISTRY_INTERNAL = "containers.instana.io"

  def STATIC_IMAGE_NAME = "instana/agent/static"
  def DYNAMIC_IMAGE_NAME = "instana/agent/dynamic"
  def RHEL_IMAGE_NAME = "instana/agent/rhel"

  def releaseVersion = getNextPatchVersion(env.INSTANA_SAAS_RELEASE, BUILD_NUMBER)
  currentBuild.displayName = "#${BUILD_NUMBER}:${releaseVersion}"

  stage ('Checkout Git Repo') {
    deleteDir()
    checkout scm
  }

  stage ('Build Dynamic Agent Docker Image') {
    println "Building dynamic agent docker image"
    buildImage(DYNAMIC_IMAGE_NAME, "dynamic", releaseVersion, null)
  }

  stage ('Build Static Agent Docker Image') {
    println "Building static agent docker image"
    buildImage(STATIC_IMAGE_NAME, "static", releaseVersion, "${DYNAMIC_IMAGE_NAME}:${releaseVersion}")
  }

  stage ('Build RHEL Agent Docker Image') {
    println "Building rhel agent docker image"
    buildImage(RHEL_IMAGE_NAME, "rhel", releaseVersion, null)
  }

  stage('Push to prerelease') {
    if (env.DRY_RUN.toBoolean()) {
      println "Skipping publish to prerelease!"
    } else {
      // Push docker images to prerelease
      println "Pushing images to prerelease"

      println "Push dynamic agent docker image to prerelease"
      publishImage(DYNAMIC_IMAGE_NAME, "${DOCKER_REGISTRY_INTERNAL}/instana/prerelease/agent/dynamic", releaseVersion)

      println "Push static agent docker image to prerelease"
      publishImage(STATIC_IMAGE_NAME, "${DOCKER_REGISTRY_INTERNAL}/instana/prerelease/agent/static", releaseVersion)

      println "Push rhel agent docker image to prerelease"
      publishImage(RHEL_IMAGE_NAME, "${DOCKER_REGISTRY_INTERNAL}/instana/prerelease/agent/rhel", releaseVersion)
    }
  }

  cleanUp()

  if (!env.DRY_RUN.toBoolean()) {
    slackSend channel: "#${SLACK_CHANNEL}", color: "#389a07", message: "Successfully build Instana agent docker ${releaseVersion} \n(<${env.BUILD_URL}|Open>)"
  }
}

def getNextPatchVersion(def saasVersion, def buildNumber) {
  def versionBaseDir = '/mnt/efs/data/instana-version'
  def patchMarkerFile = "${versionBaseDir}/agent-docker/${saasVersion}.number"

  if(fileExists("${patchMarkerFile}")) {
    def patchVersionNumberProp = readProperties file: patchMarkerFile

    def patchVersionNumber
    if (patchVersionNumberProp.buildNumber != buildNumber) {
      def currentPatchNumber = patchVersionNumberProp.value as Integer
      def nextPatchVersionNumber = currentPatchNumber + 1
      new File(patchMarkerFile).write(
        """value=${nextPatchVersionNumber}
        buildNumber=${buildNumber}
        """)
      patchVersionNumber = nextPatchVersionNumber
    } else {
      patchVersionNumber = patchVersionNumberProp.value as Integer
    }

    return "1.${saasVersion}.${patchVersionNumber}"
  } else {
    new File(patchMarkerFile).write(
      """value=0
    buildNumber=${buildNumber}
    """)
    return "1.${saasVersion}.0"
  }
}

def buildImage(name, context, releaseVersion, cacheFromImage) {
  def cacheFlag = cacheFromImage != null ? "--cache-from ${cacheFromImage}" : "--no-cache"
  try {
    sh """
      cp -r ./util ./${context}/
      docker build --pull ./${context} ${cacheFlag} --build-arg FTP_PROXY=${INSTANA_AGENT_KEY} --label "version=${releaseVersion}" -t ${name}:${releaseVersion}
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
