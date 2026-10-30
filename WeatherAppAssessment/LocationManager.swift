//
//  LocationManager.swift
//  WeatherAppAssessment
//
//  Created by Thobile Jiyane on 2026/10/18.
//
import CoreLocation
import Observation

protocol LocationProvider: AnyObject {
    var delegate: (any CLLocationManagerDelegate)? { get set }
    var authorizationStatus:CLAuthorizationStatus { get }
    var desiredAccuracy: CLLocationAccuracy { get set }
    func requestWhenInUseAuthorization()
    func requestLocation()
}

extension CLLocationManager: LocationProvider {}

@MainActor
@Observable
final class LocationManager: NSObject, CLLocationManagerDelegate {
    private let manager : any LocationProvider
    
    private(set) var location: CLLocation?
    private(set) var isLocating = false
    private(set) var message = "User Location"
    
    init(manager: any LocationProvider = CLLocationManager()) {
        self.manager = manager
        super.init()
        
        self.manager.delegate = self
        self.manager.desiredAccuracy = kCLLocationAccuracyBest
    }
    
    func requestCurrentLocation(){
        message = ""
        
        switch manager.authorizationStatus{
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .authorizedAlways, .authorizedWhenInUse:
            fetchLocation()
        case .denied, .restricted:
            isLocating = false
            message = "Location denied."
        @unknown default:
            isLocating = false
        }
    }
    
    private func fetchLocation(){
        isLocating = true
        manager.requestLocation()
    }
    
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager){
        let status = manager.authorizationStatus
        Task{ @MainActor in
        
        }
    }
    
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let latest = locations.last
        Task { @MainActor in
            location = latest
            isLocating = false
            if latest == nil {
                message = "Location not found."
            }
        }
    }
    
    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        let description = error.localizedDescription
        Task { @MainActor in
        isLocating = false
        message = description
        }
    }
    
    func handleAuthorizationChange(_ status: CLAuthorizationStatus){
        switch status {
        case .authorizedAlways, .authorizedWhenInUse:
            fetchLocation()
        case .denied, .restricted:
            isLocating = false
        case .notDetermined:
            break
        @unknown default:
            isLocating = false
            message = "Location not found."
        }
    }
}
