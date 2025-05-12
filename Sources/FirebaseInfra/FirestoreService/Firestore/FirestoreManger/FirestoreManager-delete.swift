//
//  FirestoreManager-delete.swift
//  FirebaseInfra
//
//  Created by Eunji Hwang on 12/5/2025.
//

import FirebaseFirestore

extension FirestoreManager {

    /// 지정한 문서를 Firestore에서 삭제합니다.
    ///
    /// - Parameters:
    ///   - collection: 삭제할 문서가 있는 Firestore 컬렉션
    ///   - docId: 삭제할 문서의 ID
    ///
    /// - Example:
    /// ```swift
    /// try await FirestoreManager.delete(
    ///     collection: .writings,
    ///     docId: "abc123"
    /// )
    /// ```
    static func delete(
        collection: NFFirestoreCollection,
        docId: String
    ) async throws {
        try await Firestore.firestore()
            .collection(collection.rawValue)
            .document(docId)
            .delete()
    }

    /// DocumentReference를 직접 받아 삭제할 수도 있습니다.
    ///
    /// - Parameters:
    ///   - docRef: Firestore DocumentReference 객체
    ///
    /// - Example:
    /// ```swift
    /// let ref = Firestore.firestore()
    ///     .collection("writings")
    ///     .document("abc123")
    ///
    /// try await FirestoreManager.delete(docRef: ref)
    /// ```
    static func delete(docRef: DocumentReference) async throws {
        try await docRef.delete()
    }
    

    /// 문서를 soft delete 처리합니다. (deleted_at 필드에 현재 시간 저장)
       ///
       /// - Parameters:
       ///   - collection: Firestore 컬렉션
       ///   - docId: 문서 ID
       ///   - additional: (선택) 함께 저장할 메타데이터 (예: deleted_by 등)
       ///
       /// - Example:
       /// ```swift
       /// try await FirestoreManager.softDelete(
       ///     collection: .writings,
       ///     docId: "abc123",
       ///     additional: ["deleted_by": "user_456"]
       /// )
       /// ```
       static func softDelete(
           collection: NFFirestoreCollection,
           docId: String,
           additional: [String: Any]? = nil
       ) async throws {
           var data: [String: Any] = [
               "deleted_at": Timestamp(date: Date())
           ]

           if let additional = additional {
               data.merge(additional) { _, new in new }
           }

           try await Firestore.firestore()
               .collection(collection.rawValue)
               .document(docId)
               .updateData(data)
       }

}

