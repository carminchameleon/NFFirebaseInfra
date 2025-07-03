//
//  FirestoreManager.swift
//  FirebaseInfra
//
//  Created by Eunji Hwang on 12/5/2025.
//
import FirebaseFirestore

public enum NFFirestoreCollection: String {
    case users
    case goals
}

public struct FirestoreManager {

    public init() {}
    
    /// 자동 생성된 문서 ID로 Firestore에 문서를 생성합니다.
    /// Encodable 객체를 전달하면 자동으로 JSON으로 변환되어 저장됩니다.
    ///
    /// - Parameters:
    ///   - collection: 저장할 Firestore 컬렉션
    ///   - data: 저장할 Encodable 객체
    /// - Returns: 생성된 문서의 DocumentReference
    ///
    /// - Example:
    /// ```swift
    /// struct Writing: Codable {
    ///     var title: String
    ///     var body: String
    /// }
    ///
    /// let writing = Writing(title: "Hello", body: "This is my post")
    /// let ref = try await FirestoreManager.create(collection: .writings, data: writing)
    /// ```
    @discardableResult
    public func create<T: Encodable>(collection: NFFirestoreCollection, data: T) async throws -> DocumentReference {
        return try Firestore.firestore()
            .collection(collection.rawValue)
            .addDocument(from: data)
    }
    
    public func createDocument(collection: NFFirestoreCollection) async throws -> DocumentReference {
        let docRef = Firestore.firestore()
            .collection(collection.rawValue)
            .document()
        return docRef
    }
    /// Firestore 문서 ID를 자동 생성하고, 해당 ID를 포함한 데이터로 저장합니다.
       ///
       /// - Parameters:
       ///   - collection: Firestore 컬렉션
       ///   - build: 자동 생성된 ID를 받아서 데이터(T)를 구성하는 클로저
       /// - Returns: 저장된 문서의 DocumentReference
       ///
       /// - Example:
       /// ```swift
       /// let ref = try await FirestoreManager.createWithAutoId(collection: .writings) { id in
       ///     Writing(id: id, title: "My Post", body: "Hello Firebase")
       /// }
       /// ```
       @discardableResult
        public func createWithAutoId<T: Encodable>(
           collection: NFFirestoreCollection,
           build: (String) -> T
       ) async throws -> DocumentReference {
           let docRef = Firestore.firestore()
               .collection(collection.rawValue)
               .document()

           let data = build(docRef.documentID)

           try await docRef.setData(from: data)

           return docRef
       }
    
    

    /// 지정된 문서 ID로 문서를 저장합니다.
    /// 기존 문서를 완전히 덮어쓰기 때문에, 기존 데이터는 모두 사라지고 새 데이터로 대체됩니다.
    ///
    /// - Parameters:
    ///   - collection: 저장할 Firestore 컬렉션
    ///   - docId: 지정할 문서 ID
    ///   - data: 저장할 Encodable 객체
    ///
    /// - Example:
    /// ```swift
    /// let user = User(id: "123", name: "Carmen")
    /// try await FirestoreManager.create(collection: .users, docId: "123", data: user)
    /// ```
    public func create<T: Encodable>(collection: NFFirestoreCollection, docId: String, data: T) async throws {
        try await Firestore.firestore()
            .collection(collection.rawValue)
            .document(docId)
            .setData(from: data)
    }

    /// 지정된 문서 ID로 데이터를 저장하되, merge 옵션을 사용합니다.
    /// 기존 문서가 존재하면 필드 단위로 병합되고, 존재하지 않으면 새로 생성됩니다.
    ///
    /// - Parameters:
    ///   - collection: Firestore 컬렉션
    ///   - docId: 문서 ID
    ///   - data: 저장할 Encodable 객체
    ///   - merge: true일 경우 기존 문서와 병합
    ///
    /// - Example:
    /// ```swift
    /// let profile = Profile(username: "calmoon", bio: "iOS dev")
    /// try await FirestoreManager.create(collection: .profiles, docId: "user_456", data: profile, merge: true)
    /// ```
    public func create<T: Encodable>(collection: NFFirestoreCollection, docId: String, data: T, merge: Bool) async throws {
        try await Firestore.firestore()
            .collection(collection.rawValue)
            .document(docId)
            .setData(from: data, merge: merge)
    }

    /// Dictionary 형태의 데이터를 문서에 저장합니다.
    /// merge가 true인 경우 기존 문서와 병합되고, false면 완전히 덮어씁니다.
    ///
    /// - Parameters:
    ///   - collection: Firestore 컬렉션
    ///   - docId: 문서 ID
    ///   - data: 저장할 [String: Any] 형태의 데이터
    ///   - merge: 병합 여부 (기본값 false)
    ///
    /// - Example:
    /// ```swift
    /// let data: [String: Any] = ["title": "My Post", "tags": ["swift", "firebase"]]
    /// try await FirestoreManager.create(collection: .writings, docId: "abc123", data: data, merge: true)
    /// ```
    public func create(collection: NFFirestoreCollection, docId: String, data: [String: Any], merge: Bool = false) async throws {
        try await Firestore.firestore()
            .collection(collection.rawValue)
            .document(docId)
            .setData(data, merge: merge)
    }
}
