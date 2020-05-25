make build_lambda
make cp_lambda_to_sls_build_local
serverless deploy -f createProduct
serverless deploy -f readProduct
serverless deploy -f updateProduct
serverless deploy -f deleteProduct
serverless deploy -f listProducts