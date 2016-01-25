//
//  Component.h
//  DiagramEditor
//
//  Created by Diego Vaquero Melchor on 5/11/15.
//  Copyright © 2015 Diego Vaquero Melchor. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AppDelegate.h"
#import "Canvas.h"

@interface Component : UIView <UIGestureRecognizerDelegate>{
    
    UITapGestureRecognizer * tapGR;
    UILongPressGestureRecognizer * longGR;
    UIPanGestureRecognizer * panGR;
    
    
    UIFont * font;
    AppDelegate * dele;

    UIPanGestureRecognizer * resizeGr;

    CAShapeLayer * backgroundLayer;
    
    UIView * resizeView;
}


@property NSString * name;
@property NSMutableArray * connections;
@property CATextLayer * textLayer;
@property NSString * type;
@property NSString * shapeType;
@property UIColor * fillColor;
@property UIImage * image;
@property BOOL isImage;

@property NSMutableArray * attributes;


-(CGPoint)getTopAnchorPoint;
-(CGPoint)getBotAnchorPoint;
-(CGPoint)getLeftAnchorPoint;
-(CGPoint)getRightAnchorPoint;

-(void)updateNameLabel;

@end
