# AWS Serverless Swift-Sprinter API Template

[![Swift 5.2.3](https://img.shields.io/badge/Swift-5.2.3-blue.svg)](https://swift.org/download/) [![docker amazonlinux2](https://img.shields.io/badge/docker-amazonlinux2-orange.svg)](https://swift.org/download/)

This package demostrates how to write a Scalable REST API with the Serverless stack by using only Swift as development language.

## Swift-Sprinter Product API Example

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

More details on the API are described in [swagger.json](swagger.json).

The file can be imported in popular tool such as PostMan.

The full [HTML documentation](swagger-doc.html) has been generated using [pretty-swag](https://twskj.github.io/pretty-swag/)

## Serverless architecture

The architecture is based on the classical AWS Serverless stack: APIGateway, Lambda and DynamoDB.
- `APIGateway`: acts as a `proxy` for the `Lambda` and exposing it to the internet.
- `Lambda`: is the computational layer.
- `DynamoDB`: is the AWS `NoSQL` database

Advantages:
- Pay per use
- No fixed costs
- Auto-Scaling
- DevOps

## Application

The application uses [Swift-Sprinter](https://github.com/swift-sprinter/aws-lambda-swift-sprinter) as AWS Custom Lambda Runtime and acts as a presentation layer of the DynamoDB content via Web.

The following frameworks are used:
- [aws-lambda-swift-sprinter-nio-plugin](https://github.com/swift-sprinter/aws-lambda-swift-sprinter-nio-plugin): Implements the AWS Custom Runtime usin Swift NIO.
- [aws-sdk-swift](https://github.com/swift-aws/aws-sdk-swift): Interacts with DynamoDB

## Requirements

- Install [Docker](https://docs.docker.com/install/)
- Install [Serverless Framework](https://www.serverless.com/framework/docs/getting-started/)
- Ensure your AWS Account has the right [credentials](https://www.serverless.com/framework/docs/providers/aws/guide/credentials/) to deploy a Serverless stack.
- Clone this repository. From the command line type:

```console
git clone https://github.com/swift-sprinter/aws-serverless-swift-sprinter-web-template
cd aws-serverless-swift-sprinter-web-template
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
```
./build.sh
```

## Deploy

Deploy the full solution to your AWS using Serverless:
```
./deploy.sh
```

After the deployment is completed, the URL of the website is provided by the Serverless framework.

## Update

Rebuild the code and update the Lambda to your AWS using Serverless:
```
./update.sh
```

## Remove

To remove the deployment use:
```
serverless remove
```
