//
//  EditorViewController.h
//  DiagramEditor
//
//  Created by Diego Vaquero Melchor on 9/12/15.
//  Copyright © 2015 Diego Vaquero Melchor. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Component.h"
#import "AppDelegate.h"
#import "Canvas.h"
#import "ComponentDetailsView.h"
#import "ConnectionDetailsView.h"
#import "SaveNameView.h"
#import "SureView.h"
#import "EdgeListView.h"

@class Palette;
@class PaletteItem;
@class ComponentDetailsView;

#import <MessageUI/MFMailComposeViewController.h>

@interface EditorViewController : UIViewController<MFMailComposeViewControllerDelegate,
UIGestureRecognizerDelegate,
UIScrollViewDelegate,
ComponentDetailsViewDelegate,
SaveNameDelegate,
ConnectionDetailsViewDelegate,
SureViewDelegate,
EdgeListDelegate>{
    AppDelegate * dele;
    __weak IBOutlet Palette *palette;
    
    PaletteItem * tempIcon;
    __weak IBOutlet UIButton *newDiagram;
    __weak IBOutlet UIButton *saveDiagram;
    
    MFMailComposeViewController* controller ;
    
    
    Canvas *canvas;
    
    int canvasW;
    
    
    //Button outlets
    __weak IBOutlet UIButton *saveButton;
    
    
    
    int zoomLevel; //0-> No zoom     1-> mid zoom   2-> Full zoom
    
    ComponentDetailsView * compDetView;
    UIView * containerView;
    
    UIView * saveBackgroundBlackView;
    SaveNameView * snv;
    
    NSString * textToSave;
    NSString * oldFileName;
    
    __weak IBOutlet UIButton *cameraOutlet;
    
    
    SureView * sureView;
    __weak IBOutlet UISlider *slider;
}
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;

@property NSString * loadedContent;




- (IBAction)showComponentList:(id)sender;
- (IBAction)showActionsList:(id)sender;
- (IBAction)createNewDiagram:(id)sender;


- (IBAction)saveCurrentDiagram:(id)sender;
- (IBAction)exportCanvasToImage:(id)sender;

- (IBAction) valueChanged:(id)sender event:(UIControlEvents)event ;
@end
