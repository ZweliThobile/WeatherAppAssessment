//
//  ContentView.swift
//  WeatherAppAssessment
//
//  Created by Thobile Jiyane on 2026/10/18.
//

import SwiftUI

struct ContentView: View {
    @State private var location = LocationManager()
    
    
    var body: some View {
        ZStack {
            Image("Cloudy")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Hello, worjdkdkld!")
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
