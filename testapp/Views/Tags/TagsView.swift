//
//  TagsView.swift
//  testapp
//
//  Tags management view
//

import SwiftUI

struct TagsView: View {
    @StateObject private var viewModel = TagsViewModel()
    @State private var showingCreateTag = false
    
    var body: some View {
        List {
            if viewModel.isLoading && viewModel.tags.isEmpty {
                ProgressView()
            } else if viewModel.tags.isEmpty {
                Text("No tags yet")
                    .foregroundColor(.secondary)
            } else {
                ForEach(viewModel.tags, id: \.id) { tag in
                    TagRow(tag: tag, viewModel: viewModel)
                }
            }
            
            if let error = viewModel.errorMessage {
                Section {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.caption)
                }
            }
        }
        .navigationTitle("Tags")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Add") {
                    showingCreateTag = true
                }
            }
        }
        .sheet(isPresented: $showingCreateTag) {
            CreateTagView(viewModel: viewModel)
        }
        .refreshable {
            await viewModel.loadTags()
        }
        .task {
            await viewModel.loadTags()
        }
    }
}

struct TagRow: View {
    let tag: Tag
    @ObservedObject var viewModel: TagsViewModel
    @State private var showingDeleteAlert = false
    
    var body: some View {
        HStack {
            if let color = tag.color {
                Circle()
                    .fill(Color(hex: color) ?? .blue)
                    .frame(width: 20, height: 20)
            } else {
                Circle()
                    .fill(Color.blue)
                    .frame(width: 20, height: 20)
            }
            
            Text(tag.name)
                .font(.body)
            
            Spacer()
            
            Button(action: { showingDeleteAlert = true }) {
                Image(systemName: "trash")
                    .foregroundColor(.red)
                    .font(.caption)
            }
        }
        .alert("Delete Tag", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                Task {
                    await viewModel.deleteTag(id: tag.id)
                }
            }
        } message: {
            Text("Are you sure you want to delete this tag? It will be removed from all transactions.")
        }
    }
}

@MainActor
class TagsViewModel: ObservableObject {
    @Published var tags: [Tag] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let apiClient = APIClient.shared
    
    func loadTags() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let response = try await apiClient.getTags()
            tags = response.items
        } catch {
            errorMessage = ErrorHandler.userFriendlyMessage(for: error)
        }
        
        isLoading = false
    }
    
    func createTag(name: String, color: String?) async {
        isLoading = true
        errorMessage = nil
        
        do {
            _ = try await apiClient.createTag(name: name, color: color)
            await loadTags()
        } catch {
            errorMessage = ErrorHandler.userFriendlyMessage(for: error)
        }
        
        isLoading = false
    }
    
    func deleteTag(id: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            try await apiClient.deleteTag(tagId: id)
            await loadTags()
        } catch {
            errorMessage = ErrorHandler.userFriendlyMessage(for: error)
        }
        
        isLoading = false
    }
}

struct CreateTagView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: TagsViewModel
    @State private var name = ""
    @State private var colorHex = ""
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationView {
            Form {
                Section("Tag Details") {
                    TextField("Tag Name", text: $name)
                    
                    TextField("Color (hex, optional)", text: $colorHex)
                        .autocapitalization(.none)
                }
                
                if let error = errorMessage {
                    Section {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("New Tag")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveTag()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
    
    private func saveTag() {
        guard !name.isEmpty else {
            errorMessage = "Please enter a tag name"
            return
        }
        
        errorMessage = nil
        
        Task {
            await viewModel.createTag(
                name: name,
                color: colorHex.isEmpty ? nil : colorHex
            )
            dismiss()
        }
    }
}

extension Color {
    init?(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            return nil
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

#Preview {
    NavigationView {
        TagsView()
    }
}

