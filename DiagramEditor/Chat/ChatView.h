//
//  ChatView.h
//  ChatTest
//
//  Created by Diego on 5/5/16.
//  Copyright © 2016 Diego. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AppDelegate.h"
@interface ChatView : UIView<UITextFieldDelegate, UITableViewDelegate, UITableViewDataSource, UITextViewDelegate, UIGestureRecognizerDelegate>{
    CGFloat animatedDistance;
    __weak IBOutlet UITextView *tv;
    __weak IBOutlet UITableView *table;
    
    
    
    NSMutableDictionary * dic;
    AppDelegate * dele;
    
    UIFont * whoFont;
    UIFont * bodyFont;
    
    NSDateFormatter *dateFormatter ;
    __weak IBOutlet UIView *bottomBar;
    
    CGRect oldFrame;
}

- (IBAction)sendMessage:(id)sender;

-(void)prepare;

@property (weak, nonatomic) IBOutlet UIView *background;
@property UIViewController * parent;
@end
