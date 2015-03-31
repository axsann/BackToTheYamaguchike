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
#define BG_MOVE_INTERVAL 25.0f
//#define BG_MOVE_INTERVAL 15.0f // for Debug
#define BG_MOVE_DURATION 5.0f
#define PEOPLE_WAIT_DURATION 1.9f
#define PEOPLE_OFFSET 50.0f
#define CAR_OFFSET 120.0f
#define PEOPLE_WALK_TIME_PER_FRAME 0.4f
#define TACHIBANASHI_R_ANIMATION_TIME_PER_FRAME 0.8f
#define TACHIBANASHI_L_ANIMATION_TIME_PER_FRAME 1.2f
#define BIKE_ANIMATION_TIME_PER_FRAME 0.2f
#define BIKE_SPEED_RATE 3.6f
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
    SKSpriteNode *_edoDogTono;
    SKSpriteNode *_edoTachibanashi;
    SKSpriteNode *_edoHikyakuOkami;
    SKSpriteNode *_edoShounin;
    SKSpriteNode *_meijiJinriki;
    SKSpriteNode *_meijiHitodakari;
    SKSpriteNode *_meijiTachibanashi;
    SKSpriteNode *_shouwaSobaya;
    SKSpriteNode *_heiseiGentsuki;
    SKAction *_edoDogTonoAnimation;
    SKAction *_edoTachibanashiAnimation;
    SKAction *_edoHikyakuOkamiAnimation;
    SKAction *_edoShouninAnimation;
    SKAction *_meijiJinrikiAnimation;
    SKAction *_meijiHitodakariAnimation;
    SKAction *_meijiTachibanashiAnimation;
    SKAction *_shouwaSobayaAnimation;
    float _nextRunTime;
    float _leftEdgeX;
    float _rightEdgeX;
    float _standardSpeed;
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
    _standardSpeed = BG_ORIGIN_WIDTH/30.0f;
    
    for (int i=0; i<_eraNameArray.count; i++) {
        [_doesYearShowDict setObject:[NSNumber numberWithBool:YES] forKey:_eraNameArray[i]];
    }
    
    self.backgroundColor = [NSColor blackColor];
    self.view.window.backgroundColor = [NSColor grayColor];
    [self addAllBg];
    [self addYamaguchike];
    [self addDogTonoToEdo];
    [self addHikyakuOkamiToEdo];
    [self addTachibanashiToEdo];
    [self addShouninToEdo];
    [self addHitodakariToMeiji];
    [self addTachibanashiToMeiji];
    [self addAllCar];
    [self addJinrikiToMeiji];
    [self addSobayaToShouwa];
    [self addGentsukiToHeisei];
    [self addAllPeople];
    [self addAllYear];
    [self addTwoGrayMask];
    [self addThreeBlackZone];
}

-(void)update:(CFTimeInterval)currentTime {
    // Called before each frame is rendered
    [self animateDogTonoOnEdo];
    [self animateTachibanashiOnEdo];
    [self animateHikyakuOkamiOnEdo];
    [self animateShouninOnEdo];
    [self animateHitodakariOnMeiji];
    [self animateTachibanashiOnMeiji];
    [self moveAllCar];
    [self moveJinrikiOnMeiji];
    [self moveSobayaOnShouwa];
    [self moveGentsukiOnHeisei];
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
    [self addCarWithEraName:@"heisei"];
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
    [self moveCarWithEraName:@"heisei"];
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

-(void)addDogTonoToEdo {
    SKSpriteNode *bg = _bgNodeDict[@"edo"];
    NSString *dogTonoName = @"edo_dog_tono";
    SKTextureAtlas *atlas = [SKTextureAtlas atlasNamed:dogTonoName]; // アトラスを取得
    NSMutableArray *textureArray = [NSMutableArray array]; //アニメ用のテクスチャを格納する配列
    for (int j=0; j<atlas.textureNames.count; j++) {
        NSString *textureName = [dogTonoName stringByAppendingFormat:@"%d", j]; // テクスチャの名前(pngの名前)を指定
        SKTexture *texture = [atlas textureNamed:textureName];
        [textureArray addObject:texture]; // アニメ用のテクスチャ配列に格納
    }
    // キャラクターを配置
    _edoDogTono= [SKSpriteNode spriteNodeWithTexture:textureArray[0]];
    _edoDogTono.name = dogTonoName;
    float positionX = -(BG_ORIGIN_WIDTH/2.3);
    float positionY = -(BG_ORIGIN_HIGHT/50);
    _edoDogTono.position = CGPointMake(positionX, positionY);
    [bg addChild:_edoDogTono];
    
    // アニメーションを作成
    SKAction *dogTonoAnimationOnce = [SKAction animateWithTextures:textureArray timePerFrame:TACHIBANASHI_R_ANIMATION_TIME_PER_FRAME];
    _edoDogTonoAnimation = [SKAction repeatActionForever:dogTonoAnimationOnce];
    
}

-(void)addTachibanashiToEdo {
    SKSpriteNode *bg = _bgNodeDict[@"edo"];
    NSString *tachibanashiName = @"edo_tachibanashi";
    SKTextureAtlas *atlas = [SKTextureAtlas atlasNamed:tachibanashiName]; // アトラスを取得
    NSMutableArray *textureArray = [NSMutableArray array]; //アニメ用のテクスチャを格納する配列
    for (int j=0; j<atlas.textureNames.count; j++) {
        NSString *textureName = [tachibanashiName stringByAppendingFormat:@"%d", j]; // テクスチャの名前(pngの名前)を指定
        SKTexture *texture = [atlas textureNamed:textureName];
        [textureArray addObject:texture]; // アニメ用のテクスチャ配列に格納
    }
    // キャラクターを配置
    _edoTachibanashi= [SKSpriteNode spriteNodeWithTexture:textureArray[0]];
    _edoTachibanashi.name = tachibanashiName;
    float positionX = (BG_ORIGIN_WIDTH/3);
    float positionY = -(BG_ORIGIN_HIGHT/11);
    _edoTachibanashi.position = CGPointMake(positionX, positionY);
    [bg addChild:_edoTachibanashi];
    
    // アニメーションを作成
    SKAction *tachibanashiAnimationOnce = [SKAction animateWithTextures:textureArray timePerFrame:TACHIBANASHI_L_ANIMATION_TIME_PER_FRAME];
    _edoTachibanashiAnimation = [SKAction repeatActionForever:tachibanashiAnimationOnce];
    
}

-(void)addShouninToEdo {
    SKSpriteNode *bg = _bgNodeDict[@"edo"];
    NSString *shouninName = @"edo_shounin";
    SKTextureAtlas *atlas = [SKTextureAtlas atlasNamed:shouninName]; // アトラスを取得
    NSMutableArray *textureArray = [NSMutableArray array]; //アニメ用のテクスチャを格納する配列
    for (int j=0; j<atlas.textureNames.count; j++) {
        NSString *textureName = [shouninName stringByAppendingFormat:@"%d", j]; // テクスチャの名前(pngの名前)を指定
        SKTexture *texture = [atlas textureNamed:textureName];
        [textureArray addObject:texture]; // アニメ用のテクスチャ配列に格納
    }
    // キャラクターを配置
    _edoShounin = [SKSpriteNode spriteNodeWithTexture:textureArray[0]];
    _edoShounin.name = shouninName;
    float positionX = -(BG_ORIGIN_WIDTH/3.2f);
    float positionY = -(BG_ORIGIN_HIGHT/11);
    _edoShounin.position = CGPointMake(positionX, positionY);
    [bg addChild:_edoShounin];
    
    // アニメーションを作成
    SKAction *shouninAnimationOnce = [SKAction animateWithTextures:textureArray timePerFrame:TACHIBANASHI_L_ANIMATION_TIME_PER_FRAME];
    _edoShouninAnimation = [SKAction repeatActionForever:shouninAnimationOnce];
    
}

-(void)addTachibanashiToMeiji {
    SKSpriteNode *bg = _bgNodeDict[@"meiji"];
    NSString *tachibanashiName = @"meiji_tachibanashi";
    SKTextureAtlas *atlas = [SKTextureAtlas atlasNamed:tachibanashiName]; // アトラスを取得
    NSMutableArray *textureArray = [NSMutableArray array]; //アニメ用のテクスチャを格納する配列
    for (int j=0; j<atlas.textureNames.count; j++) {
        NSString *textureName = [tachibanashiName stringByAppendingFormat:@"%d", j]; // テクスチャの名前(pngの名前)を指定
        SKTexture *texture = [atlas textureNamed:textureName];
        [textureArray addObject:texture]; // アニメ用のテクスチャ配列に格納
    }
    // キャラクターを配置
    _meijiTachibanashi = [SKSpriteNode spriteNodeWithTexture:textureArray[0]];
    _meijiTachibanashi.name = tachibanashiName;
    float positionX = -(BG_ORIGIN_WIDTH/3.5);
    float positionY = -(BG_ORIGIN_HIGHT/11);
    _meijiTachibanashi.position = CGPointMake(positionX, positionY);
    [bg addChild:_meijiTachibanashi];
    
    // アニメーションを作成
    SKAction *tachibanashiAnimationOnce = [SKAction animateWithTextures:textureArray timePerFrame:TACHIBANASHI_R_ANIMATION_TIME_PER_FRAME];
    _meijiTachibanashiAnimation = [SKAction repeatActionForever:tachibanashiAnimationOnce];
    
}

-(void)addHitodakariToMeiji {
    SKSpriteNode *bg = _bgNodeDict[@"meiji"];
    NSString *hitodakariName = @"meiji_hitodakari";
    SKTextureAtlas *atlas = [SKTextureAtlas atlasNamed:hitodakariName]; // アトラスを取得
    NSMutableArray *textureArray = [NSMutableArray array]; //アニメ用のテクスチャを格納する配列
    for (int j=0; j<atlas.textureNames.count; j++) {
        NSString *textureName = [hitodakariName stringByAppendingFormat:@"%d", j]; // テクスチャの名前(pngの名前)を指定
        SKTexture *texture = [atlas textureNamed:textureName];
        [textureArray addObject:texture]; // アニメ用のテクスチャ配列に格納
    }
    // キャラクターを配置
    _meijiHitodakari= [SKSpriteNode spriteNodeWithTexture:textureArray[0]];
    _meijiHitodakari.name = hitodakariName;
    float positionX = (BG_ORIGIN_WIDTH/2.5f);
    float positionY = -(BG_ORIGIN_HIGHT/11);
    _meijiHitodakari.position = CGPointMake(positionX, positionY);
    [bg addChild:_meijiHitodakari];
    
    // アニメーションを作成
    SKAction *hitodakariAnimationOnce = [SKAction animateWithTextures:textureArray timePerFrame:TACHIBANASHI_L_ANIMATION_TIME_PER_FRAME];
    _meijiHitodakariAnimation = [SKAction repeatActionForever:hitodakariAnimationOnce];
    
}

-(void)addHikyakuOkamiToEdo {
    SKSpriteNode *bg = _bgNodeDict[@"edo"];
    NSString *hikyakuOkamiName = @"edo_hikyaku_okami";
    SKTextureAtlas *atlas = [SKTextureAtlas atlasNamed:hikyakuOkamiName]; // アトラスを取得
    NSMutableArray *textureArray = [NSMutableArray array]; //アニメ用のテクスチャを格納する配列
    for (int j=0; j<atlas.textureNames.count; j++) {
        NSString *textureName = [hikyakuOkamiName stringByAppendingFormat:@"%d", j]; // テクスチャの名前(pngの名前)を指定
        SKTexture *texture = [atlas textureNamed:textureName];
        [textureArray addObject:texture]; // アニメ用のテクスチャ配列に格納
    }
    // キャラクターを配置
    _edoHikyakuOkami= [SKSpriteNode spriteNodeWithTexture:textureArray[0]];
    _edoHikyakuOkami.name = hikyakuOkamiName;
    float positionX = -(BG_ORIGIN_WIDTH/5);
    float positionY = -(BG_ORIGIN_HIGHT/10);
    _edoHikyakuOkami.position = CGPointMake(positionX, positionY);
    [bg addChild:_edoHikyakuOkami];
    
    // アニメーションを作成
    SKAction *hikyakuOkamiAnimationOnce = [SKAction animateWithTextures:textureArray timePerFrame:TACHIBANASHI_R_ANIMATION_TIME_PER_FRAME];
    _edoHikyakuOkamiAnimation = [SKAction repeatActionForever:hikyakuOkamiAnimationOnce];
    
}
-(void)addJinrikiToMeiji {
    SKSpriteNode *bg = _bgNodeDict[@"meiji"];
    NSString *jinrikiName = @"meiji_jinriki";
    SKTextureAtlas *atlas = [SKTextureAtlas atlasNamed:jinrikiName]; // アトラスを取得
    NSMutableArray *textureArray = [NSMutableArray array]; //アニメ用のテクスチャを格納する配列
    for (int j=0; j<atlas.textureNames.count; j++) {
        NSString *textureName = [jinrikiName stringByAppendingFormat:@"%d", j]; // テクスチャの名前(pngの名前)を指定
        SKTexture *texture = [atlas textureNamed:textureName];
        [textureArray addObject:texture]; // アニメ用のテクスチャ配列に格納
    }
    // キャラクターを配置
    _meijiJinriki = [SKSpriteNode spriteNodeWithTexture:textureArray[0]];
    _meijiJinriki.name = jinrikiName;
    float positionX = (int)(arc4random() % (BG_ORIGIN_WIDTH)) + (int)(-(BG_ORIGIN_WIDTH/2)); // 位置を乱数にする
    float positionY = -(BG_ORIGIN_HIGHT/10);
    _meijiJinriki.position = CGPointMake(positionX, positionY);
    [bg addChild:_meijiJinriki];
    
    // アニメーションを作成
    SKAction *jinrikiAnimationOnce = [SKAction animateWithTextures:textureArray timePerFrame:BIKE_ANIMATION_TIME_PER_FRAME];
    _meijiJinrikiAnimation = [SKAction repeatActionForever:jinrikiAnimationOnce];
    
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
    _shouwaSobaya= [SKSpriteNode spriteNodeWithTexture:textureArray[0]];
    _shouwaSobaya.name = sobayaName;
    float positionX = (int)(arc4random() % (BG_ORIGIN_WIDTH)) + (int)(-(BG_ORIGIN_WIDTH/2)); // 位置を乱数にする
    float positionY = -(BG_ORIGIN_HIGHT/7);
    _shouwaSobaya.position = CGPointMake(positionX, positionY);
    [bg addChild:_shouwaSobaya];
    
    // アニメーションを作成
    SKAction *sobayaAnimationOnce = [SKAction animateWithTextures:textureArray timePerFrame:BIKE_ANIMATION_TIME_PER_FRAME];
    _shouwaSobayaAnimation = [SKAction repeatActionForever:sobayaAnimationOnce];
    
}
-(void)addGentsukiToHeisei {
    SKSpriteNode *bg = _bgNodeDict[@"heisei"];
    NSString *gentsukiName = @"heisei_gentsuki";

    // キャラクターを配置
    _heiseiGentsuki = [SKSpriteNode spriteNodeWithImageNamed:gentsukiName];
    _heiseiGentsuki.name = gentsukiName;
    float positionX = (int)(arc4random() % (BG_ORIGIN_WIDTH)) + (int)(-(BG_ORIGIN_WIDTH/2)); // 位置を乱数にする
    float positionY = -(BG_ORIGIN_HIGHT/7);
    _heiseiGentsuki.position = CGPointMake(positionX, positionY);
    [bg addChild:_heiseiGentsuki];
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
                    SKAction *moveRightAction = [self getMoveRightActionWithNode:car speedRate:carSpeedRate offset:CAR_OFFSET];
                    SKAction *actionSequence = [SKAction sequence:@[actionWait, moveRightAction]];
                    [car runAction:actionSequence];
                } else {
                    SKAction *moveLeftAction = [self getMoveLeftActionWithNode:car speedRate:carSpeedRate offset:CAR_OFFSET];
                    SKAction *actionSequence = [SKAction sequence:@[actionWait, moveLeftAction]];
                    [car runAction:actionSequence];
                    
                }
            }
            if ([car.name hasSuffix:@"right"]) {
                
                if (car.position.x >= _rightEdgeX+CAR_OFFSET) {
                    car.position = CGPointMake(_leftEdgeX-CAR_OFFSET-(BG_ORIGIN_WIDTH/2), car.position.y);
                    SKAction *moveRightAction = [self getMoveRightActionWithNode:car speedRate:carSpeedRate offset:CAR_OFFSET];
                    [car runAction:moveRightAction];
                }
            }else {

                if (car.position.x <= _leftEdgeX-CAR_OFFSET) {
                    car.position = CGPointMake(_rightEdgeX+CAR_OFFSET+(BG_ORIGIN_WIDTH/2), car.position.y);
                    SKAction *moveLeftAction = [self getMoveLeftActionWithNode:car speedRate:carSpeedRate offset:CAR_OFFSET];
                    [car runAction:moveLeftAction];
                }
            }
            
        }else {
            [car removeAllActions];
        }
        
    }
}

-(void)moveGentsukiOnHeisei {
    SKSpriteNode *bg = _bgNodeDict[@"heisei"];
    float gentsukiSpeedRate = BIKE_SPEED_RATE;
    // 真ん中に来たら歩く
    if ([self isBgCenter:bg.position.y]) {
        SKAction *actionWait = [SKAction waitForDuration:PEOPLE_WAIT_DURATION]; // 指定した秒数待つ
        if (![_heiseiGentsuki hasActions]) {
                SKAction *moveLeftAction = [self getMoveLeftActionWithNode:_heiseiGentsuki speedRate:gentsukiSpeedRate offset:CAR_OFFSET];
                SKAction *actionSequence = [SKAction sequence:@[actionWait, moveLeftAction]];
                [_heiseiGentsuki runAction:actionSequence];
                
        }

            
        if (_heiseiGentsuki.position.x <= _leftEdgeX-CAR_OFFSET) {
            _heiseiGentsuki.position = CGPointMake(_rightEdgeX+CAR_OFFSET+(BG_ORIGIN_WIDTH), _heiseiGentsuki.position.y);
            SKAction *moveLeftAction = [self getMoveLeftActionWithNode:_heiseiGentsuki speedRate:gentsukiSpeedRate offset:CAR_OFFSET];
            [_heiseiGentsuki runAction:moveLeftAction];
        }
        
    }else {
        [_heiseiGentsuki removeAllActions];
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
                    SKAction *moveLeftAction = [self getMoveLeftActionWithNode:people speedRate:peopleSpeedRate offset:PEOPLE_OFFSET];
                    SKAction *actionGroup = [SKAction group:@[walkAction, moveLeftAction]];
                    SKAction *actionSequence = [SKAction sequence:@[actionWait, actionGroup]];
                    [people runAction:actionSequence];
                    
                }else if ([self isPeopleFacingRight:people]) {
                    SKAction *moveRightAction = [self getMoveRightActionWithNode:people speedRate:peopleSpeedRate offset:PEOPLE_OFFSET];
                    SKAction *actionGroup = [SKAction group:@[walkAction, moveRightAction]];
                    SKAction *actionSequence = [SKAction sequence:@[actionWait, actionGroup]];
                    [people runAction:actionSequence];
                }
            }
            
            // 端を超えたら折り返す
            if (people.position.x >= _rightEdgeX+PEOPLE_OFFSET) {
                SKAction *moveLeftAction = [self getMoveLeftActionWithNode:people speedRate:peopleSpeedRate offset:PEOPLE_OFFSET];
                [people runAction:moveLeftAction];
            }else if (people.position.x <= _leftEdgeX-PEOPLE_OFFSET) {
                
                SKAction *moveRightAction = [self getMoveRightActionWithNode:people speedRate:peopleSpeedRate offset:PEOPLE_OFFSET];
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
    float sobayaSpeedRate = BIKE_SPEED_RATE;
        // 真ん中に来たら歩く
        if ([self isBgCenter:bg.position.y]) {
            
            SKAction *actionWait = [SKAction waitForDuration:PEOPLE_WAIT_DURATION]; // 指定した秒数待つ
            
            if (![_shouwaSobaya hasActions]) {
                    SKAction *moveLeftAction = [self getMoveLeftActionWithNode:_shouwaSobaya speedRate:sobayaSpeedRate offset:CAR_OFFSET];
                    SKAction *actionGroup = [SKAction group:@[_shouwaSobayaAnimation, moveLeftAction]];
                    SKAction *actionSequence = [SKAction sequence:@[actionWait, actionGroup]];
                    [_shouwaSobaya runAction:actionSequence];
            }
            if (_shouwaSobaya.position.x <= _leftEdgeX-CAR_OFFSET) {
                _shouwaSobaya.position = CGPointMake(_rightEdgeX+CAR_OFFSET+(BG_ORIGIN_WIDTH), _shouwaSobaya.position.y);
                SKAction *moveLeftAction = [self getMoveLeftActionWithNode:_shouwaSobaya speedRate:sobayaSpeedRate offset:CAR_OFFSET];
                [_shouwaSobaya runAction:moveLeftAction];
            }

        }else {
            [_shouwaSobaya removeAllActions];
        }
}
-(void)moveJinrikiOnMeiji {
    NSString *eraName = @"meiji";
    SKSpriteNode *bg = _bgNodeDict[eraName];
    float jinrikiSpeedRate = BIKE_SPEED_RATE;
    // 真ん中に来たら歩く
    if ([self isBgCenter:bg.position.y]) {
        
        SKAction *actionWait = [SKAction waitForDuration:PEOPLE_WAIT_DURATION]; // 指定した秒数待つ
        
        if (![_meijiJinriki hasActions]) {
            SKAction *moveLeftAction = [self getMoveLeftActionWithNode:_meijiJinriki speedRate:jinrikiSpeedRate offset:CAR_OFFSET];
            SKAction *actionGroup = [SKAction group:@[_meijiJinrikiAnimation, moveLeftAction]];
            SKAction *actionSequence = [SKAction sequence:@[actionWait, actionGroup]];
            [_meijiJinriki runAction:actionSequence];
        }
        if (_meijiJinriki.position.x <= _leftEdgeX-CAR_OFFSET) {
            _meijiJinriki.position = CGPointMake(_rightEdgeX+CAR_OFFSET+(BG_ORIGIN_WIDTH), _meijiJinriki.position.y);
            SKAction *moveLeftAction = [self getMoveLeftActionWithNode:_meijiJinriki speedRate:jinrikiSpeedRate offset:CAR_OFFSET];
            [_meijiJinriki runAction:moveLeftAction];
        }
        
    }else {
        [_meijiJinriki removeAllActions];
    }
}


-(void)animateDogTonoOnEdo {
    SKSpriteNode *bg = _bgNodeDict[@"edo"];
    if ([self isBgCenter:bg.position.y]) {
        SKAction *actionWait = [SKAction waitForDuration:PEOPLE_WAIT_DURATION]; // 指定した秒数待つ
        if (![_edoDogTono hasActions]) {
            SKAction *actionSequence = [SKAction sequence:@[actionWait, _edoDogTonoAnimation]];
            [_edoDogTono runAction:actionSequence];
        }
    }else {
            [_edoDogTono removeAllActions];
    }
}
-(void)animateTachibanashiOnEdo {
    SKSpriteNode *bg = _bgNodeDict[@"edo"];
    if ([self isBgCenter:bg.position.y]) {
        SKAction *actionWait = [SKAction waitForDuration:PEOPLE_WAIT_DURATION]; // 指定した秒数待つ
        if (![_edoTachibanashi hasActions]) {
            SKAction *actionSequence = [SKAction sequence:@[actionWait, _edoTachibanashiAnimation]];
            [_edoTachibanashi runAction:actionSequence];
        }
    }else {
        [_edoTachibanashi removeAllActions];
    }
}
-(void)animateShouninOnEdo {
    SKSpriteNode *bg = _bgNodeDict[@"edo"];
    if ([self isBgCenter:bg.position.y]) {
        SKAction *actionWait = [SKAction waitForDuration:PEOPLE_WAIT_DURATION]; // 指定した秒数待つ
        if (![_edoShounin hasActions]) {
            SKAction *actionSequence = [SKAction sequence:@[actionWait, _edoShouninAnimation]];
            [_edoShounin runAction:actionSequence];
        }
    }else {
        [_edoShounin removeAllActions];
    }
}

-(void)animateTachibanashiOnMeiji {
    SKSpriteNode *bg = _bgNodeDict[@"meiji"];
    if ([self isBgCenter:bg.position.y]) {
        SKAction *actionWait = [SKAction waitForDuration:PEOPLE_WAIT_DURATION]; // 指定した秒数待つ
        if (![_meijiTachibanashi hasActions]) {
            SKAction *actionSequence = [SKAction sequence:@[actionWait, _meijiTachibanashiAnimation]];
            [_meijiTachibanashi runAction:actionSequence];
        }
    }else {
        [_meijiTachibanashi removeAllActions];
    }
}
-(void)animateHitodakariOnMeiji {
    SKSpriteNode *bg = _bgNodeDict[@"meiji"];
    if ([self isBgCenter:bg.position.y]) {
        SKAction *actionWait = [SKAction waitForDuration:PEOPLE_WAIT_DURATION]; // 指定した秒数待つ
        if (![_meijiHitodakari hasActions]) {
            SKAction *actionSequence = [SKAction sequence:@[actionWait, _meijiHitodakariAnimation]];
            [_meijiHitodakari runAction:actionSequence];
        }
    }else {
        [_meijiHitodakari removeAllActions];
    }
}

-(void)animateHikyakuOkamiOnEdo {
    SKSpriteNode *bg = _bgNodeDict[@"edo"];
    if ([self isBgCenter:bg.position.y]) {
        SKAction *actionWait = [SKAction waitForDuration:PEOPLE_WAIT_DURATION]; // 指定した秒数待つ
        if (![_edoHikyakuOkami hasActions]) {
            SKAction *actionSequence = [SKAction sequence:@[actionWait, _edoHikyakuOkamiAnimation]];
            [_edoHikyakuOkami runAction:actionSequence];
        }
    }else {
        [_edoHikyakuOkami removeAllActions];
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

-(SKAction *)getMoveLeftActionWithNode:(SKSpriteNode *)node speedRate:(float)speedRate offset:(float)offset {
    float speed = speedRate * _standardSpeed;
    float distance = fabs(node.position.x - (_leftEdgeX-offset));
    float moveDuration = distance / speed;
    node.xScale = fabs(node.xScale);
    SKAction *moveLeftAction = [SKAction moveToX:_leftEdgeX-offset duration:moveDuration];
    return moveLeftAction;
}

-(SKAction *)getMoveRightActionWithNode:(SKSpriteNode *)node speedRate:(float)speedRate offset:(float)offset {
    float speed = speedRate * _standardSpeed;
    float distance = fabs(node.position.x - (_rightEdgeX+offset));
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
