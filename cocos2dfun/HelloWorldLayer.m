//
//  HelloWorldLayer.m
//  cocos2dfun
//
//  Created by Ben Scheirman on 5/22/12.
//  Copyright __MyCompanyName__ 2012. All rights reserved.
//


// Import the interfaces
#import "HelloWorldLayer.h"

enum {
    RunAnimationTag = 12,
    JumpAnimationTag
};

// HelloWorldLayer implementation
@implementation HelloWorldLayer

+(CCScene *) scene
{
	// 'scene' is an autorelease object.
	CCScene *scene = [CCScene node];
	
	// 'layer' is an autorelease object.
	HelloWorldLayer *layer = [HelloWorldLayer node];
	
	// add layer as a child to scene
	[scene addChild: layer];
	
	// return the scene
	return scene;
}

- (void)setupRunAnimation {
    runAnimation = [[CCAnimation animation] retain];
    const int NUM_FRAMES = 10;
    const int WIDTH = 42;
    const int HEIGHT = 52;
    const int Y = 285;
    const int Frames[] = {0, 42, 84, 126, 168, 210, 252, 294, 341, 383};

    int x = 0;
    for (int i=0; i < NUM_FRAMES; i++) {
        x = Frames[i];
        CCSpriteFrame *frame = 
            [CCSpriteFrame frameWithTexture:spriteSheet.texture 
                                       rect:CGRectMake(x, Y, WIDTH, HEIGHT)];
        [runAnimation addFrame:frame];
    }
    runAnimation.delay = 0.05;
}

- (void)setupBackground {
    CGSize size = [[CCDirector sharedDirector] winSize];
    CGPoint center =  ccp( size.width /2 , size.height/2 );

    CCSprite *bg = [CCSprite spriteWithFile:@"bg.png"];
    bg.position = center;
    bg.scale = 1.8;
    [self addChild:bg z:ZIndexSpace];
}

- (void)appendGround:(CCSprite *)ground {
    if (!ground) {
        ground = [CCSprite spriteWithFile:@"ground.png"];
        ground.scale = 0.8;
    }
    
    if (!groundSprites) {
        groundSprites = [[NSMutableArray alloc] init];
    }
    
    int x;
    if ([groundSprites count] == 0) {
        // left edge
        x = ground.textureRect.size.width * ground.scale / 2;
    } else {
        CCSprite *lastGround = [groundSprites lastObject];
        x = lastGround.position.x + lastGround.textureRect.size.width * lastGround.scale;
    }
    
    int y = ground.textureRect.size.height * ground.scale / 2;
    ground.position = ccp(x, y);

    [groundSprites addObject:ground];
    
    if (!ground.parent) {
        [self addChild:ground z:ZIndexGround];                    
    }
}

- (void)setupGround {
    [self appendGround:nil];
    [self appendGround:nil];
    [self appendGround:nil];
}

- (void)setupPlayer {
    spriteSheet = [CCSpriteBatchNode 
                    batchNodeWithFile:@"SuperMetroidSamus.gif"];
    player = [CCSprite spriteWithBatchNode:spriteSheet
                                      rect:CGRectMake(0, 0, 30, 56)];
    
    // the scaled up version looks ugly, 
    // we want the "8-bit" blocky look
    ccTexParams texParams = { GL_NEAREST, GL_NEAREST, 
        GL_CLAMP_TO_EDGE, GL_CLAMP_TO_EDGE };
    
    [player.texture setTexParameters:&texParams];
    
    player.position = ccp(100, 150);
    player.scale = 3.0f;
    
    [spriteSheet addChild:player];
    [self addChild:spriteSheet z:ZIndexPlayer];
}

- (void)setupJumpAnimation {
    jumpAnimation = [[CCAnimation animation] retain];
    const int NUM_FRAMES = 8;
    const int WIDTH = 36;
    const int HEIGHT = 45;
    const int Y = 240;
    const int Frames[] = {0, 36, 72, 108, 144, 177, 212, 254};
    for (int i=0; i < NUM_FRAMES; i++) {
        int x = Frames[i];
        if (i > 3) {
            x -= 2;
        } else if (i >= 6) {
            x += 9;
        }
        CCSpriteFrame *frame = [CCSpriteFrame frameWithTexture:spriteSheet.texture rect:CGRectMake(x, Y, WIDTH, HEIGHT)];
        [jumpAnimation addFrame:frame];
    }
    jumpAnimation.delay = 0.04;
}

// HelloWorldLayer.m
- (id)init {
    self = [super init];
    if (self) {
        [self setupBackground];
        [self setupGround];
        [self setupPlayer];
        
        [self setupJumpAnimation];
        [self setupRunAnimation];
        [self startRunning];
        
        //self.scale = 0.2;
        
        [self schedule:@selector(update:) interval:1/60.0];
        [self registerWithTouchDispatcher];
    }
    return self;
}

- (void)jump {
    CCAnimate *animateJump = [CCAnimate actionWithAnimation:jumpAnimation];
    CCRepeatForever *animateJumpRepeatedly = [CCRepeatForever actionWithAction:animateJump];
    [player runAction:animateJumpRepeatedly];
    
    CCJumpBy *jump = [CCJumpBy actionWithDuration:0.8
                                         position:ccp(0, 0)
                                           height:180
                                            jumps:1];
    
    CCCallFunc *startRunningAgain = [CCCallFunc actionWithTarget:self 
                                                        selector:@selector(startRunning)];
    CCSequence *sequence = [CCSequence actionOne:jump two:startRunningAgain];
    [player runAction:sequence];
}

- (void)ccTouchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    [self jump];
}

- (void)checkToRecycleGround {
    CCSprite *ground = [groundSprites objectAtIndex:0];
    if (ground.position.x < -1 * ground.textureRect.size.width * ground.scale / 2) {
        [groundSprites removeObject:ground];
        [self appendGround:ground];
    }
}

- (void)update:(ccTime)delta {
    const CGFloat speed = 500.0f;
    CGFloat deltaX = - speed * delta;
    for (CCSprite *ground in groundSprites) {
        ground.position = ccpAdd(ground.position, ccp(deltaX, 0));
    }
    
    [self checkToRecycleGround];
}

- (void)startRunning {
    id animateAction = [CCAnimate actionWithAnimation:runAnimation
                                 restoreOriginalFrame:YES];
    CCAction *repeatAnimationAction = [CCRepeatForever 
                                       actionWithAction:animateAction];
    repeatAnimationAction.tag = RunAnimationTag;
    [player runAction:repeatAnimationAction];
}

- (void)stopRunning {
    [player stopActionByTag:RunAnimationTag];    
}

- (void)dealloc {
    [runAnimation release];
    [groundSprites release];
    [super dealloc];
}

@end

