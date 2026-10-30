//
//  OpenWeatherForecastProvider.swift
//  WeatherAppAssessment
//
//  Created by Thobile Jiyane on 2026/10/30.
//
import Foundation

struct OpenWeatherForecastProvider: ForecastProvider {
    func forecast(
        latitude: Double,
        longitude: Double
    ) async throws -> ForecastResult {
        
        guard let apiKey = OpenWeatherAPIKey.current else {
            throw WeatherServiceError.rejectedKey
        }

        let forecast = try await OpenWeatherClient.forecast(
            latitude: latitude,
            longitude: longitude,
            apiKey: apiKey
        )

        return ForecastResult(
            cityName: forecast.cityName,
            days: forecast.days,
            unitSymbol: forecast.unitSymbol,
            backgroundImage: forecast.backgroundImage
        )
    }
}
