//
//  ClassAttribute.h
//  DiagramEditor
//
//  Created by Diego on 22/1/16.
//  Copyright © 2016 Diego Vaquero Melchor. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ClassAttribute : NSObject<NSCoding>


@property NSString * name;
@property NSString * type;
@property NSNumber * min;
@property NSNumber * max;
@property NSString * defaultValue;
@property NSString * currentValue;

@property BOOL isLabel;

@end
