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
import DynamoDB
import NIO
import LambdaSwiftSprinter
import LambdaSwiftSprinterNioPlugin

public struct APIGatewayEventIdentity: Codable {
    public let accessKey: String?
    public let accountId: String?
    public let apiKey: String?
    public let apiKeyId: String?
    public let caller: String?
    public let cognitoAuthenticationProvider: String?
    public let cognitoAuthenticationType: String?
    public let cognitoIdentityId: String?
    public let cognitoIdentityPoolId: String?
    public let sourceIp: String
    public let user: String?
    public let userAgent: String?
    public let userArn: String?
}

//struct APIGatewayAuthResponseContext: Codable {
//
//}

public struct APIGatewayEventRequestContext: Codable {
    public let accountId: String
    public let apiId: String
//    let authorizer: [String: Any]?
    public let connectedAt: Int?
    public let connectionId: String?
    public let domainName: String?
    public let domainPrefix: String?
    public let eventType: String?
    public let extendedRequestId: String?
    public let httpMethod: String
    public let identity: APIGatewayEventIdentity
    public let messageDirection: String?
    public let messageId: String?
    public let path: String
    public let stage: String
    public let requestId: String
    public let requestTime: String?
    public let requestTimeEpoch: Int
    public let resourceId: String
    public let resourcePath: String
    public let routeKey: String?
}

public struct APIGatewayProxyEvent: Codable {
    public let body: String?
    public let headers: [String: String]?
    public let multiValueHeaders: [String: [String]]?
    public let httpMethod: String
    public let isBase64Encoded: Bool
    public let path: String
    public let pathParameters: [String: String]?
    public let queryStringParameters: [String: String]?
    public let multiValueQueryStringParameters: [String: [String]]?
    public let stageVariables: [String: String]?
    public let requestContext: APIGatewayEventRequestContext?
    public let resource: String
}

public struct APIGatewayProxySimpleEvent: Codable {
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

public struct APIGatewayProxyResult: Codable {
    
    public let isBase64Encoded: Bool?
    public let statusCode: Int
    public let headers: [String: String]?
    public let multiValueHeaders: [String: [String]]?
    public let body: String
    
    public init(isBase64Encoded: Bool? = false,
                statusCode: Int,
                headers: [String: String]? = nil,
                multiValueHeaders: [String: [String]]? = nil,
                body: String) {
        self.isBase64Encoded = isBase64Encoded
        self.statusCode = statusCode
        self.headers = headers
        self.multiValueHeaders = multiValueHeaders
        self.body = body
    }
    
    public init<T: Codable>(object: T, statusCode: Int) {
        let encoder = JSONEncoder()
        guard let value = try? encoder.encode(object),
            let outBody = String(data: value, encoding: .utf8) else {
                self.init(
                    statusCode: 400,
                    body: "{\"message\":\"Invalid object\"}"
                )
            return
        }
        self.init(
            statusCode: statusCode,
            headers: ["Content-Type": "application/json",
                      "Access-Control-Allow-Origin": "*"],
            body: outBody
        )
    }
}
