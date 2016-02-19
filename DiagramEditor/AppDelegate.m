//
//  AppDelegate.m
//  DiagramEditor
//
//  Created by Diego Vaquero Melchor on 9/12/15.
//  Copyright © 2015 Diego Vaquero Melchor. All rights reserved.
//

#import "AppDelegate.h"
#import "Canvas.h"
#import "Connection.h"
#import "EditorViewController.h"

@interface AppDelegate ()

@end

@implementation AppDelegate

@synthesize components, connections, paletteItems, blue4, blue3, originalCanvasRect, currentPaletteFileName, subPalette, graphicR, evc, blue0, blue1, blue2;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    connections = [[NSMutableArray alloc] init];
    components = [[NSMutableArray alloc] init];
    
    paletteItems = [[NSMutableArray alloc] init];
    
    blue0 = [[UIColor alloc]initWithRed:91/256.0 green:109/256.0 blue:146/256.0 alpha:1.0];
    blue1 = [[UIColor alloc]initWithRed:182/256.0 green:191/256.0 blue:209/256.0 alpha:1.0];
    blue2 = [[UIColor alloc]initWithRed:130/256.0 green:144/256.0 blue:173/256.0 alpha:1.0];
    blue3 = [[UIColor alloc]initWithRed:58/256.0 green:78/256.0 blue:120/256.0 alpha:1.0];
    blue4 = [[UIColor alloc]initWithRed:34/256.0 green:54/256.0 blue:96/256.0 alpha:1.0];
    
    currentPaletteFileName = nil;
    subPalette = nil;
    graphicR = nil;
    evc = nil;
    
    
    /*CGAffineTransform trans = CGAffineTransformIdentity;
    trans = CGAffineTransformConcat(trans, CGAffineTransformMakeRotation(M_PI/180*30));
    trans = CGAffineTransformConcat(trans, CGAffineTransformMakeTranslation(200, 0));
 
    //trans = CGAffineTransformConcat(trans, CGAffineTransformMakeTranslation(1, 1));
    

    CGAffineTransform transformTarget = CGAffineTransformIdentity;
    transformTarget = CGAffineTransformRotate(transformTarget, M_PI/180*30);
    transformTarget = CGAffineTransformTranslate(transformTarget,200,0);

    //transformTarget = CGAffineTransformTranslate(transformTarget,1,1);
    

    int r = 2;*/
    
    
    
    return YES;
}




- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}


-(int)getOutConnectionsForComponent: (Component *)comp
                             ofType: (NSString * )type{

    int count = 0;
    
    for(Connection * con in connections){
        if(con.source == comp && [con.className isEqualToString:type]){
            count++;
        }
    }
    return count;
}


-(int)getInConnectionsForComponent: (Component *)comp
                             ofType: (NSString *)type{
    
    int count = 0;
    
    for(Connection * con in connections){
        if(con.target == comp && [con.className isEqualToString:type]){
            count++;
        }
    }
    return count;
}


@end
