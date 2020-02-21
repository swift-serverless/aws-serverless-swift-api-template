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

public struct ProductField {
    static let sku = "sku"
    static let name = "name"
    static let description = "description"
    static let createdAt = "createdAt"
    static let updatedAt = "updatedAt"
}

public extension Product {
    var dynamoDictionary: [String : DynamoDB.AttributeValue] {
        var dictionary = [ProductField.sku: DynamoDB.AttributeValue(s:sku),
                          ProductField.name: DynamoDB.AttributeValue(s:name),
                          ProductField.description: DynamoDB.AttributeValue(s:description)]
        if let createdAt = createdAt {
            dictionary[ProductField.createdAt] = DynamoDB.AttributeValue(s:createdAt)
        }
        
        if let updatedAt = updatedAt {
            dictionary[ProductField.updatedAt] = DynamoDB.AttributeValue(s:updatedAt)
        }
        return dictionary
    }
    
    init(dictionary: [String: DynamoDB.AttributeValue]) throws {
        guard let name = dictionary[ProductField.name]?.s,
            let sku = dictionary[ProductField.sku]?.s,
            let description = dictionary[ProductField.description]?.s else {
                throw APIError.invalidItem
        }
        self.name = name
        self.sku = sku
        self.description = description
        self.createdAt = dictionary[ProductField.createdAt]?.s
        self.updatedAt = dictionary[ProductField.updatedAt]?.s
    }
}
