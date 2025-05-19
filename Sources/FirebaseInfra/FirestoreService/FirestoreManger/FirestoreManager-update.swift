//
//  FirestoreManager-Update.swift
//  FirebaseInfra
//
//  Created by Eunji Hwang on 12/5/2025.
//
import FirebaseFirestore
extension FirestoreManager {
    /// 기존 문서의 필드들을 수정합니다.
     /// 문서가 존재하지 않으면 에러가 발생합니다.
     ///
     /// - Parameters:
     ///   - collection: 수정할 문서가 위치한 Firestore 컬렉션
     ///   - docId: 수정 대상 문서의 ID
     ///   - data: 수정할 필드와 값의 딕셔너리
     ///
     /// - Throws: 문서가 존재하지 않으면 오류 발생
     ///
     /// - Example:
     /// ```swift
     /// try await FirestoreManager.update(
     ///     collection: .writings,
     ///     docId: "abc123",
     ///     data: ["title": "새로운 제목", "views": 101]
     /// )
     /// ```
     static func update(collection: NFFirestoreCollection, docId: String, data: [String: Any]) async throws {
         try await Firestore.firestore()
             .collection(collection.rawValue)
             .document(docId)
             .updateData(data)
     }

     
     /// 특정 필드 하나만 수정할 수 있습니다.
     /// 문서가 존재하지 않으면 에러가 발생합니다.
     ///
     /// - Parameters:
     ///   - collection: Firestore 컬렉션
     ///   - docId: 문서 ID
     ///   - key: 수정할 필드 이름
     ///   - value: 수정할 값
     ///
     /// - Example:
     /// ```swift
     /// try await FirestoreManager.updateField(
     ///     collection: .writings,
     ///     docId: "abc123",
     ///     key: "views",
     ///     value: 300
     /// )
     /// ```
     static func updateField(collection: NFFirestoreCollection, docId: String, key: String, value: Any) async throws {
         try await Firestore.firestore()
             .collection(collection.rawValue)
             .document(docId)
             .updateData([key: value])
     }

     
     /// 여러 필드를 한 번에 수정할 수 있습니다.
     /// `update`와 같은 기능이며, 이름만 직관적으로 분리한 버전입니다.
     ///
     /// - Parameters:
     ///   - collection: Firestore 컬렉션
     ///   - docId: 문서 ID
     ///   - fields: 수정할 키-값 쌍 목록
     ///
     /// - Example:
     /// ```swift
     /// try await FirestoreManager.updateFields(
     ///     collection: .profiles,
     ///     docId: "user_456",
     ///     fields: [
     ///         "username": "carmen",
     ///         "bio": "Hello, I’m back!"
     ///     ]
     /// )
     /// ```
     static func updateFields(collection: NFFirestoreCollection, docId: String, fields: [String: Any]) async throws {
         try await Firestore.firestore()
             .collection(collection.rawValue)
             .document(docId)
             .updateData(fields)
     }
}
