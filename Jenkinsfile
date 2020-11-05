pipeline {
    agent { label 'windows && sfdx' }
    environment {
        HUB_ORG                        = 'patrick.guimaraes-6039383736@vlocityapps.com'
        SFDX_HOST_PRD                  = 'https://login.salesforce.com'
        //SFDX_HOST_QA                   = 'https://test.salesforce.com'
        PACKAGE_NAME                   = "mdDeploysrc"
        DEPLOY_DEV                     = false
        //DEPLOY_QA                      = false
        //DEPLOY_E2E                     = false
        SF_CONSUMER_KEY                   = credentials('SF_CONSUMER_KEY')

        // DEV
        USER_DEV = 'patrick.guimaraes-6039383736@vlocityapps.com'
        CONNECTED_APP_CONSUMER_KEY_DEV = credentials('SF_CONSUMER_KEY')

        // QA
       // USER_QA = 'adminjenkins@grupocobra.com.cobraqa'
       // CONNECTED_APP_CONSUMER_KEY_QA  = credentials('COBRA-SDFX-CONNECTED-APP-KEY-QA')

        // E2E
       // USER_E2E = 'adminjenkins@grupocobra.com.cobrae2e'
        // CONNECTED_APP_CONSUMER_KEY_E2E = credentials('COBRA-SDFX-CONNECTED-APP-KEY-E2E')

        // PRD
        // USER_PRD = 'adminjenkins@grupocobra.com'
        // CONNECTED_APP_CONSUMER_KEY_PRD = credentials('COBRA-SDFX-CONNECTED-APP-KEY-PRD')
    }
        
    stages {
        stage('Choose environment') {
            options {
                timeout time: 2, unit: 'MINUTES'
            }
            steps {
                script {
                    result = input(
                        message: 'Select deploy environment:',    
                        parameters: [                           
                            [$class: 'BooleanParameterDefinition', name: 'DEV', defaultValue: true, description: ''],    
                            //[$class: 'BooleanParameterDefinition', name: 'QA', defaultValue: false, description: 'Confirm deployment settings!'],
                            //[$class: 'BooleanParameterDefinition', name: 'E2E', defaultValue: false, description: 'Confirm deployment settings!']
                        ]   
                    )
                    DEPLOY_DEV = result.DEV;
                    //DEPLOY_QA = result.QA;
                    //DEPLOY_E2E = result.E2E;
                }
            }
        }

        stage('Code Analysis') {
            steps {                
                withSonarQubeEnv('SonarQube LDC') {
                    bat "sonar-scanner -Dproject.settings=./sonar-project.properties"
                }
            }
        }

        stage('Convert') {
            steps {
                dir ('sfvlocity') {
                    bat "sfdx force:source:convert -d ${PACKAGE_NAME}"
                }
            }
        }

        stage('Deploy: DEV') {
            when {
                expression{ env.DEPLOY_DEV }
            }
            steps {
                bat "sfdx force:auth:jwt:grant --clientid ${CONNECTED_APP_CONSUMER_KEY_DEV} --username ${USER_DEV} --jwtkeyfile ${JWT_KEY_CRED} --setdefaultdevhubusername --instanceurl ${SFDX_HOST_PRD}"

                dir ('cobraProject') {
                    bat "sfdx force:mdapi:deploy -d ${PACKAGE_NAME} -u ${USER_DEV} -w 15"
                }
            }
        }

      //  stage('Deploy: QA') {
      //      when {
      //          expression{ env.DEPLOY_QA }
      //      }
      //      steps {
      //          bat "sfdx force:auth:jwt:grant --clientid ${CONNECTED_APP_CONSUMER_KEY_QA} --username ${USER_QA} --jwtkeyfile ${JWT_KEY_CRED} --setdefaultdevhubusername --instanceurl ${SFDX_HOST_QA}"

     //           dir ('cobraProject') {
     //               bat "sfdx force:mdapi:deploy -d ${PACKAGE_NAME} -u ${USER_QA} -w 15"
     //           }
     //       }
     //   }

     //   stage('Deploy: E2E') {
     //       when {
     //           expression{ env.DEPLOY_E2E }
     //       }
     //       steps {
     //           bat "sfdx force:auth:jwt:grant --clientid ${CONNECTED_APP_CONSUMER_KEY_E2E} --username ${USER_E2E} --jwtkeyfile ${JWT_KEY_CRED} --setdefaultdevhubusername --instanceurl ${SFDX_HOST_QA}"
     //
     //           dir ('cobraProject') {
     //               bat "sfdx force:mdapi:deploy -d ${PACKAGE_NAME} -u ${USER_E2E} -w 15"
     //           }
     //       }
     //   }
  //  }
    
    post {
        always {
            dir('sfvlocity'){
                bat "IF EXIST ${PACKAGE_NAME} rmdir ${PACKAGE_NAME} /Q /S "
            }
        }
    }
}