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
import DynamoDBService
import Logging
import AWSLambdaEvents

struct DynamoDBLambdaHandler<T: DynamoDBItem> {
    
    typealias Event = APIGatewayV2Request
    typealias Output = APIGatewayV2Response
    
    let service: DynamoDBService<T>
    let operation: Operation
    
    var keyName: String {
        service.keyName
    }
    
    func handle(context: AWSLambdaRuntimeCore.LambdaContext, event: APIGatewayV2Request) async -> APIGatewayV2Response {
        
        switch self.operation {
        case .create:
            return await createLambdaHandler(context: context, event: event)
        case .read:
            return await readLambdaHandler(context: context, event: event)
        case .update:
            return await updateLambdaHandler(context: context, event: event)
        case .delete:
            return await deleteLambdaHandler(context: context, event: event)
        case .list:
            return await listLambdaHandler(context: context, event: event)
        }
    }
    
    func createLambdaHandler(context: AWSLambdaRuntimeCore.LambdaContext, event: APIGatewayV2Request) async -> APIGatewayV2Response {
        guard let item: T = try? event.bodyObject() else {
            let error = APIError.invalidRequest
            return APIGatewayV2Response(with: error, statusCode: .forbidden)
        }
        do {
            let result = try await service.createItem(item: item)
            return APIGatewayV2Response(with: result, statusCode: .created)
        } catch {
            return APIGatewayV2Response(with: error, statusCode: .forbidden)
        }
    }
    
    func readLambdaHandler(context: AWSLambdaRuntimeCore.LambdaContext, event: APIGatewayV2Request) async -> APIGatewayV2Response {
        guard let sku = event.pathParameters?[keyName] else {
            let error = APIError.invalidRequest
            return APIGatewayV2Response(with: error, statusCode: .forbidden)
        }
        do {
            let result = try await service.readItem(key: sku)
            return APIGatewayV2Response(with: result, statusCode: .ok)
        } catch {
            return APIGatewayV2Response(with: error, statusCode: .notFound)
        }
    }
    
    func updateLambdaHandler(context: AWSLambdaRuntimeCore.LambdaContext, event: APIGatewayV2Request) async -> APIGatewayV2Response {
        guard let item: T = try? event.bodyObject() else {
            let error = APIError.invalidRequest
            return APIGatewayV2Response(with: error, statusCode: .forbidden)
        }
        do {
            let result = try await service.updateItem(item: item)
            return APIGatewayV2Response(with: result, statusCode: .ok)
        } catch {
            return APIGatewayV2Response(with: error, statusCode: .notFound)
        }
    }
    
    func deleteLambdaHandler(context: AWSLambdaRuntimeCore.LambdaContext, event: APIGatewayV2Request) async -> APIGatewayV2Response {
        guard let sku = event.pathParameters?[keyName] else {
            let error = APIError.invalidRequest
            return APIGatewayV2Response(with: error, statusCode: .forbidden)
        }
        do {
            try await service.deleteItem(key: sku)
            return APIGatewayV2Response(with: EmptyResponse(), statusCode: .ok)
        } catch {
            return APIGatewayV2Response(with: error, statusCode: .notFound)
        }
    }
    
    func listLambdaHandler(context: AWSLambdaRuntimeCore.LambdaContext, event: APIGatewayV2Request) async -> APIGatewayV2Response {
        do {
            let result = try await service.listItems()
            return APIGatewayV2Response(with: result, statusCode: .ok)
        } catch {
            return APIGatewayV2Response(with: error, statusCode: .forbidden)
        }
    }
}
