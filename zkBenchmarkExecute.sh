#!/bin/sh

buildCode=false
codeSrcPath=""
tarballPath=""
remoteDestPath=""
numIter=0
sTime=0
testName=""
logDir=""
benchArgs=""
clushGroup=""
cleanup=false

nodes=(10.10.103.67 10.10.103.68 10.10.103.69 10.10.103.70)
#Build the repo if needed
script_usage="usage: $0 [--build] [--clushGroup <clush group of nodes>] [--srcPath <srcRepoPath>] [--tarPath <location of tarball>] [--destPath <location to copy tarball on remote nodes>] [--numIter <number of iterations> --sTime <sleep time in seconds between iterations>] [--testName <Name of test to run>] [--logDir <location of log dir>] [--benchArgs <arguments to pass to benchmark test>]"
if [ ${#} -ge 1 ] ; then
    OPTS=`getopt -a -o h -l build -l clushGroup: -l srcPath: -l tarPath: -l destPath: -l numIter: -l sTime: -l testName: -l logDir: -l benchArgs: -- "$@"`
    if [ $? != 0 ] ; then
        echo ${script_usage}
        exit 2
    fi
    eval set -- "$OPTS"

    for i ; do
        case "$i" in
            --build)
                buildCode=true
                shift 1
                ;;
            --clushGroup)
                shift 1
                clushGroup=$1
                shift 1
                ;;
            --srcPath)
                shift 1
                codeSrcPath=$1
                shift 1
                ;;
            --tarPath)
                shift 1
                tarballPath=$1
                shift 1
                ;;
            -h)
                echo ${script_usage}
                exit 2
                ;;
            --destPath)
                shift 1
                remoteDestPath=$1
                shift 1
                ;;
            --numIter)
                shift 1
                numIter=$1;
                shift 1
                ;;
            --sTime)
                shift 1
                sTime=$1;
                shift 1;;
            --testName)
                shift 1
                testName=$1
                shift 1;;
            --logDir)
                shift 1
                logDir=$1
                shift 1;;
            --benchArgs)
                shift 1
                benchArgs=$1
                shift 1;;
            --)
                shift
                break;;
        esac
    done
fi

#echo "Options are: BuildCode: $buildCode, SrcPath: $codeSrcPath, TarPath: $tarballPath, RemotePath: $remoteDestPath, NumIter: $numIter, SleepTime: $sTime, TestName: $testName, LogDir: $logDir, BenchArgs: $benchArgs" 
#if [ "$cleanup" = true ]; then
#   echo "Removing the tarball: "
#   echo "Removing Untarred directory: "
#fi

if [ "$buildCode" = true ]; then
   if [ -z "$codeSrcPath" ]; then
     echo "With buildCode set you must enter the local source repo path as well"
     echo "$script_usage"
     exit 1
   fi

   # Valid srcRepoPath is provided
   pushd . &> /dev/null
   cd $codeSrcPath
   #pwd
   git pull
   if [ $? -eq 0 ]; then
      echo "Successfully pulled the latest source code"
   else
      echo "Failed to pull the latest code. Exiting !!!"
      exit 1
   fi
   mvn clean install -DskipTests &> /dev/null
   if [ $? -eq 0 ]; then
      echo "Successfully build the tarball"
   else
      echo "Build Failed. Exiting"
      exit 1
   fi
   #pwd
   tarballPath=`pwd`"/target/zookeeper-bench-1.0-SNAPSHOT.tar.gz"
   #echo $tarballPath
   popd &> /dev/null
   #pwd
   
fi

if [ -z "$tarballPath" ]; then
   echo "TarBall path is not provided neither build option is selected"
   exit 1
fi
   
#Tarball path is available so copy this tarball to all node
for node in ${nodes[*]}
do
   scp $tarballPath root@$node:$remoteDestPath
done

# Untar the tarball on all node
if [ -d "$remoteDestPath/zookeeper-bench-1.0-SNAPSHOT" ]; then
   echo "Untar directory already exists. Hence deleting it"
   clush -g $clushGroup "rm -rf $remoteDestPath/zookeeper-bench-1.0-SNAPSHOT"
fi

echo "Expanding the tarball on all nodes"
clush -g $clushGroup "cd $remoteDestPath; tar -xvf $remoteDestPath/zookeeper-bench-1.0-SNAPSHOT.tar.gz" &> /dev/null

testLogDir=$logDir/$testName
if [ -d "$testLogDir" ]; then
   testBkupLogDir=$logDir/$testName"_bkup"
   echo "Log directory for the test already exists. Moving to $testBkupLogDir"
   mv $testLogDir $testBkupLogDir
   if [ $? -eq 0 ]; then
     echo "Successfully moved the previous log directory. Creating new one: $testLogDir"
   else
     echo "Failed to move the previous log directory. Either delete or move manually. Exiting!!"
     exit 1
   fi
fi
echo "Creating the logfile directory: $testLogDir"
mkdir $testLogDir

if [ $? -eq 0 ]; then
   echo "Successfully created the log directory"
else
   echo "Failed to create log file directory. Exiting!!"
   exit 1
fi

#Start the test loop
iterationNum=0
while [ $iterationNum -lt $numIter ]; do
   echo "Running iteration $iterationNum"
   echo "Executing the tests: $testName"
   logFileName="$testLogDir/$testName"
   logFileName="$logFileName"\-"$iterationNum"
   clush -g $clushGroup "$remoteDestPath/zookeeper-bench-1.0-SNAPSHOT/bin/bench.sh $benchArgs" > $logFileName
   echo "Sleeping for $sTime seconds"
   sleep $sTime
   let iterationNum=iterationNum+1
done
