#Provide Github account where thу project repo hosted and the name of repo:
GITHUB_ORG='patrickick'                                         
GITHUB_REPO='sfvlocity'

#Exit from build:
#params: 1 - status, 2 - callback command to call before exit, 3 - comment text for  failed GitHub commit
exit_on_error() {
    if [ $1 -ne 0 ]
    then
        if [ "$2" != '' ]
        then
            $2
        fi

        set_github_commit_status 'failure' "$3"
        exit 1
    fi
}

#Remove scratch org from DevHub:
#params: 1 - scratch org username/alias
delete_scratch_org() {
    sfdx force:org:delete --targetusername "$1" --noprompt
}

#Set GitHub commit status:
#params: 1 - commit state(success/failure/pending), 2 - commit status description
set_github_commit_status() {
    echo "Settings GitHub Commit $GIT_COMMIT to the status $1..."
    curl "https://api.github.com/repos/$GITHUB_ORG/$GITHUB_REPO/statuses/$GIT_COMMIT?access_token=$GITHUB_ACCESS_TOKEN" \
      -H "Content-Type: application/json" \
      -X POST \
      -d "{\"state\": \"$1\", \"description\": \"$2\", \"target_url\": \"$BUILD_URL/console\", \"context\": \"continuous-integration/jenkins/push\"}" \
      -s > /dev/null #Hide curl output
}

#==================================================================

#Set GitHub commit to pending before process
set_github_commit_status 'pending' 'The build is processing...'

#Login to Developer Hub Org
sfdx force:auth:jwt:grant --username "$HUB_ORG" --jwtkeyfile "$JWT_KEY_FILE" --clientid "$CONNECTED_APP_CONSUMER_KEY" --setdefaultdevhubusername --setalias DevHub
exit_on_error $? '' 'Developer hub auth process failed'

#Define unique Scratch Org Alias and create Org based on it
SCRATCH_ORG_ALIAS="Scratch-ORG:Push-Build-${BUILD_NUMBER}"
sfdx force:org:create --definitionfile "config/project-scratch-def.json" --setalias "${SCRATCH_ORG_ALIAS}" --setdefaultusername
exit_on_error $? '' 'Scratch org creation process failed'

#Push sources to Scratch org and assign permission set to user
sfdx force:source:push
exit_on_error $? "delete_scratch_org ${SCRATCH_ORG_ALIAS}" 'Source pushing process failed'

#Run Apex tests
TEST_RESULTS_FOLDER="tests/${BUILD_NUMBER}"
mkdir -p "$TEST_RESULTS_FOLDER"
UNIT_TESTS_RUN_ID=$(sfdx force:apex:test:run --testlevel RunLocalTests --outputdir "$TEST_RESULTS_FOLDER" --json  | jq .result.testRunId -r)
if [ "$UNIT_TESTS_RUN_ID" = '' ] ; then UNIT_TESTS_RUN_STATUS=1 ; else UNIT_TESTS_RUN_STATUS=0; fi
#Exit if error occurs while running tests (ex. ORG has not test classes)
exit_on_error ${UNIT_TESTS_RUN_STATUS} "delete_scratch_org ${SCRATCH_ORG_ALIAS}" 'Unit tests run process failed'

#Run Apex Unit tests report
sfdx force:apex:test:report --testrunid $UNIT_TESTS_RUN_ID --outputdir "$TEST_RESULTS_FOLDER" --wait 10
UNIT_TESTS_FINAL_STATUS=$(cat "$TEST_RESULTS_FOLDER/test-result-$UNIT_TESTS_RUN_ID.json" | jq .summary.outcome -r)

#Remove Scratch org
delete_scratch_org "${SCRATCH_ORG_ALIAS}"

#Set GitHub commit status based on results
if [ "$UNIT_TESTS_FINAL_STATUS" == 'Failed' ]
then
  set_github_commit_status 'failure' 'Unit tests checks failed'
else
  set_github_commit_status 'success' 'The build is valid'
fi

#Mark build as failed if Apex Tests failed
if [ "$UNIT_TESTS_FINAL_STATUS" == 'Failed' ]
then
	echo "The build #${BUILD_NUMBER} has failed due to Apex Tests!"
    exit 1
else
	echo "The build #${BUILD_NUMBER} has successfully DONE!"
fi