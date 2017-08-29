//
//  AppDelegate.h
//  Simple Survey
//
//  Created by Ben Leiken on 6/16/15.
//  Copyright (c) 2015 SurveyMonkey Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ViewController.h"
#import <WindowsAzureMessaging/WindowsAzureMessaging.h>
#import "HubInfo.h"

@interface AppDelegate : UIResponder <UIApplicationDelegate, UIAlertViewDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) NSString *surveyHash;

@end

