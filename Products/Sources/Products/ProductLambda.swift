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

import SotoDynamoDB
import AWSLambdaEvents
import AWSLambdaRuntime
import AsyncHTTPClient
import Logging
import NIO
import ProductService

enum Operation: String {
    case create = "build/Products.create"
    case read = "build/Products.read"
    case update = "build/Products.update"
    case delete = "build/Products.delete"
    case list = "build/Products.list"
}

struct EmptyResponse: Codable {}

struct ProductLambda: LambdaHandler {
    
    typealias In = APIGateway.V2.Request
    typealias Out = APIGateway.V2.Response
    
    let dbTimeout: Int64 = 30
    let region: Region
    let db: SotoDynamoDB.DynamoDB
    let service: ProductService
    let tableName: String
    let operation: Operation
    var httpClient: HTTPClient
    
    static func currentRegion() -> Region {
        if let awsRegion = Lambda.env("AWS_REGION") {
            let value = Region(rawValue: awsRegion)
            return value
        } else {
            return .useast1
        }
    }
    
    static func tableName() throws -> String {
        guard let tableName = Lambda.env("PRODUCTS_TABLE_NAME") else {
            throw APIError.tableNameNotFound
        }
        return tableName
    }
    
    init(context: Lambda.InitializationContext) throws {
        
        guard let handler = Lambda.env("_HANDLER"),
            let operation = Operation(rawValue: handler) else {
                throw APIError.invalidHandler
        }
        self.operation = operation
        self.region = Self.currentRegion()
        
        let lambdaRuntimeTimeout: TimeAmount = .seconds(dbTimeout)
        let timeout = HTTPClient.Configuration.Timeout(
            connect: lambdaRuntimeTimeout,
            read: lambdaRuntimeTimeout
        )
    
        let configuration = HTTPClient.Configuration(timeout: timeout)
        self.httpClient = HTTPClient(
            eventLoopGroupProvider: .shared(context.eventLoop),
            configuration: configuration
        )
        
        let awsClient = AWSClient(httpClientProvider: .shared(self.httpClient))
        self.db = SotoDynamoDB.DynamoDB(client: awsClient, region: region)
        self.tableName = try Self.tableName()

        self.service = ProductService(
            db: db,
            tableName: tableName
        )
    }
    
    func handle(
        context: Lambda.Context, event: APIGateway.V2.Request,
        callback: @escaping (Result<APIGateway.V2.Response, Error>) -> Void
    ) {
        let _ = ProductLambdaHandler(service: service, operation: operation)
            .handle(context: context, event: event)
            .always { (result) in
                callback(result)
        }
    }
}
