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

public enum APIError: Error {
    case invalidItem
    case tableNameNotFound
    case invalidRequest
}

extension Date {
    var iso8601: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter.string(from: self)
    }
}

public class ProductService {
    
    let db: DynamoDB
    let tableName: String
    
    public init(db: DynamoDB, tableName: String) {
        self.db = db
        self.tableName = tableName
    }
    
    public func createItem(product: Product) -> EventLoopFuture<DynamoDB.PutItemOutput> {
        
        var product = product
        let date = Date().iso8601
        product.createdAt = date
        product.updatedAt = date
        
        let input = DynamoDB.PutItemInput(
            item: product.dynamoDictionary,
            tableName: tableName
        )
        return db.putItem(input)
    }
    
    public func readItem(key: String) -> EventLoopFuture<DynamoDB.GetItemOutput> {
        let input = DynamoDB.GetItemInput(
            key: [ProductField.sku: DynamoDB.AttributeValue(s: key)],
            tableName: tableName
        )
        return db.getItem(input)
    }
    
    public func updateItem(product: Product) -> EventLoopFuture<DynamoDB.UpdateItemOutput> {
        
        var product = product
        let date = Date().iso8601
        product.updatedAt = date
        
        let input = DynamoDB.UpdateItemInput(
            expressionAttributeNames: [
                "#name": ProductField.name,
                "#description": ProductField.description,
                "#updatedAt": ProductField.updatedAt
            ],
            expressionAttributeValues: [
                ":name": DynamoDB.AttributeValue(s:product.name),
                ":description": DynamoDB.AttributeValue(s:product.description),
                ":updatedAt": DynamoDB.AttributeValue(s:product.updatedAt)
            ],
            key: [ProductField.sku: DynamoDB.AttributeValue(s: product.sku)],
            returnValues: DynamoDB.ReturnValue.allNew,
            tableName: tableName,
            updateExpression: "SET #name = :name, #description = :description, #updatedAt = :updatedAt"
        )
        return db.updateItem(input)
    }
    
    public func deleteItem(key: String) -> EventLoopFuture<DynamoDB.DeleteItemOutput> {
        let input = DynamoDB.DeleteItemInput(
            key: [ProductField.sku: DynamoDB.AttributeValue(s: key)],
            tableName: tableName
        )
        return db.deleteItem(input)
    }
    
    public func listItems() -> EventLoopFuture<DynamoDB.ScanOutput> {
        let input = DynamoDB.ScanInput(tableName: tableName)
        return db.scan(input)
    }
}
