//
//  TagPickerView.swift
//  testapp
//
//  Tag picker for adding tags to transactions
//

import SwiftUI

struct TagPickerView: View {
    @Environment(\.dismiss) var dismiss
    let transactionId: String
    let currentTags: [Tag]
    let onTagAdded: () -> Void
    
    @StateObject private var viewModel = TagsViewModel()
    @StateObject private var transactionViewModel = TransactionDetailViewModel()
    
    var availableTags: [Tag] {
        viewModel.tags.filter { tag in
            !currentTags.contains(where: { $0.id == tag.id })
        }
    }
    
    var body: some View {
        NavigationView {
            List {
                if viewModel.isLoading {
                    ProgressView()
                } else if availableTags.isEmpty {
                    Text("No tags available")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(availableTags, id: \.id) { tag in
                        Button(action: {
                            Task {
                                await transactionViewModel.addTag(transactionId: transactionId, tagId: tag.id)
                                onTagAdded()
                                dismiss()
                            }
                        }) {
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
                                    .foregroundColor(.primary)
                                
                                Spacer()
                            }
                        }
                    }
                }
            }
            .navigationTitle("Add Tag")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .task {
                await viewModel.loadTags()
            }
        }
    }
}

#Preview {
    TagPickerView(transactionId: "1", currentTags: [], onTagAdded: {})
}

