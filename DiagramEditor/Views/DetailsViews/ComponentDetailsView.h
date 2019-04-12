//
//  ComponentDetailsViewController.h
//  DiagramEditor
//
//  Created by Diego Vaquero Melchor on 9/12/15.
//  Copyright © 2015 Diego Vaquero Melchor. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Component;
@class AppDelegate;


@interface ComponentDetailsView : UIView <UITextFieldDelegate, UITableViewDataSource, UITableViewDelegate, UIGestureRecognizerDelegate>{
    
    __weak IBOutlet UIView *previewComponentView;
    Component * previewComponent;
    __weak IBOutlet UILabel *typeLabel;
    
    AppDelegate * dele;
    __weak IBOutlet UILabel *classLabel;
    

    __weak IBOutlet UITableView *table;

    
    NSMutableArray * connections;
    
    __weak IBOutlet UIView *blurView;
    UITapGestureRecognizer * tapgr;
    id delegate;
    __weak IBOutlet UIView *containerView;
}

@property (nonatomic, retain)id delegate;

@property Component * comp;

@property UIScrollView * scroll;
- (void)prepare;
- (IBAction)closeDetailsViw:(id)sender;

@property (weak, nonatomic) IBOutlet UIView *background;

@end;

@protocol ComponentDetailsViewDelegate

@required
-(void)closeDetailsViewAndUpdateThings;

@end
