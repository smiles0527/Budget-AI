//
//  AppRootView.swift
//  testapp
//
//  Created by Curtis Wei on 2025-08-24.
//

import SwiftUI

struct AppRootView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Home")
                }
            
            ExploreView()
                .tabItem {
                    Image(systemName: "magnifyingglass")
                    Text("Explore")
                }
            
            ProfileView()
                .tabItem {
                    Image(systemName: "person.fill")
                    Text("Profile")
                }
        }
        .accentColor(.blue)
    }
}

struct HomeView: View {
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("Welcome")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Your dashboard")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
                
                // Content Cards
                ScrollView {
                    VStack(spacing: 16) {
                        ContentCard(
                            title: "Quick Actions",
                            subtitle: "Get started with common tasks",
                            icon: "bolt.fill",
                            color: .blue
                        )
                        
                        ContentCard(
                            title: "Recent Activity",
                            subtitle: "See what's been happening",
                            icon: "clock.fill",
                            color: .green
                        )
                        
                        ContentCard(
                            title: "Statistics",
                            subtitle: "View your progress",
                            icon: "chart.bar.fill",
                            color: .orange
                        )
                    }
                    .padding(.horizontal)
                }
            }
            .navigationBarBackButtonHidden(true)
        }
    }
}

struct ExploreView: View {
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    Text("Search...")
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
                .padding(.horizontal)
                
                // Categories
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                    CategoryCard(title: "Featured", icon: "star.fill", color: .yellow)
                    CategoryCard(title: "Popular", icon: "flame.fill", color: .red)
                    CategoryCard(title: "New", icon: "sparkles", color: .purple)
                    CategoryCard(title: "Trending", icon: "chart.line.uptrend.xyaxis", color: .blue)
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .navigationTitle("Explore")
        }
    }
}

struct ProfileView: View {
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Profile Header
                VStack(spacing: 16) {
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 80, height: 80)
                        .overlay(
                            Image(systemName: "person.fill")
                                .foregroundColor(.white)
                                .font(.system(size: 40))
                        )
                    
                    VStack(spacing: 4) {
                        Text("User Name")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text("user@example.com")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.top)
                
                // Settings List
                VStack(spacing: 0) {
                    SettingsRow(icon: "person.circle", title: "Edit Profile", color: .blue)
                    SettingsRow(icon: "bell", title: "Notifications", color: .orange)
                    SettingsRow(icon: "gear", title: "Settings", color: .gray)
                    SettingsRow(icon: "questionmark.circle", title: "Help & Support", color: .green)
                }
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)
                .padding(.horizontal)
                
                Spacer()
            }
            .navigationTitle("Profile")
        }
    }
}

// MARK: - Supporting Views

struct ContentCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .frame(width: 40, height: 40)
                .background(color.opacity(0.1))
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

struct CategoryCard: View {
    let title: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title)
                .foregroundColor(color)
            
            Text(title)
                .font(.headline)
                .fontWeight(.medium)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

struct SettingsRow: View {
    let icon: String
    let title: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
                .frame(width: 24)
            
            Text(title)
                .font(.body)
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.white)
    }
}

#Preview {
    AppRootView()
}
