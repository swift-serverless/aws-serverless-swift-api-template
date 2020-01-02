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
#if canImport(FoundationNetworking)
    import FoundationNetworking
#endif
import DynamoDB

public struct Product: Codable {
    public let sku: String
    public let name: String
    public let description: String
    public let createdAt: String?
    public let updatedAt: String?
}

public extension Product {
    var dynamoDictionary: [String : DynamoDB.AttributeValue] {
        var dictionary = ["sku": DynamoDB.AttributeValue(s:sku),
                          "name": DynamoDB.AttributeValue(s:name),
                          "description": DynamoDB.AttributeValue(s:description)]
        if let createdAt = createdAt {
            dictionary["createdAt"] = DynamoDB.AttributeValue(s:createdAt)
        }
        if let updatedAt = updatedAt {
            dictionary["updatedAt"] = DynamoDB.AttributeValue(s:updatedAt)
        }
        return dictionary
    }
    
    init(dictionary: [String: DynamoDB.AttributeValue]) throws {
        guard let name = dictionary["name"]?.s,
            let sku = dictionary["sku"]?.s,
            let description = dictionary["description"]?.s else {
                throw APIError.invalidItem
        }
        self.name = name
        self.sku = sku
        self.description = description
        self.createdAt = dictionary["createdAt"]?.s
        self.updatedAt = dictionary["updatedAt"]?.s
    }
}
