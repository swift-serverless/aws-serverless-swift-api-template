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
import LambdaSwiftSprinter
import LambdaSwiftSprinterNioPlugin
import DynamoDB
import NIO
import NIOHTTP1
import ProductService
import Logging

let logger = Logger(label: "AWS.Lambda.ProductService")

guard let tableName = ProcessInfo.processInfo.environment["PRODUCTS_TABLE_NAME"] else {
    logger.error("\(String(describing: APIError.tableNameNotFound))")
    throw APIError.tableNameNotFound
}

let region: Region

if let awsRegion = ProcessInfo.processInfo.environment["AWS_REGION"],
    let value = Region(rawValue: awsRegion) {
    region = value
    logger.info("AWS_REGION: \(region)")
} else {
    //Default configuration
    region = .useast1
    logger.info("AWS_REGION: us-east-1")
}

let db = DynamoDB(region: region)

let service = ProductService(
    db: db,
    tableName: tableName
)

let createHandler: (APIGatewayProxySimpleEvent, Context) throws -> EventLoopFuture<Product> = { (event,context) throws -> EventLoopFuture<Product> in
    let product: Product = try event.object()
    let future = service.createItem(product: product)
    .flatMapThrowing { item -> Product in
        return product
    }
    return future
}

let create = APIGatewayProxyLambda<Product>(config: responseCreated, handler: createHandler)

let readHandler: (APIGatewayProxySimpleEvent, Context) throws -> EventLoopFuture<Product> = { (event,context) throws -> EventLoopFuture<Product> in
    guard let sku = event.pathParameters?["sku"] else {
        throw APIError.invalidRequest
    }
    let future = service.readItem(key: sku)
        .flatMapThrowing { data -> Product in
            return try Product(dictionary: data.item ?? [:])
    }
    return future
}

let read = APIGatewayProxyLambda<Product>(config: responseOK, handler: readHandler)

let updateHandler: (APIGatewayProxySimpleEvent, Context) throws -> EventLoopFuture<Product> = { (event,context) throws -> EventLoopFuture<Product> in
    let product: Product = try event.object()
    let future = service.updateItem(product: product)
        .flatMapThrowing { (data) -> Product in
            return product
    }
    return future
}

let update = APIGatewayProxyLambda<Product>(config: responseOK, handler: updateHandler)


struct EmptyResponse: Codable {
    
}

let deleteHandler: (APIGatewayProxySimpleEvent, Context) throws -> EventLoopFuture<EmptyResponse> = { (event,context) throws -> EventLoopFuture<EmptyResponse> in
    guard let sku = event.pathParameters?["sku"] else {
        throw APIError.invalidRequest
    }
    let future = service.deleteItem(key: sku)
        .flatMapThrowing { (data) -> EmptyResponse in
            return EmptyResponse()
    }
    return future
}

let delete = APIGatewayProxyLambda<EmptyResponse>(config: responseNoContent, handler: deleteHandler)


let listHandler: (APIGatewayProxySimpleEvent, Context) throws -> EventLoopFuture<[Product]> = { (event,context) throws -> EventLoopFuture<[Product]> in
    let future = service.listItems()
        .flatMapThrowing { data -> [Product] in
            let products: [Product]? = try data.items?.compactMap { (item) -> Product in
                return try Product(dictionary: item)
            }
            return products ?? []
    }
    return future
}

let list = APIGatewayProxyLambda<[Product]>(config: responseOK, handler: listHandler)

do {
    let sprinter = try SprinterNIO()
    sprinter.register(handler: "create", lambda: create)
    sprinter.register(handler: "read", lambda: read)
    sprinter.register(handler: "update", lambda: update)
    sprinter.register(handler: "delete", lambda: delete)
    sprinter.register(handler: "list", lambda: list)
    try sprinter.run()
} catch {
    logger.error("\(String(describing: error))")
}
