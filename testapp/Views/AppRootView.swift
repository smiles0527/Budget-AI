//
//  AppRootView.swift
//  testapp
//
//  Created by Curtis Wei on 2025-08-24.
//

import SwiftUI

struct AppRootView: View {
    var body: some View {
        VStack {
            Text("FBLA PLANNING")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.black)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white)
    }
}

#Preview {
    AppRootView()
}
