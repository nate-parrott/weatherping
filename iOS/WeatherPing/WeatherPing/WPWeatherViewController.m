//
//  WPWeatherViewController.m
//  WeatherPing
//
//  Created by Nate Parrott on 8/18/14.
//  Copyright (c) 2014 Nate Parrott. All rights reserved.
//

#import "WPWeatherViewController.h"
#import "WPWeatherView.h"

#define TAKING_DEFAULT_IMAGE 0

@interface WPWeatherViewController ()

@property (nonatomic) IBOutlet WPWeatherView *weather;
@property (nonatomic) IBOutlet UIButton *timeLabel;

@end

@implementation WPWeatherViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refresh) name:UIApplicationDidBecomeActiveNotification object:nil];
    self.timeLabel.titleLabel.numberOfLines = 0;
    self.timeLabel.titleLabel.textAlignment = NSTextAlignmentCenter;
    
#if TAKING_DEFAULT_IMAGE
    self.timeLabel.hidden = YES;
    self.weather.hidden = YES;
#endif
    
    self.timeLabel.alpha = 0;
    self.weather.alpha = 0;
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self refresh];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if ([[PFInstallation currentInstallation] valueForKey:@"weatherURL"] == nil) {
        [self performSegueWithIdentifier:@"Setup" sender:nil];
    }
    [UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionAllowUserInteraction animations:^{
        self.timeLabel.alpha = 1;
        self.weather.alpha = 1;
    } completion:^(BOOL finished) {
        
    }];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)refresh {
    [self updateTimeLabel];
    [self.weather refresh:nil];
}

- (void)updateTimeLabel {
    NSString *title;
    if ([APP_DELEGATE pushNotificationsEnabled]) {
        double secondsFromMidnight = [[PFInstallation currentInstallation][@"deliveryTime"] doubleValue];
        NSInteger minutes = ((int)secondsFromMidnight / 60) % 60;
        NSInteger hours = ((int)secondsFromMidnight / 3600);
        BOOL PM = hours >= 12;
        if (PM) hours -= 12;
        if (hours == 0) hours = 12;
        title = [NSString localizedStringWithFormat:NSLocalizedString(@"%i:%02i %@ | %@", @""), hours, minutes, (PM? @"PM" : @"AM"), [PFInstallation currentInstallation][@"locationName"]];
    } else {
        title = NSLocalizedString(@"Notifications are turned off. Turn them back on in Settings.", @"");
    }
    [self.timeLabel setTitle:title forState:UIControlStateNormal];
}


@end
