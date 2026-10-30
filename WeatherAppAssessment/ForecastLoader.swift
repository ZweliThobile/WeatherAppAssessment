//
//  ForecastLoader.swift
//  WeatherAppAssessment
//
//  Created by Thobile Jiyane on 2026/10/28.
//

import Foundation
import Observation

struct ForecastResult {
    let cityName: String
    let days: [DailyForecast]
    let unitSymbol: String
    let backgroundImage: String
}

protocol ForecastProvider {
    func forecast(
        latitude: Double,
        longitude: Double
    ) async throws -> ForecastResult
}

@Observable
final class ForecastLoader {
    
    private let service: any ForecastProvider
    
    private(set) var days: [DailyForecast] = []
    private(set) var cityName = ""
    private(set) var unitSymbol = "°C"
    private(set) var isLoading = false
    private(set) var errorMessage: String?
    private(set) var backgroundImage = "Sunny"
    
    init(service: any ForecastProvider) {
        self.service = service
    }

    func load(latitude: Double, longitude: Double) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let forecast = try await service.forecast(
                latitude: latitude,
                longitude: longitude
            )
            
            guard !Task.isCancelled else { return }
            
            cityName = forecast.cityName
            days = forecast.days
            unitSymbol = forecast.unitSymbol
            backgroundImage = forecast.backgroundImage
        } catch is CancellationError {
            return
        } catch {
            if Task.isCancelled { return }
            days = []
            errorMessage = error.localizedDescription
        }
    }
}

 enum OpenWeatherAPIKey {
    private static let placeholder = "YOUR_OPENWEATHERMAP_API_KEY"

    static var current: String? {
        guard let url = Bundle.main.url(forResource: "Secrets", withExtension: "plist"),
              let data = try? Data(contentsOf: url),
              let plist = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: String],
              let key = plist["OpenWeatherAPIKey"],
              !key.isEmpty,
              key != placeholder
        else {
            return nil
        }
        return key
    }
}

 enum OpenWeatherClient {
    struct Forecast {
        let cityName: String
        let days: [DailyForecast]
        let unitSymbol: String
        let backgroundImage: String
    }

    static func forecast(latitude: Double, longitude: Double, apiKey: String) async throws -> Forecast {
        let usesFahrenheit = Locale.current.measurementSystem == .us
        let units = usesFahrenheit ? "imperial" : "metric"

        var components = URLComponents(string: "https://api.openweathermap.org/data/2.5/forecast")
        components?.queryItems = [
            URLQueryItem(name: "lat", value: String(latitude)),
            URLQueryItem(name: "lon", value: String(longitude)),
            URLQueryItem(name: "units", value: units),
            URLQueryItem(name: "appid", value: apiKey)
        ]

        guard let url = components?.url else {
            throw WeatherServiceError.invalidURL
        }

        let (data, response) = try await URLSession.shared.data(from: url)
        guard let http = response as? HTTPURLResponse else {
            throw WeatherServiceError.invalidResponse
        }
        guard http.statusCode == 200 else {
            let message = (try? JSONDecoder().decode(ErrorBody.self, from: data).message) ?? "The forecast request failed."
            if http.statusCode == 401 {
                throw WeatherServiceError.rejectedKey
            }
            throw WeatherServiceError.server(message)
        }

        let decoded = try JSONDecoder().decode(ForecastResponse.self, from: data)
        let currentWeather = decoded.list.min {
            abs($0.dt - Date().timeIntervalSince1970) <
            abs($1.dt - Date().timeIntervalSince1970)
        }

        let currentIcon = currentWeather?.weather.first?.icon ?? "01d"

        let backgroundImage = backgroundImage(for: currentIcon)
        let days = dailyForecasts(from: decoded)
        guard !days.isEmpty else {
            throw WeatherServiceError.invalidResponse
        }

        return Forecast(
            cityName: decoded.city.name,
            days: days,
            unitSymbol: usesFahrenheit ? "°F" : "°C",
            backgroundImage: backgroundImage
        )
    }

    private static func dailyForecasts(from response: ForecastResponse) -> [DailyForecast] {
        var calendar = Calendar(identifier: .gregorian)
        if let timeZone = TimeZone(secondsFromGMT: response.city.timezone) {
            calendar.timeZone = timeZone
        }

        struct Accumulator {
            var temp: Double
            var icon: String
            var distance: TimeInterval
        }
        
        var grouped: [Date: Accumulator] = [:]
        
        for item in response.list {
            guard let weather = item.weather.first else {
                continue }
            let date = Date(timeIntervalSince1970: item.dt)
            let day = calendar.startOfDay(for: date)
            let noon = calendar.date(bySettingHour: 12, minute: 0, second: 0, of: day) ?? day
            let distance = abs(date.timeIntervalSince(noon))
            let sample = Accumulator(
                temp: item.main.temp,
                icon: weather.icon,
                distance: distance
            )
            if let existing = grouped[day] {
                if distance < existing.distance {
                    grouped[day] = sample
                }
            } else {
                grouped[day] = sample
            }
            
        }
        
        let sortedDays = grouped.keys.sorted()
        
        return sortedDays.prefix(5).compactMap {
            day -> DailyForecast? in
            
            guard let value = grouped[day] else {
                return nil
            }
           
            return DailyForecast(
                date: day,
                temperature: Int(value.temp),
                icon: iconName(for: value.icon)
            )
        }
    }

    private static func iconName(for icon: String) -> String {
        switch icon {
        case "01d":
            return "Property 1=01.sun-light"
        case "01n":
            return "Property 1=08.full-moon-light"
        case "02d":
            return "Property 1=05.partial-cloudy-light"
        case "02n":
            return "Property 1=17.cloudy-night-stars-light"
        case "03d":
            return "Property 1=07.mostly-cloud-light"
        case "03n":
            return "Property 1=10.cloudy-night-light"
        case "04d":
            return "Property 1=15.cloud-light"
        case "04n":
            return "Property 1=16.cloudy-night-light"
        case "09d", "09n":
            return "Property 1=18.heavy-rain-light"
        case "10d", "10n":
            return "Property 1=20.rain-light"
        case "11d", "11n":
            return "Property 1=13.thunderstorm-light"
        case "13d", "13n":
            return "Property 1=22.snow-light"
        case "50d", "50n":
            return "Property 1=07.mostly-cloud-light"
        default:
            return "Property 1=15.cloud-light"
        }
    }
    
    
    private static func backgroundImage(for icon: String) -> String {
        switch String(icon.prefix(2)) {
        case "01":
            return "Sunny"
        case "02", "03", "04", "50":
            return "Cloudy"
        case "09", "10", "11":
            return "Rainy"
        case "13":
            return "Forest"
            
        default:
            return "Cloudy"
        }
    }

}

private struct ForecastResponse: Decodable {
    struct Item: Decodable {
        struct Main: Decodable {
            let temp: Double

            enum CodingKeys: String, CodingKey {
                case temp = "temp"
            }
        }

        struct Weather: Decodable {
            let description: String
            let icon: String
        }

        let dt: TimeInterval
        let main: Main
        let weather: [Weather]
    }

    struct City: Decodable {
        let name: String
        let timezone: Int
    }

    let list: [Item]
    let city: City
}

private struct ErrorBody: Decodable {
    let message: String?
}

 enum WeatherServiceError: LocalizedError {
    case invalidURL
    case invalidResponse
    case rejectedKey
    case server(String)

    var errorDescription: String? {
        switch self {
        case .invalidURL, .invalidResponse:
            return "The weather forecast could not be read."
        case .rejectedKey:
            return "OpenWeatherMap rejected the API key. Replace the placeholder in FunProject/Secrets.plist."
        case .server(let message):
            return message
        }
    }
}

