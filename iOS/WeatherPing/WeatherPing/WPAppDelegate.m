//
//  WPAppDelegate.m
//  WeatherPing
//
//  Created by Nate Parrott on 8/18/14.
//  Copyright (c) 2014 Nate Parrott. All rights reserved.
//

#import "WPAppDelegate.h"
#import <Crashlytics/Crashlytics.h>

@interface WPAppDelegate ()

@property (nonatomic) NSInteger activityIndicatorCount;

@end

@implementation WPAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [Crashlytics startWithAPIKey:@"c00a274f2c47ad5ee89b17ccb2fdb86e8d1fece8"];
    [self applyTheming];
    [Parse setApplicationId:@"Uf9cDf0SaNEnyM4IolJj3OOKnAgycEfqhcjcBiPJ"
                  clientKey:@"X9vWnuPZu9MAloBiZyaTqJnvcHf5ACEm6Xln1RLh"];
    [PFAnalytics trackAppOpenedWithLaunchOptions:launchOptions];
    self.installation = [PFInstallation currentInstallation];
    [self updatePushStatus];
    [self.window makeKeyAndVisible];
    
    return YES;
}

- (void)applyTheming {
    [self.window setTintColor:[UIColor colorWithRed:0.271 green:0.647 blue:0.584 alpha:1.000]];
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    [self updatePushStatus];
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

#pragma mark Push

- (void)registerForPush {
    [[UIApplication sharedApplication] registerForRemoteNotificationTypes:
     UIRemoteNotificationTypeBadge |
     UIRemoteNotificationTypeAlert];
}

- (void)application:(UIApplication *)application
didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)newDeviceToken {
    // Store the deviceToken in the current installation and save it to Parse.
    [self.installation setDeviceTokenFromData:newDeviceToken];
    self.installation.channels = @[@"global"];
    [self saveInstallation];
    [self updatePushStatus];
}

- (void)application:(UIApplication *)application
didReceiveRemoteNotification:(NSDictionary *)userInfo {
    [PFPush handlePush:userInfo];
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
    [self updatePushStatus];
}

- (void)updatePushStatus {
    self.pushNotificationsEnabled = [[UIApplication sharedApplication] enabledRemoteNotificationTypes] != UIRemoteNotificationTypeNone;
}

#pragma mark Activity indicator

- (void)incrementNetworkActivityIndicatorCount {
    self.activityIndicatorCount++;
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
}
- (void)decrementNetworkActivityIndicatorCount {
    self.activityIndicatorCount--;
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:self.activityIndicatorCount > 0];
}

- (void)saveInstallation {
    [self.installation saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (!succeeded) {
            [self.installation saveEventually];
        }
    }];
}

@end
