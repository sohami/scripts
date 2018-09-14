# scripts
#### Few Automated scripts

zkBenchmarkExecute.sh

#### For usage:
 ./zkBenchmarkExecute.sh -h
 
 ##### Other options:
* [--clushGroup <clush group of nodes>] - Clush group of nodes to run setup and execute benchmark tool
* [--build] - Flag to indicate if build is required
* [--srcPath <srcRepoPath>] - Absolute source path local to do maven build of repo
* [--tarPath <location of tarball>] - Absolute tarball location when building is not selected
* [--destPath <location to copy tarball on remote nodes>] - Remote location to copy the built tarball
* [--numIter <number of iterations>] - Number of iteration to run for the test
* [--sTime <sleep time in seconds between iterations>] - Sleep time in seconds between 2 iterations of the test
* [--testName <Name of test to run>] - Name of the test to run to create log directory
* [--logDir <location of log dir>] - Absolute location of log root folder
* [--benchArgs <arguments to pass to benchmark test>] - String of arguments to pass to the benchmark too

