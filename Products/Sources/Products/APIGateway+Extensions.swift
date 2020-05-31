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
import AWSLambdaEvents
import ProductService

public extension APIGateway {
    struct SimpleRequest: Codable {
        public let body: String?
        public let pathParameters: [String: String]?
        
        public func object<T: Codable>() throws -> T {
            let decoder = JSONDecoder()
            guard let body = self.body,
                let dataBody = body.data(using: .utf8) else {
                    throw APIError.invalidRequest
            }
            return try decoder.decode(T.self, from: dataBody)
        }
    }
}

let defaultHeaders = ["Content-Type": "application/json",
               "Access-Control-Allow-Origin": "*",
               "Access-Control-Allow-Methods": "OPTIONS,GET,POST,PUT,DELETE",
               "Access-Control-Allow-Credentials": "true"]

extension APIGateway.Response {

    init(with error: Error, statusCode: AWSLambdaEvents.HTTPResponseStatus) {
    
        self.init(
            statusCode: statusCode,
            headers: defaultHeaders,
            multiValueHeaders: nil,
            body: "{\"message\":\"\(error.localizedDescription)\"}",
            isBase64Encoded: false
        )
    }
    
    init<Out: Encodable>(with object: Out, statusCode: AWSLambdaEvents.HTTPResponseStatus) {
        let encoder = JSONEncoder()
        
        var body: String = "{}"
        if let data = try? encoder.encode(object) {
            body = String(data: data, encoding: .utf8) ?? body
        }
        self.init(
            statusCode: statusCode,
            headers: defaultHeaders,
            multiValueHeaders: nil,
            body: body,
            isBase64Encoded: false
        )
        
    }
    
    init<Out: Encodable>(with result: Result<Out, Error>, statusCode: AWSLambdaEvents.HTTPResponseStatus) {
        
        switch result {
        case .success(let value):
            self.init(with: value, statusCode: statusCode)
        case .failure(let error):
            self.init(with: error, statusCode: statusCode)
        }
    }
}
