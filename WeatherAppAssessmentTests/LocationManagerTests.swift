//
//  LocationManagerTests.swift
//  WeatherAppAssessment
//
//  Created by Thobile Jiyane on 2026/10/29.
//
import Foundation
import CoreLocation
import Testing
@testable import WeatherAppAssessment

@MainActor
struct LocationManagerTests {
    
    @Test
       func startsWithNoLocation() {
           let provider = MockLocationProvider()
           let manager = LocationManager(manager: provider)

           #expect(manager.location == nil)
           #expect(manager.isLocating == false)
           #expect(manager.message == "User Location")
           #expect(provider.delegate === manager)
           #expect(provider.desiredAccuracy == kCLLocationAccuracyBest)
       }
    
    @Test
     func undeterminedPermissionRequestsAuthorization() {
         let provider = MockLocationProvider()
         provider.authorizationStatus = .notDetermined
         let manager = LocationManager(manager: provider)

         manager.requestCurrentLocation()

         #expect(provider.permissionRequestCount == 1)
         #expect(provider.locationRequestCount == 0)
         #expect(manager.isLocating == false)
         #expect(manager.message.isEmpty)
     }
    
    @Test(arguments: [
           CLAuthorizationStatus.denied,
           .restricted
       ])
       func deniedPermissionDoesNotRequestLocation(
           status: CLAuthorizationStatus
       ) {
           let provider = MockLocationProvider()
           provider.authorizationStatus = status
           let manager = LocationManager(manager: provider)

           manager.requestCurrentLocation()

           #expect(provider.locationRequestCount == 0)
           #expect(provider.permissionRequestCount == 0)
           #expect(manager.isLocating == false)
           #expect(manager.message == "Location denied.")
       }
    
    @Test
       func undeterminedAuthorizationChangeDoesNotRequestLocation() {
           let provider = MockLocationProvider()
           let manager = LocationManager(manager: provider)

           manager.handleAuthorizationChange(.notDetermined)

           #expect(provider.locationRequestCount == 0)
           #expect(provider.permissionRequestCount == 0)
           #expect(manager.isLocating == false)
       }
    
    @Test
    func authorizedUserCanRequestLocation() {
        let provider = MockLocationProvider()
        provider.authorizationStatus = .authorizedWhenInUse
        let manager = LocationManager(manager: provider)

        manager.requestCurrentLocation()

        #expect(provider.locationRequestCount == 1)
        #expect(provider.permissionRequestCount == 0)
        #expect(manager.isLocating)
        #expect(manager.message.isEmpty)
    }
}
