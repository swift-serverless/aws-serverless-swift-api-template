//    Copyright 2022 (c) Andrea Scuderi - https://github.com/swift-sprinter
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

#if compiler(>=5.5) && canImport(_Concurrency)

struct AsyncProductLambdaHandler {
    
    typealias In = APIGateway.V2.Request
    typealias Out = APIGateway.V2.Response
    
    let service: ProductService
    let operation: Operation
    
    func handle(context: Lambda.Context, event: APIGateway.V2.Request) async -> APIGateway.V2.Response {
        
        switch self.operation {
        case .create:
            return await createLambdaHandler(context: context, event: event)
        case .read:
            return await readLambdaHandler(context: context, event: event)
        case .update:
            return await updateLambdaHandler(context: context, event: event)
        case .delete:
            return await deleteUpdateLambdaHandler(context: context, event: event)
        case .list:
            return await listUpdateLambdaHandler(context: context, event: event)
        }
    }
    
    func createLambdaHandler(context: Lambda.Context, event: APIGateway.V2.Request) async -> APIGateway.V2.Response {
        guard let product: Product = try? event.bodyObject() else {
            let error = APIError.invalidRequest
            return APIGateway.V2.Response(with: error, statusCode: .forbidden)
        }
        do {
            let result = try await service.createItem(product: product)
            return APIGateway.V2.Response(with: result, statusCode: .created)
        } catch {
            return APIGateway.V2.Response(with: error, statusCode: .forbidden)
        }
    }
    
    func readLambdaHandler(context: Lambda.Context, event: APIGateway.V2.Request) async -> APIGateway.V2.Response {
        guard let sku = event.pathParameters?["sku"] else {
            let error = APIError.invalidRequest
            return APIGateway.V2.Response(with: error, statusCode: .forbidden)
        }
        do {
            let result = try await service.readItem(key: sku)
            return APIGateway.V2.Response(with: result, statusCode: .ok)
        } catch {
            return APIGateway.V2.Response(with: error, statusCode: .notFound)
        }
    }
    
    func updateLambdaHandler(context: Lambda.Context, event: APIGateway.V2.Request) async -> APIGateway.V2.Response {
        guard let product: Product = try? event.bodyObject() else {
            let error = APIError.invalidRequest
            return APIGateway.V2.Response(with: error, statusCode: .forbidden)
        }
        do {
            let result = try await service.updateItem(product: product)
            return APIGateway.V2.Response(with: result, statusCode: .ok)
        } catch {
            return APIGateway.V2.Response(with: error, statusCode: .notFound)
        }
    }
    
    func deleteUpdateLambdaHandler(context: Lambda.Context, event: APIGateway.V2.Request) async -> APIGateway.V2.Response {
        guard let sku = event.pathParameters?["sku"] else {
            let error = APIError.invalidRequest
            return APIGateway.V2.Response(with: error, statusCode: .forbidden)
        }
        do {
            try await service.deleteItem(key: sku)
            return APIGateway.V2.Response(with: EmptyResponse(), statusCode: .ok)
        } catch {
            return APIGateway.V2.Response(with: error, statusCode: .notFound)
        }
    }
    
    func listUpdateLambdaHandler(context: Lambda.Context, event: APIGateway.V2.Request) async -> APIGateway.V2.Response {
        do {
            let result = try await service.listItems()
            return APIGateway.V2.Response(with: result, statusCode: .ok)
        } catch {
            return APIGateway.V2.Response(with: error, statusCode: .forbidden)
        }
    }
}

#endif
