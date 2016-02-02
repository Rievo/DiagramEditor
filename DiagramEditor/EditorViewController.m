//
//  EditorViewController.m
//  DiagramEditor
//
//  Created by Diego Vaquero Melchor on 9/12/15.
//  Copyright © 2015 Diego Vaquero Melchor. All rights reserved.
//

#import "EditorViewController.h"
#import "ComponentDetailsView.h"

#import "Connection.h"
#import "Palette.h"
#import "PaletteItem.h"
#import "XMLWriter.h"
#import "XMLDictionary.h"

@import Foundation;

@interface EditorViewController ()

@end

@implementation EditorViewController

@synthesize scrollView, loadedContent;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    canvasW = 1500;
    
    dele = [[UIApplication sharedApplication]delegate];
    
    canvas = [[Canvas alloc] initWithFrame:CGRectMake(0, 0, canvasW, canvasW)];
    canvas.backgroundColor = [dele blue4];
    [canvas prepareCanvas];
    dele.can = canvas;
    dele.originalCanvasRect = canvas.frame;
    
    //Add canvas to scrollView contents
    [scrollView addSubview:canvas];
    [scrollView setScrollEnabled:YES];
    [scrollView setContentSize:CGSizeMake(canvas.frame.size.width, canvas.frame.size.height)];
    [scrollView setBounces:NO];
    scrollView.contentSize = CGSizeMake(canvas.frame.size.width, canvas.frame.size.height);
    scrollView.minimumZoomScale = 0.7;
    scrollView.maximumZoomScale = 4.0;
    scrollView.delegate = self;
    
    //[self setZoomForIntValue:0]; //No zoom
    float nullZoom = [self getZoomScaleForIntValue:0];
    [scrollView setZoomScale:nullZoom animated:YES];
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(showComponentDetails:)
                                                 name:@"showCompNot"
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(showConnectionDetails:)
                                                 name:@"showConnNot"
                                               object:nil];
    
    
    compDetView = [[[NSBundle mainBundle] loadNibNamed:@"ComponentDetailsView"
                                                 owner:self
                                               options:nil] objectAtIndex:0];
    
    
    [compDetView setDelegate:self];
    
    

    [self.view addSubview:compDetView];
    [compDetView setFrame:self.view.frame];
    [compDetView setHidden:YES];
    
    
    
    UITapGestureRecognizer * zoomTapGr = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                                 action:@selector(doZoom:)];
    
    [zoomTapGr setNumberOfTapsRequired:2];
    [scrollView setUserInteractionEnabled:YES];
    [scrollView setCanCancelContentTouches:YES];
    [scrollView addGestureRecognizer:zoomTapGr];
    zoomTapGr.delegate = self;
    zoomLevel = 0; //No zoom
    

    
    //Si estoy cargando un fichero
    if(dele.components.count != 0){
        
        for(Component * comp in dele.components){
            [canvas addSubview:comp];
            [comp updateNameLabel];
        }
        //repaint canvas
        [[NSNotificationCenter defaultCenter]postNotificationName:@"repaintCanvas" object:self];
    }else{
          }
    
    palette.paletteItems = [[NSMutableArray alloc] initWithArray:dele.paletteItems];
    [palette preparePalette];
    palette.name = dele.subPalette;
    
}



#pragma mark Show/Hide detailsView
-(void)showDetailsView{
    [compDetView prepare];
    [compDetView setHidden:NO];
}
-(void)hideDetailsView{
    [compDetView setHidden:YES];
}


-(void)viewWillAppear:(BOOL)animated{
    palette.paletteItems = [[NSMutableArray alloc] initWithArray:dele.paletteItems];
    [palette preparePalette];
    palette.name = dele.subPalette;
    
    //Añadimos a los items de la paleta el gestor de gestos para poder arrastrarlos
    for(int i  =0; i< palette.paletteItems.count; i++){
        PaletteItem * item = [palette.paletteItems objectAtIndex:i];
        
        UIPanGestureRecognizer * panGr = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
        [item addGestureRecognizer:panGr];
    }
}

-(void)showComponentDetails:(NSNotification *)not{
    NSLog(@"Showing component's details");
    Component * temp = not.object;
    
    //[self performSegueWithIdentifier:@"showComponentDetails" sender:temp];
    
    //Load component details view
    compDetView.comp = temp;
    [compDetView prepare];
    [self showDetailsView];
    
}

#pragma mark UIPanGestureRecognizer


-(void)handlePan:(UIPanGestureRecognizer *)recog{
    PaletteItem * sender = (PaletteItem *)recog.view;
    
    CGPoint p = [recog locationInView:self.view];
    
    if(recog.state == UIGestureRecognizerStateBegan){
        //Creamos el icono temporal
        tempIcon = [[PaletteItem alloc] init];
        tempIcon.type = sender.type;
        tempIcon.dialog = sender.dialog;
        tempIcon.width = sender.width;
        tempIcon.height = sender.height;
        tempIcon.shapeType = sender.shapeType;
        [tempIcon setFrame:sender.frame];
        [tempIcon setAlpha:0.2];
        tempIcon.center = p;
        tempIcon.backgroundColor = [UIColor blackColor];
        [self.view addSubview:tempIcon];
    }else if(recog.state == UIGestureRecognizerStateChanged){
        //Movemos el icono temporal
        tempIcon.center = p;
    }else if(recog.state == UIGestureRecognizerStateEnded){
        //Retiramos el icono temporal
        [tempIcon removeFromSuperview];
        tempIcon = nil;
        
        //Check if point is inside canvas.
        
        CGPoint pointInSV = [self.view convertPoint:p toView:canvas];
        
        if(CGRectContainsPoint(scrollView.frame, p)){
            //Añadimos un Component al lienzo
            if([sender.type isEqualToString:@"graphicR:Node"]){
                //It is a node
                NSLog(@"Creating a node");
                
                Component * comp = [[Component alloc] initWithFrame:CGRectMake(0, 0, sender.width.floatValue, sender.height.floatValue)];
                comp.center = pointInSV;
                comp.name = sender.dialog;
                comp.type = sender.type;
                comp.shapeType = sender.shapeType;
                comp.fillColor = sender.fillColor;
                comp.attributes = sender.attributes;
                comp.colorString = sender.colorString;
                //TODO: comp.colorString = sender.
                
                if(sender.isImage){
                    comp.isImage = YES;
                    comp.image = sender.image;
                }else{
                    comp.isImage = NO;
                }
                
                [dele.components addObject:comp];
                [comp updateNameLabel];
                [canvas addSubview:comp];
                
            }else if([sender.type isEqualToString:@"graphicR:Edge"]){
                //It is an edge
                
                //Comprobamos si hay alguna relación cerca
                //En caso de que la haya, esa relación pasará a ser del tipo arrastrado
                
                //sender.attributes tiene los atributos
                //
                
                Connection * con;
                for(int  i = 0; i< dele.connections.count; i++){
                    con = [dele.connections objectAtIndex:i];
                    BOOL res = [canvas isPoint:pointInSV
                                withinDistance:10.0
                                        ofPath:con.arrowPath.CGPath];
                    
                    if(res == true){
                        //Set that connection to sender
                        //con.reference = sender;
                        NSLog(@"Change reference type");
                        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Info"
                                                                        message:@"Changing connection type"
                                                                       delegate:self
                                                              cancelButtonTitle:@"OK"
                                                              otherButtonTitles:nil];
                        [alert show];
                        
                        con.attributes = sender.attributes;
                        
                    }else{
                        //Nothing to do
                    }
                }
            }
        }else{
            NSLog(@"There is no canvas on this point.");
        }
        
        
    }
}



#pragma mark Toolbar


-(void)showConnectionDetails:(NSNotification *)not{
    Connection * temp = not.object;
    
    
    
    //TODO: Show connection info view
    ConnectionDetailsView * cdv = [[[NSBundle mainBundle] loadNibNamed:@"ConnectionDetailsView"
                                                                 owner:self
                                                               options:nil] objectAtIndex:0];
    
    //cdv.center = self.view.center;
    cdv.connection = temp;
    [cdv setFrame:self.view.frame];
    [cdv prepare];
    cdv.delegate = self;
    [self.view addSubview:cdv];
    [cdv setNeedsDisplay];
}

- (IBAction)showComponentList:(id)sender {
    [self performSegueWithIdentifier:@"showComponentsView" sender:self];
}

- (IBAction)showActionsList:(id)sender {
    
}

- (IBAction)createNewDiagram:(id)sender {
    //TODO: show are you sure view
    sureView = [[[NSBundle mainBundle] loadNibNamed:@"SureView"
                                              owner:self
                                            options:nil] objectAtIndex:0];
    [self.view addSubview:sureView];
    [sureView setFrame:self.view.frame];
    sureView.delegate = self;
}

-(void)resetAll{
    dele.components = [[NSMutableArray alloc] init];
    dele.connections = [[NSMutableArray alloc] init];
    [canvas prepareCanvas];
}

- (IBAction)saveCurrentDiagram:(id)sender {
    
    
    UIAlertController * ac  = [UIAlertController alertControllerWithTitle:nil
                                                                  message:nil
                                                           preferredStyle:UIAlertControllerStyleActionSheet];
    UIAlertAction * sendemail = [UIAlertAction actionWithTitle:@"Send email"
                                                         style:UIAlertActionStyleDefault
                                                       handler:^(UIAlertAction * _Nonnull action) {
                                                           
                                                           NSString * txt = [self generateXML];
                                                           
                                                           controller = [[MFMailComposeViewController alloc] init];
                                                           controller.mailComposeDelegate = self;
                                                           [controller setSubject:@"Diagram test"];
                                                           //[controller setMessageBody:@"Hello there." isHTML:NO];
                                                           [controller setMessageBody:txt isHTML:NO];
                                                           [self presentViewController:controller animated:YES completion:nil];
                                                       }];
    
    UIAlertAction * saveondevice = [UIAlertAction actionWithTitle:@"Local save"
                                                            style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction * _Nonnull action) {
                                                              [self saveDiagramOnDevice];
                                                          }];
    
    UIAlertAction * cancel = [UIAlertAction actionWithTitle:@"Cancel"
                                                      style:UIAlertActionStyleCancel
                                                    handler:^(UIAlertAction * _Nonnull action) {
                                                        
                                                    }];
    
    [ac addAction:sendemail];
    [ac addAction:saveondevice];
    [ac addAction:cancel];
    
    
    UIPopoverPresentationController * popover = ac.popoverPresentationController;
    if(popover){
        popover.sourceView = saveButton;
        //popover.sourceRect = sender.bounds;
        popover.permittedArrowDirections = UIPopoverArrowDirectionUp;
    }
    
    [self presentViewController:ac animated:YES completion:nil];
}

-(void) saveDiagramOnDevice{
    textToSave = [self generateXML];
    
    [snv removeFromSuperview];
    
    [saveBackgroundBlackView removeFromSuperview];
    saveBackgroundBlackView = [[UIView alloc] initWithFrame:self.view.frame];
    [saveBackgroundBlackView setBackgroundColor:[UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.5]];
    
    snv = [[[NSBundle mainBundle] loadNibNamed:@"SaveNameView"
                                         owner:self
                                       options:nil] objectAtIndex:0];
    
    if(oldFileName.length  > 0)
        snv.textField.text = oldFileName;
    snv.center = saveBackgroundBlackView.center;
    [saveBackgroundBlackView addSubview:snv];
    snv.delegate = self;
    
    [self.view addSubview:saveBackgroundBlackView];
}

-(void)writeFile: (NSString *)name{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0]; // Get documents folder
    NSString *folderPath = [documentsDirectory stringByAppendingPathComponent:@"/diagrams"];
    NSFileManager *fileManager  = [NSFileManager defaultManager];
    
    NSError *error = nil;
    if (![fileManager fileExistsAtPath:folderPath])
        [fileManager createDirectoryAtPath:folderPath withIntermediateDirectories:NO attributes:nil error:&error]; //Create folder
    
    if(error){
        NSLog([error description]);
    }
    
    error = nil;
    NSString *filePath = [folderPath stringByAppendingPathComponent:name];
    filePath = [filePath stringByAppendingString:@".xml"];
    [textToSave writeToFile:filePath atomically:NO encoding:NSUTF8StringEncoding error:&error];
    
    if(error){
        NSLog([error description]);
    }
    
}

-(NSString *)generateXML{
    //Generate XML
    XMLWriter * writer = [[XMLWriter alloc] init];
    [writer writeStartDocumentWithEncodingAndVersion:@"UTF-8" version:@"1.0"];
    [writer writeStartElement:@"Diagram"];
    
    [writer writeStartElement:@"palette_name"];
    [writer writeAttribute:@"name" value: dele.currentPaletteFileName];
    [writer writeEndElement];
    
    [writer writeStartElement:@"subpalette"];
    [writer writeAttribute:@"name" value: dele.subPalette];
    [writer writeEndElement];
    
    
    [writer writeStartElement:@"Nodes"];
    Component * temp = nil;
    for(int i = 0; i< dele.components.count; i++){
        temp = [dele.components objectAtIndex:i];
        [writer writeStartElement:@"node"];
        [writer writeAttribute:@"name" value:temp.name];
        [writer writeAttribute:@"shape_type" value:temp.shapeType];
        [writer writeAttribute:@"x" value: [[NSNumber numberWithFloat:temp.center.x]description]];
        [writer writeAttribute:@"y" value: [[NSNumber numberWithFloat:temp.center.y]description]];
        [writer writeAttribute:@"id" value: [[NSNumber numberWithInt:(int)temp ]description]];
        [writer writeAttribute:@"color" value:temp.colorString];
        [writer writeAttribute:@"type" value:temp.type];
        [writer writeAttribute:@"width" value: [[NSNumber numberWithFloat:temp.frame.size.width]description]];
        [writer writeAttribute:@"height" value: [[NSNumber numberWithFloat:temp.frame.size.height]description]];
        [writer writeEndElement];
    }
    [writer writeEndElement];//Close nodes
    
    
    [writer writeStartElement:@"Edges"];
    Connection * c = nil;
    for(int i = 0; i<dele.connections.count; i++){
        c = [dele.connections objectAtIndex:i];
        [writer writeStartElement:@"edge"];
        [writer writeAttribute:@"name" value:c.name];
        [writer writeAttribute:@"source" value:[[NSNumber numberWithInt:(int)c.source]description]];
        [writer writeAttribute:@"target" value:[[NSNumber numberWithInt:(int)c.target]description]];
        [writer writeEndElement];
    }
    [writer writeEndElement];
    
    [writer writeEndElement];//Close diagram
    [writer writeEndDocument];
    
    NSString * xml = [writer toString];
    return xml;
}


- (IBAction)willChangePalette:(id)sender {
    
    dele.currentPaletteFileName = nil;
    [dele.components removeAllObjects];
    [dele.connections removeAllObjects];
    [[NSNotificationCenter defaultCenter]postNotificationName:@"repaintCanvas" object:self];

    [self dismissViewControllerAnimated:YES completion:nil];
}




- (IBAction)exportCanvasToImage:(id)sender {
    UIGraphicsBeginImageContext(canvas.frame.size);
    [canvas.layer renderInContext:UIGraphicsGetCurrentContext()];
    
    UIImage* image = nil;
    
    UIGraphicsBeginImageContext(scrollView.contentSize);
    {
        CGPoint savedContentOffset = scrollView.contentOffset;
        CGRect savedFrame = scrollView.frame;
        
        scrollView.contentOffset = CGPointZero;
        scrollView.frame = CGRectMake(0, 0, scrollView.contentSize.width, scrollView.contentSize.height);
        
        [scrollView.layer renderInContext: UIGraphicsGetCurrentContext()];
        image = UIGraphicsGetImageFromCurrentImageContext();
        
        scrollView.contentOffset = savedContentOffset;
        scrollView.frame = savedFrame;
    }
    UIGraphicsEndImageContext();
    
    NSData * data = UIImagePNGRepresentation(image);
    
    
    /*
     controller = [[MFMailComposeViewController alloc] init];
     controller.mailComposeDelegate = self;
     [controller setSubject:@"Digram image text"];
     [controller addAttachmentData:data mimeType:@"image/png" fileName:@"photo"];
     [self presentViewController:controller animated:YES completion:nil];
     */
    
    UIAlertController * ac  = [UIAlertController alertControllerWithTitle:nil
                                                                  message:nil
                                                           preferredStyle:UIAlertControllerStyleActionSheet];
    UIAlertAction * sendemail = [UIAlertAction actionWithTitle:@"Send email"
                                                         style:UIAlertActionStyleDefault
                                                       handler:^(UIAlertAction * _Nonnull action) {
                                                           
                                                           controller = [[MFMailComposeViewController alloc] init];
                                                           controller.mailComposeDelegate = self;
                                                           [controller setSubject:@"Digram image text"];
                                                           [controller addAttachmentData:data mimeType:@"image/png" fileName:@"photo"];
                                                           [self presentViewController:controller animated:YES completion:nil];
                                                       }];
    
    UIAlertAction * saveondevice = [UIAlertAction actionWithTitle:@"Save on camera roll"
                                                            style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction * _Nonnull action) {
                                                              [self saveImageOnCameraRoll:image];
                                                          }];
    
    
    [ac addAction:sendemail];
    [ac addAction:saveondevice];
    
    
    UIPopoverPresentationController * popover = ac.popoverPresentationController;
    if(popover){
        popover.sourceView = cameraOutlet;
        popover.permittedArrowDirections = UIPopoverArrowDirectionUp;
    }
    
    [self presentViewController:ac animated:YES completion:nil];
}

-(void)saveImageOnCameraRoll: (UIImage *) image{
    UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil);
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Info"
                                                    message:@"Image saved properly"
                                                   delegate:self
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
    [alert show];
}



#pragma mark Storyboard
-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    
}




#pragma mark MFMailComposeViewController delegate methods
- (void)mailComposeController:(MFMailComposeViewController*)controller
          didFinishWithResult:(MFMailComposeResult)result
                        error:(NSError*)error;
{
    if (result == MFMailComposeResultSent) {
        NSLog(@"It's away!");
    }
    //[self dismissModalViewControllerAnimated:YES];
    [self dismissViewControllerAnimated:YES completion:nil];
}



#pragma mark UIScrollViewDelegate

-(float)getZoomScaleForIntValue:(int) val{
    float minz = scrollView.minimumZoomScale;
    float maxz = scrollView.maximumZoomScale;
    
    //float current = val * minz / maxz;
    float current = val * maxz ;
    if(current <minz){
        current = minz;
    }
    return current;
}
-(UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView{
    return canvas;
}

-(void)scrollViewDidEndZooming:(UIScrollView *)sv withView:(UIView *)view atScale:(CGFloat)scale{
    [sv setContentSize:CGSizeMake(dele.originalCanvasRect.size.width * scale, dele.originalCanvasRect.size.height * scale)];
}


- (void)zoomToPoint:(CGPoint)zoomPoint withScale:(CGFloat)scale animated:(BOOL)animated
{
    
    
    CGPoint translatedZoomPoint = CGPointZero;
    translatedZoomPoint.x = zoomPoint.x + scrollView.contentOffset.x;
    translatedZoomPoint.y = zoomPoint.y + scrollView.contentOffset.y;
    
    
    CGFloat zoomFactor = 1.0f / scrollView.zoomScale;
    
    
    translatedZoomPoint.x *= zoomFactor;
    translatedZoomPoint.y *= zoomFactor;
    
    
    CGRect destinationRect = CGRectZero;
    destinationRect.size.width = CGRectGetWidth(scrollView.frame) / scale;
    destinationRect.size.height = CGRectGetHeight(scrollView.frame) / scale;
    destinationRect.origin.x = translatedZoomPoint.x - (CGRectGetWidth(destinationRect) * 0.5f);
    destinationRect.origin.y = translatedZoomPoint.y - (CGRectGetHeight(destinationRect) * 0.5f);
    
    
    [UIView animateWithDuration:0.55f delay:0.0f usingSpringWithDamping:1.0f initialSpringVelocity:0.6f options:UIViewAnimationOptionAllowUserInteraction animations:^{
        [scrollView zoomToRect:destinationRect animated:NO];
    } completion:^(BOOL completed) {
        if ([scrollView.delegate respondsToSelector:@selector(scrollViewDidEndZooming:withView:atScale:)]) {
            [scrollView.delegate scrollViewDidEndZooming:scrollView withView:[scrollView.delegate viewForZoomingInScrollView:scrollView] atScale:scale];
        }
    }];
}


-(void)doZoom: (UITapGestureRecognizer * )tapRecognizer{
    if(zoomLevel == 0){
        zoomLevel = 1;
    }else if(zoomLevel == 1){
        zoomLevel = 0;
    }

    
    CGPoint p = [tapRecognizer locationInView: self.view];
    CGPoint pointInSV = [self.view convertPoint:p toView:canvas];
    
    float newScale = [self getZoomScaleForIntValue:zoomLevel];
    
    
    [self zoomToPoint:pointInSV withScale:newScale animated:YES];
}

#pragma mark ComponentDetailsView delegate

-(void)closeDetailsViewAndUpdateThings{
   [compDetView setHidden:YES];
}



#pragma mark UIGestureRecognizer
-(BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer{
    return  YES;
}


#pragma mark SaveNameDelegate
-(void)saveName: (NSString *)name{
    [self writeFile:name];
    oldFileName = name;
    [saveBackgroundBlackView setHidden:YES];
}
-(void)cancelSaving{
    [saveBackgroundBlackView setHidden:YES];
}


#pragma mark Check integrity
/*
 Cuando el usuario suelte la conexión entre dos elementos: Siempre mirando el GraphicR
 1) Comprobar si del nodo origen puede salir alguna conexión
 2) En caso de que pueda salir conexión, mirar el nodo destino
 2.1)Si no se pueden unir origen y destino, esto es, 0 conexiones posibles
 2.2)Si se pueden unir origen y destino
 2.2.1) Si solo hay una posible conexión en el graphicR, tomarla
 2.2.2) Si hay más de una posible conexión, mostrar un popup para que el usuario elija cuál de ellas
 */

-(BOOL)checkIntegrityForSource: (Component *)source
                     andTarget: (Component *)target{
    BOOL result = false;
    
    
    
    return result;
}


#pragma mark ConnectionDetailsViewDelegate

#pragma mark SureViewDelegate methods

-(void)closeSureViewWithResult:(BOOL)res{
    if (res == YES){
        [self resetAll];
    }else{
        
    }
}


-(BOOL) isiPad {
    return UI_USER_INTERFACE_IDIOM()==UIUserInterfaceIdiomPad;
}



@end
