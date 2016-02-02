//
//  PasteView.m
//  DiagramEditor
//
//  Created by Diego on 21/1/16.
//  Copyright © 2016 Diego Vaquero Melchor. All rights reserved.
//

#import "PasteView.h"

@implementation PasteView

@synthesize textview, backView, delegate, background;

-(void)awakeFromNib{
    /*UITapGestureRecognizer * tapgr = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                             action:@selector(handleTap:)];
    [background addGestureRecognizer:tapgr];
    [tapgr setDelegate:self];*/
    [textview setDelegate:self];
}

- (IBAction)cancel:(id)sender {
    
    [self removeFromSuperview];
}


- (IBAction)ok:(id)sender {
    [self removeFromSuperview];
    [delegate saveTextFromPasteView:self];
}



-(void)handleTap: (UITapGestureRecognizer *)recog{
    [self removeFromSuperview];
}


- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    
    if(touch.view == background){
        return YES;
    }else if(touch.view ==blueView){
        [textview resignFirstResponder];
        return NO;
    }else{
        return NO;
    }
    
}

-(BOOL) textFieldShouldReturn:(UITextField *)textField{
    
    [textField resignFirstResponder];
    return YES;
}

@end
