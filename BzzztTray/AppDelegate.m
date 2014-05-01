//
//  AppDelegate.m
//  BzzztTray
//
//  Created by Alex Barlow on 30/04/2014.
//  Copyright (c) 2014 Alex Barlow. All rights reserved.
//

#import "AppDelegate.h"
#import <AFNetworking.h>

#define BUTTON_TITLE @"bzzzt"
#define BUTTON_FAIL  @"failure.."
#define BUTTON_OPEN  @"open.."

#define OPEN_TIME  3

#define API_URL(token) [NSString stringWithFormat:@"http://bzzzt.local?token=%@", token]

@interface AppDelegate ()
@property (weak) IBOutlet NSMenu *statusMenu;
@end

@implementation AppDelegate
{
    __weak NSMenu *_statusMenu;
    NSStatusItem *_statusItem;
    AFHTTPRequestOperationManager *_manager;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    _manager = [AFHTTPRequestOperationManager manager];
    
    _statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
    [_statusItem setTitle:BUTTON_TITLE];
    [_statusItem setHighlightMode:YES];

    [_statusItem setTarget:self];
    [_statusItem setAction:@selector(didClickStatusBar)];
}

-(void)didClickStatusBar
{
    [_statusItem setEnabled:NO];
    NSUUID *uid = [NSUUID UUID];
    
    [_manager POST:API_URL([uid UUIDString]) parameters:nil constructingBodyWithBlock:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        [_statusItem setTitle:BUTTON_OPEN];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(OPEN_TIME * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [_statusItem setEnabled:YES];
            [_statusItem setTitle:BUTTON_TITLE];
        });
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [_statusItem setTitle:BUTTON_FAIL];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [_statusItem setEnabled:YES];
            [_statusItem setTitle:BUTTON_TITLE];
        });
    }];
}

@end
