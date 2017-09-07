//
//  TableViewController.m
//  Simple Survey
//
//  Created by swedrowp on 07/09/2017.
//  Copyright © 2017 SurveyMonkey Inc. All rights reserved.
//

#import "AppDelegate.h"
#import "TableViewController.h"
#import <surveymonkey-ios-sdk/SurveyMonkeyiOSSDK/SurveyMonkeyiOSSDK.h>

@interface TableViewController () <SMFeedbackDelegate>

@property (nonatomic,assign) BOOL observer;
@property (nonatomic, strong) AppDelegate *appDelegate;
@property (nonatomic, strong) SMFeedbackViewController * feedbackController;

@end

@implementation TableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _observer = NO;
    _appDelegate = (AppDelegate*)[UIApplication sharedApplication].delegate;
    
    if (!_observer) {
        [self addObserver];
    }
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - survey monkey 
-(void)initSurvey{
    /*
     * Initialize your SMFeedbackViewController like this, pass the survey code from your Mobile SDK Collector on SurveyMonkey.com
     */
    _feedbackController = [[SMFeedbackViewController alloc] initWithSurvey:_appDelegate.surveyHash];
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

#pragma mark - observer handler
- (void)addObserver{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(initAndTakeSurvey) name:@"initAndTakeSurvey" object:nil];
    _observer = YES;
}

- (void)removeObserver{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    _observer = NO;
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
#warning Incomplete implementation, return the number of sections
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
#warning Incomplete implementation, return the number of rows
    return 10;
}


/*
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:<#@"reuseIdentifier"#> forIndexPath:indexPath];
    
    
    
    return cell;
}
*/

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
