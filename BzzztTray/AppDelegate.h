//
//  AppDelegate.h
//  BzzztTray
//
//  Created by Alex Barlow on 30/04/2014.
//  Copyright (c) 2014 Alex Barlow. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <SRWebSocket.h>

@interface AppDelegate : NSObject <NSApplicationDelegate, SRWebSocketDelegate>

@property (assign) IBOutlet NSWindow *window;

@end
