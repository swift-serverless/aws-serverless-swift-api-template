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

let logger = Logger(label: "AWS.Lambda.ProductSerivce")

//let lambda: AsyncDictionaryLambda = { (event, context, completion) in
//
//    let result:[String: Any] = ["isBase64Encoded": false,
//                                "statusCode": 200,
//                                "headers": ["Content-Type": "application/json"],
//                                "body": "\(event)"]
//    completion(.success(result))
//}

guard let tableName = ProcessInfo.processInfo.environment["PRODUCTS_TABLE_NAME"] else {
    logger.error("\(String(describing: APIError.tableNameNotFound))")
    throw APIError.tableNameNotFound
}

let db = DynamoDB(region: .useast1)
let service = ProductService(
    db: db,
    tableName: tableName
)

typealias APIGatewaySyncLambda = SyncCodableNIOLambda<APIGatewayProxySimpleEvent, APIGatewayProxyResult>

let create: APIGatewaySyncLambda = { (event,context) throws -> EventLoopFuture<APIGatewayProxyResult>  in
    let product: Product = try event.object()
    let future = service.createItem(product: product).map { (item) -> APIGatewayProxyResult in
        return APIGatewayProxyResult(object: product, statusCode: 201)
    }
    return future
}

let read: APIGatewaySyncLambda = { (event,context) throws -> EventLoopFuture<APIGatewayProxyResult>  in
    
    guard let sku = event.pathParameters?["sku"] else {
        throw APIError.invalidRequest
    }

    let future = service.readItem(key: sku).flatMapThrowing { data -> APIGatewayProxyResult in
        let object = try Product(dictionary: data.item ?? [:])
        return APIGatewayProxyResult(object: object, statusCode: 200)
    }
    return future
}

let update: APIGatewaySyncLambda = { (event,context) throws -> EventLoopFuture<APIGatewayProxyResult> in
    
    let product: Product = try event.object()
    let future = service.updateItem(product: product).map { (data) -> APIGatewayProxyResult in
        return APIGatewayProxyResult(object: product, statusCode: 200)
    }
    return future
}

let delete: APIGatewaySyncLambda = { (event,context) throws -> EventLoopFuture<APIGatewayProxyResult>  in
    
    guard let sku = event.pathParameters?["sku"] else {
        throw APIError.invalidRequest
    }
    
    let future = service.deleteItem(key: sku).flatMapThrowing { data -> APIGatewayProxyResult in
        return APIGatewayProxyResult(statusCode: 204,
                                     body: "")
    }
    return future
}

let list: APIGatewaySyncLambda = { (event,context) throws -> EventLoopFuture<APIGatewayProxyResult> in
    let future = service.listItems().flatMapThrowing { data -> [Product] in
        let products: [Product]? = try data.items?.compactMap { (item) -> Product in
            return try Product(dictionary: item)
        }
        return products ?? []
    }.map { products -> APIGatewayProxyResult in
        return APIGatewayProxyResult(object: products, statusCode: 200)
    }
    return future
}

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
