//
//  GameScene.m
//  BackToTheYamaguchike
//
//  Created by kanta on 2015/01/29.
//  Copyright (c) 2015年 kanta. All rights reserved.
//

#import "GameScene.h"
#import "AppDelegate.h"
#define BG_SCALE 0.93f
#define BG_ORIGIN_WIDTH 930
#define BG_ORIGIN_HIGHT 256 // 背景画像の高さはGameScene.sksの高さ(768)の3分の1(256)にする
#define INTERVAL 18.0f

@implementation GameScene {
    AppDelegate *app;
    BOOL _isSettingMode;
    NSMutableArray *_bgNodeArray;
    NSMutableDictionary *_peopleNodeArrayDict;
    float _nextRunTime;
    NSMutableArray *_eraNameArray;
    NSMutableArray *_bgNameArray;
}


-(void)didMoveToView:(SKView *)view {
    // Setup your scene here
    // AppDelegateをインスタンス化
    app = [[NSApplication sharedApplication] delegate];
    _peopleNodeArrayDict = [NSMutableDictionary dictionary];
    _bgNodeArray = [NSMutableArray array];
    _eraNameArray = [NSMutableArray arrayWithArray:@[@"edo", @"meiji", @"shouwa", @"heisei"]];
    _bgNameArray = [NSMutableArray array];
    _nextRunTime = 0.0f;
    _isSettingMode = true;
    self.backgroundColor = [NSColor blackColor];
    self.view.window.backgroundColor = [NSColor grayColor];
    [self addAllEraBg];
    [self addAllEraPeople];
    [self moveAllEraPeopleOnce];
}

-(void)update:(CFTimeInterval)currentTime {
    // Called before each frame is rendered
    [self moveAllEraPeopleLoop];
    [self moveBgIn30secInterval:currentTime];
    [self moveBgToLast];
}

-(void)addAllEraBg {
    _bgNameArray = [NSMutableArray arrayWithArray:_eraNameArray]; // 時代名一覧で初期化
    [_bgNameArray addObject:@"blank"]; // 末尾にblankを追加
    for (int i=0; i<_bgNameArray.count; i++) {
        [self addBgWithEraName:_bgNameArray[i] atIndex:i];
    }
}

-(void)addAllEraPeople {
    for (NSString *eraName in _eraNameArray) {
        [self addPeopleWithEraName:eraName];
    }
}

-(void)moveAllEraPeopleOnce {
    for (NSString *eraName in _eraNameArray) {
        [self movePeopleOnceWithEraName:eraName];
    }
}

-(void)moveAllEraPeopleLoop {
    for (NSString *eraName in _eraNameArray) {
        [self movePeopleLoopWithEraName:eraName];
    }
}

-(void)moveBgIn30secInterval:(CFTimeInterval)currentTime {
    float interval = INTERVAL;
    if (_nextRunTime==0.0f) {
        _nextRunTime = currentTime+interval;
    }
    if (currentTime>=_nextRunTime) {
        [self moveBg];
        _nextRunTime = currentTime+interval;
    }
}

-(void)moveBg {
    CGSize screenSize = self.frame.size;
    float distanceY = screenSize.height/3;
    for (SKSpriteNode *bg in _bgNodeArray) {
        SKAction *moveUpAction = [SKAction moveByX:0 y:distanceY duration:10];
        [bg runAction:moveUpAction];
    }
}

-(void)moveBgToLast {
    CGSize screenSize = self.frame.size;
    NSUInteger bgLastIndex = _bgNameArray.count-1;
    float positionY = screenSize.height-(BG_ORIGIN_HIGHT*bgLastIndex)-(BG_ORIGIN_HIGHT/2);
    for (SKSpriteNode *bg in _bgNodeArray) {
        if (bg.position.y >= screenSize.height+(screenSize.height/3)/2) {
            bg.position = CGPointMake(bg.position.x, positionY);
        }
    }
}

-(void)addBgWithEraName:(NSString *)eraName atIndex:(NSInteger)index {
    CGSize screenSize = self.frame.size;
    NSString *bgName = [eraName stringByAppendingString:@"_bg"];
    SKSpriteNode *bg = [SKSpriteNode spriteNodeWithImageNamed:bgName];
    bg.position = CGPointMake(screenSize.width/2, screenSize.height-(BG_ORIGIN_HIGHT*index)-(BG_ORIGIN_HIGHT/2));
    bg.name = bgName;
    bg.xScale = BG_SCALE;
    bg.yScale = BG_SCALE;
    [_bgNodeArray addObject:bg];
    [self addChild:bg];
}

-(SKSpriteNode *)getBgWithEraName:(NSString *)eraName {
    NSString *bgName = [eraName stringByAppendingString:@"_bg"];
    for (SKSpriteNode *bg in _bgNodeArray) {
        if ([bg.name isEqualToString:bgName]) {
            return bg;
        }
    }
    return nil;
}

 
-(void)addPeopleWithEraName:(NSString *)eraName {
    SKSpriteNode *bg = [self getBgWithEraName:eraName];
    NSDictionary *peopleDict = app.peopleDict[eraName]; // eraNameの時代のDictを読み込む
    NSArray *peopleNameArray = [peopleDict allKeys]; // 名前を取得
    NSMutableArray *peopleNodeArray = [NSMutableArray array];
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
        float positionX = (int)(arc4random() % (BG_ORIGIN_WIDTH)) + (int)(-(BG_ORIGIN_WIDTH/2)); // 位置を乱数にする
        float positionY = (people.size.height/2 * -1)+(BG_ORIGIN_HIGHT/5);
        people.position = CGPointMake(positionX, positionY);
        [peopleNodeArray addObject:people];
        [_peopleNodeArrayDict setObject:peopleNodeArray forKey:eraName];
        [bg addChild:people];
        
        // アニメーションを実行
        SKAction *walkAction = [SKAction animateWithTextures:textureArray timePerFrame:0.4];
        [people runAction:[SKAction repeatActionForever:walkAction]];
    }
}


-(void)movePeopleOnceWithEraName:(NSString *)eraName {
    NSDictionary *edoPeopleDict = app.peopleDict[eraName];
    NSMutableArray *peopleNodeArray = _peopleNodeArrayDict[eraName];
    float leftEdgeX = -(BG_ORIGIN_WIDTH/2.0f);
    for (SKSpriteNode *people in peopleNodeArray) {
        NSString *peopleSpeedRateStr = edoPeopleDict[people.name]; // DictからSpeedRateを文字列型で取得
        float peopleSpeedRate = [peopleSpeedRateStr floatValue]; // SpeedRateを小数に変換
        float peopleSpeed = BG_ORIGIN_WIDTH / peopleSpeedRate; // 背景の幅をSpeedRateで割ったものをスピードにする
        float distance = fabs(people.position.x - leftEdgeX);
        float moveDuration = distance / peopleSpeed;
        people.xScale = fabs(people.xScale);
        SKAction *moveLeftAction = [SKAction moveToX:leftEdgeX duration:moveDuration];
        [people runAction:moveLeftAction];
    }
    
}

-(void)movePeopleLoopWithEraName:(NSString *)eraName {
    NSDictionary *edoPeopleDict = app.peopleDict[eraName];
    NSMutableArray *peopleNodeArray = _peopleNodeArrayDict[eraName];
    float rightEdgeX = BG_ORIGIN_WIDTH/2.0f;
    float leftEdgeX = -(BG_ORIGIN_WIDTH/2.0f);
    for (SKSpriteNode *people in peopleNodeArray) {
        NSString *peopleSpeedRateStr = edoPeopleDict[people.name]; // DictからSpeedRateを文字列型で取得
        float peopleSpeedRate = [peopleSpeedRateStr floatValue]; // SpeedRateを小数に変換
        float peopleSpeed = BG_ORIGIN_WIDTH / peopleSpeedRate; // 背景の幅をSpeedRateで割ったものをスピードにする
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

@end
