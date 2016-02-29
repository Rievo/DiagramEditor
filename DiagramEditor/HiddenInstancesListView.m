//
//  HiddenInstancesListView.m
//  DiagramEditor
//
//  Created by Diego on 29/2/16.
//  Copyright © 2016 Diego Vaquero Melchor. All rights reserved.
//

#import "HiddenInstancesListView.h"
#import "Component.h"
#import "AppDelegate.h"
#import "Connection.h"

@implementation HiddenInstancesListView

@synthesize className, delegate, connection;

-(void)awakeFromNib{
    [instancesTable setDataSource:self];
    [instancesTable setDelegate:self];
    instancesArray = [[NSMutableArray alloc] init];
    [self recoverInstancesOfClass:className];
}

-(void)reloadInfo{
    [self recoverInstancesOfClass:className];
}


-(void)recoverInstancesOfClass:(NSString *)cn{
    AppDelegate * dele = [[UIApplication sharedApplication]delegate];
    NSMutableArray * array = [dele.elementsDictionary objectForKey:cn];
    instancesArray = array;
    [instancesTable reloadData];
}


#pragma mark UITableView Delegate methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;    //count of section
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    return instancesArray.count;
}



- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath
{
    static NSString *MyIdentifier = @"MyIdentifier";
    
    UITableViewCell *cell;
    
    Component * c = [instancesArray objectAtIndex:indexPath.row];
    
    
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
    return cell;
    
    
}


- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    
    return NO;
}



- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    
    Component * selected = [instancesArray objectAtIndex:indexPath.row];
    [delegate closeHILV:self withSelectedComponent:selected andConnection:connection];
}

@end
