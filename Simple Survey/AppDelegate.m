//
//  AppDelegate.m
//  Simple Survey
//
//  Created by Ben Leiken on 6/16/15.
//  Copyright (c) 2015 SurveyMonkey Inc. All rights reserved.
//


#import "AppDelegate.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    if (launchOptions != nil)
    {
        //opened from a push notification when the app is closed
        NSDictionary* userInfo = [launchOptions objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey];
        if (userInfo != nil)
        {
            NSLog(@"%@", userInfo);
            self.surveyHash = [[userInfo objectForKey:@"aps"] valueForKey:@"surveyHash"];
            [self MessageBox:@"Notification" message:[[userInfo objectForKey:@"aps"] valueForKey:@"alert"]];
        }
        
    }
    
    // Override point for customization after application launch.
    UIUserNotificationSettings *settings = [UIUserNotificationSettings settingsForTypes:UIUserNotificationTypeSound |
                                            UIUserNotificationTypeAlert | UIUserNotificationTypeBadge categories:nil];
    
    [[UIApplication sharedApplication] registerUserNotificationSettings:settings];
    [[UIApplication sharedApplication] registerForRemoteNotifications];
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}



#pragma mark - WindowsAzureNotifications

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *) deviceToken {
    SBNotificationHub* hub = [[SBNotificationHub alloc] initWithConnectionString:HUBLISTENACCESS
                                                             notificationHubPath:HUBNAME];
    
    [hub registerNativeWithDeviceToken:deviceToken tags:nil completion:^(NSError* error) {
        if (error != nil) {
            NSLog(@"Error registering for notifications: %@", error);
        }
        else {
            NSLog(@"registered, device token: %@", deviceToken);
        }
    }];
}

-(void)MessageBox:(NSString *)title message:(NSString *)messageText
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title message:messageText delegate:self
                                          cancelButtonTitle:@"Cancel" otherButtonTitles:@"OK", nil];
    alert.tag = 101;
    [alert show];
}

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    if (alertView.tag == 101) {
        switch (buttonIndex) {
            case 0:
                NSLog(@"Cancel");
                break;
                
            case 1:
                NSLog(@"OK");
                [[NSNotificationCenter defaultCenter] postNotificationName:@"initAndTakeSurvey" object:nil];
            default:
                break;
        }
    }
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification: (NSDictionary *)userInfo {
    
    if ( application.applicationState == UIApplicationStateInactive)
    {
        //opened from a push notification when the app was on background
    }
    else if(application.applicationState == UIApplicationStateActive)
    {
        // a push notification when the app is running. So that you can display an alert and push in any view
    }
    
    NSLog(@"%@", userInfo);
    self.surveyHash = [[userInfo objectForKey:@"aps"] valueForKey:@"surveyHash"];
    [self MessageBox:@"Notification" message:[[userInfo objectForKey:@"aps"] valueForKey:@"alert"]];
}

@end
