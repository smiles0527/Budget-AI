//
//  CameraView.swift
//  testapp
//
//  Camera view for receipt capture
//

import SwiftUI
import AVFoundation
import PhotosUI

struct ImagePickerView: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Environment(\.dismiss) var dismiss
    var sourceType: UIImagePickerController.SourceType
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = sourceType
        picker.allowsEditing = false
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePickerView
        
        init(_ parent: ImagePickerView) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.selectedImage = image
            }
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

struct PhotoPickerView: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Environment(\.dismiss) var dismiss
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = 1
        
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: PhotoPickerView
        
        init(_ parent: PhotoPickerView) {
            self.parent = parent
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)
            
            guard let result = results.first else { return }
            
            if result.itemProvider.canLoadObject(ofClass: UIImage.self) {
                result.itemProvider.loadObject(ofClass: UIImage.self) { image, error in
                    DispatchQueue.main.async {
                        if let image = image as? UIImage {
                            self.parent.selectedImage = image
                        }
                    }
                }
            }
        }
    }
}

struct ReceiptCaptureView: View {
    @StateObject private var uploader = ReceiptUploader.shared
    @State private var showingImageSource = false
    @State private var showingCamera = false
    @State private var showingPhotoLibrary = false
    @State private var capturedImage: UIImage?
    @State private var isUploading = false
    @State private var uploadProgress: String?
    @State private var errorMessage: String?
    @State private var showingSuccess = false
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(spacing: 24) {
            if let image = capturedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 400)
                    .cornerRadius(12)
                    .padding()
                
                if isUploading {
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.5)
                        if let progress = uploadProgress {
                            Text(progress)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                } else {
                    HStack(spacing: 16) {
                        Button("Cancel") {
                            capturedImage = nil
                        }
                        .buttonStyle(.bordered)
                        
                        Button("Upload Receipt") {
                            uploadReceipt(image: image)
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                }
            } else {
                VStack(spacing: 24) {
                    Text("Add Receipt")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("Capture a photo or select from your library")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    VStack(spacing: 16) {
                        Button(action: {
                            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                                showingCamera = true
                            } else {
                                errorMessage = "Camera not available on this device"
                            }
                        }) {
                            HStack {
                                Image(systemName: "camera.fill")
                                Text("Take Photo")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        
                        Button(action: {
                            showingPhotoLibrary = true
                        }) {
                            HStack {
                                Image(systemName: "photo.on.rectangle")
                                Text("Choose from Library")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .foregroundColor(.primary)
                            .cornerRadius(12)
                        }
                    }
                }
                .padding()
            }
            
            if let error = errorMessage {
                Text(ErrorHandler.userFriendlyMessage(for: error))
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.horizontal)
                    .multilineTextAlignment(.center)
            }
        }
        .navigationTitle("Add Receipt")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingCamera) {
            ImagePickerView(selectedImage: $capturedImage, sourceType: .camera)
        }
        .sheet(isPresented: $showingPhotoLibrary) {
            PhotoPickerView(selectedImage: $capturedImage)
        }
        .alert("Receipt Uploaded", isPresented: $showingSuccess) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text("Your receipt is being processed. The transaction will appear shortly.")
        }
    }
    
    private func uploadReceipt(image: UIImage) {
        isUploading = true
        uploadProgress = "Uploading..."
        errorMessage = nil
        
        Task {
            do {
                let receipt = try await uploader.uploadReceipt(image: image)
                uploadProgress = "Processing receipt..."
                
                // Poll for completion (with timeout)
                do {
                    _ = try await uploader.pollReceiptStatus(receiptId: receipt.id, maxAttempts: 30)
                    uploadProgress = "Complete!"
                    showingSuccess = true
                } catch {
                    // Even if polling times out, receipt is uploaded and will process
                    uploadProgress = "Uploaded! Processing in background..."
                    showingSuccess = true
                }
            } catch {
                errorMessage = ErrorHandler.userFriendlyMessage(for: error)
            }
            
            isUploading = false
            uploadProgress = nil
        }
    }
}

#Preview {
    NavigationView {
        ReceiptCaptureView()
    }
}

