//
//  FirestoreManager.Read.swift
//  FirebaseInfra
//
//  Created by Eunji Hwang on 12/5/2025.
//

import FirebaseFirestore

extension FirestoreManager {

    /// Firestore에서 특정 문서 1개를 읽어와 디코딩합니다.
    ///
    /// - Parameters:
    ///   - collection: 읽을 컬렉션
    ///   - docId: 문서 ID
    ///   - type: 디코딩할 타입
    /// - Returns: 디코딩된 모델 또는 nil
    ///
    /// - Example:
    /// ```swift
    /// let writing = try await FirestoreManager.getDocument(
    ///     collection: .writings,
    ///     docId: "abc123",
    ///     type: Writing.self
    /// )
    /// ```
    public func getDocument<T: Decodable>(
        collection: NFFirestoreCollection,
        docId: String,
        type: T.Type
    ) async throws -> T? {
        let snapshot = try await Firestore.firestore()
            .collection(collection.rawValue)
            .document(docId)
            .getDocument()

        return try snapshot.data(as: T.self)
    }
  
    public func getDocument<T: Decodable>(
        collection: NFFirestoreCollection,
        docId: String,
        subCollection: NFFirestoreCollection,
        subDocId: String,
        type: T.Type
    ) async throws -> T? {
        let snapshot = try await Firestore.firestore()
            .collection(collection.rawValue)
            .document(docId)
            .collection(subCollection.rawValue)
            .document(subDocId)
            .getDocument()

        return try snapshot.data(as: T.self)
    }
  
    
    
//    public func getSubCollection(mainCollection: NFFirestoreCollection, id: String, subCollection: NFFirestoreCollection, subId: String) -> CollectionReference {
//        let mainRef = Firestore.firestore().collection(mainCollection.rawValue).document(id).collection(subCollection.rawValue).document(subId)
//
//    }


    /// Firestore 쿼리를 실행하고, 여러 문서를 가져옵니다.
    ///
    /// - Parameters:
    ///   - query: Firestore Query 객체
    ///   - type: 디코딩할 타입
    /// - Returns: 디코딩된 모델 배열과 마지막 문서 (페이징용)
    ///
    /// - Example:
    /// ```swift
    /// let query = Firestore.firestore()
    ///     .collection("writings")
    ///     .order(by: "createdAt", descending: true)
    ///     .limit(to: 20)
    ///
    /// let (writings, lastDoc) = try await FirestoreManager.getDocuments(query: query, type: Writing.self)
    /// ```
    public func getDocuments<T: Decodable>(
        query: Query,
        type: T.Type
    ) async throws -> ([T], DocumentSnapshot?) {
        let snapshot = try await query.getDocuments()

        let models = snapshot.documents.compactMap { doc in
            try? doc.data(as: T.self)
        }

        return (models, snapshot.documents.last)
    }

    /// 디코딩 에러 상세 로그까지 출력하는 안전한 쿼리 조회
    ///
    /// - Example:
    /// ```swift
    /// let (writings, _) = try await FirestoreManager.getDetailedDocuments(query: ..., type: Writing.self)
    /// ```
    public func getDetailedDocuments<T: Decodable>(
        query: Query,
        type: T.Type
    ) async throws -> ([T], DocumentSnapshot?) {
        let snapshot = try await query.getDocuments()
        var result: [T] = []

        for doc in snapshot.documents {
            do {
                let value = try doc.data(as: T.self)
                result.append(value)
            } catch {
                print("❌ 디코딩 에러 (\(doc.documentID)): \(error)")
            }
        }

        return (result, snapshot.documents.last)
    }
}
