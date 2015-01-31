//
//  GameScene.m
//  BackToTheYamaguchike
//
//  Created by kanta on 2015/01/29.
//  Copyright (c) 2015年 kanta. All rights reserved.
//

#import "GameScene.h"
#import "AppDelegate.h"

@implementation GameScene {
    AppDelegate *app;
    CGFloat _additionW;
    CGFloat _additionH;
    BOOL _isSettingMode;
    SKSpriteNode *_edoBg;
    NSMutableArray *_edoPeopleNodeArray;
    float _nextRunTime;
}


-(void)didMoveToView:(SKView *)view {
    // AppDelegateをインスタンス化
    app = [[NSApplication sharedApplication] delegate];
    _edoPeopleNodeArray = [NSMutableArray array];
    // Setup your scene here
    _additionW = 0.0f;
    _additionH = 0.0f;
    _nextRunTime = 0.0f;
    _isSettingMode = true;
    self.backgroundColor = [NSColor blackColor];
    self.view.window.backgroundColor = [NSColor grayColor];
    [self addEdoBackground];
    [self addPeople];
    [self movePeopleOnce];
}

-(void)update:(CFTimeInterval)currentTime {
    // Called before each frame is rendered
    [self movePeopleLoop];
    //[self moveBackgroundIn30secInterval:currentTime];
}

-(void)addPeople {
    [self addEdoPeople];
    //[self addMeijiPeople];
}

-(void)moveBackgroundIn30secInterval:(CFTimeInterval)currentTime {
    float interval = 30.0f;
    if (_nextRunTime==0.0f) {
        _nextRunTime = currentTime+interval;
    }
    if (currentTime>=_nextRunTime) {
        [self moveBackground];
        _nextRunTime = currentTime+interval;
    }
}


-(void)moveBackground {
    float positionY = _edoBg.position.y-_edoBg.size.height;
    SKAction *moveUpAction = [SKAction moveToY:positionY duration:10];
    [_edoBg runAction:moveUpAction];
}

-(void)addEdoBackground {
    CGSize screenSize = self.frame.size;
    _edoBg = [SKSpriteNode spriteNodeWithImageNamed:@"edo_bg"];
    CGSize bgSize = _edoBg.size;
    _edoBg.position = CGPointMake(screenSize.width/2, screenSize.height-(bgSize.height/2));
    [self addChild:_edoBg];
}

-(void)addEdoPeople {
    //CGSize screenSize = self.frame.size;
    CGSize bgSize = _edoBg.size;
    NSDictionary *edoPeopleDict = app.peopleDict[@"edo"];
    NSArray *peopleNameArray = [edoPeopleDict allKeys]; // 名前を取得
    for (int i=0; i<peopleNameArray.count; i++) {
        NSString *peopleName = peopleNameArray[i]; // 配列からアトラスの名前を取得
        SKTextureAtlas *atlas = [SKTextureAtlas atlasNamed:peopleName]; // アトラスを取得
        NSMutableArray *textureArray = [NSMutableArray array]; //アニメ用のテクスチャを格納する配列
        for (int j=0; j<atlas.textureNames.count; j++) {
            NSString *textureName = [peopleName stringByAppendingFormat:@"%d", j]; // テクスチャの名前(pngの名前)を指定
            SKTexture *texture = [atlas textureNamed:textureName];
            [textureArray addObject:texture]; // アニメ用のテクスチャ配列に格納
        }

        // キャラクターを配置
        SKSpriteNode *people= [SKSpriteNode spriteNodeWithTexture:textureArray[0]];
        people.name = peopleName;
        //people.xScale = 0.08;
        //people.yScale = 0.08;
        float positionX = (int)(arc4random() % (int)(bgSize.width)) + ((bgSize.width/2)*-1); // 位置を乱数にする
        float positionY = (people.size.height/2 * -1)+(bgSize.height/5);
        //people.position = CGPointMake(positionX, 600);
        people.position = CGPointMake(positionX, positionY);
        [_edoPeopleNodeArray addObject:people];
        [_edoBg addChild:people];
        
        // アニメーションを実行
        SKAction *walkAction = [SKAction animateWithTextures:textureArray timePerFrame:0.4];
        [people runAction:[SKAction repeatActionForever:walkAction]];
    }
}


-(void)movePeopleOnce {
    NSDictionary *edoPeopleDict = app.peopleDict[@"edo"];
    CGSize bgSize = _edoBg.size;
    float leftEdgeX = bgSize.width/2 * -1;
    for (SKSpriteNode *people in _edoPeopleNodeArray) {
        NSString *peopleSpeedRateStr = edoPeopleDict[people.name]; // DictからSpeedRateを文字列型で取得
        float peopleSpeedRate = [peopleSpeedRateStr floatValue]; // SpeedRateを小数に変換
        float peopleSpeed = bgSize.width / peopleSpeedRate; // スクリーンの幅をSpeedRateで割ったものをスピードにする
        float distance = fabs(people.position.x - leftEdgeX);
        float moveDuration = distance / peopleSpeed;
        people.xScale = fabs(people.xScale);
        SKAction *moveLeftAction = [SKAction moveToX:leftEdgeX duration:moveDuration];
        [people runAction:moveLeftAction];
    }
    
}

-(void)movePeopleLoop {
    NSDictionary *edoPeopleDict = app.peopleDict[@"edo"];
    CGSize bgSize = _edoBg.size;
    float rightEdgeX = bgSize.width/2;
    float leftEdgeX = bgSize.width/2 * -1;
    for (SKSpriteNode *people in _edoPeopleNodeArray) {
        NSString *peopleSpeedRateStr = edoPeopleDict[people.name]; // DictからSpeedRateを文字列型で取得
        float peopleSpeedRate = [peopleSpeedRateStr floatValue]; // SpeedRateを小数に変換
        float peopleSpeed = bgSize.width / peopleSpeedRate; // スクリーンの幅をSpeedRateで割ったものをスピードにする
        if (people.position.x == rightEdgeX) {
            float distance = fabs(people.position.x - leftEdgeX);
            float moveDuration = distance / peopleSpeed;
            people.xScale = fabs(people.xScale);
            SKAction *moveLeftAnimation = [SKAction moveToX:leftEdgeX duration:moveDuration];
            [people runAction:moveLeftAnimation];
        }else if (people.position.x == leftEdgeX) {
            float distance = fabs(people.position.x - rightEdgeX);
            float moveDuration = distance / peopleSpeed;
            people.xScale = fabs(people.xScale)*-1;
            SKAction *moveRightAnimation = [SKAction moveToX:rightEdgeX duration:moveDuration];
            [people runAction:moveRightAnimation];
        }

    }

}


//========== For Setting ==========
-(void)keyDown:(NSEvent *)theEvent {
    if (_isSettingMode){
        if (theEvent.keyCode == 123) { // left arrow
            _additionW += 1;
        }else if (theEvent.keyCode == 124) { // right arrow
            _additionW -= 1;
        }else if (theEvent.keyCode == 125) { // down arrow
            _additionH += 1;
        }else if (theEvent.keyCode == 126) { // up arrow
            _additionH -= 1;
        }
        self.view.frame = CGRectMake(self.view.frame.origin.x, self.view.frame.origin.y,
                                 self.view.frame.size.width  - _additionW,
                                 self.view.frame.size.height - _additionH);
    }
}

-(void)keyUp:(NSEvent *)theEvent {
 
    _additionW = 0.0f;
    _additionH = 0.0f;
    if (self.view.frame.size.width<100 || self.view.frame.size.height<100) {
        self.view.frame = CGRectMake(self.view.frame.origin.x, self.view.frame.origin.y,
                                     100.0f, 100.0f);
    }
    if (_isSettingMode) {
        if (theEvent.keyCode == 1) { // 's'キー
            _isSettingMode = false;
        }
    }else {
        _isSettingMode = true;
    }
}
 
 -(void)mouseDragged:(NSEvent *)theEvent {
     if (_isSettingMode) {
         CGPoint mouseLocation = [theEvent locationInWindow];
         NSLog(@"mouseX: %f, mouseY: %f", mouseLocation.x, mouseLocation.y);
         CGFloat viewWidthHalf = self.view.frame.size.width/2;
         CGFloat viewHeightHalf = self.view.frame.size.height/2;
         self.view.frame = CGRectMake(mouseLocation.x-viewWidthHalf, mouseLocation.y-viewHeightHalf,
                                      self.view.frame.size.width, self.view.frame.size.height);
     }
}



@end
