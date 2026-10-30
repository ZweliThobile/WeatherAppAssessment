//
//  MockForecastProvider.swift
//  WeatherAppAssessment
//
//  Created by Thobile Jiyane on 2026/10/30.
//
import Foundation
@testable import WeatherAppAssessment

final class MockForecastProvider: ForecastProvider {
    var result: Result<ForecastResult, Error>
    var onForecast: (() -> Void)?
    private(set) var requestedCoordinates: [(Double, Double)] = []

    init(result: Result<ForecastResult, Error>) {
        self.result = result
    }

    func forecast(
        latitude: Double,
        longitude: Double
    ) async throws -> ForecastResult {
        requestedCoordinates.append((latitude, longitude))
        onForecast?()
        return try result.get()
    }
}
