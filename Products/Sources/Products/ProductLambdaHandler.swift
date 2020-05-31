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

struct ProductLambdaHandler: EventLoopLambdaHandler {
    
    typealias In = APIGateway.SimpleRequest
    typealias Out = APIGateway.Response
    
    let service: ProductService
    let operation: Operation
    
    func handle(context: Lambda.Context, payload: APIGateway.SimpleRequest) -> EventLoopFuture<APIGateway.Response> {
    
        switch operation {
        case .create:
            logger.info("create")
            let create = CreateLambdaHandler(service: service).handle(context: context, payload: payload)
                .flatMap { response -> EventLoopFuture<APIGateway.Response> in
                switch response {
                case .success(let result):
                    let value = APIGateway.Response(with: result, statusCode: .created)
                    return context.eventLoop.makeSucceededFuture(value)
                case .failure(let error):
                    let value = APIGateway.Response(with: error, statusCode: .forbidden)
                    return context.eventLoop.makeSucceededFuture(value)
                }
            }
            return create
        case .read:
            logger.info("read")
            let read = ReadLambdaHandler(service: service).handle(context: context, payload: payload)
            .flatMap { response -> EventLoopFuture<APIGateway.Response> in
                switch response {
                case .success(let result):
                    let value = APIGateway.Response(with: result, statusCode: .ok)
                    return context.eventLoop.makeSucceededFuture(value)
                case .failure(let error):
                    let value = APIGateway.Response(with: error, statusCode: .forbidden)
                    return context.eventLoop.makeSucceededFuture(value)
                }
            }
            return read
        case .update:
            logger.info("update")
            let update = UpdateLambdaHandler(service: service).handle(context: context, payload: payload)
            .flatMap { response -> EventLoopFuture<APIGateway.Response> in
                switch response {
                case .success(let result):
                    let value = APIGateway.Response(with: result, statusCode: .ok)
                    return context.eventLoop.makeSucceededFuture(value)
                case .failure(let error):
                    let value = APIGateway.Response(with: error, statusCode: .forbidden)
                    return context.eventLoop.makeSucceededFuture(value)
                }
            }
            return update
        case .delete:
            logger.info("delete")
            let delete = DeleteUpdateLambdaHandler(service: service).handle(context: context, payload: payload)
            .flatMap { response -> EventLoopFuture<APIGateway.Response> in
                switch response {
                case .success(let result):
                    let value = APIGateway.Response(with: result, statusCode: .ok)
                    return context.eventLoop.makeSucceededFuture(value)
                case .failure(let error):
                    let value = APIGateway.Response(with: error, statusCode: .forbidden)
                    return context.eventLoop.makeSucceededFuture(value)
                }
            }
            return delete
        case .list:
            logger.info("list")
            let list = ListUpdateLambdaHandler(service: service).handle(context: context, payload: payload)
            .flatMap { response -> EventLoopFuture<APIGateway.Response> in
                switch response {
                case .success(let result):
                    let value = APIGateway.Response(with: result, statusCode: .ok)
                    return context.eventLoop.makeSucceededFuture(value)
                case .failure(let error):
                    let value = APIGateway.Response(with: error, statusCode: .forbidden)
                    return context.eventLoop.makeSucceededFuture(value)
                }
            }
            return list
        case .unknown:
            logger.info("unknown")
            let value = APIGateway.Response(with: APIError.handlerNotFound, statusCode: .forbidden)
            return context.eventLoop.makeSucceededFuture(value)
        }
    }
    
    struct CreateLambdaHandler {
        
        let service: ProductService
        
        init(service: ProductService) {
            self.service = service
        }

        func handle(context: Lambda.Context, payload: APIGateway.SimpleRequest) -> EventLoopFuture<Result<Product,Error>> {
                    
            guard let product: Product = try? payload.object() else {
                let error = APIError.invalidRequest
                return context.eventLoop.makeFailedFuture(error)
            }
            let future = service.createItem(product: product)
                .flatMapThrowing { item -> Result<Product,Error> in
                    return Result.success(product)
            }
            return future
        }
    }
    
    struct ReadLambdaHandler {
    
        let service: ProductService
        
        init(service: ProductService) {
            self.service = service
        }

        func handle(context: Lambda.Context, payload: APIGateway.SimpleRequest) -> EventLoopFuture<Result<Product,Error>> {
            
            guard let sku = payload.pathParameters?["sku"] else {
                 let error = APIError.invalidRequest
                return context.eventLoop.makeFailedFuture(error)
            }
            let future = service.readItem(key: sku)
                .flatMapThrowing { data -> Result<Product,Error> in
                    let product = try Product(dictionary: data.item ?? [:])
                    return Result.success(product)
            }
            return future
        }
    }
    
    struct UpdateLambdaHandler {
        
        let service: ProductService
        
        init(service: ProductService) {
            self.service = service
        }

        func handle(context: Lambda.Context, payload: APIGateway.SimpleRequest) -> EventLoopFuture<Result<Product,Error>> {
            
            guard let product: Product = try? payload.object() else {
                let error = APIError.invalidRequest
                return context.eventLoop.makeFailedFuture(error)
            }
            let future = service.updateItem(product: product)
                .flatMapThrowing { (data) -> Result<Product,Error> in
                    return Result.success(product)
            }
            return future
        }
    }
    
    struct DeleteUpdateLambdaHandler {
        
        let service: ProductService
        
        init(service: ProductService) {
            self.service = service
        }

        func handle(context: Lambda.Context, payload: APIGateway.SimpleRequest) -> EventLoopFuture<Result<EmptyResponse,Error>> {
            
            guard let sku = payload.pathParameters?["sku"] else {
                 let error = APIError.invalidRequest
                               return context.eventLoop.makeFailedFuture(error)
            }
            let future = service.deleteItem(key: sku)
                .flatMapThrowing { (data) -> Result<EmptyResponse,Error> in
                    return Result.success(EmptyResponse())
            }
            return future
        }
    }
    
    struct ListUpdateLambdaHandler {
        
        let service: ProductService
        
        init(service: ProductService) {
            self.service = service
        }

        func handle(context: Lambda.Context, payload: APIGateway.SimpleRequest) -> EventLoopFuture<Result<[Product],Error>> {
            
            let future = service.listItems()
                .flatMapThrowing { data -> Result<[Product],Error> in
                    let products: [Product]? = try data.items?.compactMap { (item) -> Product in
                        return try Product(dictionary: item)
                    }
                    let object = products ?? []
                    return Result.success(object)
            }
            return future
        }
    }
}
