//
//  DailyForecast.swift
//  WeatherAppAssessment
//
//  Created by Thobile Jiyane on 2026/10/28.
//
import Foundation

struct DailyForecast: Identifiable {
    var id: Date { date }
    let date: Date
    let temperature: Int 
    let icon: String
}
