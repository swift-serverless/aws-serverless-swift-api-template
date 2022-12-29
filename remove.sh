BUILD_ARCH=`uname -m`
if [ $BUILD_ARCH = "arm64" ];
then
    serverless remove
else
    serverless remove -c serverless-x86_64.yml
fi