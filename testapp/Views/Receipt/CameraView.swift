//
//  CameraView.swift
//  testapp
//
//  Camera view for receipt capture
//

import SwiftUI
import AVFoundation

struct CameraView: UIViewControllerRepresentable {
    @Binding var capturedImage: UIImage?
    @Environment(\.dismiss) var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .camera
        picker.allowsEditing = false
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraView
        
        init(_ parent: CameraView) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.capturedImage = image
            }
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

struct ReceiptCaptureView: View {
    @StateObject private var uploader = ReceiptUploader.shared
    @State private var showingCamera = false
    @State private var capturedImage: UIImage?
    @State private var isUploading = false
    @State private var uploadProgress: String?
    @State private var errorMessage: String?
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(spacing: 24) {
            if let image = capturedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 400)
                    .cornerRadius(12)
                
                if isUploading {
                    VStack(spacing: 8) {
                        ProgressView()
                        if let progress = uploadProgress {
                            Text(progress)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                } else {
                    Button("Upload Receipt") {
                        uploadReceipt(image: image)
                    }
                    .buttonStyle(.borderedProminent)
                }
            } else {
                Button(action: { showingCamera = true }) {
                    VStack(spacing: 16) {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.blue)
                        
                        Text("Capture Receipt")
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
                }
            }
            
            if let error = errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
        .padding()
        .navigationTitle("Add Receipt")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingCamera) {
            CameraView(capturedImage: $capturedImage)
        }
        .onChange(of: capturedImage) { newValue in
            if newValue != nil {
                uploadReceipt(image: newValue!)
            }
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
                
                // Poll for completion
                _ = try await uploader.pollReceiptStatus(receiptId: receipt.id)
                
                uploadProgress = "Complete!"
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
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

