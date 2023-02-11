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
import Foundation
import NIO

extension DateFormatter {
    static var iso8061: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter
    }
}

extension Date {
    var iso8601: String {
        let formatter = DateFormatter.iso8061
        return formatter.string(from: self)
    }
}

extension String {
    var iso8601: Date? {
        let formatter = DateFormatter.iso8061
        return formatter.date(from: self)
    }
    
    var timeIntervalSince1970String: String? {
        guard let timeInterval = self.iso8601?.timeIntervalSince1970 else {
            return nil
        }
        return "\(timeInterval)"
    }
}

public class ProductService {
    
    enum ProductError: Error {
        case notFound
    }
    
    let db: DynamoDB
    let tableName: String
    
    public init(db: DynamoDB, tableName: String) {
        self.db = db
        self.tableName = tableName
    }
}

public extension ProductService {
    
    func createItem(product: Product) async throws -> Product {
        var product = product
        let date = Date()
        product.createdAt = date.iso8601
        product.updatedAt = date.iso8601
        let input = DynamoDB.PutItemCodableInput(item: product, tableName: tableName)
        
        let _ = try await db.putItem(input)
        return try await readItem(key: product.sku)
    }
    
    func readItem(key: String) async throws -> Product {
        let input = DynamoDB.GetItemInput(
            key: [Product.Field.sku: DynamoDB.AttributeValue.s(key)],
            tableName: tableName
        )
        let data = try await db.getItem(input, type: Product.self)
        guard let product = data.item else {
            throw ProductError.notFound
        }
        return product
    }
    
    func updateItem(product: Product) async throws -> Product {
        var product = product
        let date = Date()
        let updatedAt = date.iso8601
        product.updatedAt = date.iso8601
        
        let input = DynamoDB.UpdateItemInput(
            conditionExpression: "attribute_exists(#createdAt)",
            expressionAttributeNames: [
                "#name": Product.Field.name,
                "#description": Product.Field.description,
                "#updatedAt": Product.Field.updatedAt,
                "#createdAt": Product.Field.createdAt
            ],
            expressionAttributeValues: [
                ":name": DynamoDB.AttributeValue.s(product.name),
                ":description": DynamoDB.AttributeValue.s(product.description),
                ":updatedAt": DynamoDB.AttributeValue.s(updatedAt)
            ],
            key: [Product.Field.sku: DynamoDB.AttributeValue.s(product.sku)],
            returnValues: DynamoDB.ReturnValue.allNew,
            tableName: tableName,
            updateExpression: "SET #name = :name, #description = :description, #updatedAt = :updatedAt"
        )
        let _ = try await db.updateItem(input)
        return try await readItem(key: product.sku)
    }
    
    func deleteItem(key: String) async throws {
        let input = DynamoDB.DeleteItemInput(
            key: [Product.Field.sku: DynamoDB.AttributeValue.s(key)],
            tableName: tableName
        )
        let _ = try await db.deleteItem(input)
        return
    }
    
    func listItems() async throws -> [Product] {
        let input = DynamoDB.ScanInput(tableName: tableName)
        let data = try await db.scan(input, type: Product.self)
        return data.items ?? []
    }
}
