//
//  PrivacyControlsView.swift
//  testapp
//
//  Privacy controls for data sharing and GDPR compliance
//

import SwiftUI

struct PrivacyControlsView: View {
    @StateObject private var viewModel = PrivacyControlsViewModel()
    @State private var showingDataDownload = false
    
    var body: some View {
        List {
            Section("Data Sharing") {
                Toggle("Share anonymized insights", isOn: $viewModel.shareAnonymizedInsights)
                    .onChange(of: viewModel.shareAnonymizedInsights) { newValue in
                        Task {
                            await viewModel.updatePrivacySettings()
                        }
                    }
                
                Toggle("Analytics & Crash Reports", isOn: $viewModel.analyticsEnabled)
                    .onChange(of: viewModel.analyticsEnabled) { newValue in
                        Task {
                            await viewModel.updatePrivacySettings()
                        }
                    }
            }
            
            Section("Data Management") {
                Button(action: {
                    showingDataDownload = true
                    Task {
                        await viewModel.requestDataDownload()
                    }
                }) {
                    HStack {
                        Image(systemName: "arrow.down.doc")
                        Text("Download My Data")
                        Spacer()
                        if viewModel.isDownloading {
                            ProgressView()
                        }
                    }
                }
                .disabled(viewModel.isDownloading)
                
                if let downloadURL = viewModel.downloadURL {
                    Link("Download Link", destination: URL(string: downloadURL)!)
                        .foregroundColor(.blue)
                }
            }
            
            Section("Information") {
                Text("Your financial data is encrypted and stored securely. We use industry-standard encryption (AES-256) for data at rest and TLS for data in transit.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("You can delete your account and all associated data at any time from the Profile settings.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .navigationTitle("Privacy")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Data Download", isPresented: $showingDataDownload) {
            Button("OK") {}
        } message: {
            if let url = viewModel.downloadURL {
                Text("Your data download is ready. Tap the download link to access your data.")
            } else {
                Text("Your data download request has been submitted. You will receive an email when it's ready.")
            }
        }
    }
}

@MainActor
class PrivacyControlsViewModel: ObservableObject {
    @Published var shareAnonymizedInsights = true
    @Published var analyticsEnabled = true
    @Published var isDownloading = false
    @Published var downloadURL: String?
    
    private let apiClient = APIClient.shared
    
    func updatePrivacySettings() async {
        // Note: This would require a backend endpoint
        // For now, we'll just update local state
    }
    
    func requestDataDownload() async {
        isDownloading = true
        
        // Note: This would require a backend endpoint for GDPR data export
        // For now, we'll use the CSV export endpoint as a placeholder
        do {
            let calendar = Calendar.current
            let endDate = Date()
            let startDate = calendar.date(byAdding: .year, value: -10, to: endDate) ?? endDate
            
            let response = try await apiClient.exportCSV(
                fromDate: startDate.toInputString(),
                toDate: endDate.toInputString(),
                wait: false
            )
            
            if let url = response.download_url {
                downloadURL = url
            } else if let jobId = response.job_id {
                // Poll for completion
                await pollExportStatus(jobId: jobId)
            }
        } catch {
            print("Error requesting data download: \(error)")
        }
        
        isDownloading = false
    }
    
    private func pollExportStatus(jobId: String) async {
        // Poll every 2 seconds, max 30 seconds
        for _ in 0..<15 {
            do {
                let status = try await apiClient.getExportStatus(jobId: jobId)
                if let url = status.download_url {
                    downloadURL = url
                    return
                }
                try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
            } catch {
                break
            }
        }
    }
}

#Preview {
    NavigationView {
        PrivacyControlsView()
    }
}






