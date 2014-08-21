//
//  WPLocationViewController.m
//  WeatherPing
//
//  Created by Nate Parrott on 8/18/14.
//  Copyright (c) 2014 Nate Parrott. All rights reserved.
//

#import "WPLocationViewController.h"
#import <CoreLocation/CoreLocation.h>
#import "NSString+URLEncoded.h"

typedef enum {
    WPLocationViewControllerStateNone = 0,
    WPLocationViewControllerStateGettingLocation,
    WPLocationViewControllerStateGettingGeocoding,
    WPLocationViewControllerStateError,
    WPLocationViewControllerStateNoPermission,
    WPLocationViewControllerStateDone
} WPLocationViewControllerState;

@interface WPLocationViewController () <CLLocationManagerDelegate, UIAlertViewDelegate>

@property (nonatomic) WPLocationViewControllerState state;

@property (nonatomic) CLLocationManager *loc;

@property (nonatomic) IBOutlet UILabel *locationLabel;
@property (nonatomic) IBOutlet UIView *noPermission, *error;
@property (nonatomic) IBOutlet UIActivityIndicatorView *loader;
@property (nonatomic) IBOutlet UIButton *nextButton;

@end

@implementation WPLocationViewController

- (void)startIfNeeded {
    if (self.state == WPLocationViewControllerStateNone || self.state == WPLocationViewControllerStateNoPermission || self.state == WPLocationViewControllerStateError) {
        [self findLocation];
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(startIfNeeded) name:UIApplicationDidBecomeActiveNotification object:nil];
    [self startIfNeeded];
    
    RAC(self.error, hidden) = [RACObserve(self, state) map:^id(id value) {
        return @([value integerValue] != WPLocationViewControllerStateError);
    }];
    RAC(self.noPermission, hidden) = [RACObserve(self, state) map:^id(id value) {
        return @([value integerValue] != WPLocationViewControllerStateNoPermission);
    }];
    RAC(self.loader, hidden) = [RACObserve(self, state) map:^id(id value) {
        WPLocationViewControllerState s = [value integerValue];
        return @(!(s == WPLocationViewControllerStateGettingLocation || s == WPLocationViewControllerStateGettingGeocoding));
    }];
    WEAK(self);
    [RACObserve(self, state) subscribeNext:^(id x) {
        weak_self.locationLabel.text = [PFInstallation currentInstallation][@"locationName"];
        weak_self.locationLabel.hidden = weak_self.state != WPLocationViewControllerStateDone;
        weak_self.nextButton.enabled = weak_self.state == WPLocationViewControllerStateDone;
    }];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


- (void)findLocation {
    self.state = WPLocationViewControllerStateGettingLocation;
    self.loc = [CLLocationManager new];
    self.loc.delegate = self;
    [self.loc startUpdatingLocation];
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
    CLLocation *loc = locations.firstObject;
    [self.loc stopUpdatingLocation];
    self.loc = nil;
    [self fetchWeatherURLFromLocation:loc];
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    [self.loc stopUpdatingLocation];
    self.loc = nil;
    if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorized) {
        self.state = WPLocationViewControllerStateError;
    } else {
        self.state = WPLocationViewControllerStateNoPermission;
    }
}

- (IBAction)retry:(id)sender {
    [self startIfNeeded];
}

- (IBAction)enterZipCode:(id)sender {
    UIAlertView *av = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Where are you?", @"") message:NSLocalizedString(@"Enter your US zip code:", @"") delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Okay", nil];
    av.alertViewStyle = UIAlertViewStylePlainTextInput;
    [av textFieldAtIndex:0].keyboardType = UIKeyboardTypeNumberPad;
    [av show];
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (buttonIndex != alertView.cancelButtonIndex) {
        NSString *zip = [alertView textFieldAtIndex:0].text;
        if (zip.length >= 5) {
            [self fetchWeatherURLFromZipcode:zip];
        }
    }
}

#pragma mark Revgeo

- (NSString *)apiRoot {
    return @"http://api.wunderground.com/api/71170515284b31ae";
}

- (void)fetchWeatherURLFromLocation:(CLLocation *)location {
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/geolookup/q/%f,%f.json", [self apiRoot], location.coordinate.latitude, location.coordinate.longitude]];
    [self fetchWeatherURLFromRequestURL:url];
}

- (void)fetchWeatherURLFromZipcode:(NSString *)zipcode {
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/geolookup/q/%@.json", [self apiRoot], [zipcode URLEncodedString_ch]]];
    [self fetchWeatherURLFromRequestURL:url];
}

- (void)fetchWeatherURLFromRequestURL:(NSURL *)url {
    self.state = WPLocationViewControllerStateGettingGeocoding;
    [[[NSURLSession sharedSession] dataTaskWithRequest:[NSURLRequest requestWithURL:url] completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            PFInstallation *inst = [APP_DELEGATE installation];
            NSDictionary *location = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil][@"location"];
            NSString *weatherURL = location[@"requesturl"];
            NSString *locationName = location[@"city"];
            if (weatherURL) {
                inst[@"weatherURL"] = weatherURL;
                inst[@"locationName"] = locationName;
                self.state = WPLocationViewControllerStateDone;
            } else {
                self.state = WPLocationViewControllerStateError;
            }
        });
    }] resume];
}

@end
