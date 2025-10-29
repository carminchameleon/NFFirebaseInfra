//
//  StorageClient.swift
//  FirebaseInfra
//
//  Created by Eunji Hwang on 20/9/2025.
//
import FirebaseStorage
import Firebase
import SwiftUI
public final class FirebaseStorageManager {
    public init() {
            guard let app = FirebaseApp.app() else {
                fatalError("❌ FirebaseApp is not configured. Call FirebaseApp.configure() before using FirebaseStorageManager.")
            }
            self.storage = Storage.storage(app: app)
        
        }
    var storage: Storage
//    private let storage = Storage.storage()
    
    // MARK: - Upload
    //    let url = try await storageManager.uploadData(
    //        path: "actionBoards/123/cover.jpg",
    //        data: imageData
    //    )
    
    public func covertImageToData(image: UIImage) throws -> Data {
        guard let data = image.jpegData(compressionQuality: 0.75) else {
            throw URLError(.backgroundSessionWasDisconnected)
        }
        return data
    }
    
    public func uploadData(path: String, data: Data, contentType: String? = nil) async throws -> URL {
        let startTime = Date()
        print("🚀 Firebase upload started - Path: \(path)")
        print("🚀 Data size: \(String(format: "%.2f", Double(data.count) / 1024.0)) KB")
        
        let ref = getReference(path: path)
        let meta = StorageMetadata()
        meta.contentType = contentType ?? "image/jpeg"
        meta.cacheControl = "no-cache"
        
        let uploadStart = Date()
        _ = try await ref.putDataAsync(data, metadata: meta)
        let uploadDuration = Date().timeIntervalSince(uploadStart)
        print("✅ Upload to Firebase completed in \(String(format: "%.2f", uploadDuration))s")
        
        // Retry logic for eventual consistency issues
        let urlStart = Date()
        var lastError: Error?
        
        for attempt in 1...5 {
            do {
                let url = try await ref.downloadURL()
                let urlDuration = Date().timeIntervalSince(urlStart)
                if attempt > 1 {
                    print("✅ Download URL retrieved on attempt \(attempt) in \(String(format: "%.2f", urlDuration))s")
                } else {
                    print("✅ Download URL retrieved in \(String(format: "%.2f", urlDuration))s")
                }
                
                let totalDuration = Date().timeIntervalSince(startTime)
                print("✅ Total Firebase operation: \(String(format: "%.2f", totalDuration))s")
                
                return url
            } catch {
                lastError = error
                print("⚠️ Attempt \(attempt) failed: \(error.localizedDescription)")
                if attempt < 5 {
                    // Exponential backoff: 100ms, 200ms, 400ms, 800ms
                    let delayMs = UInt64(100 * (1 << (attempt - 1))) * 1_000_000
                    try? await Task.sleep(nanoseconds: delayMs)
                }
            }
        }
        
        print("❌ All retry attempts failed")
        throw lastError ?? NSError(domain: "FirebaseStorageManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to get download URL after retries"])
    }
        
    public func getReference(path: String) -> StorageReference {
        return storage.reference(withPath: path)
    }
    
    //let downloadURL = try await storageManager.downloadURL(forPath: "actionBoards/123/cover.jpg")
    public func downloadURL(forPath path: String) async throws -> URL {
       let ref = storage.reference(withPath: path)
       return try await ref.downloadURL()
    }

    /// Data 다운로드
//    public func downloadData(path: String, maxSize: Int64 = 5 * 1024 * 1024) async throws -> Data {
//        let ref = storage.reference(withPath: path)
//        return try await ref.getData(maxSize: maxSize)
//    }
    
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
