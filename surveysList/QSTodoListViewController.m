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

#import <MicrosoftAzureMobile/MicrosoftAzureMobile.h>
#import "QSAppDelegate.h"
#import "QSTodoListViewController.h"
#import "QSTodoService.h"
#import "QSAppDelegate.h"

#pragma mark * Private Interface


@interface QSTodoListViewController ()

// Private properties
@property (nonatomic,assign) BOOL observer;
@property (strong, nonatomic) QSTodoService *todoService;
@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;
@property (nonatomic, strong) SMFeedbackViewController * feedbackController;
@property (nonatomic, strong) QSAppDelegate *appDelegate;
@end


@implementation QSTodoListViewController


#pragma mark - sending push notification from app
NSString *HubEndpoint;
NSString *HubSasKeyName;
NSString *HubSasKeyValue;

-(void)ParseConnectionString
{
    NSArray *parts = [HUBFULLACCESS componentsSeparatedByString:@";"];
    NSString *part;
    
    if ([parts count] != 3)
    {
        NSException* parseException = [NSException exceptionWithName:@"ConnectionStringParseException"
                                                              reason:@"Invalid full shared access connection string" userInfo:nil];
        
        @throw parseException;
    }
    
    for (part in parts)
    {
        if ([part hasPrefix:@"Endpoint"])
        {
            HubEndpoint = [NSString stringWithFormat:@"https%@",[part substringFromIndex:11]];
        }
        else if ([part hasPrefix:@"SharedAccessKeyName"])
        {
            HubSasKeyName = [part substringFromIndex:20];
        }
        else if ([part hasPrefix:@"SharedAccessKey"])
        {
            HubSasKeyValue = [part substringFromIndex:16];
        }
    }
}

-(NSString *)CF_URLEncodedString:(NSString *)inputString
{
    return (__bridge NSString *)CFURLCreateStringByAddingPercentEscapes(NULL, (CFStringRef)inputString,
                                                                        NULL, (CFStringRef)@"!*'();:@&=+$,/?%#[]", kCFStringEncodingUTF8);
}

-(void)MessageBox:(NSString *)title message:(NSString *)messageText
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title message:messageText delegate:self
                                          cancelButtonTitle:@"OK" otherButtonTitles: nil];
    [alert show];
}

-(NSString*) generateSasToken:(NSString*)uri
{
    NSString *targetUri;
    NSString* utf8LowercasedUri = NULL;
    NSString *signature = NULL;
    NSString *token = NULL;
    
    @try
    {
        // Add expiration
        uri = [uri lowercaseString];
        utf8LowercasedUri = [self CF_URLEncodedString:uri];
        targetUri = [utf8LowercasedUri lowercaseString];
        NSTimeInterval expiresOnDate = [[NSDate date] timeIntervalSince1970];
        int expiresInMins = 60; // 1 hour
        expiresOnDate += expiresInMins * 60;
        UInt64 expires = trunc(expiresOnDate);
        NSString* toSign = [NSString stringWithFormat:@"%@\n%qu", targetUri, expires];
        
        // Get an hmac_sha1 Mac instance and initialize with the signing key
        const char *cKey  = [HubSasKeyValue cStringUsingEncoding:NSUTF8StringEncoding];
        const char *cData = [toSign cStringUsingEncoding:NSUTF8StringEncoding];
        unsigned char cHMAC[CC_SHA256_DIGEST_LENGTH];
        CCHmac(kCCHmacAlgSHA256, cKey, strlen(cKey), cData, strlen(cData), cHMAC);
        NSData *rawHmac = [[NSData alloc] initWithBytes:cHMAC length:sizeof(cHMAC)];
        signature = [self CF_URLEncodedString:[rawHmac base64EncodedStringWithOptions:0]];
        
        // Construct authorization token string
        token = [NSString stringWithFormat:@"SharedAccessSignature sig=%@&se=%qu&skn=%@&sr=%@",
                 signature, expires, HubSasKeyName, targetUri];
    }
    @catch (NSException *exception)
    {
        [self MessageBox:@"Exception Generating SaS Token" message:[exception reason]];
    }
    @finally
    {
        if (utf8LowercasedUri != NULL)
            CFRelease((CFStringRef)utf8LowercasedUri);
        if (signature != NULL)
            CFRelease((CFStringRef)signature);
    }
    
    return token;
}

- (void)SendNotificationRESTAPI
{
    NSURLSession* session = [NSURLSession
                             sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]
                             delegate:nil delegateQueue:nil];
    
    // Apple Notification format of the notification message
    NSString *json = [NSString stringWithFormat:@"{\"aps\":{\"alert\":\"%@\", \"surveyHash\":\"%@\"}}",
                      self.surveyTitleNotification,
                      self.surveyHashNotification];
    NSLog(@"push notification: %@", json);
    
    // Construct the message's REST endpoint
    NSURL* url = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@/messages/%@", HubEndpoint,
                                       HUBNAME, API_VERSION]];
    
    // Generate the token to be used in the authorization header
    NSString* authorizationToken = [self generateSasToken:[url absoluteString]];
    
    //Create the request to add the APNs notification message to the hub
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setHTTPMethod:@"POST"];
    [request setValue:@"application/json;charset=utf-8" forHTTPHeaderField:@"Content-Type"];
    
    // Signify Apple notification format
    [request setValue:@"apple" forHTTPHeaderField:@"ServiceBusNotification-Format"];
    
    //Authenticate the notification message POST request with the SaS token
    [request setValue:authorizationToken forHTTPHeaderField:@"Authorization"];
    
    //Add the notification message body
    [request setHTTPBody:[json dataUsingEncoding:NSUTF8StringEncoding]];
    
    // Send the REST request
    NSURLSessionDataTask* dataTask = [session dataTaskWithRequest:request
                                                completionHandler:^(NSData *data, NSURLResponse *response, NSError *error)
                                      {
                                          NSHTTPURLResponse* httpResponse = (NSHTTPURLResponse*) response;
                                          if (error || (httpResponse.statusCode != 200 && httpResponse.statusCode != 201))
                                          {
                                              NSLog(@"\nError status: %ld\nError: %@", (long)httpResponse.statusCode, error);
                                          }
                                          if (data != NULL)
                                          {
                                              xmlParser = [[NSXMLParser alloc] initWithData:data];
                                              [xmlParser setDelegate:self];
                                              [xmlParser parse];
                                          }
                                      }];
    [dataTask resume];
}

-(void)parserDidStartDocument:(NSXMLParser *)parser
{
    self.statusResult = @"";
}

-(void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName
 namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName
   attributes:(NSDictionary *)attributeDict
{
    NSString * element = [elementName lowercaseString];
    NSLog(@"*** New element parsed : %@ ***",element);
    
    if ([element isEqualToString:@"code"] | [element isEqualToString:@"detail"])
    {
        self.currentElement = element;
    }
}

-(void) parser:(NSXMLParser *)parser foundCharacters:(NSString *)parsedString
{
    self.statusResult = [self.statusResult stringByAppendingString:
                         [NSString stringWithFormat:@"%@ : %@\n", self.currentElement, parsedString]];
}

-(void)parserDidEndDocument:(NSXMLParser *)parser
{
    // Set the status label text on the UI thread
    dispatch_async(dispatch_get_main_queue(),
                   ^{
                       NSLog(@"%@", self.statusResult);
                   });
}

#pragma mark * UIView methods
- (void)viewDidLoad
{
    [super viewDidLoad];
    [self ParseConnectionString];
    
    _observer = NO;
    if (!_observer) {
        [self addObserver];
    }
    
    self.appDelegate = (QSAppDelegate*)[UIApplication sharedApplication].delegate;
    self.tableView.allowsMultipleSelectionDuringEditing = NO;

    // Create the todoService - this creates the Mobile Service client inside the wrapped service
    self.todoService = [QSTodoService defaultService];

    // have refresh control reload all data from server
    [self.refreshControl addTarget:self
                            action:@selector(onRefresh:)
                  forControlEvents:UIControlEventValueChanged];

    NSError *error;
    if (![[self fetchedResultsController] performFetch:&error]) {
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        exit(-1);  // Fail
    }

    // load the data
    [self refresh];
}


- (void)viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];
}

- (void)addObserver{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(initAndTakeSurvey) name:@"initAndTakeSurvey" object:nil];
    _observer = YES;
}

- (void)removeObserver{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    _observer = NO;
}


- (NSFetchedResultsController *)fetchedResultsController {

    if (_fetchedResultsController != nil) {
        return _fetchedResultsController;
    }

    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    QSAppDelegate *delegate = (QSAppDelegate *)[[UIApplication sharedApplication] delegate];
    NSManagedObjectContext *context = delegate.managedObjectContext;

    fetchRequest.entity = [NSEntityDescription entityForName:@"SurveysTable" inManagedObjectContext:context];

    // sort by item text
    fetchRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"createdAt" ascending:YES]];

    // Note: if storing a lot of data, you should specify a cache for the last parameter
    // for more information, see Apple's documentation: http://go.microsoft.com/fwlink/?LinkId=524591&clcid=0x409
    NSFetchedResultsController *theFetchedResultsController =
        [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                            managedObjectContext:context sectionNameKeyPath:nil
                                                       cacheName:nil];
    self.fetchedResultsController = theFetchedResultsController;

    _fetchedResultsController.delegate = self;

    return _fetchedResultsController;

}

- (void) refresh
{
    [self.refreshControl beginRefreshing];

    [self.todoService syncData:^
    {
        [self.refreshControl endRefreshing];
    }];
}



#pragma mark * UITableView methods
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    //Nothing gets called here if you invoke `tableView:editActionsForRowAtIndexPath:` according to Apple docs so just leave this method blank
}

-(NSArray *)tableView:(UITableView *)tableView editActionsForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewRowAction *delete = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleDefault title:@"Delete" handler:^(UITableViewRowAction *action, NSIndexPath *indexPath)
                                    {
                                        NSManagedObject *itemObj = [self.fetchedResultsController objectAtIndexPath:indexPath];
                                        NSDictionary *item = @{ @"id" : [itemObj valueForKey:@"id"] };
                                        [self.todoService removeItem:item completion:nil];
                                        
                                        NSLog(@"deleted item: %@",[itemObj valueForKey:@"id"]);
                                    }];
    delete.backgroundColor = [UIColor redColor];
    
    UITableViewRowAction *push = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleDefault title:@"Push" handler:^(UITableViewRowAction *action, NSIndexPath *indexPath)
                                  {
                                      NSManagedObject *itemObj = [self.fetchedResultsController objectAtIndexPath:indexPath];
                                      self.surveyTitleNotification = [itemObj valueForKey:@"surveyTitle"];
                                      self.surveyHashNotification = [itemObj valueForKey:@"surveyHash"];
                                      [self SendNotificationRESTAPI];
                                  }];
    push.backgroundColor = [UIColor grayColor];
    
    return @[delete, push];
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    // Set background color of cell here if you don't want default white
}

- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    NSManagedObject *item = [self.fetchedResultsController objectAtIndexPath:indexPath];

    // Set the label on the cell and make sure the label color is black (in case this cell
    // has been reused and was previously greyed out
    cell.textLabel.textColor = [UIColor blackColor];
    cell.textLabel.text = [item valueForKey:@"surveyTitle"];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"Cell";
    
    UITableViewCell *cell = (UITableViewCell *)[tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdentifier];
    }

    [self configureCell:cell atIndexPath:indexPath];

    return cell;
}


-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    NSManagedObject *item = [self.fetchedResultsController objectAtIndexPath:indexPath];
    self.appDelegate.surveyHash = [item valueForKey:@"surveyHash"];
    [self initAndTakeSurvey];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;  // Always a single section
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    id  sectionInfo = [self.fetchedResultsController.sections objectAtIndex:section];
    return [sectionInfo numberOfObjects];
}



#pragma mark * UITextFieldDelegate methods
-(BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder]; // hide the on-screen keyboard
    return YES;
}



#pragma mark * SurveyMonkey Methods
- (void)respondentDidEndSurvey:(SMRespondent *)respondent error:(NSError *) error {
    if (respondent != nil) {
        SMQuestionResponse * questionResponse = respondent.questionResponses[0];
        NSString * questionID = questionResponse.questionID;
    }
    else {
        /*
         * Handle error returned when a response is not successfully collected
         */
    }
    
}

-(void)initSurvey{
    /*
     * Initialize your SMFeedbackViewController like this, pass the survey code from your Mobile SDK Collector on SurveyMonkey.com
     */
    _feedbackController = [[SMFeedbackViewController alloc] initWithSurvey:self.appDelegate.surveyHash];
    /*
     * Setting the feedback controller's delegate allows you to detect when a user has completed your survey and to
     * capture and consume their response in the form of an SMRespondent object
     */
    _feedbackController.delegate = self;
    [[UINavigationBar appearance] setTintColor:[UIColor blueColor]];
}

- (void)takeSurvey{
    [_feedbackController presentFromViewController:self animated:YES completion:nil];
}

- (void)initAndTakeSurvey{
    [self initSurvey];
    [self takeSurvey];
}



#pragma mark * UI Actions
- (IBAction)onAdd:(id)sender
{
    if ((self.surveyTitle.text.length  == 0) || (self.surveyHash.text.length  == 0))
    {
        return;
    }
    
    NSDictionary *item = @{ @"surveyTitle" : self.surveyTitle.text,  @"surveyHash" : self.surveyHash.text };
    [self.todoService addItem:item completion:nil];
    
    self.surveyTitle.text = @"";
    self.surveyHash.text = @"";
}


- (void)onRefresh:(id) sender
{
    [self refresh];
}

#pragma mark * NSFetchedResultsController methods
- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
    // The fetch controller is about to start sending change notifications, so prepare the table view for updates.
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView beginUpdates];
    });
}


- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath
{
    dispatch_async(dispatch_get_main_queue(), ^{
        UITableView *tableView = self.tableView;

        switch(type) {

            case NSFetchedResultsChangeInsert:
                [tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
                break;

            case NSFetchedResultsChangeDelete:
                [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
                break;

            case NSFetchedResultsChangeUpdate:
                [tableView reloadRowsAtIndexPaths:@[indexPath]
                                 withRowAnimation:UITableViewRowAnimationAutomatic];

                // note: Apple samples show a call to configureCell here; this is incorrect--it can result in retrieving the
                // wrong index when rows are reordered. For more information, see http://go.microsoft.com/fwlink/?LinkID=524590&clcid=0x409
                // [self configureCell:[tableView cellForRowAtIndexPath:indexPath] atIndexPath:indexPath]; // wrong! call reloadRows instead
                break;

            case NSFetchedResultsChangeMove:
                [tableView deleteRowsAtIndexPaths:[NSArray
                                                   arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
                [tableView insertRowsAtIndexPaths:[NSArray
                                                   arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
                break;
        }
    });
}


- (void)controller:(NSFetchedResultsController *)controller
    didChangeSection:(id)sectionInfo
    atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type
{
    dispatch_async(dispatch_get_main_queue(), ^{
        switch(type) {

            case NSFetchedResultsChangeInsert:
                [self.tableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
                break;

            case NSFetchedResultsChangeDelete:
                [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
                break;

            case NSFetchedResultsChangeUpdate:
                [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
                break;

            default:
                break;
        }
    });
}


- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
    // The fetch controller has sent all current change notifications, so tell the table view to process all updates.
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView endUpdates];
    });
}


@end
