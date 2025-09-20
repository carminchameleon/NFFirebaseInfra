//
//  StorageClient.swift
//  FirebaseInfra
//
//  Created by Eunji Hwang on 20/9/2025.
//
import FirebaseStorage

public final class FirebaseStorageManager {
    public init() {}
    
    private let storage = Storage.storage()
    
    // MARK: - Upload
    //    let url = try await storageManager.uploadData(
    //        path: "actionBoards/123/cover.jpg",
    //        data: imageData
    //    )
    func uploadData(path: String, data: Data, contentType: String? = nil) async throws -> URL {
        let reference = getReference(path: path)
        let meta = StorageMetadata()
        meta.contentType = contentType ?? "image/jpeg"
        meta.cacheControl = "no-cache"
        
        _ = try await ref.putDataAsync(data, metadata: meta)
        return try await ref.downloadURL()
    }
        
    func getReference(path: String) {
        return storage.reference(withPath: path)
    }
    
    //let downloadURL = try await storageManager.downloadURL(forPath: "actionBoards/123/cover.jpg")
    public func downloadURL(forPath path: String) async throws -> URL {
       let ref = storage.reference(withPath: path)
       return try await ref.downloadURL()
    }

    /// Data 다운로드
    public func downloadData(path: String, maxSize: Int64 = 5 * 1024 * 1024) async throws -> Data {
        let ref = storage.reference(withPath: path)
        return try await ref.getData(maxSize: maxSize)
    }
    
    func converGSToHttps(gsPath: String) async throws -> URL {
        let storageRef = storage.reference(forURL: gsPath)
        let url = try await storageRef.downloadURL()
        return url
    }

    
    func getPathForImage(path: String) -> StorageReference {
        Storage.storage().reference(withPath: path)
    }
    
    // gs로 되어 있는걸 UIImage로 리턴
    public func convertGSToUIImage(gsPath: String) async throws -> UIImage {
        let storageRef = Storage.storage().reference(forURL: gsPath)

        // withCheckedThrowingContinuation 으로 completion 기반을 async/await으로 래핑
        let data: Data = try await withCheckedThrowingContinuation { continuation in
            storageRef.getData(maxSize: 5 * 1024 * 1024) { data, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let data = data {
                    continuation.resume(returning: data)
                } else {
                    continuation.resume(throwing: NSError(domain: "convertGSToUIImage",
                                                         code: -1,
                                                         userInfo: [NSLocalizedDescriptionKey: "Unknown error"]))
                }
            }
        }

        guard let image = UIImage(data: data) else {
            throw NSError(domain: "convertGSToUIImage",
                          code: -2,
                          userInfo: [NSLocalizedDescriptionKey: "Failed to decode image"])
        }
        return image
    }
    
    
    public func delete(path: String) async throws {
         let ref = storage.reference(withPath: path)
         try await ref.delete()
    }
    
}
