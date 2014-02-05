//
//  MMNetworkController.m
//  MetroMobile
//
//  Created by Nicholas Barnard on 2/3/14.
//  Copyright (c) 2014 NMFF Development. All rights reserved.
//

#import "MMNetworkController.h"
#import "MMTransitSystem.h"
#import <MapKit/MapKit.h>
#import "RXMLElement.h"
#import "OneBusAwayKey.h"

@interface MMNetworkController ()

@property (nonatomic, strong) NSCache *systemCache;

@end

@implementation MMNetworkController

+ (MMNetworkController *) sharedController {

    static dispatch_once_t pred;
    static MMNetworkController *shared = nil;

    dispatch_once(&pred, ^{
        shared = [[MMNetworkController alloc] init];
        shared.systemCache = [NSCache new];
    });

    return shared;
}

- (NSString *)getOBAStringforUniqueDataPoint: (uniqueDataPoint)requestedDataPoint WithSource:(NSDictionary *)currentSource  {
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

// Only supports Keys with a single source. (e.g. doesn't support stopsSource)

- (NSString *) getStringforUniqueDataPoint: (uniqueDataPoint) requestedDataPoint ForSystem: (MMTransitSystem *) transitSystem withDataSources: (NSSet *) dataSources {

    NSString *dataPointSource = [[transitSystem getSourceForType:(sourceType)requestedDataPoint] objectAtIndex:0]; // Source Type and uniqueDataPoint align.

    NSDictionary *currentSource = [self identifyCorrectSourceForDataPoint:dataPointSource withDataSources:dataSources];

    NSString *requestedString = [NSString new];

    if([[currentSource objectForKey:@"apispec"] isEqualToString:@"onebusaway"]) {
        requestedString = [self getOBAStringforUniqueDataPoint:requestedDataPoint WithSource:currentSource];
    }

    if([[currentSource objectForKey:@"apispec"] isEqualToString:@"nextbus"]) {
        requestedString = [self getNextBusStringforUniqueDataPoint:requestedDataPoint WithSource:currentSource];
    }

    return requestedString;
}


- (NSString *)getNextBusStringforUniqueDataPoint: (uniqueDataPoint)requestedDataPoint WithSource:(NSDictionary *)currentSource  {
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

//  Putting this method on ice for a bit, going to hard code mappings into obtainKeyforUniqueDataPoint
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


- (MKCoordinateRegion) getBoundBoxForSystem: (MMTransitSystem *) transitSystem withDataSources: (NSSet *) dataSources {

    NSString *dataPointSource = [[transitSystem getSourceForType:boundBoxSource] objectAtIndex:0]; // We only support once source for boundbox, take the first one.

    NSDictionary *currentSource = [self identifyCorrectSourceForDataPoint:dataPointSource withDataSources:dataSources];

    // Bound box information is only currently available to the onebusaway API. NextBus is thin on these things.
    if(![[currentSource objectForKey:@"apispec"] isEqualToString:@"onebusaway"]) {
        // returning a 0,0,0,0 region.
        return NULL_COORDINATE_REGION;
    }

    NSDictionary *obaAgencyCoverage = [self getOneBusAwayDataForCommand:@"agencies-with-coverage" with:currentSource];

    NSArray *obaData = [obaAgencyCoverage objectForKey:@"data"];
    NSString *hostID = [currentSource objectForKey:@"hostid"];

    __block MKCoordinateRegion currentSystemRegion;

    [obaData enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        NSDictionary *currentSystem = (NSDictionary *)obj;
        if([[[currentSystem objectForKey:@"agency"] objectForKey:@"id"] isEqualToString:hostID]){
            MKCoordinateSpan boundBoxSpan = MKCoordinateSpanMake([[currentSystem objectForKey:@"latSpan"] doubleValue], [[currentSystem objectForKey:@"lonSpan"] doubleValue]);
            CLLocationCoordinate2D boundBoxCenter = CLLocationCoordinate2DMake([[currentSystem objectForKey:@"lat"] doubleValue], [[currentSystem objectForKey:@"lon"] doubleValue]);

            currentSystemRegion = MKCoordinateRegionMake(boundBoxCenter, boundBoxSpan);

            *stop = YES;
        }
    }];

//    NSLog(@"%f", currentSystemRegion.center.longitude);
//    NSLog(@"%f", currentSystemRegion.center.latitude);
//    NSLog(@"%f", currentSystemRegion.span.longitudeDelta);
//    NSLog(@"%f", currentSystemRegion.span.latitudeDelta);


    return currentSystemRegion;
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
        return nil;
        NSLog(@"Invalid Response");
    }

    [_systemCache setObject:requestedDictionary forKey:cacheKey];

    return requestedDictionary;
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


//- (NSArray *) getAgencies {
//    NSURL *searchURL = [NSURL URLWithString:@"http://api.pugetsound.onebusaway.org/api/where/agencies-with-coverage.json?key=TEST"];
//
//    // Get data with the Search String
//    NSData *searchData = [NSData dataWithContentsOfURL: searchURL];
//    NSError *error;
//
//    NSDictionary *rawJSONData = [NSJSONSerialization JSONObjectWithData:searchData options: NSJSONReadingMutableContainers error:&error];
//
//    NSNumber *responseCode = [rawJSONData objectForKey:@"code"];
//
//    if (![responseCode isEqualToNumber:[NSNumber numberWithInt:200]]) {
//        return nil;
//        NSLog(@"Invalid Response");
//    }
//
//    NSArray *rawAgencies = [rawJSONData objectForKey:@"data"];
//
//    NSMutableArray *agencies = [NSMutableArray new];
//
//    for (NSDictionary *agencyWithLatLong in rawAgencies) {
//        NSDictionary *agencyInfo = [agencyWithLatLong objectForKey:@"agency"];
//        NSString *agencyID = [agencyInfo objectForKey:@"id"];
//        NSString *name = [agencyInfo objectForKey:@"name"];
//        NSString *disclaimer = [agencyInfo objectForKey:@"disclaimer"];
//
//        MMAgency *newAgency = [[MMAgency alloc] initWithID:agencyID
//                                                    andName:name
//                                              andDisclaimer:disclaimer];
//        [agencies addObject:newAgency];
//        // Delete this
//        NSLog(@"\nName %@\n lat %@\n latSpan %@\n lon %@\n lonSpan %@\n", [agencyInfo objectForKey:@"name"], [agencyWithLatLong objectForKey:@"lat"], [agencyWithLatLong objectForKey:@"latSpan"], [agencyWithLatLong objectForKey:@"lon"], [agencyWithLatLong objectForKey:@"lonSpan"]);
//
//
//        // to here
//
//    }
//
//    return [[NSArray alloc] initWithArray:agencies];
//}

@end
