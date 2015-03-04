//
//  AppDelegate.h
//  BackToTheYamaguchike
//

//  Copyright (c) 2015年 kanta. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <SpriteKit/SpriteKit.h>

@interface AppDelegate : NSObject <NSApplicationDelegate>

@property (assign) IBOutlet NSWindow *window;
@property (assign) IBOutlet SKView *skView;
@property (strong, nonatomic) NSDictionary *peopleDict;
@property (strong, nonatomic) NSDictionary *carDict;

@end
