//
//  ConnectionDetailsView.m
//  DiagramEditor
//
//  Created by Diego on 26/1/16.
//  Copyright © 2016 Diego Vaquero Melchor. All rights reserved.
//

#import "ConnectionDetailsView.h"
#import "Connection.h"
#import "ReferenceTableViewCell.h"
#import "AppDelegate.h"
#import "Component.h"

@implementation ConnectionDetailsView



@synthesize delegate, sourceLabel, targetLabel, background, connection;

- (void)awakeFromNib {
    UITapGestureRecognizer * tapgr = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
    [background addGestureRecognizer:tapgr];
    [tapgr setDelegate:self];
    
    //[nameTextField addTarget:self action:@selector(textFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
}


-(void)handleTap: (UITapGestureRecognizer *)recog{
    [self closeConnectionDetailsView];
}

-(void)closeConnectionDetailsView{
    [self removeFromSuperview];
}

- (IBAction)removeThisConnection:(id)sender {
    
    AppDelegate * dele = [[UIApplication sharedApplication] delegate];
    [dele.connections removeObject:self.connection];
    [[NSNotificationCenter defaultCenter]postNotificationName:@"repaintCanvas" object:self];
    [self closeConnectionDetailsView];
}

- (IBAction)associateNewInstance:(id)sender {
}

-(void)prepare{
    //nameTextField.text = connection.name;
    //attributesTable.delegate = self;
    //attributesTable.dataSource = self;
    sourceLabel.text = [NSString stringWithFormat:@"%@",connection.source.name];
    targetLabel.text = [NSString stringWithFormat:@"%@", connection.target.name];
    
    
    associatedComponentsArray = [[NSMutableArray alloc] init];
    //Llenamos ese array con las instancias asociadas a esta conexión
    
    instancesTable.delegate = self;
    instancesTable.dataSource = self;
    
    
    for (NSString * key in [connection.instancesOfClassesDictionary allKeys]) {
        NSLog(@"%@", key);
        NSMutableArray * tempArray = [connection.instancesOfClassesDictionary objectForKey:key];
        
        for(Component * comp in tempArray){
            [associatedComponentsArray addObject:comp];
        }
    }
    
    [instancesTable reloadData];
    
    attributesArray = [[NSMutableArray alloc] init];
    
    
    for(int i = 0; i< connection.attributes.count; i++){
        [attributesArray addObject:[connection.attributes objectAtIndex:i]];
    }
    
    [attributesTable reloadData];
}


-(void)textFieldDidChange :(UITextField *)textField{
    if(textField.text.length == 0){
        
    }else{
        //connection.name = textField.text;
        [[NSNotificationCenter defaultCenter]postNotificationName:@"repaintCanvas" object:self];
    }
}

#pragma mark UITableViewDelegate methods
-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    if (tableView == instancesTable) {
        return associatedComponentsArray.count;
    }else{
        return 0;
    }
    
}



- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *MyIdentifier = @"MyIdentifier";
    
    UITableViewCell *cell = nil;
    
    if(tableView == instancesTable){
        Component * c = [associatedComponentsArray objectAtIndex:indexPath.row];
        
        
        cell= [tableView dequeueReusableCellWithIdentifier:MyIdentifier];
        
        if (cell == nil)
        {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                          reuseIdentifier:MyIdentifier] ;
        }
        cell.backgroundColor = [UIColor clearColor];
        cell.textLabel.adjustsFontSizeToFitWidth = YES;
        cell.textLabel.minimumScaleFactor = 0.5;
        cell.textLabel.text = [NSString stringWithFormat:@"--: %@", c.name];
    }
    

    return cell;
    
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath;
{
    
    if(tableView == instancesTable){
        NSArray * nib = [[NSBundle mainBundle] loadNibNamed:@"ReferenceTableViewCell"
                                                      owner:self
                                                    options:nil];
        ReferenceTableViewCell * temp = [nib objectAtIndex:0];
        return temp.frame.size.height;
    }else{
        return 30;
    }

}



- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    
    [self endEditing:YES];
    if (touch.view != background) { // accept only touchs on superview, not accept touchs on subviews
        return NO;
    }
    
    return YES;
}



@end
