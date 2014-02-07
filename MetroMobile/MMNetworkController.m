//
//  MMNetworkController.m
//  MetroMobile
//
//  Created by Nicholas Barnard on 2/3/14.
//  Copyright (c) 2014 NMFF Development. All rights reserved.
//

#import "MMNetworkController.h"
#import "MMFullModel.h"
#import <MapKit/MapKit.h>
#import "RXMLElement.h"
#import "OneBusAwayKey.h"

@interface MMNetworkController ()

@property (nonatomic, strong) NSCache *systemCache;
@property (nonatomic, strong) NSOperationQueue *networkRequestQueue;

@end

@implementation MMNetworkController

#pragma mark External Methods

- (NSString *) getStringforUniqueDataPoint: (uniqueDataPoint) requestedDataPoint ForSystem: (MMTransitSystem *) transitSystem withDataSources: (NSSet *) dataSources {

    NSString *dataPointSource = [[transitSystem getSourceForType:(sourceType)requestedDataPoint] objectAtIndex:0]; // Source Type and uniqueDataPoint align.

    NSDictionary *currentSource = [self identifyCorrectSourceForDataPoint:dataPointSource withDataSources:dataSources];

    NSString *requestedString;

    if([[currentSource objectForKey:@"apispec"] isEqualToString:@"onebusaway"]) {
        requestedString = [self getOBAStringforUniqueDataPoint:requestedDataPoint WithSource:currentSource];
    }

    if([[currentSource objectForKey:@"apispec"] isEqualToString:@"nextbus"]) {
        requestedString = [self getNextBusStringforUniqueDataPoint:requestedDataPoint WithSource:currentSource];
    }

    return requestedString;
}

- (MKMapRect) getBoundBoxForSystem: (MMTransitSystem *) transitSystem withDataSources: (NSSet *) dataSources {

    NSString *dataPointSource = [[transitSystem getSourceForType:boundBoxSource] objectAtIndex:0]; // We only support once source for boundbox, take the first one.

    NSDictionary *currentSource = [self identifyCorrectSourceForDataPoint:dataPointSource withDataSources:dataSources];

    // Bound box information is only currently available to the onebusaway API. NextBus is thin on these things.
    if(![[currentSource objectForKey:@"apispec"] isEqualToString:@"onebusaway"]) {
        // returning a 0,0,0,0 region.
        return [self MKMapRectForCoordinateRegion:NULL_COORDINATE_REGION];
    }

    NSDictionary *obaAgencyCoverage = [self getOneBusAwayDataForCommand:@"agencies-with-coverage" with:currentSource];

    NSArray *obaData = [obaAgencyCoverage objectForKey:@"data"];
    NSString *hostID = [currentSource objectForKey:@"hostid"];

    __block MKCoordinateRegion currentSystemCoordinateRegion;

    [obaData enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        NSDictionary *currentSystem = (NSDictionary *)obj;
        if([[[currentSystem objectForKey:@"agency"] objectForKey:@"id"] isEqualToString:hostID]){
            MKCoordinateSpan boundBoxSpan = MKCoordinateSpanMake([[currentSystem objectForKey:@"latSpan"] doubleValue], [[currentSystem objectForKey:@"lonSpan"] doubleValue]);
            CLLocationCoordinate2D boundBoxCenter = CLLocationCoordinate2DMake([[currentSystem objectForKey:@"lat"] doubleValue], [[currentSystem objectForKey:@"lon"] doubleValue]);

            currentSystemCoordinateRegion = MKCoordinateRegionMake(boundBoxCenter, boundBoxSpan);

            *stop = YES;
        }
    }];

    //    NSLog(@"%f", currentSystemRegion.center.longitude);
    //    NSLog(@"%f", currentSystemRegion.center.latitude);
    //    NSLog(@"%f", currentSystemRegion.span.longitudeDelta);
    //    NSLog(@"%f", currentSystemRegion.span.latitudeDelta);


    return [self MKMapRectForCoordinateRegion:currentSystemCoordinateRegion];
}

- (void) getRoutesForSystems:(NSSet *) systems atPoint: (MKMapPoint)locationPoint withDataSources: (NSSet *) dataSources {
    __block NSMutableDictionary *hostsToCheck = [NSMutableDictionary new];

    [systems enumerateObjectsUsingBlock:^(id obj, BOOL *stop) {
        MMTransitSystem *currentSystem = (MMTransitSystem *) obj;
        NSString *datapoint = [[currentSystem getSourceForType:stopsSource] objectAtIndex:0];
        NSDictionary *source = [self identifyCorrectSourceForDataPoint:datapoint withDataSources: dataSources];
        NSString *host = [source objectForKey:@"host"];

        if([hostsToCheck objectForKey:host] == nil) {
            NSMutableSet *systemsOnHost = [[NSMutableSet alloc] initWithObjects:currentSystem, nil];
            [hostsToCheck setObject:systemsOnHost forKey:host];
        } else {
            NSMutableSet *systemsOnHost = [hostsToCheck objectForKey:host];
            [systemsOnHost addObject:currentSystem];
        }
    }];

    __block NSSet *stops = [NSMutableSet new];

    [hostsToCheck enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {

        NSSet *systemsOnHost = [[NSSet alloc] initWithSet: (NSMutableSet *) obj];

        MMTransitSystem *representativeSystem = [systemsOnHost anyObject];

        [_networkRequestQueue addOperationWithBlock:^{
            NSSet *returnedStops = [self getNearbyStopsForSystem:representativeSystem atPoint:locationPoint withDataSources:dataSources];
            @synchronized (stops)
            {
                NSSet *newStops = [stops setByAddingObjectsFromSet:returnedStops];
                stops = newStops;
            } // end of Syncronized block
        }]; // end of networkRequest with Block
    }]; // end of iterating over systems needed to check

    [_networkRequestQueue waitUntilAllOperationsAreFinished];


    
}

- (NSSet *) getNearbyStopsForSystem: (MMTransitSystem *) transitSystem atPoint: (MKMapPoint)locationPoint withDataSources: (NSSet *) dataSources {

    NSString *dataPointSource = [[transitSystem getSourceForType:(sourceType) systemStops] objectAtIndex:0]; // Source Type and uniqueDataPoint align.

    NSDictionary *currentSource = [self identifyCorrectSourceForDataPoint:dataPointSource withDataSources:dataSources];

    NSSet *stops;

    if([[currentSource objectForKey:@"apispec"] isEqualToString:@"onebusaway"]) {
        [self getOBAStopsforSystem:transitSystem forLocation:locationPoint withDataSources:dataSources];
    }

    if([[currentSource objectForKey:@"apispec"] isEqualToString:@"nextbus"]) {
        // get next bus stops.
    }

    return stops;
}

#pragma mark OneBusAway

- (NSSet *) getOBAStopsforSystem:(MMTransitSystem *) transitSystem forLocation: (MKMapPoint)location withDataSources: (NSSet *) dataSources {

//    NSDictionary *currentSource = [self identifyCorrectSourceForDataPoint:dataPointSource withDataSources:dataSources];

    // just request out to OBA Puget Sound with the location point and process it.

    CLLocationCoordinate2D coordinateLocation = MKCoordinateForMapPoint(location);

    NSString *requestString = [NSString stringWithFormat:@"http://api.pugetsound.onebusaway.org/api/where/stops-for-location.json?key=TEST&lat=%f&lon=%f", coordinateLocation.latitude, coordinateLocation.longitude];

    NSURL *requestURL = [NSURL URLWithString:requestString];
    NSError *error;
    NSData *stopsData = [NSData dataWithContentsOfURL:requestURL];

    NSDictionary *stopsDictionary = [NSJSONSerialization JSONObjectWithData:stopsData options: NSJSONReadingMutableContainers error:&error];

    NSNumber *responseCode = [stopsDictionary objectForKey:@"code"];

    if (![responseCode isEqualToNumber:[NSNumber numberWithInt:200]]) {
        NSLog(@"Invalid Response");
        return nil;
    }

    NSArray *rawStops = [[stopsDictionary objectForKey:@"data"] objectForKey:@"stops"];

//    __block NSMutableSet *stops = [NSMutableSet new];

    [rawStops enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        NSDictionary *currentStop = (NSDictionary *) obj;
        MMStop *newMMStop = [MMStop new];
        NSNumber *lat = [currentStop objectForKey:@"lat"];
        NSNumber *lon = [currentStop objectForKey:@"lon"];

        newMMStop.location = [[CLLocation alloc] initWithLatitude:[lat doubleValue] longitude:[lon doubleValue]];

    }];



    return nil;
}

- (NSString *) obtainOBAKeyforUniqueDataPoint: (uniqueDataPoint) requestedDataPoint {
    switch (requestedDataPoint) {
        case systemName:
            return @"name";
        case systemTimeZone:
            return @"timezone";
        default:
            return @"";
    }
}

- (NSString *) getOBAStringforUniqueDataPoint: (uniqueDataPoint) requestedDataPoint WithSource:(NSDictionary *)currentSource  {
    NSDictionary *obaAgencyCoverage = [self getOneBusAwayDataForCommand:@"agencies-with-coverage" with:currentSource];
    
    NSArray *obaData = [obaAgencyCoverage objectForKey:@"data"];
    NSString *hostID = [currentSource objectForKey:@"hostid"];
    
    __block NSString *result = [NSString new];
    
    [obaData enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        NSDictionary *currentSystem = (NSDictionary *)obj;
        NSDictionary *agency = [currentSystem objectForKey:@"agency"];
        if([[agency objectForKey:@"id"] isEqualToString:hostID])
        {
            result = [agency objectForKey:[self obtainOBAKeyforUniqueDataPoint:requestedDataPoint]];
            *stop = YES;
        }
    }];
    
    return result;
}

- (NSDictionary *) getOneBusAwayDataForCommand: (NSString *) command with: (NSDictionary *) source {

    NSString *host = [source objectForKey:@"host"];

    NSString *cacheKey = [NSString stringWithFormat:@"%@-%@", host, command];

    NSDictionary *requestedDictionary = [_systemCache objectForKey:cacheKey];

    if (requestedDictionary != nil) {
        return requestedDictionary;
    }

    NSString *requestString = [NSString stringWithFormat:@"http://%@/api/where/%@.json?key=%@", host, command, OneBusAwayKey];

    NSURL *commandURL = [NSURL URLWithString:requestString];
    NSError *error;

    NSData *commandData = [NSData dataWithContentsOfURL:commandURL];

    requestedDictionary = [NSJSONSerialization JSONObjectWithData:commandData options: NSJSONReadingMutableContainers error:&error];

    NSNumber *responseCode = [requestedDictionary objectForKey:@"code"];

    if (![responseCode isEqualToNumber:[NSNumber numberWithInt:200]]) {
        NSLog(@"Invalid Response");
        return nil;
    }

    [_systemCache setObject:requestedDictionary forKey:cacheKey];
    
    return requestedDictionary;
}

#pragma mark NextBus
- (NSString *) obtainNextBusKeyforUniqueDataPoint: (uniqueDataPoint) requestedDataPoint {
    switch (requestedDataPoint) {
        case systemName:
            return @"title";
            break;
        case systemTimeZone:  // Purposfully falling through, as we don't serve TZ from NextBus
        default:
            return @"";
            break;
    }
}

- (NSString *) getNextBusStringforUniqueDataPoint: (uniqueDataPoint)requestedDataPoint WithSource:(NSDictionary *)currentSource  {
    NSData *nextBusAgencyCoverage = [self getNextBusDataForCommand:@"agencyList" with:currentSource];

    NSString *hostID = [currentSource objectForKey:@"hostid"];
    NSString *key = [self obtainNextBusKeyforUniqueDataPoint:requestedDataPoint];

    NSArray *agencies = [[RXMLElement elementFromXMLData:nextBusAgencyCoverage] children:@"agency"];

    __block NSString *result = [NSString new];

    [agencies enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        RXMLElement *agency = (RXMLElement *) obj;
        if ([[agency attribute:@"tag"] isEqualToString:hostID]) {
            result = [agency attribute:key];
            *stop = YES;
        }
    }];
    return result;
}

- (NSData *) getNextBusDataForCommand: (NSString *) command with: (NSDictionary *) source {

    NSString *host = [source objectForKey:@"host"];

    NSString *cacheKey = [NSString stringWithFormat:@"%@-%@", host, command];

    NSData *requestedData = [_systemCache objectForKey:cacheKey];

    if (requestedData != nil){
        return requestedData;
    }

    NSString *requestString = [NSString stringWithFormat:@"http://%@/service/publicXMLFeed?command=%@", host, command];

    NSURL *commandURL = [NSURL URLWithString:requestString];

    NSData *commandData = [NSData dataWithContentsOfURL:commandURL];

    // Need to add in error checking here

    [_systemCache setObject:commandData forKey:cacheKey];
    
    return commandData;
}

#pragma mark Support Methods

// Only supports Keys with a single source. (e.g. doesn't support stopsSource)
- (NSDictionary *) identifyCorrectSourceForDataPoint: (NSString *) datapoint withDataSources: (NSSet *) dataSources {
    __block NSDictionary *currentSource;

    [dataSources enumerateObjectsUsingBlock:^(id obj, BOOL *stop) {
        NSDictionary *source = (NSDictionary *) obj;
        if ([[source objectForKey:@"id"] isEqualToString:datapoint]) {
            currentSource = source;
            *stop = YES;
        }
    }];

    return currentSource;
    
}

// From http://stackoverflow.com/questions/9270268/convert-mkcoordinateregion-to-mkmaprect - Leo
- (MKMapRect) MKMapRectForCoordinateRegion: (MKCoordinateRegion) region {
    MKMapPoint a = MKMapPointForCoordinate(CLLocationCoordinate2DMake(
                                                                      region.center.latitude + region.span.latitudeDelta / 2,
                                                                      region.center.longitude - region.span.longitudeDelta / 2));
    MKMapPoint b = MKMapPointForCoordinate(CLLocationCoordinate2DMake(
                                                                      region.center.latitude - region.span.latitudeDelta / 2,
                                                                      region.center.longitude + region.span.longitudeDelta / 2));
    return MKMapRectMake(MIN(a.x,b.x), MIN(a.y,b.y), ABS(a.x-b.x), ABS(a.y-b.y));
}

//  Putting this method on ice for a bit, going to hard code mappings into obtain(APISPEC)KeyforUniqueDataPoint
//
//- (NSDictionary *) getAPISpecFor: (NSString *) apispec {
//
//    NSString *cacheKey = [NSString stringWithFormat:@"apispec-%@", apispec];
//    NSDictionary *requestedDictionary = [_systemCache objectForKey:cacheKey];
//
//    if(requestedDictionary != nil) {
//        return requestedDictionary;
//    }
//
//    NSString *apiSpecPlist = [[NSBundle mainBundle] pathForResource:@"APISpecification" ofType:@"plist"];
//    NSDictionary *allApiSpecs = [[NSDictionary alloc] initWithContentsOfFile:apiSpecPlist];
//
//    requestedDictionary = [allApiSpecs objectForKey:apispec];
//
//    [_systemCache setObject:requestedDictionary forKey:cacheKey];
//
//    return requestedDictionary;
//
//}

#pragma mark boilerPlate
+ (MMNetworkController *) sharedController {

    static dispatch_once_t pred;
    static MMNetworkController *shared = nil;

    dispatch_once(&pred, ^{
        shared = [[MMNetworkController alloc] init];
        shared.systemCache = [NSCache new];
        shared.networkRequestQueue = [NSOperationQueue new];
    });

    return shared;
}

@end
