//
//  MMMainViewController.m
//  MetroMobile
//
//  Created by Nicholas Barnard on 2/6/14.
//  Copyright (c) 2014 NMFF Development. All rights reserved.
//

#import "MMMainViewController.h"
#import "MMLocationController.h"
#import "MMDataController.h"
#import <ProgressHUD.h>

@interface MMMainViewController ()

@end

@implementation MMMainViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)findNearbyRoutesTapped {

    MMLocationController *locationController = [MMLocationController sharedController];

    if (locationController.currentLocation == Nil) {
        MMLocationController *locationController = [MMLocationController sharedController];
        locationController.userWaiting = YES;
        [ProgressHUD show:@"Finding Location and Stops"];

        [[NSNotificationCenter defaultCenter] addObserver: self
                                                 selector: @selector(presentNearbyRoutes)
                                                     name: @"routesReceived"
                                                   object: nil];
    } else {
        // check if we already have nearby routes for this location if so go for presentNearbyRoutes,
        // if not register for a notification and throw up a hud.
        [self presentNearbyRoutes];
    }
}

- (void) presentNearbyRoutes {
// Pull down hud.

// push to a table view controller to present routes.

}


@end
