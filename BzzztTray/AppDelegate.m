//
//  AppDelegate.m
//  BzzztTray
//
//  Created by Alex Barlow on 30/04/2014.
//  Copyright (c) 2014 Alex Barlow. All rights reserved.
//

#import "AppDelegate.h"
#import "PFMoveApplication.h"
#import "NSBundle+LoginItem.h"
#import <Sparkle/Sparkle.h>

#define BUTTON_TITLE @"bzzzt"
#define BUTTON_OPEN  @"open.."

#define RECCONECT_DELAY 8
#define PING_INTERVAL 4

#define API_URL(username) [NSString stringWithFormat:@"ws://bzzzt.local:8888?id=%@", username]

@interface AppDelegate ()
@property (weak) IBOutlet NSMenu *statusMenu;
@end

@implementation AppDelegate
{
    SUUpdater *updater;
    
    __weak NSMenu *_statusMenu;
    NSStatusItem *_statusItem;
    SRWebSocket *_webSocket;
    BOOL _isDown;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    PFMoveToApplicationsFolderIfNecessary();
    if (![[NSBundle mainBundle] isLoginItem]) {
        [[NSBundle mainBundle] addToLoginItems];
    }
    
    updater = [SUUpdater sharedUpdater];
    [updater checkForUpdates:self];
    
    _isDown = NO;
    
    _statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
    [_statusItem setTitle:BUTTON_TITLE];
    [_statusItem setHighlightMode:YES];
    [_statusItem setEnabled:NO];

    [_statusItem setTarget:self];
    [_statusItem setAction:@selector(didClickStatusBar:)];
    [_statusItem sendActionOn:NSLeftMouseDownMask|NSLeftMouseUpMask];
    
    [self openConnection];
}

-(void)openConnection
{
    [_webSocket close];
    _webSocket = nil;
    
    _webSocket = [[SRWebSocket alloc] initWithURL:[NSURL URLWithString:API_URL(NSUserName())]];
    _webSocket.delegate = self;
    [_webSocket open];
    [_webSocket monitorReachabilityWithInterval:PING_INTERVAL];
}

-(void)didClickStatusBar:(id)sender
{
    [self toggleDoor];
}

-(void)toggleDoor{
    if (_isDown) {
        _isDown = NO;
        [_webSocket send:@"0"];
        [_statusItem setTitle:BUTTON_TITLE];
    }else{
        _isDown = YES;
        [_webSocket send:@"1"];
        [_statusItem setTitle:BUTTON_OPEN];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            if (_isDown) {
                _isDown = NO;
                [_webSocket send:@"0"];
                [_statusItem setTitle:BUTTON_TITLE];
            }
        });
    }
}

// Websocket callbacks

- (void)webSocketDidOpen:(SRWebSocket *)webSocket{
    [_statusItem setEnabled:YES];
    NSLog(@"websocket open");
}


- (void)webSocket:(SRWebSocket *)webSocket didFailWithError:(NSError *)error{
    NSLog(@"reason %@", error);
    [self recconnectAfterDelay];
    [_statusItem setEnabled:NO];
}

- (void)webSocket:(SRWebSocket *)webSocket didCloseWithCode:(NSInteger)code reason:(NSString *)reason wasClean:(BOOL)wasClean
{
    NSLog(@"reason %@", reason);
    [self recconnectAfterDelay];
    [_statusItem setEnabled:NO];
}

- (void)webSocket:(SRWebSocket *)webSocket didReceiveMessage:(id)message
{
    NSData* data = [message dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
    
    if ([dict[@"id"] isEqualToString:NSUserName()]) {
        // It's me!
    } else {
        if ((BOOL)dict[@"is_unlocked"]) {
            [_statusItem setEnabled:NO];
            [_statusItem setTitle:dict[@"id"]];
        } else {
            [_statusItem setEnabled:YES];
            [_statusItem setTitle:BUTTON_TITLE];
        }
    }
}

-(void)recconnectAfterDelay
{
    NSLog(@"recconecting after delay");
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(RECCONECT_DELAY * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (_webSocket.readyState != SR_OPEN) {
            [self openConnection];
        }
    });
}

@end
