//
//  CloudKitExtenstions.swift
//  ReviseDaily
//
//  Created by Kai Major on 24/05/2023.
//

import Foundation
import CloudKit

private let database = CKContainer.default().publicCloudDatabase

public func getPersonalID() async -> CKRecord.ID? {
    if let id = try? await CKContainer.default().userRecordID() {
        return id
    } else {
        return nil
    }
}

public func updateUserRecord(custom: (CKRecord) -> () ) async {
    guard let personalID = await getPersonalID() else {
        print("No user id")
        return
    }
    let record = CKRecord(recordType: CKRecord.SystemType.userRecord, recordID: personalID)
    custom(record)
    let operation = CKModifyRecordsOperation(recordsToSave: [record])
    operation.savePolicy = .changedKeys
    operation.modifyRecordsResultBlock = { results in
        switch results {
        case .success:
            print("Modify records result block")
        case .failure(let error):
            print("Error updating user info: \(error)")
        }
    }
    database.add(operation)
}

public func createNewRecord(recordType: CKRecord.RecordType, custom: (CKRecord) -> () ) {
    let record = CKRecord(recordType: recordType)
    custom(record)
    database.save(record) { savedRecord, error in
        if let error {
            print(error)
        } else {
            print("Uploaded record of type \"\(recordType)\" successfully!")
        }
    }
}

public func updateExistingRecord(record: CKRecord, custom: () -> () ) {
    custom()
    let operation = CKModifyRecordsOperation(recordsToSave: [record])
    operation.savePolicy = .changedKeys
    operation.modifyRecordsResultBlock = { result in
        switch result {
        case .success:
            print("Updating existing record!")
        case .failure(let error):
            print("Error updating existing record: \(error)")
        }
    }
    database.add(operation)
}

public func fetchAllRecords(_ recordType: CKRecord.RecordType, custom: @escaping ([CKRecord]) -> () ) async {
    let predicate = NSPredicate(value: true)
    let query = CKQuery(recordType: recordType, predicate: predicate)
    do {
        let CKReturn = try await database.records(matching: query)
        let matchedResults = CKReturn.matchResults
        let results = matchedResults.compactMap { $0.1 }
        let records = results.compactMap { try? $0.get() }
        custom(records)
    } catch {
        print("Error fetching records of type: \"\(recordType)\"")
    }
}
