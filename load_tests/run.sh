#!/bin/bash
##
## Descript+ion: Restcomm performance test script
## Author     : George Vagenas
#

if [ $# -lt 6 ]; then
    echo "No proper arguments provided: (1: $1) (2: $2) (3: $3) (4: $4) (5: $5) (6: $6) (7: $7)"
    echo "Usage instructions: "
    echo './run.sh $RESTCOMM_ADDRESS $LOCAL_ADDRESS $SIMULTANEOUS_CALLS $MAXIMUM_CALLS $CALL_RATE $TEST_NAME'
    echo "Example: ./run.sh 192.168.1.11 192.168.1.12 100 10000 30 helloplay"
    exit 1
fi

if [[ -z $VOICERSS ]] || [ "$VOICERSS" == ''  ]; then
  echo "VoiceRSS TTS Service key is not set! Will exit"
  exit 1
fi

export CURRENT_FOLDER=`pwd`
export SIPP_EXECUTABLE=$CURRENT_FOLDER/sipp
export JVMTOP_EXECUTABLE=$CURRENT_FOLDER/jvmtop.sh
export SIPP_REPORT_EXECUTABLE="java -jar $CURRENT_FOLDER/sipp-report-0.2-SNAPSHOT-with-dependencies.jar -a"

export RESULTS_FOLDER=$CURRENT_FOLDER/results
if [ ! -d "$RESULTS_FOLDER" ]; then
  mkdir $RESULTS_FOLDER
fi

echo "Current folder $CURRENT_FOLDER"
echo "SIPP Executable $SIPP_EXECUTABLE"
echo "JVMTOP Executable $JVMTOP_EXECUTABLE"
echo "Collect JMAP: $COLLECT_JMAP"


prepareRestcomm() {
  #First prepare Restcomm
  echo $'\n********** About to start preparing Restcomm\n'
  $CURRENT_FOLDER/prepare-restcomm-for-perf.sh
  echo $'\n********** Finished  preparing Restcomm\n'
}

getPID(){
   RESTCOMM_PID=""
   RMS_PID=""

   export RESTCOMM_PID=$(jps | grep jboss-modules.jar | cut -d " " -f 1)
   export JBOSS_PID=$RESTCOMM_PID
   echo "Restcomm PID: $RESTCOMM_PID"

   while read -r line
   do
    if  ps -ef | grep $line | grep -q  mediaserver
    then
          export RMS_PID=$line
          echo "RMS PID: $RMS_PID"
   fi
   done < <(jps | grep Main | cut -d " " -f 1)
}

collectMonitoringServiceMetrics() {
  curl http://ACae6e420f425248d6a26948c17a9e2acf:$RESTCOMM_NEW_PASSWORD@$RESTCOMM_ADDRESS:8080/restcomm/2012-04-24/Accounts/ACae6e420f425248d6a26948c17a9e2acf/Supervisor.json/metrics -o $RESULTS_FOLDER/MonitoringService_$TEST_NAME_$(date +%F_%H_%M)
}

stopRestcomm(){
if [ "$COLLECT_JMAP" == "true"  ] || [ "$COLLECT_JMAP" == "TRUE"  ]; then
    $CURRENT_FOLDER/collect_jmap.sh
    sleep 1
    $CURRENT_FOLDER/perfRecorder.sh
    sleep 1
fi
    $RESTCOMM_HOME/bin/restcomm/stop-restcomm.sh
}

startRestcomm(){
  $RESTCOMM_HOME/bin/restcomm/start-restcomm.sh
  if [ "$COLLECT_JMAP" == "true"  ] || [ "$COLLECT_JMAP" == "TRUE"  ]; then
      sleep 30
      getPID
      ###start data collection
      cd $TOOLS_DIR
      $TOOLS_DIR/jvmdump.sh $RESTCOMM_PID
      $TOOLS_DIR/pc_start_collect.sh $RESTCOMM_PID
      cd $CURRENT_FOLDER
  fi
}

case "$TEST_NAME" in
"helloplay")
    echo "Testing Hello-Play"
    prepareRestcomm
    #In case a previous CI job killed, Restcomm will be still running, so make sure we first stop Restcomm
    $RESTCOMM_HOME/bin/restcomm/stop-restcomm.sh
    sleep 5
    startRestcomm
    echo $'\n********** Restcomm started\n'
    sleep 45
    echo $'\nChange default administrator password\n'
    curl -X PUT http://ACae6e420f425248d6a26948c17a9e2acf:77f8c12cc7b8f8423e5c38b035249166@$RESTCOMM_ADDRESS:8080/restcomm/2012-04-24/Accounts/ACae6e420f425248d6a26948c17a9e2acf -d "Password=$RESTCOMM_NEW_PASSWORD"
    echo ""
    sleep 15
    $CURRENT_FOLDER/tests/hello-play/helloplay.sh
    sleep 60
    collectMonitoringServiceMetrics
    sleep 5
    stopRestcomm
    echo $'\n********** Restcomm stopped\n'
    ;;
"conference")
    echo "Testing Conference"
    prepareRestcomm
    #In case a previous CI job killed, Restcomm will be still running, so make sure we first stop Restcomm
    $RESTCOMM_HOME/bin/restcomm/stop-restcomm.sh
    sleep 5
    cp $CURRENT_FOLDER/tests/conference/conference-app.xml $RESTCOMM_HOME/standalone/deployments/restcomm.war/demos/conference-app.xml
    startRestcomm
    echo $'\n********** Restcomm started\n'
    sleep 45
    echo $'\nChange default administrator password\n'
    curl -X PUT http://ACae6e420f425248d6a26948c17a9e2acf:77f8c12cc7b8f8423e5c38b035249166@$RESTCOMM_ADDRESS:8080/restcomm/2012-04-24/Accounts/ACae6e420f425248d6a26948c17a9e2acf -d "Password=$RESTCOMM_NEW_PASSWORD"
    echo $'\nAdd new IncomingPhoneNumber 2222 for Conference application\n'
    curl -X POST  http://administrator%40company.com:$RESTCOMM_NEW_PASSWORD@$RESTCOMM_ADDRESS:8080/restcomm/2012-04-24/Accounts/ACae6e420f425248d6a26948c17a9e2acf/IncomingPhoneNumbers.json -d "PhoneNumber=2222" -d "VoiceUrl=/restcomm/demos/conference-app.xml" -d "isSIP=true"
    echo ""
    sleep 15
    $CURRENT_FOLDER/tests/conference/conference.sh
    sleep 45
    collectMonitoringServiceMetrics
    sleep 5
    stopRestcomm
    echo $'\n********** Restcomm stopped\n'
    ;;
"helloplay-one-minute")
    echo "Testing Hello-Play with one minute anno"
    prepareRestcomm
    #In case a previous CI job killed, Restcomm will be still running, so make sure we first stop Restcomm
    $RESTCOMM_HOME/bin/restcomm/stop-restcomm.sh
    sleep 5
    echo "Testing Hello-Play One Minute"
    cp -ar $CURRENT_FOLDER/resources/audio/demo-prompt-one-minute.wav $RESTCOMM_HOME/standalone/deployments/restcomm.war/audio/demo-prompt.wav
    rm -rf $RESTCOMM_HOME/standalone/deployments/restcomm.war/cache/AC*
    startRestcomm
    echo $'\n********** Restcomm started\n'
    sleep 45
    echo $'\nChange default administrator password\n'
    curl -X PUT http://ACae6e420f425248d6a26948c17a9e2acf:77f8c12cc7b8f8423e5c38b035249166@$RESTCOMM_ADDRESS:8080/restcomm/2012-04-24/Accounts/ACae6e420f425248d6a26948c17a9e2acf -d "Password=$RESTCOMM_NEW_PASSWORD"
    echo ""
    sleep 15
    $CURRENT_FOLDER/tests/hello-play-one-minute/helloplay-one-minute.sh
    sleep 45
    collectMonitoringServiceMetrics
    sleep 5
    stopRestcomm
    echo $'\n********** Restcomm stopped\n'
    ;;
"dialclient")
  echo "Testing DialClient"
  prepareRestcomm
  #In case a previous CI job killed, Restcomm will be still running, so make sure we first stop Restcomm
  $RESTCOMM_HOME/bin/restcomm/stop-restcomm.sh
  sleep 5
  echo "Testing Dial Client Application"
  cp -ar $CURRENT_FOLDER/tests/dialclient/DialClientApp.xml $RESTCOMM_HOME/standalone/deployments/restcomm.war/demos/
  sed -i "s/SIPP_SERVER_IP_HERE/$LOCAL_ADDRESS/g" $RESTCOMM_HOME/standalone/deployments/restcomm.war/demos/DialClientApp.xml
  startRestcomm
  echo $'\n********** Restcomm started\n'
  sleep 45
  echo $'\nChange default administrator password\n'
  curl -X PUT http://ACae6e420f425248d6a26948c17a9e2acf:77f8c12cc7b8f8423e5c38b035249166@$RESTCOMM_ADDRESS:8080/restcomm/2012-04-24/Accounts/ACae6e420f425248d6a26948c17a9e2acf -d "Password=$RESTCOMM_NEW_PASSWORD"
  echo $'\nAdd new IncomingPhoneNumber 2222 for DialClient application\n'
  curl -X POST  http://administrator%40company.com:$RESTCOMM_NEW_PASSWORD@$RESTCOMM_ADDRESS:8080/restcomm/2012-04-24/Accounts/ACae6e420f425248d6a26948c17a9e2acf/IncomingPhoneNumbers.json -d "PhoneNumber=2222" -d "VoiceUrl=/restcomm/demos/DialClientApp.xml" -d "isSIP=true"
  #First run the server script that is the client that will listen for Restcomm calls
  screen -dmS 'dialclient-server' $CURRENT_FOLDER/tests/dialclient/dialclient-server.sh
  #Next run the client script that will initiate callls to Restcomm
  $CURRENT_FOLDER/tests/dialclient/dialclient-client.sh
  sleep 45
  collectMonitoringServiceMetrics
  sleep 5
  stopRestcomm
  echo $'\n********** Restcomm stopped\n'
  ;;
"gather")
    echo "Testing Gather"
    prepareRestcomm
    #In case a previous CI job killed, Restcomm will be still running, so make sure we first stop Restcomm
    $RESTCOMM_HOME/bin/restcomm/stop-restcomm.sh
    sleep 5
    echo "Testing Gather Application"
    rm -rf $RESTCOMM_HOME/standalone/deployments/restcomm.war/demos/gather/
    cp -ar $CURRENT_FOLDER/tests/gather/gather_app/ $RESTCOMM_HOME/standalone/deployments/restcomm.war/demos/gather
    startRestcomm
    echo $'\n********** Restcomm started\n'
    sleep 45
    echo $'\nChange default administrator password\n'
    curl -X PUT http://ACae6e420f425248d6a26948c17a9e2acf:77f8c12cc7b8f8423e5c38b035249166@$RESTCOMM_ADDRESS:8080/restcomm/2012-04-24/Accounts/ACae6e420f425248d6a26948c17a9e2acf -d "Password=$RESTCOMM_NEW_PASSWORD"
    echo ""
    sleep 15
    $CURRENT_FOLDER/tests/gather/gather.sh
    sleep 45
    collectMonitoringServiceMetrics
    sleep 5
    stopRestcomm
    echo $'\n********** Restcomm stopped\n'
    ;;
*) echo "Not known test: $TEST_NAME"
   ;;
esac
