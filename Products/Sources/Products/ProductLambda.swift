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
import AWSDynamoDB
import NIO
import ProductService
import Logging
import AsyncHTTPClient
import AWSLambdaEvents

enum Operation: String {
    case create = "build/Products.create"
    case read = "build/Products.read"
    case update = "build/Products.update"
    case delete = "build/Products.delete"
    case list = "build/Products.list"
    case unknown
}

struct EmptyResponse: Codable {
    
}

struct ProductLambda: LambdaHandler {
    
    typealias In = APIGateway.SimpleRequest
    typealias Out = APIGateway.Response
    
    let dbTimeout:Int64 = 30
    
    let region: Region
    let db: AWSDynamoDB.DynamoDB
    let service: ProductService
    let tableName: String
    let operation: Operation

    var httpClient: HTTPClient
    
    static func currentRegion() -> Region {
        
        if let awsRegion = ProcessInfo.processInfo.environment["AWS_REGION"] {
            let value = Region(rawValue: awsRegion)
            return value
            
        } else {
            //Default configuration
            return .useast1
        }
    }
    
    static func tableName() throws -> String {
        guard let tableName = ProcessInfo.processInfo.environment["PRODUCTS_TABLE_NAME"] else {
            throw APIError.tableNameNotFound
        }
        return tableName
    }
    
    init(eventLoop: EventLoop) {
        
        let handler = Lambda.env("_HANDLER") ?? ""
        self.operation = Operation(rawValue: handler) ?? .unknown
        
        self.region = Self.currentRegion()
        logger.info("\(Self.currentRegion())")

        let lambdaRuntimeTimeout: TimeAmount = .seconds(dbTimeout)
        let timeout = HTTPClient.Configuration.Timeout(connect: lambdaRuntimeTimeout,
                                                           read: lambdaRuntimeTimeout)
        let configuration = HTTPClient.Configuration(timeout: timeout)
        self.httpClient = HTTPClient(eventLoopGroupProvider: .createNew, configuration: configuration)
    
        self.db = AWSDynamoDB.DynamoDB(region: region, httpClientProvider: .shared(self.httpClient))
        logger.info("DynamoDB")
        
        self.tableName = (try? Self.tableName()) ?? ""
        
        self.service = ProductService(
            db: db,
            tableName: tableName
        )
        logger.info("ProductService")
    }

    func handle(context: Lambda.Context, payload: APIGateway.SimpleRequest, callback: @escaping (Result<APIGateway.Response, Error>) -> Void) {
        let _ = ProductLambdaHandler(service: service, operation: operation).handle(context: context, payload: payload)
            .always { (result) in
                callback(result)
        }
    }
}
