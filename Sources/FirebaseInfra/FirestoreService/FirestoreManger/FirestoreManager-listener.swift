//
//  FirestoreManager-listen.swift
//  FirebaseInfra
//
//  Created by Eunji Hwang on 12/5/2025.
//
import FirebaseFirestore

extension FirestoreManager {

    /// 쿼리를 리스닝하여 문서 변경 사항(documentChanges)을 감지합니다.
    ///
    /// - Parameters:
    ///   - query: Firestore 쿼리
    ///   - completion: 변경된 문서들의 DocumentChange 배열을 전달
    /// - Returns: 리스너 등록 객체 (취소 시 필요)
    ///
    /// - Example:
    /// ```swift
    /// let listener = FirestoreManager.listenToChanges(query: query) { result in
    ///     switch result {
    ///     case .success(let changes):
    ///         for change in changes {
    ///             print(change.document.data())
    ///         }
    ///     case .failure(let error):
    ///         print("🔥 Error: \(error)")
    ///     }
    /// }
    /// ```
    public func listenToChanges(
        query: Query,
        completion: @escaping (Result<QuerySnapshot, Error>) -> Void
    ) -> ListenerRegistration {
        return query.addSnapshotListener { snapshot, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let snapshot = snapshot else {
                completion(.failure(CancellationError.init()))
                return
            }

            completion(.success(snapshot))
        }
    }

    /// 쿼리를 리스닝하여 전체 데이터를 특정 모델 타입으로 디코딩합니다.
    ///
    /// - Parameters:
    ///   - query: Firestore 쿼리
    ///   - type: 디코딩할 모델 타입
    ///   - completion: 디코딩된 데이터 배열 전달
    ///
    /// - Example:
    /// ```swift
    /// let listener = FirestoreManager.listenTo(query: query, type: Writing.self) { result in
    ///     switch result {
    ///     case .success(let writings):
    ///         print("Updated list: \(writings)")
    ///     case .failure(let error):
    ///         print("🔥 Error: \(error)")
    ///     }
    /// }
    /// ```
    public func listenTo<T: Decodable>(
        query: Query,
        type: T.Type,
        completion: @escaping (Result<[T], Error>) -> Void
    ) -> ListenerRegistration {
        return query.addSnapshotListener { snapshot, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let snapshot = snapshot else {
                completion(.success([]))
                return
            }

            let models = snapshot.documents.compactMap { doc in
                try? doc.data(as: T.self)
            }

            completion(.success(models))
        }
    }

    /// 단일 문서를 리스닝하여 해당 문서의 모델 데이터를 전달합니다.
    ///
    /// - Parameters:
    ///   - documentRef: 감시할 문서
    ///   - type: 디코딩할 모델 타입
    ///   - completion: 해당 문서의 모델 또는 nil
    ///
    /// - Example:
    /// ```swift
    /// let docRef = Firestore.firestore().collection("writings").document("abc123")
    /// let listener = FirestoreManager.listenToDocument(documentRef: docRef, type: Writing.self) { result in
    ///     print(result)
    /// }
    /// ```
    public func listenToDocument<T: Decodable>(
        documentRef: DocumentReference,
        type: T.Type,
        completion: @escaping (Result<T?, Error>) -> Void
    ) -> ListenerRegistration {
        return documentRef.addSnapshotListener { snapshot, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let snapshot = snapshot, snapshot.exists else {
                completion(.success(nil))
                return
            }

            let model = try? snapshot.data(as: T.self)
            completion(.success(model))
        }
    }
    
    
    /// 단일 문서를 리스닝하여 해당 문서의 모델 데이터를 전달합니다.
    ///
    /// - Parameters:
    ///   - documentRef: 감시할 문서
    ///   - type: 디코딩할 모델 타입
    ///   - completion: 해당 문서의 모델 또는 nil
    ///
    /// - Example:
    /// ```swift
    /// let docRef = Firestore.firestore().collection("writings").document("abc123")
    /// let listener = FirestoreManager.listenToDocument(documentRef: docRef, type: Writing.self) { result in
    ///     print(result)
    /// }
    /// ```
    public func listenToDocument<T: Decodable>(
        collection: NFFirestoreCollection,
        id: String,
        type: T.Type,
        completion: @escaping (Result<T, Error>) -> Void
    ) -> ListenerRegistration {
        
        let documentRef = Firestore.firestore().collection(collection.rawValue).document(id)
        return documentRef.addSnapshotListener { snapshot, error in
            
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let snapshot = snapshot, snapshot.exists else {
                completion(.failure(NSError(domain: "Firestore", code: -1, userInfo: [NSLocalizedDescriptionKey: "Nil snapshot"])))
                return
            }
            
            do {
                let model = try snapshot.data(as: T.self)
                completion(.success(model))
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    
    public func listenTo<T: Decodable>(
        query: Query,
        type: T.Type,
        completion: @escaping (Result<([T], DocumentSnapshot?), Error>) -> Void
    ) -> ListenerRegistration {
        query.addSnapshotListener { snapshot, error in
            if let error { completion(.failure(error)); return }
            guard let snapshot else {
                completion(.success(([], nil)))
                return
            }

            do {
                let items: [T] = try snapshot.documents.compactMap { doc in
                    try doc.data(as: T.self)
                }
                let last = snapshot.documents.last
                completion(.success((items, last)))
            } catch {
                completion(.failure(error))
            }
        }
    }
}
