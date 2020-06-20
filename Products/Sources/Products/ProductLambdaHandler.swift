//    Copyright 2020 (c) Andrea Scuderi - https://github.com/swift-sprinter
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
import NIO
import ProductService
import Logging
import AWSLambdaEvents

import AWSLambdaEvents
import AWSLambdaRuntime
import Logging
import NIO

struct ProductLambdaHandler: EventLoopLambdaHandler {
    
    typealias In = APIGateway.V2.Request
    typealias Out = APIGateway.V2.Response
    
    let service: ProductService
    let operation: Operation
    
    func handle(context: Lambda.Context, event: APIGateway.V2.Request) -> EventLoopFuture<APIGateway.V2.Response> {
        
        switch self.operation {
        case .create:
            return createLambdaHandler(context: context, event: event)
        case .read:
            return readLambdaHandler(context: context, event: event)
        case .update:
            return updateLambdaHandler(context: context, event: event)
        case .delete:
            return deleteUpdateLambdaHandler(context: context, event: event)
        case .list:
            return listUpdateLambdaHandler(context: context, event: event)
        }
    }
    
    func createLambdaHandler(context: Lambda.Context, event: APIGateway.V2.Request) -> EventLoopFuture<APIGateway.V2.Response> {
        guard let product: Product = try? event.bodyObject() else {
            let error = APIError.invalidRequest
            return context.eventLoop.makeFailedFuture(error)
        }
        return service.createItem(product: product)
            .map { result -> (APIGateway.V2.Response) in
                return APIGateway.V2.Response(with: result, statusCode: .created)
        }.flatMapError { (error) -> EventLoopFuture<APIGateway.V2.Response> in
            let value = APIGateway.V2.Response(with: error, statusCode: .forbidden)
            return context.eventLoop.makeSucceededFuture(value)
        }
    }
    
    func readLambdaHandler(context: Lambda.Context, event: APIGateway.V2.Request) -> EventLoopFuture<APIGateway.V2.Response> {
        guard let sku = event.pathParameters?["sku"] else {
            let error = APIError.invalidRequest
            return context.eventLoop.makeFailedFuture(error)
        }
        return service.readItem(key: sku)
            .flatMapThrowing { result -> APIGateway.V2.Response in
                return APIGateway.V2.Response(with: result, statusCode: .ok)
        }.flatMapError { (error) -> EventLoopFuture<APIGateway.V2.Response> in
            let value = APIGateway.V2.Response(with: error, statusCode: .notFound)
            return context.eventLoop.makeSucceededFuture(value)
        }
    }
    
    func updateLambdaHandler(context: Lambda.Context, event: APIGateway.V2.Request) -> EventLoopFuture<APIGateway.V2.Response> {
        guard let product: Product = try? event.bodyObject() else {
            let error = APIError.invalidRequest
            return context.eventLoop.makeFailedFuture(error)
        }
        return service.updateItem(product: product)
            .map { result -> (APIGateway.V2.Response) in
                return APIGateway.V2.Response(with: result, statusCode: .ok)
        }.flatMapError { (error) -> EventLoopFuture<APIGateway.V2.Response> in
            let value = APIGateway.V2.Response(with: error, statusCode: .notFound)
            return context.eventLoop.makeSucceededFuture(value)
        }
    }
    
    func deleteUpdateLambdaHandler(context: Lambda.Context, event: APIGateway.V2.Request) -> EventLoopFuture<APIGateway.V2.Response> {
        guard let sku = event.pathParameters?["sku"] else {
            let error = APIError.invalidRequest
            return context.eventLoop.makeFailedFuture(error)
        }
        return service.deleteItem(key: sku)
            .map { _ -> (APIGateway.V2.Response) in
                return APIGateway.V2.Response(with: EmptyResponse(), statusCode: .ok)
        }.flatMapError { (error) -> EventLoopFuture<APIGateway.V2.Response> in
            let value = APIGateway.V2.Response(with: error, statusCode: .notFound)
            return context.eventLoop.makeSucceededFuture(value)
        }
    }
    
    func listUpdateLambdaHandler(context: Lambda.Context, event: APIGateway.V2.Request) -> EventLoopFuture<APIGateway.V2.Response> {
        return service.listItems()
            .flatMapThrowing { result -> APIGateway.V2.Response in
                return APIGateway.V2.Response(with: result, statusCode: .ok)
        }.flatMapError { (error) -> EventLoopFuture<APIGateway.V2.Response> in
            let value = APIGateway.V2.Response(with: error, statusCode: .forbidden)
            return context.eventLoop.makeSucceededFuture(value)
        }
    }
}
