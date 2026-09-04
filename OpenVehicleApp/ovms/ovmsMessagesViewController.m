//
//  ovmsMessagesViewController.m
//  Open Vehicle
//
//  Created by Mark Webb-Johnson on 15/1/2019.
//  Copyright © 2019 Open Vehicle Systems. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ovmsMessagesViewController.h"
#import "NoChat/ovmsTextMessageCell.h"
#import "NoChat/ovmsTextMessageCellLayout.h"
#import "NoChat/ovmsMessageInputPanel.h"
#import "JHNotificationManager.h"
#import <TargetConditionals.h>

@implementation ovmsMessagesViewController

#pragma mark - View lifecycle

+ (UITableViewStyle)tableViewStyleForCoder:(NSCoder *)decoder
{
    return UITableViewStylePlain;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    self.edgesForExtendedLayout = UIRectEdgeNone;
    self.navigationItem.title = [ovmsAppDelegate myRef].sel_label;
    self.navigationController.delegate = self;
    [self installKeyboardDismissButton];
    [self update];
}

- (void)installKeyboardDismissButton
{
    UIBarButtonItem *doneButton = [[UIBarButtonItem alloc]
        initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                             target:self
                             action:@selector(dismissMessageKeyboard:)];
    self.navigationItem.rightBarButtonItem = doneButton;
    self.navigationItem.rightBarButtonItems = @[doneButton, [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemTrash target:self action:@selector(showClearMessagesConfirmation)]];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Commands" style:UIBarButtonItemStylePlain target:self action:@selector(showCommandShortcuts)];
    self.parentViewController.navigationItem.rightBarButtonItems = self.navigationItem.rightBarButtonItems;
    self.parentViewController.navigationItem.leftBarButtonItem = self.navigationItem.leftBarButtonItem;
}

- (void)dismissMessageKeyboard:(id)sender
{
    [self.inputPanel endInputting:YES];
    [self.view endEditing:YES];
}

- (void)dealloc
{
}

- (void)viewWillAppear:(BOOL)animated
{
    self.backgroundView.backgroundColor = [UIColor colorWithRed:0.069420576095581055 green:0.10595327615737915 blue:0.19171994924545288 alpha:1.0];
    [super viewWillAppear:animated];
    [self installKeyboardDismissButton];
    self.navigationItem.title = [ovmsAppDelegate myRef].sel_label;
    
    [[ovmsAppDelegate myRef] registerForUpdate:self];
    [self loadMessages];
    [self update];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
#if DEBUG && TARGET_OS_SIMULATOR
    if (!self.screenshotScenarioHandled) {
        NSString *scenario = [[[NSProcessInfo processInfo] environment] objectForKey:@"OVMS_SCREENSHOT_SCENARIO"];
        if ([scenario isEqualToString:@"messages-commands"]) { self.screenshotScenarioHandled = YES; [self showCommandShortcuts]; }
        else if ([scenario isEqualToString:@"messages-clear"]) { self.screenshotScenarioHandled = YES; [self showClearMessagesConfirmation]; }
    }
#endif
}

- (void)sendShortcut:(NSString *)command
{
    [[ovmsAppDelegate myRef] addMessage:command incoming:NO];
    [[ovmsAppDelegate myRef] commandDoCommand:command];
}

- (void)showCommandShortcuts
{
    UIAlertController *sheet = [UIAlertController alertControllerWithTitle:@"Command shortcuts" message:@"Run a read-only OVMS shell command." preferredStyle:UIAlertControllerStyleActionSheet];
    NSArray *commands = @[@[@"Vehicle status", @"stat"], @[@"Module summary", @"module summary"], @[@"Network status", @"network status"], @[@"List metrics", @"metrics list"]];
    for (NSArray *entry in commands) [sheet addAction:[UIAlertAction actionWithTitle:entry[0] style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) { [self sendShortcut:entry[1]]; }]];
    [sheet addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    if (sheet.popoverPresentationController) { sheet.popoverPresentationController.barButtonItem = self.navigationItem.leftBarButtonItem; }
    [self presentViewController:sheet animated:YES completion:nil];
}

- (void)showClearMessagesConfirmation
{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Clear message history?" message:@"This removes the locally stored command and notification history for this vehicle." preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:@"Clear" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) { [[ovmsAppDelegate myRef].sel_messages removeAllObjects]; [self clearMessages]; [self.collectionView reloadData]; }]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [self dismissMessageKeyboard:nil];
    [super viewWillDisappear:animated];
    [[ovmsAppDelegate myRef] deregisterFromUpdate:self];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
}

- (UIInterfaceOrientationMask) supportedInterfaceOrientations
{
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
        return UIInterfaceOrientationMaskAll;
    else
        return UIInterfaceOrientationMaskPortrait;
}

+ (Class)cellLayoutClassForItemType:(NSString *)type
{
    return [OvmsTextMessageCellLayout class];
}

+ (Class)inputPanelClass
{
    return [OvmsChatInputTextPanel class];
}

- (void)registerChatItemCells
{
     [self.collectionView registerClass:[OvmsTextMessageCell class] forCellWithReuseIdentifier:[OvmsTextMessageCell reuseIdentifier]];
}

-(void) update
{
}

-(void) clearMessages
{
    [self.layouts removeAllObjects];
}

-(void) addMessage:(OvmsMessage*)message
{
    NSIndexSet *indexes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, 1)];
    NSMutableArray *layouts = [[NSMutableArray alloc] init];
    id<NOCChatItemCellLayout> layout = [self createLayoutWithItem:message];
    [layouts insertObject:layout atIndex:0];
    [self insertLayouts:layouts atIndexes:indexes animated:true];
    [self scrollToBottomAnimated:true];
}

-(void) addMessages:(NSMutableArray*)messages animated:(BOOL)animated
{
    if ((messages!=nil)&&(messages.count > 0))
        {
        NSIndexSet *indexes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, messages.count)];
        NSMutableArray *layouts = [[NSMutableArray alloc] init];
    
        [messages enumerateObjectsUsingBlock:^(OvmsMessage *message, NSUInteger idx, BOOL *stop) {
            id<NOCChatItemCellLayout> layout = [self createLayoutWithItem:message];
            [layouts insertObject:layout atIndex:0];
        }];
    
        [self insertLayouts:layouts atIndexes:indexes animated:animated];
        [self scrollToBottomAnimated:animated];
        }
    else
    {
        [self.collectionView reloadData];
    }
}

-(void) loadMessages
{
    [self.layouts removeAllObjects];
    [self addMessages:(NSMutableArray*)[ovmsAppDelegate myRef].sel_messages animated:NO];
}

#pragma mark - OvmsChatInputTextPanelDelegate

- (void)inputTextPanel:(OvmsChatInputTextPanel *)inputTextPanel requestSendText:(NSString *)text
{
    [[ovmsAppDelegate myRef] addMessage:text incoming:NO];
    [[ovmsAppDelegate myRef] commandDoCommand:text];
}

@end
