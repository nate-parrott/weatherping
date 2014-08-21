//
//  WPAppDelegate.h
//  WeatherPing
//
//  Created by Nate Parrott on 8/18/14.
//  Copyright (c) 2014 Nate Parrott. All rights reserved.
//

#import <UIKit/UIKit.h>

#define APP_DELEGATE ((WPAppDelegate *)[UIApplication sharedApplication].delegate)

@interface WPAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

- (void)registerForPush;

@property (nonatomic) BOOL pushNotificationsEnabled;

- (void)incrementNetworkActivityIndicatorCount;
- (void)decrementNetworkActivityIndicatorCount;

@property (nonatomic) PFInstallation *installation;
- (void)saveInstallation;

@end
