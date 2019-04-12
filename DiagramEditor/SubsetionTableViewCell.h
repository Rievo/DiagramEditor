//
//  SubsetionTableViewCell.h
//  DiagramEditor
//
//  Created by Diego on 7/9/16.
//  Copyright © 2016 Diego Vaquero Melchor. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "ClassAttribute.h"
#import "Reference.h"
#import "RemovableReference.h"

@interface SubsetionTableViewCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UILabel *label;
@property (weak, nonatomic) IBOutlet UISwitch *control;


@property id associatedElement;


-(void)prepare;
@end
