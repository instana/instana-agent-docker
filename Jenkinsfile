#!groovy

stage ('Container Build') {
  node {
    deleteDir()
    checkout scm  
    // TODO: Add build status "PENDING"

    try {
      sh "./build.sh" 

      if ( env.BRANCH_NAME == "master" ) {
        sh "./publish.sh"
      }
    } catch(e) {
      
      // TODO: Add build status "FAILURE"
    }

    // TODO: Add build status "SUCCESS"
  }
}
