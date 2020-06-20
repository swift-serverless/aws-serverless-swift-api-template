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
import AWSDynamoDB

import AWSDynamoDB
import Foundation

public enum ProductError: Error {
    case invalidItem
}

extension Product {
    
    public var dynamoDictionary: [String: DynamoDB.AttributeValue] {
        var dictionary = [
            Field.sku: DynamoDB.AttributeValue(s: sku),
            Field.name: DynamoDB.AttributeValue(s: name),
            Field.description: DynamoDB.AttributeValue(s: description),
        ]
        if let createdAt = createdAt?.timeIntervalSince1970String {
            dictionary[Field.createdAt] = DynamoDB.AttributeValue(n: createdAt)
        }
        
        if let updatedAt = updatedAt?.timeIntervalSince1970String {
            dictionary[Field.updatedAt] = DynamoDB.AttributeValue(n: updatedAt)
        }
        return dictionary
    }
    
    public init(dictionary: [String: DynamoDB.AttributeValue]) throws {
        guard let name = dictionary[Field.name]?.s,
            let sku = dictionary[Field.sku]?.s,
            let description = dictionary[Field.description]?.s
            else {
                throw ProductError.invalidItem
        }
        self.name = name
        self.sku = sku
        self.description = description
        if let value = dictionary[Field.createdAt]?.n,
            let timeInterval = TimeInterval(value) {
            let date = Date(timeIntervalSince1970: timeInterval)
            self.createdAt = date.iso8601
        }
        if let value = dictionary[Field.updatedAt]?.n,
            let timeInterval = TimeInterval(value) {
            let date = Date(timeIntervalSince1970: timeInterval)
            self.updatedAt = date.iso8601
        }
    }
}

