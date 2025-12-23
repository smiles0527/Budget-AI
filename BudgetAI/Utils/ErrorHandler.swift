//
//  ErrorHandler.swift
//  testapp
//
//  Error handling utilities
//

import Foundation

class ErrorHandler {
    static func userFriendlyMessage(for error: Error) -> String {
        if let apiError = error as? APIError {
            switch apiError {
            case .invalidURL:
                return "Invalid request. Please try again."
            case .invalidResponse:
                return "Received an invalid response from server."
            case .httpError(let code):
                switch code {
                case 401:
                    return "Please log in again."
                case 403:
                    return "You don't have permission to perform this action."
                case 404:
                    return "The requested item was not found."
                case 402:
                    return "This feature requires a premium subscription."
                case 429:
                    return "Too many requests. Please wait a moment."
                case 500...599:
                    return "Server error. Please try again later."
                default:
                    return "An error occurred (code: \(code))."
                }
            case .serverError(let message):
                return message
            case .decodingError:
                return "Failed to process server response."
            }
        }
        
        if let urlError = error as? URLError {
            switch urlError.code {
            case .notConnectedToInternet:
                return "No internet connection. Please check your network."
            case .timedOut:
                return "Request timed out. Please try again."
            case .cannotFindHost, .cannotConnectToHost:
                return "Cannot connect to server. Please check your connection."
            default:
                return "Network error: \(urlError.localizedDescription)"
            }
        }
        
        return error.localizedDescription
    }
}

