/*
 * Copyright (C) SurveyMonkey
 */

#import "AppDelegate.h"
#import "ViewController.h"
#import <surveymonkey-ios-sdk/SurveyMonkeyiOSSDK/SurveyMonkeyiOSSDK.h>

#define SURVEY_HASH @"M2TH2TN"

//Set to Angry Birds -- change to your app
#define APP_ID @"343200656"

@interface ViewController () <SMFeedbackDelegate>

@property (nonatomic,assign) BOOL observer;
@property (nonatomic, strong) AppDelegate *appDelegate;
@property (nonatomic, strong) SMFeedbackViewController * feedbackController;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _observer = NO;
    _appDelegate = (AppDelegate*)[UIApplication sharedApplication].delegate;
    
    if (!_observer) {
        [self addObserver];
    }
    
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

@end
