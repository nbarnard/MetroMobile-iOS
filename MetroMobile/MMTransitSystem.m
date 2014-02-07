//
//  MMAgency.m
//  MetroMobile
//
//  Created by Nicholas Barnard on 2/3/14.
//  Copyright (c) 2014 NMFF Development. All rights reserved.
//

#import "MMTransitSystem.h"

@interface MMTransitSystem ()

@property (nonatomic, strong) NSDictionary *supportedSystem;

@end

@implementation MMTransitSystem


- (MMTransitSystem *) initWithSupportedSystemDictionary:(NSDictionary *)supportedSystem {
    self = [super init];

    if (self != nil) {
        _supportedSystem = supportedSystem;

        NSLog(@"Initilized Transit System with readable name: %@", [_supportedSystem objectForKey:@"readableName"]);
        if ([_supportedSystem count] <= 3) {
            NSLog(@"System Has Single Source, with sourceID: %@", [[_supportedSystem objectForKey:@"defaultSource"] lastObject]);
        } else {
            NSLog(@"System Has Multiple Sources.");
            [_supportedSystem enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
                NSString *stringKey = (NSString *)key;

                NSUInteger length = [stringKey length];
                if (!(length == 12 || length == 7)) { // we don't want to show the keys with the length of 7 or 12. long story.
                    NSArray *sourceArray = (NSArray *)obj;
                    NSString *sourceID = [sourceArray lastObject];
                    NSLog(@"Source for: %@ is %@", stringKey, sourceID);
                }
            }];
        }

        NSLog(@"System Sources are:");

        NSArray *sources = [_supportedSystem objectForKey:@"sources"];

        [sources enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            NSDictionary *source = (NSDictionary*) obj;
            NSLog(@"id: %@", [source objectForKey:@"id"]);
            NSLog(@"host: %@", [source objectForKey:@"host"]);
            NSLog(@"System ID on Host: %@", [source objectForKey:@"hostid"]);
            NSLog(@"Host Conforms to API Spec: %@", [source objectForKey:@"apispec"]);
        }];

    }

    NSLog(@"----------------------------------------------");

    return self;
}

-(NSArray *)getSourceForType: (sourceType) sourceType {
// If the supported system has no more than three entries, there are no optional source overrides, so return the default.
    if ([_supportedSystem count] <= 3) {
        return [_supportedSystem objectForKey:@"defaultSource"];
    }

    NSString *sourceKey;

    switch (sourceType) {
        case defaultSource:
            sourceKey = @"defaultSource";
            break;
        case nameSource:
            sourceKey = @"nameSource";
            break;
        case boundBoxSource:
            sourceKey = @"boundBoxSource";
            break;
        case realTimeSource:
            sourceKey = @"realTimeSource";
            break;
        case stopsSource:
            sourceKey = @"stopsSource";
            break;
        case routePolygonSource: 
            sourceKey = @"routePolygonSource";
            break;
        case timeZoneSource: 
            sourceKey = @"timeZoneSource";
            break;
        case scheduleSource: 
            sourceKey = @"scheduleSource";
            break;
        default:
            sourceKey = @"defaultSource";
            break;
    }

    NSArray *requestedResult = [_supportedSystem objectForKey:sourceKey];

    if (requestedResult == nil) {
        requestedResult = [_supportedSystem objectForKey:@"defaultSource"];
    }


    return requestedResult;

}

@end
