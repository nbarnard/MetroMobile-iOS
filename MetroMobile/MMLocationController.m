//
//  MMLocationController.m
//  MetroMobile
//
//  Created by Nicholas Barnard on 2/5/14.
//  Copyright (c) 2014 NMFF Development. All rights reserved.
//

#import "MMLocationController.h"
#import "MMDataController.h"

@interface MMLocationController ()

@property (strong, nonatomic) CLLocationManager *locationManager;

@end

@implementation MMLocationController

+ (MMLocationController *) sharedController {
    static dispatch_once_t pred;
    static MMLocationController *shared = nil;

    dispatch_once(&pred, ^{
        shared = [[MMLocationController alloc] init];
        [shared initLocationManager];
    });

    return shared;
}

- (void) initLocationManager {
    _locationManager = [CLLocationManager new];
    _locationManager.delegate = self;
    _locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters; // 100 meters is just over a block or so.
    _locationManager.distanceFilter = 200; // meters

    // only start updating if we're already authorized.
    if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorized) {
        [_locationManager startUpdatingLocation];
    } else {
        NSLog(@"****Not Authorized for Location, if we weren't in testing, we'd not ask for a location");
        [_locationManager startUpdatingLocation]; // for testing
    }
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
    for (CLLocation *location in locations) {
        NSDate *locationDate = location.timestamp;

        NSTimeInterval locationAge = [locationDate timeIntervalSinceNow];

        // We'll use the location if its newer than 20 s. Set it if we don't have a location or if it is newer than the current location.
        if (abs(locationAge) < 20) {
            if(_currentLocation == Nil) {
                [self updateLocationPropertyWithLocation:location];
            } else if ([locationDate timeIntervalSinceDate:_currentLocation.timestamp] > 0) {
                [self updateLocationPropertyWithLocation:location];
            }
        }
    }

}

- (void)updateLocationPropertyWithLocation: (CLLocation *) location {
    _currentLocation = location;
//    [[NSNotificationCenter defaultCenter] postNotificationName:@"locrecvd" object:nil]
    ;

    NSLog(@"----------------------------------------------");
    NSLog(@"Location Received. Latitude: %f Longitude: %f", location.coordinate.latitude, location.coordinate.longitude);

    NSOperationQueue *selectedThread;

//    if(_userWaiting) { // this is commented out as a demo adjustment
    if(TRUE) {
    selectedThread = [NSOperationQueue mainQueue];
    } else {
        selectedThread = [NSOperationQueue new];
    }

    [selectedThread addOperationWithBlock:^{
// message to Data Controller to get stops w/ location.
        MMDataController *dataController = [MMDataController sharedController];
        [dataController getStopsForCLLocation:location];
    }];

}

@end
