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

import ProductService
import NIO
import Foundation
import LambdaSwiftSprinter
import LambdaSwiftSprinterNioPlugin
import Logging

public typealias APIGatewaySyncLambda = SyncCodableNIOLambda<APIGatewayProxySimpleEvent, APIGatewayProxyResult>

public struct APIGatewayProxyResultConfig {
    var statusCode: Int
    var errorResult: APIGatewayProxyResult
}

public class APIGatewayProxyLambda<T: Codable>: LambdaHandler {
    
    init(config: APIGatewayProxyResultConfig, handler: @escaping (APIGatewayProxySimpleEvent, Context) throws -> EventLoopFuture<T>) {
        self.handler = handler
        self.config = config
    }
    internal var config: APIGatewayProxyResultConfig
    internal var handler: (APIGatewayProxySimpleEvent, Context) throws -> EventLoopFuture<T>
    
    internal let encoder = JSONEncoder()
    internal let decoder = JSONDecoder()
    
    
}

public extension APIGatewayProxyLambda {
    
    func commonHandler(event: Data, context: Context) -> LambdaResult {
        logger.info("\(String(describing: event))")
        do {
            let decodedEvent = try decoder.decode(APIGatewayProxySimpleEvent.self, from: event)
            let object = try handler(decodedEvent, context).wait()
            let result = APIGatewayProxyResult(object: object, statusCode: config.statusCode)
            let data = try encoder.encode(result)
            //logger.info("\(String(describing: result))")
            return .success(data)
        } catch {
            if let data = try? encoder.encode(config.errorResult) {
                logger.error("\(String(describing: config.errorResult))")
                return .success(data)
            } else {
                logger.error("Internal Error")
                return .failure(error)
            }
        }
    }
}


let responseNoContent = APIGatewayProxyResultConfig(
    statusCode: 204,
    errorResult: APIGatewayProxyResult(object: "Invalid Request",
                                       statusCode: 404)
)

let responseCreated = APIGatewayProxyResultConfig(
    statusCode: 201,
    errorResult: APIGatewayProxyResult(object: "Invalid Request",
                                       statusCode: 404)
)

let responseOK = APIGatewayProxyResultConfig(
    statusCode: 200,
    errorResult: APIGatewayProxyResult(object: "Invalid Request",
                                       statusCode: 404)
)
