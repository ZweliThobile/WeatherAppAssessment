//
//  ContentView.swift
//  WeatherAppAssessment
//
//  Created by Thobile Jiyane on 2026/10/18.
//

import SwiftUI

struct ContentView: View {
    @State private var location = LocationManager()
    @State private var forecastLoader = ForecastLoader(
        service: OpenWeatherForecastProvider()
    )

    var body: some View {
        ZStack {
            GeometryReader { geometry in
                Image(forecastLoader.backgroundImage)
                    .resizable()
                    .scaledToFill()
                    .frame(
                        width: geometry.size.width,
                        height: geometry.size.height
                    )
                    .clipped()
                    .ignoresSafeArea()
            }.ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    header
                    locationDetails
                    forecastContent
                    
                    Button("Refresh") {
                        location.requestCurrentLocation()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(location.isLocating || forecastLoader.isLoading)
                }
                .padding()
                .frame(maxWidth: 420)
                .frame(maxWidth: .infinity)
            }
            .onAppear {
                location.requestCurrentLocation()
            }
            .task(id: locationID){
                guard let location = location.location else { return }
                await forecastLoader.load(
                    latitude: location.coordinate.latitude,
                    longitude: location.coordinate.longitude)
            }
        }
    }
    
    private var locationID: String {
        guard let location = location.location else { return "" }
        return "\(location.coordinate.latitude),\(location.coordinate.longitude)"
    }
    
    
    private var header: some View {
        VStack(alignment: .leading){
            Text("5 Day Forecast")
                .font(.custom("Poppins-Bold", size: 18))
                .foregroundStyle(.white)
            
            Divider()
                .overlay(.white.opacity(0.8))
            
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    @ViewBuilder
    private var locationDetails: some View {
        if let location = location.location {
            Text("Using your current location, accurate to \(Int(location.horizontalAccuracy)) m")
                .font(.footnote)
                .foregroundStyle(.white)
        } else if location.isLocating {
            ProgressView("Finding your location…")
        } else {
            Text(location.message)
                .foregroundStyle(.white)
        }
    }
    
    @ViewBuilder
    private var forecastContent: some View {
        if forecastLoader.isLoading && forecastLoader.days.isEmpty {
            ProgressView("Loading the forecast…")
                .frame(maxWidth: .infinity)
                .foregroundStyle(.white)
        } else if let errorMessage = forecastLoader.errorMessage {
            Text(errorMessage)
                .foregroundStyle(.secondary)
        } else if !forecastLoader.days.isEmpty {
            VStack(spacing: 12) {
                ForEach(forecastLoader.days) { day in
                    WeatherCard(forecast:day)
                }
            }
        }
    }
    
    
    private func rounded(_ value: Double) -> String {
        String(Int(value.rounded()))
    }
}

struct WeatherCard: View {
    
    let forecast: DailyForecast
    
    var body: some View {
        VStack(alignment: .leading, spacing: 25) {
            
            Text(forecast.date.formatted(.dateTime.weekday(.wide)))
                .font(.custom("Poppins-Bold", size: 16))
                .foregroundStyle(.black)
            
            HStack {
                Image(forecast.icon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 65, height: 65)
                
                Spacer()
                
                Text("\(forecast.temperature)°")
                    .font(.custom("Poppins-SemiBold", size: 36))
                    .foregroundStyle(.black)
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(.white)
        .clipShape(
            RoundedRectangle(cornerRadius: 16)
        )
    }
}


#Preview {
    ContentView()
}
