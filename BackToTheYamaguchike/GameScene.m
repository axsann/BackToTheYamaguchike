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
#define BG_MOVE_INTERVAL 35.0f
//#define BG_MOVE_INTERVAL 15.0f // for Debug
#define BG_MOVE_DURATION 5.0f
#define PEOPLE_WAIT_DURATION 1.9f
#define PEOPLE_OFFSET 50.0f
#define CAR_OFFSET 120.0f
#define PEOPLE_WALK_TIME_PER_FRAME 0.4f
#define DOG_ANIMATION_TIME_PER_FRAME 0.8f
#define SOBAYA_ANIMATION_TIME_PER_FRAME 0.2f
#define SHOW_YEAR_DURATION 0.7f
#define HIDE_YEAR_DURATION 0.6f

@implementation GameScene {
    AppDelegate *app;
    BOOL _isSettingMode;
    NSMutableDictionary *_bgNodeDict;
    NSMutableDictionary *_yearNodeDict;
    NSMutableDictionary *_peopleNodeArrayDict;
    NSMutableDictionary *_carNodeArrayDict;
    NSMutableDictionary *_walkActionDict;
    NSMutableDictionary *_doesYearShowDict;
    SKSpriteNode *_dog;
    SKSpriteNode *_sobaya;
    SKAction *_dogAnimation;
    SKAction *_sobayaAnimation;
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
    _carNodeArrayDict = [NSMutableDictionary dictionary];
    _bgNameArray = [NSMutableArray array];
    _nextRunTime = 0.0f;
    _isSettingMode = true;
    _rightEdgeX = BG_ORIGIN_WIDTH/2.0f;
    _leftEdgeX = -(BG_ORIGIN_WIDTH/2.0f);
    
    for (int i=0; i<_eraNameArray.count; i++) {
        [_doesYearShowDict setObject:[NSNumber numberWithBool:YES] forKey:_eraNameArray[i]];
    }
    
    self.backgroundColor = [NSColor blackColor];
    self.view.window.backgroundColor = [NSColor grayColor];
    [self addAllBg];
    [self addYamaguchike];
    [self addDogToEdo];
    [self addAllCar];
    [self addSobayaToShouwa];
    [self addAllPeople];
    [self addAllYear];
    [self addTwoGrayMask];
    [self addThreeBlackZone];
}

-(void)update:(CFTimeInterval)currentTime {
    // Called before each frame is rendered
    [self animateDogOnEdo];
    [self moveAllCar];
    [self moveSobayaOnShouwa];
    [self moveAllPeople];
    [self moveBgInInterval:currentTime];
    [self moveBgToLast];
    [self showHideAllEraYear];
}

-(void)addAllBg {
    _bgNameArray = [NSMutableArray arrayWithArray:_eraNameArray]; // 時代名一覧で初期化
    [_bgNameArray addObject:@"blank"]; // 末尾にblankを追加
    for (int i=0; i<_bgNameArray.count; i++) {
        [self addBgWithEraName:_bgNameArray[i] atIndex:i];
    }
}

-(void)addAllPeople {
    for (NSString *eraName in _eraNameArray) {
        [self addPeopleWithEraName:eraName];
    }
}

-(void)addAllYear {
    _bgNameArray = [NSMutableArray arrayWithArray:_eraNameArray]; // 時代名一覧で初期化
    [_bgNameArray addObject:@"blank"];
    for (int i=0; i<_bgNameArray.count; i++) {
        [self addYearWithEraName:_bgNameArray[i] atIndex:i];
    }
}

-(void)addAllCar {
    [self addCarWithEraName:@"shouwa"];
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

-(void)addCarWithEraName:(NSString *)eraName {
    SKSpriteNode *bg = _bgNodeDict[eraName];
    NSDictionary *carDict = app.carDict[eraName]; // eraNameの時代のDictを読み込む
    NSArray *carNameArray = [carDict allKeys]; // 名前を取得
    NSMutableArray *carNodeArray = [NSMutableArray array];
    for (int i=0; i<carNameArray.count; i++) {
        NSString *carName = carNameArray[i]; // 配列から画像の名前を取得
        // キャラクターを配置
        SKSpriteNode *car = [SKSpriteNode spriteNodeWithImageNamed:carName];
        car.name = carName;
        float positionX = (int)(arc4random() % (BG_ORIGIN_WIDTH)) + (int)(-(BG_ORIGIN_WIDTH/2)); // 位置を乱数にする
        float positionY = -(BG_ORIGIN_HIGHT/14);
        car.position = CGPointMake(positionX, positionY);
        [carNodeArray addObject:car];
        [bg addChild:car];
    }
    [_carNodeArrayDict setObject:carNodeArray forKey:eraName];

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

-(void)moveAllPeople {
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

-(void)moveAllCar {
    [self moveCarWithEraName:@"shouwa"];
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
        [bg addChild:people];
        
        // 歩くアニメーションを作成、辞書に格納
        SKAction *walkAction = [SKAction animateWithTextures:textureArray timePerFrame:PEOPLE_WALK_TIME_PER_FRAME];
        SKAction *walkActionForever = [SKAction repeatActionForever:walkAction];
        [_walkActionDict setObject:walkActionForever forKey:peopleName];
    }
    [_peopleNodeArrayDict setObject:peopleNodeArray forKey:eraName];

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

-(void)addSobayaToShouwa {
    SKSpriteNode *bg = _bgNodeDict[@"shouwa"];
    NSString *sobayaName = @"shouwa_sobaya";
    SKTextureAtlas *atlas = [SKTextureAtlas atlasNamed:sobayaName]; // アトラスを取得
    NSMutableArray *textureArray = [NSMutableArray array]; //アニメ用のテクスチャを格納する配列
    for (int j=0; j<atlas.textureNames.count; j++) {
        NSString *textureName = [sobayaName stringByAppendingFormat:@"%d", j]; // テクスチャの名前(pngの名前)を指定
        SKTexture *texture = [atlas textureNamed:textureName];
        [textureArray addObject:texture]; // アニメ用のテクスチャ配列に格納
    }
    // キャラクターを配置
    _sobaya= [SKSpriteNode spriteNodeWithTexture:textureArray[0]];
    _sobaya.name = sobayaName;
    float positionX = (BG_ORIGIN_WIDTH/3);
    float positionY = -(BG_ORIGIN_HIGHT/7);
    _sobaya.position = CGPointMake(positionX, positionY);
    [bg addChild:_sobaya];
    
    // アニメーションを作成
    SKAction *sobayaAnimationOnce = [SKAction animateWithTextures:textureArray timePerFrame:SOBAYA_ANIMATION_TIME_PER_FRAME];
    _sobayaAnimation = [SKAction repeatActionForever:sobayaAnimationOnce];
    
}

-(void)moveCarWithEraName:(NSString *)eraName {
    SKSpriteNode *bg = _bgNodeDict[eraName];
    NSMutableArray *carNodeArray = _carNodeArrayDict[eraName];
    for (int i=0; i<carNodeArray.count; i++) {
        SKSpriteNode *car = carNodeArray[i];
        float carSpeedRate = [self getCarSpeedRateWithEraName:eraName carName:car.name]; // carの速度を辞書から取得
        // 真ん中に来たら歩く
        if ([self isBgCenter:bg.position.y]) {
            //SKAction *walkAction = _walkActionDict[car.name];
            SKAction *actionWait = [SKAction waitForDuration:PEOPLE_WAIT_DURATION]; // 指定した秒数待つ
            
            if (![car hasActions]) {
                if ([car.name hasSuffix:@"right"]) {
                    SKAction *moveRightAction = [self getMoveRightActionWithNode:car speed:carSpeedRate offset:CAR_OFFSET];
                    SKAction *actionSequence = [SKAction sequence:@[actionWait, moveRightAction]];
                    [car runAction:actionSequence];
                } else {
                    SKAction *moveLeftAction = [self getMoveLeftActionWithNode:car speed:carSpeedRate offset:CAR_OFFSET];
                    SKAction *actionSequence = [SKAction sequence:@[actionWait, moveLeftAction]];
                    [car runAction:actionSequence];
                    
                }
            }
            if ([car.name hasSuffix:@"right"]) {
                
                if (car.position.x >= _rightEdgeX+CAR_OFFSET) {
                    car.position = CGPointMake(_leftEdgeX-CAR_OFFSET-(BG_ORIGIN_WIDTH/2), car.position.y);
                    SKAction *moveRightAction = [self getMoveRightActionWithNode:car speed:carSpeedRate offset:CAR_OFFSET];
                    [car runAction:moveRightAction];
                }
            }else {

                if (car.position.x <= _leftEdgeX-CAR_OFFSET) {
                    car.position = CGPointMake(_rightEdgeX+CAR_OFFSET+(BG_ORIGIN_WIDTH/2), car.position.y);
                    SKAction *moveLeftAction = [self getMoveLeftActionWithNode:car speed:carSpeedRate offset:CAR_OFFSET];
                    [car runAction:moveLeftAction];
                }
            }
            
        }else {
            [car removeAllActions];
        }
        
    }
}

-(void)movePeopleWithEraName:(NSString *)eraName {
    SKSpriteNode *bg = _bgNodeDict[eraName];
    NSMutableArray *peopleNodeArray = _peopleNodeArrayDict[eraName];
    for (SKSpriteNode *people in peopleNodeArray) {
        float peopleSpeedRate = [self getPeopleSpeedRateWithEraName:eraName peopleName:people.name]; // peopleの速度を辞書から取得
        // 真ん中に来たら歩く
        if ([self isBgCenter:bg.position.y]) {
            SKAction *walkAction = _walkActionDict[people.name];
            SKAction *actionWait = [SKAction waitForDuration:PEOPLE_WAIT_DURATION]; // 指定した秒数待つ
            
            if (![people hasActions]) {
                if ([self isPeopleFacingLeft:people]) {
                    SKAction *moveLeftAction = [self getMoveLeftActionWithNode:people speed:peopleSpeedRate offset:PEOPLE_OFFSET];
                    SKAction *actionGroup = [SKAction group:@[walkAction, moveLeftAction]];
                    SKAction *actionSequence = [SKAction sequence:@[actionWait, actionGroup]];
                    [people runAction:actionSequence];
                    
                }else if ([self isPeopleFacingRight:people]) {
                    SKAction *moveRightAction = [self getMoveRightActionWithNode:people speed:peopleSpeedRate offset:PEOPLE_OFFSET];
                    SKAction *actionGroup = [SKAction group:@[walkAction, moveRightAction]];
                    SKAction *actionSequence = [SKAction sequence:@[actionWait, actionGroup]];
                    [people runAction:actionSequence];
                }
            }
            
            // 端を超えたら折り返す
            if (people.position.x >= _rightEdgeX+PEOPLE_OFFSET) {
                SKAction *moveLeftAction = [self getMoveLeftActionWithNode:people speed:peopleSpeedRate offset:PEOPLE_OFFSET];
                [people runAction:moveLeftAction];
            }else if (people.position.x <= _leftEdgeX-PEOPLE_OFFSET) {
                
                SKAction *moveRightAction = [self getMoveRightActionWithNode:people speed:peopleSpeedRate offset:PEOPLE_OFFSET];
                [people runAction:moveRightAction];
            }
        }else {
            [people removeAllActions];
        }

    }
}

-(void)moveSobayaOnShouwa {
    NSString *eraName = @"shouwa";
    SKSpriteNode *bg = _bgNodeDict[eraName];
    float sobayaSpeed = 100;
        // 真ん中に来たら歩く
        if ([self isBgCenter:bg.position.y]) {
            
            SKAction *actionWait = [SKAction waitForDuration:PEOPLE_WAIT_DURATION]; // 指定した秒数待つ
            
            if (![_sobaya hasActions]) {
                    SKAction *moveLeftAction = [self getMoveLeftActionWithNode:_sobaya speed:sobayaSpeed offset:PEOPLE_OFFSET];
                    SKAction *actionGroup = [SKAction group:@[_sobayaAnimation, moveLeftAction]];
                    SKAction *actionSequence = [SKAction sequence:@[actionWait, actionGroup]];
                    [_sobaya runAction:actionSequence];
            }
            if (_sobaya.position.x <= _leftEdgeX-PEOPLE_OFFSET) {
                _sobaya.position = CGPointMake(_rightEdgeX+PEOPLE_OFFSET+(BG_ORIGIN_WIDTH/2), _sobaya.position.y);
                SKAction *moveLeftAction = [self getMoveLeftActionWithNode:_sobaya speed:sobayaSpeed offset:PEOPLE_OFFSET];
                [_sobaya runAction:moveLeftAction];
            }

        }else {
            [_sobaya removeAllActions];
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

-(float)getPeopleSpeedRateWithEraName:(NSString *)eraName peopleName:(NSString *)peopleName {
    NSDictionary *peopleDict = app.peopleDict[eraName];
    NSString *peopleSpeedRateStr = peopleDict[peopleName]; // DictからSpeedRateを文字列型で取得
    float peopleSpeedRate = [peopleSpeedRateStr floatValue]; // SpeedRateを小数に変換
    //float peopleSpeed = BG_ORIGIN_WIDTH / peopleSpeedRate; // 背景の幅をSpeedRateで割ったものをスピードにする
    return peopleSpeedRate;
}

-(float)getCarSpeedRateWithEraName:(NSString *)eraName carName:(NSString *)carName {
    NSDictionary *carDict = app.carDict[eraName];
    NSString *carSpeedRateStr = carDict[carName]; // DictからSpeedRateを文字列型で取得
    float carSpeedRate = [carSpeedRateStr floatValue]; // SpeedRateを小数に変換
    //float carSpeed = BG_ORIGIN_WIDTH / carSpeedRate; // 背景の幅をSpeedRateで割ったものをスピードにする
    return carSpeedRate;
}

-(SKAction *)getMoveLeftActionWithNode:(SKSpriteNode *)node speed:(float)speed offset:(float)offset {
    float distance = fabs(node.position.x - _leftEdgeX-offset);
    float moveDuration = distance / speed;
    node.xScale = fabs(node.xScale);
    SKAction *moveLeftAction = [SKAction moveToX:_leftEdgeX-offset duration:moveDuration];
    return moveLeftAction;
}

-(SKAction *)getMoveRightActionWithNode:(SKSpriteNode *)node speed:(float)speed offset:(float)offset {
    float distance = fabs(node.position.x - _rightEdgeX+offset);
    float moveDuration = distance / speed;
    node.xScale = fabs(node.xScale)*-1;
    SKAction *moveRightAction = [SKAction moveToX:_rightEdgeX+offset duration:moveDuration];
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
