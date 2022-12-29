make build_lambda
make cp_lambda_to_sls_build_local
BUILD_ARCH=`uname -m`
if [ $BUILD_ARCH = "arm64" ];
then
    serverless deploy -f createProduct
    serverless deploy -f readProduct
    serverless deploy -f updateProduct
    serverless deploy -f deleteProduct
    serverless deploy -f listProducts
else
    serverless deploy -f createProduct -c serverless-x86_64.yml
    serverless deploy -f readProduct -c serverless-x86_64.yml
    serverless deploy -f updateProduct -c serverless-x86_64.yml
    serverless deploy -f deleteProduct -c serverless-x86_64.yml
    serverless deploy -f listProducts -c serverless-x86_64.yml
fi