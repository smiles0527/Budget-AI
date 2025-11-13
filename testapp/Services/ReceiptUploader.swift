//
//  ReceiptUploader.swift
//  testapp
//
//  Handles receipt image upload and processing
//

import Foundation
import UIKit

class ReceiptUploader {
    static let shared = ReceiptUploader()
    private let apiClient = APIClient.shared
    
    private init() {}
    
    func uploadReceipt(image: UIImage) async throws -> Receipt {
        // Step 1: Request upload URL
        let uploadResponse = try await apiClient.uploadReceipt()
        
        // Step 2: Upload image to presigned URL
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw ReceiptUploadError.imageConversionFailed
        }
        
        guard let uploadURL = URL(string: uploadResponse.upload_url) else {
            throw ReceiptUploadError.invalidUploadURL
        }
        
        var request = URLRequest(url: uploadURL)
        request.httpMethod = "PUT"
        request.setValue("image/jpeg", forHTTPHeaderField: "Content-Type")
        request.httpBody = imageData
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw ReceiptUploadError.uploadFailed
        }
        
        // Step 3: Confirm upload
        try await apiClient.confirmReceipt(
            receiptId: uploadResponse.receipt_id,
            objectKey: uploadResponse.object_key,
            mime: "image/jpeg",
            size: imageData.count
        )
        
        // Step 4: Return receipt (will be processed asynchronously)
        return try await apiClient.getReceipt(id: uploadResponse.receipt_id)
    }
    
    func pollReceiptStatus(receiptId: String, maxAttempts: Int = 30) async throws -> Receipt {
        var attempts = 0
        
        while attempts < maxAttempts {
            let receipt = try await apiClient.getReceipt(id: receiptId)
            
            if receipt.ocr_status == "done" {
                return receipt
            }
            
            if receipt.ocr_status == "failed" {
                throw ReceiptUploadError.processingFailed
            }
            
            // Wait 1 second before next poll
            try await Task.sleep(nanoseconds: 1_000_000_000)
            attempts += 1
        }
        
        throw ReceiptUploadError.processingTimeout
    }
}

enum ReceiptUploadError: Error {
    case imageConversionFailed
    case invalidUploadURL
    case uploadFailed
    case processingFailed
    case processingTimeout
}

