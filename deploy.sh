BUILD_ARCH=`uname -m`
if [ $BUILD_ARCH = "arm64" ];
then
    serverless deploy
else
    serverless deploy -c serverless-x86_64.yml
fi