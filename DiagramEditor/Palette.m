//
//  Palette.m
//  DiagramEditor
//
//  Created by Diego Vaquero Melchor on 10/12/15.
//  Copyright © 2015 Diego Vaquero Melchor. All rights reserved.
//

#import "Palette.h"
#import "AppDelegate.h"
#import "PaletteItem.h"

#define xmargin 20
#define distanceToBorder 10
#define separationBetweenElements 20


@implementation Palette

@synthesize paletteItems,name, sliderToChange;


-(void)preparePalette{
    
    //self.delegate = self;
    self.contentSize = CGSizeMake(0, self.bounds.size.height);
    
    dele = [UIApplication sharedApplication].delegate;
    
    if(paletteItems == nil)
        paletteItems = [[NSMutableArray alloc] init];
    
    for(int i = 0; i< paletteItems.count; i++){
        PaletteItem * temp = [paletteItems objectAtIndex:i];
        
        //Remove all gesture recognizers
        for (UIGestureRecognizer *recognizer in temp.gestureRecognizers) {
            [temp removeGestureRecognizer:recognizer];
        }
        
        float a = distanceToBorder;
        
        CGFloat x  = i* self.contentSize.height + xmargin;
        x = x + i* separationBetweenElements;
        
        CGRect insideRect = CGRectMake(x, a, self.contentSize.height -2*a, self.contentSize.height -2*a);
        
        
        temp.frame = insideRect;
        

        temp.backgroundColor = [UIColor clearColor];
        

        [self addSubview:temp];
        self.contentSize = CGSizeMake(self.contentSize.width + temp.frame.size.width + xmargin + separationBetweenElements, self.contentSize.height);
        
        
    }
    self.contentSize = CGSizeMake(self.contentSize.width + xmargin, self.contentSize.height);
    
    self.delegate = self;

}


-(void)resetPalette{
    PaletteItem * pi = nil;
    for(int i = 0; i< paletteItems.count; i++){
        pi = [paletteItems objectAtIndex:i];
        [pi removeFromSuperview];
    }
    paletteItems = [[NSMutableArray alloc] init];
}


#pragma mark UIScrollView

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    sliderToChange.value=self.contentOffset.x;
}

@end
