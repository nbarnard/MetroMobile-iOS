//
//  MMNetworkController.m
//  MetroMobile
//
//  Created by Nicholas Barnard on 2/3/14.
//  Copyright (c) 2014 NMFF Development. All rights reserved.
//

#import "MMNetworkController.h"
#import "MMTransitSystem.h"

@implementation MMNetworkController

+ (MMNetworkController *) sharedController {

    static dispatch_once_t pred;
    static MMNetworkController *shared = nil;

    dispatch_once(&pred, ^{
        shared = [[MMNetworkController alloc] init];
    });

    return shared;
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
