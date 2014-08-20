//
//  WPTimeViewController.m
//  WeatherPing
//
//  Created by Nate Parrott on 8/18/14.
//  Copyright (c) 2014 Nate Parrott. All rights reserved.
//

#import "WPTimeViewController.h"

@interface WPTimeViewController ()

@property (nonatomic) IBOutlet UIDatePicker *datePicker;

@end

@implementation WPTimeViewController

- (void)save {
    NSCalendar *cal = [NSCalendar currentCalendar];
    NSDateComponents *comps = [cal components:NSHourCalendarUnit | NSMinuteCalendarUnit fromDate:self.datePicker.date];
    double seconds = (comps.hour * 60 + comps.minute) * 60;
    [PFInstallation currentInstallation][@"deliveryTime"] = @(seconds);
    [[PFInstallation currentInstallation] saveEventually];
}

- (IBAction)done:(id)sender {
    [self save];
    [APP_DELEGATE registerForPush];
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

@end
