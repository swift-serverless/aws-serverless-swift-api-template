# AWS Serverless Swift API Template

[![Swift 5.7.3](https://img.shields.io/badge/Swift-5.7.3-blue.svg)](https://swift.org/download/) [![docker amazonlinux2](https://img.shields.io/badge/docker-amazonlinux2-orange.svg)](https://swift.org/download/)

This package demonstrates how to write a Scalable REST API with the Serverless stack by using only Swift as a development language.

## Product API Example

The example shows how to build a Rest API based on a `Product` swift class.

```swift
public struct Product: Codable {
    public let sku: String
    public let name: String
    public let description: String
    public var createdAt: String?
    public var updatedAt: String?
}
```
![](images/postman.png)

## API Definition

The API implements the following schema:

```
- /Product
    -> GET - List Products
    -> POST - Create Products
    -> PUT - Update Products
- /Product/{sku}
    -> DELETE - Delete Product
    -> GET - Get Product
```

More details of the API are described in [swagger.json](swagger.json).

The file can be imported into popular tools such as PostMan.

Be sure to update the `"host": "<BASE_URL>"` with the URL provided during the deployment.

## Serverless architecture

The architecture is based on the classical AWS Serverless stack: APIGateway, Lambda and DynamoDB.
- `APIGateway` acts as a `proxy` for `Lambda` and exposes it to the internet.
- `Lambda` is the computational layer.
- `DynamoDB` is the AWS `NoSQL` database

Advantages:
- Pay per use
- No fixed costs
- Auto-Scaling
- DevOps

## REST API Application

The application uses [swift-aws-lambda-runtime](https://github.com/swift-server/swift-aws-lambda-runtime/) as AWS Custom Lambda Runtime and acts as a presentation layer of the DynamoDB content providing a REST API.

The following frameworks are used:
- [swift-aws-lambda-runtime](https://github.com/swift-server/swift-aws-lambda-runtime/): Implements the AWS Custom Runtime using Swift NIO.
- [aws-sdk-swift](https://github.com/swift-aws/aws-sdk-swift): Interacts with DynamoDB

## Requirements

- Install [Docker](https://docs.docker.com/install/)
- Install [Serverless Framework](https://www.serverless.com/framework/docs/getting-started/) version 3

```
Framework Core: 3.25.0 (standalone)
Plugin: 6.2.2
SDK: 4.3.2
```

- Ensure your AWS Account has the right [credentials](https://www.serverless.com/framework/docs/providers/aws/guide/credentials/) to deploy a Serverless stack.
- Clone this repository. From the command line type:

```console
git clone https://github.com/swift-sprinter/aws-serverless-swift-api-template.git
cd aws-serverless-swift-api-template
```
- Ensure you can run `make`:

```console
make --version
```

the `Makefile` was developed with this version:
```
GNU Make 3.81
Copyright (C) 2006  Free Software Foundation, Inc.
This is free software; see the source for copying conditions.
There is NO warranty; not even for MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE.

This program built for i386-apple-darwin11.3.0
```

## Build

Use the following command to build the code before using the serverless commands:
```bash
./build.sh
```

![](images/build.png)

## Deploy

Deploy the full solution to your AWS using Serverless:
```bash
./deploy.sh
```

![](images/deploy.png)

After the deployment is completed, the URL of the website is provided by the Serverless framework.

## Update

Rebuild the code and update the Lambda to your AWS using Serverless:
```bash
./update.sh
```

![](images/update.png)

## Remove

To remove the deployment:
```bash
./remove.sh
```

![](images/remove.png)

## arm64 M1 Graviton Support

If the project is built with an M1 processor, then the AWS Lambda will be deployed on the `arm64` architecture.

## amd64/x86_64 Support

If the project is built with an Intel processor, then the AWS Lambda will be deployed on the `x86_64` architecture.

## Troubleshooting


- ### The Serverless version (2.40.0) does not satisfy the "frameworkVersion" (3) in serverless.yml

If during the deployment, the console prints the following message:

```
Serverless Error ----------------------------------------
 
  The Serverless version (2.40.0) does not satisfy the "frameworkVersion" (3) in serverless.yml
 
  Get Support --------------------------------------------
     Docs:          docs.serverless.com
     Bugs:          github.com/serverless/serverless/issues
     Issues:        forum.serverless.com
 
  Your Environment Information ---------------------------
     Operating System:          darwin
     Node Version:              14.4.0
     Framework Version:         2.40.0 (standalone)
     Plugin Version:            4.5.3
     SDK Version:               4.2.2
     Components Version:        3.9.2
```

Check the version of Serverless Framework installed in your environment:
```bash
sls -v
```

```
Framework Core: 2.40.0 (standalone)
Plugin: 4.5.3
SDK: 4.2.2
Components: 3.9.2
```

It's recommended to [upgrade to version 3](https://www.serverless.com/framework/docs/guides/upgrading-v3) the Serverless Framework. 
In case you want to use version `2` make sure to override the content of `serverless.yml` with the content of `serverless-v2.yml`.
