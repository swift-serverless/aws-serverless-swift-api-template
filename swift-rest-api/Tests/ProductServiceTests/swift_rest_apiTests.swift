import XCTest
import class Foundation.Bundle

struct APIGatewayEventIdenity: Codable {
    let accessKey: String?
    let accountId: String?
    let apiKey: String?
    let apiKeyId: String?
    let caller: String?
    let cognitoAuthenticationProvider: String?
    let cognitoAuthenticationType: String?
    let cognitoIdentityId: String?
    let cognitoIdentityPoolId: String?
    let sourceIp: String
    let user: String?
    let userAgent: String?
    let userArn: String?
}

//struct APIGatewayAuthResponseContext: Codable {
//
//}

struct APIGatewayEventRequestContext: Codable {
    let accountId: String
    let apiId: String
//    let authorizer: [String: Any]?
    let connectedAt: Int?
    let connectionId: String?
    let domainName: String?
    let domainPrefix: String?
    let eventType: String?
    let extendedRequestId: String?
    let httpMethod: String
    let identity: APIGatewayEventIdenity
    let messageDirection: String?
    let messageId: String?
    let path: String
    let stage: String
    let requestId: String
    let requestTime: String?
    let requestTimeEpoch: Int
    let resourceId: String
    let resourcePath: String
    let routeKey: String?
}

struct APIGatewayProxyEvent: Codable {
    let body: String?
    let headers: [String: String]?
    let multiValueHeaders: [String: [String]]?
    let httpMethod: String
    let isBase64Encoded: Bool
    let path: String
    let pathParameters: [String: String]?
    let queryStringParameters: [String: String]?
    let multiValueQueryStringParameters: [String: [String]]?
    let stageVariables: [String: String]?
    let requestContext: APIGatewayEventRequestContext?
    let resource: String
}

struct APIGatewayProxyResult: Codable {
    
    let isBase64Encoded: Bool?
    let statusCode: Int
    let headers: [String: String]?
    let multiValueHeaders: [String: [String]]?
    let body: String
}


final class GetProductTests: XCTestCase {
    
    func testDecode() {
        
        
        let data = jsonAPIGatewayProxyEvent.data(using: .utf8)!
        
        let decoder = JSONDecoder()
        do {
        let event = try decoder.decode(APIGatewayProxyEvent.self, from: data)
        } catch {
            print(error)
            XCTFail()
        }
    }

    static var allTests = [
        ("testDecode", testDecode),
    ]
}
