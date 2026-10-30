//
//  MockLocationProvider.swift
//  WeatherAppAssessment
//
//  Created by Thobile Jiyane on 2026/10/29.
//
import CoreLocation
@testable import WeatherAppAssessment


final class MockLocationProvider: LocationProvider {

    var delegate: CLLocationManagerDelegate?

    var authorizationStatus: CLAuthorizationStatus = .notDetermined
    
    var desiredAccuracy: CLLocationAccuracy = 0

    private(set) var permissionRequestCount = 0
    private(set) var locationRequestCount = 0

    func requestWhenInUseAuthorization() {
        permissionRequestCount += 1
    }

    func requestLocation() {
        locationRequestCount += 1
    }
}
