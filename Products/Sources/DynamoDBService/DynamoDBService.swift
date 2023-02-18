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

public protocol DynamoDBItem: Codable {
    var key: String { get set }
    var createdAt: String? { get set }
    var updatedAt: String? { get set }
}

public class DynamoDBService<T: DynamoDBItem> {
    
    enum ServiceError: Error {
        case notFound
    }
    
    let db: DynamoDB
    public let keyName: String
    let tableName: String
    
    public init(db: DynamoDB, tableName: String, keyName: String) {
        self.db = db
        self.tableName = tableName
        self.keyName = keyName
    }
}

public extension DynamoDBService {
    
    func createItem(item: T) async throws -> T {
        var item = item
        let date = Date()
        item.createdAt = date.iso8601
        item.updatedAt = date.iso8601
        let input = DynamoDB.PutItemCodableInput(
            conditionExpression: "attribute_not_exists(\(keyName))",
            item: item,
            tableName: tableName
        )
        let _ = try await db.putItem(input)
        return try await readItem(key: item.key)
    }
    
    func readItem(key: String) async throws -> T {
        let input = DynamoDB.GetItemInput(
            key: [keyName: DynamoDB.AttributeValue.s(key)],
            tableName: tableName
        )
        let data = try await db.getItem(input, type: T.self)
        guard let item = data.item else {
            throw ServiceError.notFound
        }
        return item
    }
    
    func updateItem(item: T) async throws -> T {
        var item = item
        let date = Date()
        item.updatedAt = date.iso8601
        let input = DynamoDB.UpdateItemCodableInput(
            conditionExpression: "attribute_exists(createdAt)",
            key: [keyName],
            tableName: tableName,
            updateItem: item
        )
        let _ = try await db.updateItem(input)
        return try await readItem(key: item.key)
    }
    
    func deleteItem(key: String) async throws {
        let input = DynamoDB.DeleteItemInput(
            key: [keyName: DynamoDB.AttributeValue.s(key)],
            tableName: tableName
        )
        let _ = try await db.deleteItem(input)
        return
    }
    
    func listItems() async throws -> [T] {
        let input = DynamoDB.ScanInput(tableName: tableName)
        let data = try await db.scan(input, type: T.self)
        return data.items ?? []
    }
}
