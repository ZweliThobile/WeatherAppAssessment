//
//  WeatherAppAssessmentTests.swift
//
//  Created by Thobile Jiyane on 2026/10/18.
//

import Foundation
import Testing
@testable import WeatherAppAssessment

@MainActor
struct ForecastLoaderTests {

    @Test func startsWithEmptyForecastAndNoError() {
        let day = DailyForecast(
            date: Date(timeIntervalSince1970: 0),
            temperature: 24,
            icon: "Property 1=01.sun-light"
        )

        let provider = MockForecastProvider(result: .success(
            ForecastResult(
                cityName: "Johannesburg",
                days: [day],
                unitSymbol: "°C",
                backgroundImage: "Sunny"
            )
        ))
        let loader = ForecastLoader(service: provider)

        #expect(loader.days.isEmpty)
        #expect(loader.cityName.isEmpty)
        #expect(loader.unitSymbol == "°C")
        #expect(loader.isLoading == false)
        #expect(loader.errorMessage == nil)
        #expect(loader.backgroundImage == "Sunny")
    }
    
    @Test
    func successfulLoadUpdatesForecast() async {
        let day = DailyForecast(
            date: Date(timeIntervalSince1970: 0),
            temperature: 24,
            icon: "Property 1=01.sun-light"
        )

        let provider = MockForecastProvider(result: .success(
            ForecastResult(
                cityName: "Johannesburg",
                days: [day],
                unitSymbol: "°C",
                backgroundImage: "Sunny"
            )
        ))
        let loader = ForecastLoader(service: provider)

        await loader.load(latitude: -26.2041, longitude: 28.0473)

        #expect(loader.cityName == "Johannesburg")
        #expect(loader.days.count == 1)
        #expect(loader.days.first?.date == day.date)
        #expect(loader.days.first?.temperature == 24)
        #expect(loader.days.first?.icon == day.icon)
        #expect(loader.unitSymbol == "°C")
        #expect(loader.backgroundImage == "Sunny")
        #expect(loader.errorMessage == nil)
        #expect(loader.isLoading == false)

        #expect(provider.requestedCoordinates.count == 1)
        #expect(provider.requestedCoordinates.first?.0 == -26.2041)
        #expect(provider.requestedCoordinates.first?.1 == 28.0473)
    }

    @Test
    func failedLoadShowsErrorAndStopsLoading() async {
        let provider = MockForecastProvider(result: .failure(ForecastTestError()))
        let loader = ForecastLoader(service: provider)

        await loader.load(latitude: -26.2041, longitude: 28.0473)

        #expect(loader.days.isEmpty)
        #expect(loader.errorMessage == "Forecast unavailable.")
        #expect(loader.isLoading == false)
    }

    @Test
    func failureAfterSuccessClearsPreviousDays() async {
        let provider = MockForecastProvider(result: .success(sampleForecast))
        let loader = ForecastLoader(service: provider)
        await loader.load(latitude: 1, longitude: 2)
        #expect(loader.days.count == 1)

        provider.result = .failure(ForecastTestError())
        await loader.load(latitude: 1, longitude: 2)

        #expect(loader.days.isEmpty)
        #expect(loader.errorMessage == "Forecast unavailable.")
        #expect(loader.isLoading == false)
    }

    @Test
    func retryClearsErrorWhileLoadingAndAppliesNewForecast() async {
        let provider = MockForecastProvider(result: .failure(ForecastTestError()))
        let loader = ForecastLoader(service: provider)
        await loader.load(latitude: 1, longitude: 2)
        #expect(loader.errorMessage != nil)

        // Observe state inside the service call, before it returns a result.
        provider.onForecast = { [weak loader] in
            #expect(loader?.isLoading == true)
            #expect(loader?.errorMessage == nil)
        }
        provider.result = .success(sampleForecast)
        await loader.load(latitude: 3, longitude: 4)

        #expect(loader.days.count == 1)
        #expect(loader.cityName == "Cape Town")
        #expect(loader.unitSymbol == "°F")
        #expect(loader.backgroundImage == "Rainy")
        #expect(loader.errorMessage == nil)
        #expect(loader.isLoading == false)
        #expect(provider.requestedCoordinates.count == 2)
        #expect(provider.requestedCoordinates.last?.0 == 3)
        #expect(provider.requestedCoordinates.last?.1 == 4)
    }

    @Test
    func cancellationErrorPreservesPreviousForecast() async {
        let provider = MockForecastProvider(result: .success(sampleForecast))
        let loader = ForecastLoader(service: provider)
        await loader.load(latitude: 1, longitude: 2)

        provider.result = .failure(CancellationError())
        await loader.load(latitude: 1, longitude: 2)

        #expect(loader.days.count == 1)
        #expect(loader.cityName == "Cape Town")
        #expect(loader.errorMessage == nil)
        #expect(loader.isLoading == false)
    }

    @Test(arguments: [false, true])
    func cancelledTaskIgnoresServiceResult(fails: Bool) async {
        let provider = MockForecastProvider(result: .success(sampleForecast))
        let loader = ForecastLoader(service: provider)
        await loader.load(latitude: 1, longitude: 2)

        provider.result = fails
            ? .failure(ForecastTestError())
            : .success(ForecastResult(
                cityName: "Ignored", days: [],
                unitSymbol: "°C", backgroundImage: "Cloudy"
            ))
        provider.onForecast = {
            withUnsafeCurrentTask { $0?.cancel() }
        }

        let task = Task { @MainActor in
            await loader.load(latitude: 3, longitude: 4)
        }
        await task.value

        #expect(task.isCancelled)
        #expect(loader.days.count == 1)
        #expect(loader.cityName == "Cape Town")
        #expect(loader.unitSymbol == "°F")
        #expect(loader.backgroundImage == "Rainy")
        #expect(loader.errorMessage == nil)
        #expect(loader.isLoading == false)
    }

    private var sampleForecast: ForecastResult {
        ForecastResult(
            cityName: "Cape Town",
            days: [DailyForecast(
                date: Date(timeIntervalSince1970: 0),
                temperature: 68,
                icon: "Property 1=20.rain-light"
            )],
            unitSymbol: "°F",
            backgroundImage: "Rainy"
        )
    }
}

private struct ForecastTestError: LocalizedError {
    var errorDescription: String? { "Forecast unavailable." }
}
