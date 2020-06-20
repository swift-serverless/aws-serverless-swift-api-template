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

import AWSDynamoDB
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
    
    let db: DynamoDB
    let tableName: String
    
    public init(db: DynamoDB, tableName: String) {
        self.db = db
        self.tableName = tableName
    }
    
    public func createItem(product: Product) -> EventLoopFuture<Product> {
        
        var product = product
        let date = Date()
        product.createdAt = date.iso8601
        product.updatedAt = date.iso8601
        
        let input = DynamoDB.PutItemInput(
            item: product.dynamoDictionary,
            tableName: tableName
        )
        return db.putItem(input).flatMap { _ -> EventLoopFuture<Product> in
            return self.readItem(key: product.sku)
        }
    }
    
    public func readItem(key: String) -> EventLoopFuture<Product> {
        let input = DynamoDB.GetItemInput(
            key: [Product.Field.sku: DynamoDB.AttributeValue.s(key)],
            tableName: tableName
        )
        return db.getItem(input).flatMapThrowing { data -> Product in
            return try Product(dictionary: data.item ?? [:])
        }
    }
    
    public func updateItem(product: Product) -> EventLoopFuture<Product> {
        var product = product
        let date = Date()
        let updatedAt = "\(date.timeIntervalSince1970)"
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
                ":updatedAt": DynamoDB.AttributeValue.n(updatedAt)
            ],
            key: [Product.Field.sku: DynamoDB.AttributeValue.s(product.sku)],
            returnValues: DynamoDB.ReturnValue.allNew,
            tableName: tableName,
            updateExpression: "SET #name = :name, #description = :description, #updatedAt = :updatedAt"
        )
        return db.updateItem(input).flatMap { _ -> EventLoopFuture<Product> in
            return self.readItem(key: product.sku)
        }
    }
    
    public func deleteItem(key: String) -> EventLoopFuture<Void> {
        let input = DynamoDB.DeleteItemInput(
            key: [Product.Field.sku: DynamoDB.AttributeValue.s(key)],
            tableName: tableName
        )
        return db.deleteItem(input).map { _ in Void() }
    }
    
    public func listItems() -> EventLoopFuture<[Product]> {
        let input = DynamoDB.ScanInput(tableName: tableName)
        return db.scan(input)
            .flatMapThrowing { data -> [Product] in
                let products: [Product]? = try data.items?.compactMap { (item) -> Product in
                    return try Product(dictionary: item)
                }
                return products ?? []
        }
    }
}
