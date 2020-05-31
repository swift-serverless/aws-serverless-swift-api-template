//    Copyright 2019 (c) Andrea Scuderi - https://github.com/swift-sprinter
//
//    Licensed under the Apache License, Version 2.0 (the "License");
//    you may not use this file except in compliance with the License.
//    You may obtain a copy of the License at
//
//        http://www.apache.org/licenses/LICENSE-2.0
//
//    Unless required by applicable law or agreed to in writing, software
//    distributed under the License is distributed on an "AS IS" BASIS,
//    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//    See the License for the specific language governing permissions and
//    limitations under the License.

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import AWSLambdaRuntime
import AWSDynamoDB
import NIO
import NIOHTTP1
import ProductService
import Logging
import AsyncHTTPClient

let logger = Logger(label: "AWS.Lambda.ProductService")

guard let tableName = ProcessInfo.processInfo.environment["PRODUCTS_TABLE_NAME"] else {
    logger.error("\(String(describing: APIError.tableNameNotFound))")
    throw APIError.tableNameNotFound
}

let region: Region

if let awsRegion = ProcessInfo.processInfo.environment["AWS_REGION"] {
    let value = Region(rawValue: awsRegion)
    region = value
    logger.info("AWS_REGION: \(region)")
} else {
    //Default configuration
    region = .useast1
    logger.info("AWS_REGION: us-east-1")
}

let lambdaRuntimeTimeout: TimeAmount = .seconds(30)
let timeout = HTTPClient.Configuration.Timeout(connect: lambdaRuntimeTimeout,
                                                      read: lambdaRuntimeTimeout)

let configuration = HTTPClient.Configuration(timeout: timeout)
let awsClient = HTTPClient(eventLoopGroupProvider: .createNew, configuration: configuration)

logger.info("awsClient")

let db = DynamoDB(region: region, httpClientProvider: .shared(awsClient))

logger.info("DynamoDB")

let service = ProductService(
    db: db,
    tableName: tableName
)

logger.info("ProductService")

struct EmptyResponse: Codable {
    
}

extension Lambda {
    
    public typealias CodableFuture<In: Decodable, Out: Encodable> = (In, Lambda.Context) throws -> EventLoopFuture<Out>

    public static func run<In: Decodable, Out: Encodable>(_ future: @escaping CodableFuture<In, Out>) {

        self.run { (context, event:In, callback: @escaping (Result<Out, Error>) -> Void) in
            do {
                let _ = try future(event, context)
                    .hop(to: context.eventLoop)
                    .always { (result) in
                        callback(result)
                }
            } catch {
                callback(Result.failure(error))
            }
        }
    }
}

let handler: String = Lambda.env("_HANDLER") ?? ""

logger.info("\(handler)")

switch handler {
case "build/Products.create":
    
    Lambda.run { (event: APIGatewayProxySimpleEvent, context) throws -> EventLoopFuture<APIGatewayProxyResult<Product>> in
        guard let product: Product = try? event.object() else {
            throw APIError.invalidRequest
        }
        
        let future = service.createItem(product: product)
            .flatMapThrowing { item -> APIGatewayProxyResult<Product> in
                return APIGatewayProxyResult(object: product, statusCode: 200)
        }
        return future
    }
    
case "build/Products.read":
    
    Lambda.run { (event: APIGatewayProxySimpleEvent, context) throws -> EventLoopFuture<APIGatewayProxyResult<Product>> in
        guard let sku = event.pathParameters?["sku"] else {
            throw APIError.invalidRequest
        }
        let future = service.readItem(key: sku)
            .flatMapThrowing { data -> APIGatewayProxyResult<Product> in
                let product = try Product(dictionary: data.item ?? [:])
                return APIGatewayProxyResult(object: product, statusCode: 200)
        }
        return future
    }
    
case "build/Products.update":
    Lambda.run { (event: APIGatewayProxySimpleEvent, context) throws -> EventLoopFuture<APIGatewayProxyResult<Product>> in
        guard let product: Product = try? event.object() else {
            throw APIError.invalidRequest
        }
        let future = service.updateItem(product: product)
            .flatMapThrowing { (data) -> APIGatewayProxyResult<Product> in
                return APIGatewayProxyResult(object: product, statusCode: 204)
        }
        return future
    }
    
case "build/Products.delete":
    
    Lambda.run { (event: APIGatewayProxySimpleEvent, context) throws -> EventLoopFuture<APIGatewayProxyResult<EmptyResponse>>  in
        guard let sku = event.pathParameters?["sku"] else {
            throw APIError.invalidRequest
        }
        let future = service.deleteItem(key: sku)
            .flatMapThrowing { (data) -> APIGatewayProxyResult<EmptyResponse> in
                return APIGatewayProxyResult(object: EmptyResponse(), statusCode: 200)
        }
        return future
    }
    
case "build/Products.list":
    
    Lambda.run { (event: APIGatewayProxySimpleEvent, context) throws -> EventLoopFuture<APIGatewayProxyResult<[Product]>>  in
        let future = service.listItems()
            .flatMapThrowing { data -> APIGatewayProxyResult<[Product]> in
                let products: [Product]? = try data.items?.compactMap { (item) -> Product in
                    return try Product(dictionary: item)
                }
                let object = products ?? []
                return APIGatewayProxyResult(object: object, statusCode: 200)
        }
        return future
    }

default:
    logger.error("preconditionFailure")
    preconditionFailure("Unexpected handler name: \(Lambda.env("_HANDLER") ?? "unknown")")
}
