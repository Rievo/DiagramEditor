//
//  CreateNoteView.h
//  DiagramEditor
//
//  Created by Diego on 23/5/16.
//  Copyright © 2016 Diego Vaquero Melchor. All rights reserved.
//

#import <UIKit/UIKit.h>
@class AppDelegate;

@interface CreateNoteView : UIView<UIGestureRecognizerDelegate, UIImagePickerControllerDelegate,UINavigationControllerDelegate>{
    UIColor * color;
    __weak IBOutlet UIView *container;
    __weak IBOutlet UIView *background;
    AppDelegate * dele;
    
    UIImagePickerController * picker;
    __weak IBOutlet UIButton *cameraButton;
    UIPopoverController *popover ;
    __weak IBOutlet UIImageView *preview;
    
    id delegate;
}

@property (weak, nonatomic) IBOutlet UITextView *textView;

@property UIViewController * parentVC;

@property id delegate;

@property CGPoint noteCenter;

- (IBAction)attachImage:(id)sender;
- (IBAction)cancelCreatingAlert:(id)sender;
- (IBAction)confirmCreatingAlert:(id)sender;

@end


@protocol CreateNoteViewDelegate <NSObject>

-(void) createNoteViewDidCancel;
-(void) createNoteViewConfirmWithText: (NSString *)text
                             andImage:(UIImage *)image
                              onPoint:(CGPoint) point;

@end