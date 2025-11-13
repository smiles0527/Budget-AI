//
//  FigmaService.swift
//  testapp
//
//  Service for fetching design tokens from Figma
//

import Foundation

struct FigmaConfig {
    static let apiToken = "YOUR_FIGMA_API_TOKEN" // Set this in your environment or config
    static let fileKey = "YOUR_FIGMA_FILE_KEY" // Your Figma file ID
}

struct FigmaColor {
    let name: String
    let hex: String
    let opacity: Double
}

struct FigmaTypography {
    let name: String
    let fontFamily: String
    let fontSize: CGFloat
    let fontWeight: String
    let lineHeight: CGFloat?
}

struct FigmaSpacing {
    let name: String
    let value: CGFloat
}

class FigmaService {
    static let shared = FigmaService()
    
    private init() {}
    
    // Fetch design tokens from Figma
    func fetchDesignTokens() async throws -> FigmaDesignTokens {
        guard let url = URL(string: "https://api.figma.com/v1/files/\(FigmaConfig.fileKey)") else {
            throw FigmaError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.setValue(FigmaConfig.apiToken, forHTTPHeaderField: "X-Figma-Token")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw FigmaError.apiError
        }
        
        // Parse Figma response and extract design tokens
        // This is a simplified version - you'll need to parse the actual Figma API response
        return try parseDesignTokens(from: data)
    }
    
    private func parseDesignTokens(from data: Data) throws -> FigmaDesignTokens {
        // Parse Figma API response
        // The Figma API returns a complex structure, so you'll need to:
        // 1. Find nodes with specific names (e.g., "Colors", "Typography", "Spacing")
        // 2. Extract style properties
        // 3. Convert to your design token format
        
        // For now, return empty tokens - you'll implement parsing based on your Figma structure
        return FigmaDesignTokens(colors: [], typography: [], spacing: [])
    }
}

struct FigmaDesignTokens {
    let colors: [FigmaColor]
    let typography: [FigmaTypography]
    let spacing: [FigmaSpacing]
}

enum FigmaError: Error {
    case invalidURL
    case apiError
    case parsingError
}

