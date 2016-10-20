//
//  AppDelegate.h
//  DiagramEditor
//
//  Created by Diego Vaquero Melchor on 9/12/15.
//  Copyright © 2015 Diego Vaquero Melchor. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "MCManager.h"
#import "Constants.h"
#import "PeerInfo.h"
#import "TutorialSheet.h"
#import "Palette.h"
#import <MapKit/MapKit.h>


@class PaletteFile;
@class Canvas;
@class Component;
@class PaletteItem;
@class ClassAttribute;
@class EditorViewController;
@class ChatView;
@class DrawnAlert;
@class YesOrNoView;

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;


@property NSMutableArray * connections;
@property NSMutableArray * components;
@property NSMutableDictionary * elementsDictionary;

@property NSMutableArray * paletteItems;
@property BOOL isGeoPalette;

@property UIColor * blue0;
@property UIColor * blue1;
@property UIColor * blue2;
@property UIColor * blue3;
@property UIColor * blue4;

@property Canvas * can;
@property MKMapView * map;
@property EditorViewController * evc;
@property CGRect originalCanvasRect;

@property PaletteFile * currentPaletteFile;
//@property NSString * currentPaletteFileName;
@property NSString * subPalette;


@property NSDictionary * graphicR;

@property NSString * myUUIDString;


@property BOOL loadingADiagram;


//Generate XML
@property NSString * graphicRContent;
@property NSString * ecoreContent;


//Multipeer Connectivity
@property MCManager * manager;

@property PeerInfo * serverId;
@property PeerInfo * myPeerInfo;
@property PeerInfo * currentMasterId;


@property ChatView * chat;

@property Component * fingeredComponent;

@property NSMutableArray * messagesArray;
@property NSMutableArray * notesArray;
@property NSMutableArray * drawnsArray;

@property DrawnAlert * selectedDrawn;
@property YesOrNoView * yonv;
@property UIColor * myColor;

@property BOOL showingAnnotations;


@property NSString * configureTutorialStatus;
@property NSString * editorTutorialStatus;
@property BOOL shouldShowConfigureTutorial;
@property BOOL shouldShowEditorTutorial;

@property int missedServerAttemps;
@property NSTimer * connectedToServerTimer;

@property TutorialSheet * tutSheet;


@property NSMutableArray * noVisibleItems;

@property NSMutableDictionary * colorDic;

@property Palette * paletteView;
@property float paletteW;
@property float paletteH;
@property NSString * paletteExtension;

@property BOOL inMultipeerMode;

@property NSMutableDictionary * enumsDic;

-(int)getOutConnectionsForComponent: (Component *)comp
                             ofType: (NSString * )type;
-(int)getInConnectionsForComponent: (Component *)comp
                             ofType: (NSString * )type;


-(NSData *) packElementsInfo;
-(NSData *) packAppDelegate;


-(void)recoverInfoFromData: (NSData *)data;

-(PaletteItem *) getPaletteItemForClassName:(NSString *)name andRefName:(NSString *)refName;
-(PaletteItem *) getPaletteItemForClassName:(NSString *)name;

-(void) completeClassAttribute:(ClassAttribute *)ca
                  withClasName:(NSString *)className;

-(BOOL)amITheMaster;
-(BOOL)amITheServer;

-(UIColor*)getColorForPeerWithName:(NSString *) name;

+(NSString *)getBase64StringFromImage:(UIImage *)image;
+(UIImage *)getImageFromBase64String:(NSString *)string;


@end

