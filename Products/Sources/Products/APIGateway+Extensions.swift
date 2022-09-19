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

import AWSLambdaEvents
import class Foundation.JSONEncoder
import class Foundation.JSONDecoder

public enum APIError: Error {
    case invalidItem
    case tableNameNotFound
    case invalidRequest
    case invalidHandler
}

extension APIGateway.V2.Request {
    
    static private let decoder = JSONDecoder()
    
    public func bodyObject<T: Codable>() throws -> T {
        guard let body = self.body,
            let dataBody = body.data(using: .utf8)
            else {
                throw APIError.invalidRequest
        }
        return try Self.decoder.decode(T.self, from: dataBody)
    }
}

extension APIGateway.V2.Response {
    
    private static let encoder = JSONEncoder()
    
    public static let defaultHeaders = [
        "Content-Type": "application/json",
        //Security warning: XSS are enabled
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Methods": "OPTIONS,GET,POST,PUT,DELETE",
        "Access-Control-Allow-Credentials": "true",
    ]
    
    public init(with error: Error, statusCode: AWSLambdaEvents.HTTPResponseStatus) {
        self.init(
            statusCode: statusCode,
            headers: APIGateway.V2.Response.defaultHeaders,
            body: "{\"message\":\"\(String(describing: error))\"}",
            isBase64Encoded: false
        )
    }
    
    public init<Out: Encodable>(with object: Out, statusCode: AWSLambdaEvents.HTTPResponseStatus) {
        var body: String = "{}"
        if let data = try? Self.encoder.encode(object) {
            body = String(data: data, encoding: .utf8) ?? body
        }
        self.init(
            statusCode: statusCode,
            headers: APIGateway.V2.Response.defaultHeaders,
            body: body,
            isBase64Encoded: false
        )
    }
}
