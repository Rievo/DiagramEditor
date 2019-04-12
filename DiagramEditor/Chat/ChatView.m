//
//  ChatView.m
//  ChatTest
//
//  Created by Diego on 5/5/16.
//  Copyright © 2016 Diego. All rights reserved.
//

#import "ChatView.h"
#import "ChatTableViewCell.h"

#define LABEL_WIDTH 200
#define TOP_MARGIN 10
#define BOTTOM_MARGIN 10


#import "Message.h"

@implementation ChatView

@synthesize background, parent;

static const CGFloat KEYBOARD_ANIMATION_DURATION = 0.3;


- (IBAction)sendMessage:(id)sender {
    [self sendMessageAndClear];
}

-(void)prepare{
    
    dele =(AppDelegate *) [[UIApplication sharedApplication]delegate];
    
    //tf.delegate = self;
    dele.messagesArray = [[NSMutableArray alloc] init];
    tv.delegate = self;
    
    [table setDelegate:self];
    [table setDataSource:self];

    dic = [[NSMutableDictionary alloc] init];
    
    dele = (AppDelegate *)[[UIApplication sharedApplication]delegate];
    
    whoFont = [UIFont fontWithName:@"HelveticaNeue-Bold" size:9.0];
    bodyFont = [UIFont fontWithName:@"HelveticaNeue-Light" size:11.0];
    
    dateFormatter = [[NSDateFormatter alloc] init];
    //[dateFormatter setDateFormat:@"HH:mm dd-MM-YYYY "];
    [dateFormatter setDateFormat:@"HH:mm"];
    
    
    oldFrame = bottomBar.frame;
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleNewMessage:)
                                                 name:kNewChatMessage
                                               object:nil];
    
    
    UITapGestureRecognizer * tapgr = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
    [background addGestureRecognizer:tapgr];
    [tapgr setDelegate:self];
    
    NSNotificationCenter * center = [NSNotificationCenter defaultCenter];
    [center addObserver:self
               selector:@selector(keyboardOnScreen:)
                   name:UIKeyboardWillShowNotification
                 object:nil];
    
    

    [center addObserver:self
               selector:@selector(keyboardOutOfScreen:)
                   name:UIKeyboardWillHideNotification
                 object:nil];
}

-(void)keyboardOutOfScreen:(NSNotification *)not{
    
    [UIView animateWithDuration:0.2
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
                             [bottomBar setFrame:oldFrame];
                     }
                     completion:^(BOOL finished) {
                         
                     }];

}


-(void)keyboardOnScreen:(NSNotification *)not{
    
    oldFrame = bottomBar.frame;
    
    NSDictionary * dicNot = not.userInfo;
    
    NSValue *val = dicNot[UIKeyboardFrameEndUserInfoKey];
    
    CGRect rawFrame = [val CGRectValue];
    
    CGRect keyboardFrame = [self.parent.view convertRect:rawFrame fromView:nil];
    
    [UIView animateWithDuration:0.2
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
                         [bottomBar setFrame:CGRectMake(bottomBar.frame.origin.x,
                                                        keyboardFrame.origin.y - bottomBar.frame.size.height*2,
                                                        bottomBar.frame.size.width,
                                                        bottomBar.frame.size.height)];
                     }
                     completion:^(BOOL finished) {
                         
                     }];
    
}


-(void)handleNewMessage:(NSNotification *)not{
    NSDictionary * notdic = [not userInfo];
    Message * received = [notdic objectForKey:@"message"];
    
    [dele.messagesArray addObject:received];
    [table reloadData];
}


-(void)sendMessageAndClear{
    //Send message
    
    Message * mess = [[Message alloc] init];
    mess.content = tv.text;
    mess.date = [NSDate date];
    mess.who = dele.myPeerInfo.peerID;
    
    
    [self sendMessageToPeers:mess];
    
    //Add to my database
    [dele.messagesArray addObject:mess];

    
    
    [table reloadData];
    
    
    //Clear textfield
    [tv setText:@""];
    [tv endEditing:YES];
}



#pragma mark UITableView delegate
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;    //count of section
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    return [dele.messagesArray count];    //count number of row from counting array hear cataGorry is An Array
}



- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath
{

    
    static NSString *MyIdentifier = @"ChatCellId";
    ChatTableViewCell * cell = (ChatTableViewCell *)[tableView dequeueReusableCellWithIdentifier:MyIdentifier];
    if(cell == nil){
        NSArray * nib = [[NSBundle mainBundle] loadNibNamed:@"ChatTableViewCell"
                                                      owner:self
                                                    options:nil];
        cell = nib[0];
        Message * msg = dele.messagesArray[indexPath.row];
        cell.textLabel.text = [NSString stringWithFormat:@"%@\n", msg.content];
        cell.textLabel.numberOfLines = 0;
        cell.textLabel.font = bodyFont;
        
        [dic setObject:cell forKey:indexPath];
        
        cell.whoLabel.text = msg.who.displayName;
        cell.whoLabel.font = whoFont;
        
        
        NSMutableDictionary * views = [[NSMutableDictionary alloc] init];
        [views setObject:cell.container forKey:@"container"];
        [views setObject:cell.fromMeTriangle forKey:@"fromMe"];
        [views setObject:cell.fromThemTriangle forKey:@"fromThemTriangle"];
        
        cell.container.layer.cornerRadius = 4;
        cell.container.layer.masksToBounds = YES;
        
        if([msg.who.displayName isEqualToString:dele.myPeerInfo.peerID.displayName]){ //I send it -> Right
            [cell.contentView addConstraints:[NSLayoutConstraint
                                              constraintsWithVisualFormat:@"[fromMe]|"
                                              options:0
                                              metrics:nil
                                              views:views]];
            [cell.fromThemTriangle setHidden:YES];
        }else{ //-> Left
            [cell.contentView addConstraints:[NSLayoutConstraint
                                              constraintsWithVisualFormat:@"|[fromThemTriangle]"
                                              options:0
                                              metrics:nil
                                              views:views]];
            [cell.fromMeTriangle setHidden:YES];
        }
        
        //Date
        
        NSString *formattedDateString = [dateFormatter stringFromDate:msg.date];
        cell.dateLabel.text = formattedDateString;
        
        CGSize labelSize = [cell.textLabel sizeThatFits:CGSizeMake(cell.textLabel.frame.size.width, CGFLOAT_MAX)];
        
        CGRect frame = cell.frame;
        frame.size.width = labelSize.width + 30;
        [cell setFrame:frame];
    }
    
    
    
    return cell;
    
}



-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{

    ChatTableViewCell * cell  = [dic objectForKey:indexPath];
    CGSize labelSize = [cell.textLabel sizeThatFits:CGSizeMake(cell.textLabel.frame.size.width, CGFLOAT_MAX)];
    
    if(indexPath.row > dele.messagesArray.count)
        return 0;
    else
     return (TOP_MARGIN + labelSize.height + BOTTOM_MARGIN + cell.whoLabel.frame.size.height);
    

}


#pragma mark UITextView

-(void)textViewDidBeginEditing:(UITextView *)textView{

}




-(void)textViewDidEndEditing:(UITextView *)textView{
    CGRect viewFrame = self.frame;
    viewFrame.origin.y += animatedDistance;
    
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationBeginsFromCurrentState:YES];
    [UIView setAnimationDuration:KEYBOARD_ANIMATION_DURATION];
    
    [self setFrame:viewFrame];
    
    [UIView commitAnimations];
}

-(BOOL)textViewShouldEndEditing:(UITextView *)textView{
    [textView resignFirstResponder];
    return YES;
}


-(void)sendMessageToPeers: (Message *)message{
    NSMutableDictionary * sendDic = [[NSMutableDictionary alloc] init];
    
    [sendDic setObject:kNewChatMessage forKey:@"msg"];
    [sendDic setObject:message forKey:@"message"];
    [sendDic setObject:message.who forKey:@"who"];
    
    
    
    NSError * error = nil;
    
    NSData * allData = [NSKeyedArchiver archivedDataWithRootObject:sendDic];
    [dele.manager.session sendData:allData
                           toPeers:dele.manager.session.connectedPeers
                          withMode:MCSessionSendDataReliable
                             error:&error];
    
    if(error != nil){
        NSLog(@"ERROR SENDING chat message");
    }

}




-(void)handleTap: (UITapGestureRecognizer *)recog{
    [self removeFromSuperview];
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
