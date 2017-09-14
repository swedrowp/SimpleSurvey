// ----------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// ----------------------------------------------------------------------------
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

#import "HubInfo.h"
#import <UIKit/UIKit.h>
#import "QSAppDelegate.h"
 #import <CommonCrypto/CommonHMAC.h>
#import <surveymonkey-ios-sdk/SurveyMonkeyiOSSDK/SurveyMonkeyiOSSDK.h>


@interface QSTodoListViewController : UITableViewController<UITableViewDelegate, UITableViewDataSource, NSFetchedResultsControllerDelegate, SMFeedbackDelegate, UITextFieldDelegate, NSXMLParserDelegate>
{
    NSXMLParser *xmlParser;
}


@property (weak, nonatomic) IBOutlet UITextField *surveyTitle;
@property (weak, nonatomic) IBOutlet UITextField *surveyHash;



@property (copy, nonatomic) NSString *notificationMessage;
@property (copy, nonatomic) NSString *surveyTitleNotification;
@property (copy, nonatomic) NSString *surveyHashNotification;
@property (copy, nonatomic) NSString *statusResult;
@property (copy, nonatomic) NSString *currentElement;


- (IBAction)onAdd:(id)sender;

@end
