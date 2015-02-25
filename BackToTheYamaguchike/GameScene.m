//
//  GameScene.m
//  BackToTheYamaguchike
//
//  Created by kanta on 2015/01/29.
//  Copyright (c) 2015年 kanta. All rights reserved.
//

#import "GameScene.h"
#import "AppDelegate.h"
#define BG_SCALE 0.97f
#define BG_ORIGIN_WIDTH 991
#define BG_ORIGIN_HIGHT 256 // 背景画像の高さはGameScene.sksの高さ(768)の3分の1(256)にする
//#define BG_MOVE_INTERVAL 35.0f
#define BG_MOVE_INTERVAL 15.0f // for Debug
#define BG_MOVE_DURATION 5.0f
#define PEOPLE_WAIT_DURATION 1.9f
#define PEOPLE_OFFSET 50.0f
#define PEOPLE_WALK_TIME_PER_FRAME 0.4f
#define DOG_ANIMATION_TIME_PER_FRAME 0.8f
#define SHOW_YEAR_DURATION 0.7f
#define HIDE_YEAR_DURATION 0.4f

@implementation GameScene {
    AppDelegate *app;
    BOOL _isSettingMode;
    NSMutableDictionary *_bgNodeDict;
    NSMutableDictionary *_yearNodeDict;
    NSMutableDictionary *_peopleNodeArrayDict;
    NSMutableDictionary *_walkActionDict;
    NSMutableDictionary *_doesYearShowDict;
    SKSpriteNode *_dog;
    SKAction *_dogAnimation;
    float _nextRunTime;
    float _leftEdgeX;
    float _rightEdgeX;
    NSMutableArray *_eraNameArray;
    NSMutableArray *_bgNameArray;
}


-(void)didMoveToView:(SKView *)view {
    // Setup your scene here
    // AppDelegateをインスタンス化
    app = [[NSApplication sharedApplication] delegate];
    _peopleNodeArrayDict = [NSMutableDictionary dictionary];
    _bgNodeDict = [NSMutableDictionary dictionary];
    _yearNodeDict = [NSMutableDictionary dictionary];
    _walkActionDict = [NSMutableDictionary dictionary];
    _eraNameArray = [NSMutableArray arrayWithArray:@[@"edo", @"meiji", @"shouwa", @"heisei"]];
    _doesYearShowDict = [NSMutableDictionary dictionary];
    _bgNameArray = [NSMutableArray array];
    _nextRunTime = 0.0f;
    _isSettingMode = true;
    _rightEdgeX = BG_ORIGIN_WIDTH/2.0f+PEOPLE_OFFSET;
    _leftEdgeX = -(BG_ORIGIN_WIDTH/2.0f)-PEOPLE_OFFSET;
    
    for (int i=0; i<_eraNameArray.count; i++) {
        [_doesYearShowDict setObject:[NSNumber numberWithBool:YES] forKey:_eraNameArray[i]];
    }
    
    self.backgroundColor = [NSColor blackColor];
    self.view.window.backgroundColor = [NSColor grayColor];
    [self addAllEraBg];
    [self addYamaguchike];
    [self addDogToEdo];
    [self addAllEraPeople];
    [self addAllEraYear];
    [self addTwoGrayMask];
    [self addThreeBlackZone];
}

-(void)update:(CFTimeInterval)currentTime {
    // Called before each frame is rendered
    [self animateDogOnEdo];
    [self moveAllEraPeople];
    [self moveBgInInterval:currentTime];
    [self moveBgToLast];
    [self showHideAllEraYear];
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

-(void)addAllEraYear {
    _bgNameArray = [NSMutableArray arrayWithArray:_eraNameArray]; // 時代名一覧で初期化
    [_bgNameArray addObject:@"blank"];
    for (int i=0; i<_bgNameArray.count; i++) {
        [self addYearWithEraName:_bgNameArray[i] atIndex:i];
    }
}

-(void)addYearWithEraName:eraName atIndex:(NSInteger)index {
    SKSpriteNode *bg = _bgNodeDict[eraName];
    NSString *yearName = [eraName stringByAppendingString:@"_year"];
    SKSpriteNode *year = [SKSpriteNode spriteNodeWithImageNamed:yearName];
    year.position = CGPointMake(0, 0);
    year.name = yearName;
    year.alpha = 0.0f;
    [_yearNodeDict setObject:year forKey:eraName];
    [bg addChild:year];
}

-(void)addYamaguchike {
    CGSize screenSize = self.frame.size;
    NSString *yamaguchikeStr = @"yamaguchike";
    SKSpriteNode *yamaguchikeNode = [SKSpriteNode spriteNodeWithImageNamed:yamaguchikeStr];
    yamaguchikeNode.position = CGPointMake(screenSize.width/2, screenSize.height-(BG_ORIGIN_HIGHT*1)-(BG_ORIGIN_HIGHT/2));
    yamaguchikeNode.name = yamaguchikeStr;
    yamaguchikeNode.xScale = BG_SCALE;
    yamaguchikeNode.yScale = BG_SCALE;
    [self addChild:yamaguchikeNode];
}

-(void)addTwoGrayMask {
    NSArray *indexArray = @[@0, @2];
    for (NSNumber *index in indexArray) {
        [self addGrayMask:index.intValue];
    }
}

-(void)addThreeBlackZone {
    for (int i=0; i<3; i++) {
        [self addBlackZone:i];
    }
}


-(void)addGrayMask:(NSInteger)index {
    CGSize screenSize = self.frame.size;
    NSString *grayMaskStr = @"gray_mask";
    NSString *grayMaskNodeName = [NSString stringWithFormat:@"%@%ld", grayMaskStr, (long)index];
    SKSpriteNode *grayMaskNode = [SKSpriteNode spriteNodeWithImageNamed:grayMaskStr];
    grayMaskNode.position = CGPointMake(screenSize.width/2, screenSize.height-(BG_ORIGIN_HIGHT*index)-(BG_ORIGIN_HIGHT/2));
    grayMaskNode.name = grayMaskNodeName;
    [self addChild:grayMaskNode];
}

-(void)addBlackZone:(NSInteger)index {
    CGSize screenSize = self.frame.size;
    NSString *blackZoneStr = @"black_zone";
    NSString *blackZoneNodeName = [NSString stringWithFormat:@"%@%ld", blackZoneStr, (long)index];
    SKSpriteNode *blackZoneNode = [SKSpriteNode spriteNodeWithImageNamed:blackZoneStr];
    blackZoneNode.position = CGPointMake(screenSize.width/2, screenSize.height-(BG_ORIGIN_HIGHT*index)-(BG_ORIGIN_HIGHT/2));
    blackZoneNode.name = blackZoneNodeName;
    blackZoneNode.xScale = BG_SCALE;
    blackZoneNode.yScale = BG_SCALE;
    [self addChild:blackZoneNode];
}

-(void)moveAllEraPeople {
    for (NSString *eraName in _eraNameArray) {
        [self movePeopleWithEraName:eraName];
    }
}

-(void)showHideAllEraYear {
    for (NSString *eraName in _eraNameArray) {
        [self showHideYearWithEraName:eraName];
    }
}

-(void)moveBgInInterval:(CFTimeInterval)currentTime {
    float interval = BG_MOVE_INTERVAL;
    if (_nextRunTime==0.0f) {
        _nextRunTime = currentTime+interval;
    }
    if (currentTime>=_nextRunTime) {
        [self moveBg];
        _nextRunTime = currentTime+interval;
    }
}

-(void)moveBg {
    for (id key in [_bgNodeDict keyEnumerator]) {
        SKSpriteNode *bg = _bgNodeDict[key];
        float positionY = bg.position.y+BG_ORIGIN_HIGHT;
        SKAction *moveUpAction = [SKAction moveToY:positionY duration:BG_MOVE_DURATION];
        [bg runAction:moveUpAction];
    }
}

-(void)moveBgToLast {
    CGSize screenSize = self.frame.size;
    NSUInteger bgLastIndex = _bgNameArray.count-1;
    float positionY = screenSize.height-(BG_ORIGIN_HIGHT*bgLastIndex)-(BG_ORIGIN_HIGHT/2);
    for (id key in [_bgNodeDict keyEnumerator]) {
        SKSpriteNode *bg = _bgNodeDict[key];
        if (bg.position.y >= screenSize.height+(screenSize.height/3)/2) {
            [bg removeAllActions];
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
    [_bgNodeDict setObject:bg forKey:eraName];
    [self addChild:bg];
}

 
-(void)addPeopleWithEraName:(NSString *)eraName {
    SKSpriteNode *bg = _bgNodeDict[eraName];
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
        
        // 歩くアニメーションを作成、辞書に格納
        SKAction *walkAction = [SKAction animateWithTextures:textureArray timePerFrame:PEOPLE_WALK_TIME_PER_FRAME];
        SKAction *walkActionForever = [SKAction repeatActionForever:walkAction];
        [_walkActionDict setObject:walkActionForever forKey:peopleName];
    }
}

-(void)addDogToEdo {
    SKSpriteNode *bg = _bgNodeDict[@"edo"];
    NSString *dogName = @"edo_dog";
    SKTextureAtlas *atlas = [SKTextureAtlas atlasNamed:dogName]; // アトラスを取得
    NSMutableArray *textureArray = [NSMutableArray array]; //アニメ用のテクスチャを格納する配列
    for (int j=0; j<atlas.textureNames.count; j++) {
        NSString *textureName = [dogName stringByAppendingFormat:@"%d", j]; // テクスチャの名前(pngの名前)を指定
        SKTexture *texture = [atlas textureNamed:textureName];
        [textureArray addObject:texture]; // アニメ用のテクスチャ配列に格納
    }
    // キャラクターを配置
    _dog= [SKSpriteNode spriteNodeWithTexture:textureArray[0]];
    _dog.name = dogName;
    float positionX = -(BG_ORIGIN_WIDTH/3);
    float positionY = -(BG_ORIGIN_HIGHT/7);
    _dog.position = CGPointMake(positionX, positionY);
    [bg addChild:_dog];
    
    // アニメーションを作成
    SKAction *dogAnimationOnce = [SKAction animateWithTextures:textureArray timePerFrame:DOG_ANIMATION_TIME_PER_FRAME];
    _dogAnimation = [SKAction repeatActionForever:dogAnimationOnce];

}

-(void)movePeopleWithEraName:(NSString *)eraName {
    SKSpriteNode *bg = _bgNodeDict[eraName];
    NSMutableArray *peopleNodeArray = _peopleNodeArrayDict[eraName];
    for (SKSpriteNode *people in peopleNodeArray) {
        float peopleSpeed = [self getPeopleSpeedWithEraName:eraName peopleName:people.name]; // peopleの速度を辞書から取得
        // 真ん中に来たら歩く
        if ([self isBgCenter:bg.position.y]) {
            SKAction *walkAction = _walkActionDict[people.name];
            SKAction *actionWait = [SKAction waitForDuration:PEOPLE_WAIT_DURATION]; // 指定した秒数待つ
            
            if (![people hasActions]) {
                if ([self isPeopleFacingLeft:people]) {
                    SKAction *moveLeftAction = [self getMovePeopleLeftAction:people speed:peopleSpeed];
                    SKAction *actionGroup = [SKAction group:@[walkAction, moveLeftAction]];
                    SKAction *actionSequence = [SKAction sequence:@[actionWait, actionGroup]];
                    [people runAction:actionSequence];
                    
                }else if ([self isPeopleFacingRight:people]) {
                    SKAction *moveRightAction = [self getMovePeopleRightAction:people speed:peopleSpeed];
                    SKAction *actionGroup = [SKAction group:@[walkAction, moveRightAction]];
                    SKAction *actionSequence = [SKAction sequence:@[actionWait, actionGroup]];
                    [people runAction:actionSequence];
                }
            }
            
            // 端を超えたら折り返す
            if (people.position.x >= _rightEdgeX) {
                SKAction *moveLeftAction = [self getMovePeopleLeftAction:people speed:peopleSpeed];
                [people runAction:moveLeftAction];
            }else if (people.position.x <= _leftEdgeX) {
                
                SKAction *moveRightAction = [self getMovePeopleRightAction:people speed:peopleSpeed];
                [people runAction:moveRightAction];
            }
        }else {
            [people removeAllActions];
        }

    }
}

-(void)animateDogOnEdo {
    SKSpriteNode *bg = _bgNodeDict[@"edo"];
    if ([self isBgCenter:bg.position.y]) {
        if (![_dog hasActions]) {
            [_dog runAction:_dogAnimation];
        }
    }else {
            [_dog removeAllActions];
    }
}

-(void)showHideYearWithEraName:(NSString *)eraName {
    SKSpriteNode *bg = _bgNodeDict[eraName];
    SKSpriteNode *year = _yearNodeDict[eraName];
    NSNumber *doesYearShowNumber = _doesYearShowDict[eraName];
    BOOL doesYearShow = [doesYearShowNumber boolValue];
    
    if ([self isBgCenter:bg.position.y]) {
        if (doesYearShow) {
            SKAction *fadeInAction = [SKAction fadeAlphaTo:1.0f duration:SHOW_YEAR_DURATION];
            SKAction *fadeOutAction = [SKAction fadeAlphaTo:0.0f duration:HIDE_YEAR_DURATION];
            SKAction *fadeActionSequence = [SKAction sequence:@[fadeInAction, fadeOutAction]];
            [year runAction:fadeActionSequence completion:^(void){
                [_doesYearShowDict setObject:[NSNumber numberWithBool:NO] forKey:eraName];
            }];
        }
    }else {
        year.alpha = 0.0f;
        [_doesYearShowDict setObject:[NSNumber numberWithBool:YES] forKey:eraName];
        [year removeAllActions];
    }
}

-(float)getPeopleSpeedWithEraName:(NSString *)eraName peopleName:(NSString *)peopleName {
    NSDictionary *peopleDict = app.peopleDict[eraName];
    NSString *peopleSpeedRateStr = peopleDict[peopleName]; // DictからSpeedRateを文字列型で取得
    float peopleSpeedRate = [peopleSpeedRateStr floatValue]; // SpeedRateを小数に変換
    float peopleSpeed = BG_ORIGIN_WIDTH / peopleSpeedRate; // 背景の幅をSpeedRateで割ったものをスピードにする
    return peopleSpeed;
}

-(SKAction *)getMovePeopleLeftAction:(SKSpriteNode *)people speed:(float)speed {
    float distance = fabs(people.position.x - _leftEdgeX);
    float moveDuration = distance / speed;
    people.xScale = fabs(people.xScale);
    SKAction *moveLeftAction = [SKAction moveToX:_leftEdgeX duration:moveDuration];
    return moveLeftAction;
}

-(SKAction *)getMovePeopleRightAction:(SKSpriteNode *)people speed:(float)speed {
    float distance = fabs(people.position.x - _rightEdgeX);
    float moveDuration = distance / speed;
    people.xScale = fabs(people.xScale)*-1;
    SKAction *moveRightAction = [SKAction moveToX:_rightEdgeX duration:moveDuration];
    return moveRightAction;
}

-(BOOL)isBgCenter:(float)bgPositionY {
    CGSize screenSize = self.frame.size;
    return bgPositionY==screenSize.height-(BG_ORIGIN_HIGHT*1)-(BG_ORIGIN_HIGHT/2);
}

-(BOOL)isPeopleFacingLeft:(SKSpriteNode *)people {
    return people.xScale>0;
}

-(BOOL)isPeopleFacingRight:(SKSpriteNode *)people {
    return people.xScale<0;
}

@end
