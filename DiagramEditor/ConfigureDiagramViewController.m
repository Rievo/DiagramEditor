//
//  ConfigureDiagramViewController.m
//  DiagramEditor
//
//  Created by Diego Vaquero Melchor on 9/12/15.
//  Copyright © 2015 Diego Vaquero Melchor. All rights reserved.
//

#import "ConfigureDiagramViewController.h"
#import "XMLDictionary.h"
#import "PaletteItem.h"
#import "AppDelegate.h"
#import "Palette.h"
#import "ColorPalette.h"

#import "PaletteFile.h"
#import "PasteView.h"

#import "ClassAttribute.h"
#import "Reference.h"

#import "ExploreFilesView.h"
#import "EditorViewController.h"

#import "Connection.h"

#import "ThinkingView.h"
#import "DiagramFile.h"


#import "Alert.h"
#import "PathPiece.h"

#import "LinkPalette.h"


#define defaultwidth 50
#define defaultheight 50

#define scale 7

#define xmargin 20

#define getPalettes @"https://diagrameditorserver.herokuapp.com/palettes?json=true"

#define fileExtension @".graphicR"
#define baseURL @"https://diagrameditorserver.herokuapp.com"

@interface ConfigureDiagramViewController ()

@end


@implementation ConfigureDiagramViewController
@synthesize tempPaletteFile, contentToParse;

-(void)viewDidLayoutSubviews{
    
}
-(void)viewDidAppear:(BOOL)animated{
    if(dele.shouldShowConfigureTutorial == YES){
        doingTutorial = YES;
        [self startConfigureCVTutorial];
    }else{
        doingTutorial = NO;
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //initialInfoPosition = infoView.frame;
    [infoView setHidden:YES];
    
    
    //Hide unused groups
    [subPaletteGroup setHidden:YES];
    [cancelSubpaletteSelectionOutlet setHidden:YES];
    [palette setHidden:YES];
    [confirmButton setHidden:YES];
    
    
    [subPaletteGroup setFrame:CGRectMake(subPaletteGroup.frame.origin.x, subPaletteGroup.frame.origin.y, paletteFileGroup.frame.size.width, paletteFileGroup.frame.size.height)];
    
    
    dele.loadingADiagram = NO;
    content = nil;
    
    
    tempPaletteFile = nil;
    
    
    dele = (AppDelegate *) [UIApplication sharedApplication].delegate;
    
    dele.window.rootViewController = self;
    
    palettes = [[NSMutableArray alloc] init];
    [palettesTable setDataSource:self];
    [palettesTable setDelegate:self];
    
    /*
     UILongPressGestureRecognizer * longp = [[UILongPressGestureRecognizer alloc] initWithTarget:self
     action:@selector(showInfo)];
     longp.minimumPressDuration = 3.0;
     [myInfo addGestureRecognizer:longp];*/
    
    filesArray = [[NSMutableArray alloc] init];
    [filesTable setDataSource:self];
    [filesTable setDelegate:self];
    
    
    
    
    //Load palettes from server
    NSThread * thread = [[NSThread alloc] initWithTarget:self
                                                selector:@selector(loadPalettesFromServer)
                                                  object:nil];
    [thread start];
    
    
    //Load local files
    NSThread * locThread = [[NSThread alloc] initWithTarget:self
                                                   selector:@selector(loadLocalFiles)
                                                     object:nil];
    [locThread start];
    
    
    
    //Pull to refresh
    
    refreshControl = [[UIRefreshControl alloc] init];
    [refreshControl addTarget:self action:@selector(refresh:) forControlEvents:UIControlEventValueChanged];
    [filesTable addSubview:refreshControl];
    
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didReceiveAppDeleLetsgoToEditor)
                                                 name:@"receivingAppDeleGoEditor"
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(closeSubPalette)
                                                 name:@"closeSubPalette"
                                               object:nil];
    
    
    UISwipeGestureRecognizer * ges = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swiped:)];
    ges.direction = UISwipeGestureRecognizerDirectionRight;
    [self.view addGestureRecognizer:ges];
    
    NSArray * arr =[[NSBundle mainBundle] loadNibNamed:@"SlideMenuView" owner:nil options:nil];
    menu = [arr objectAtIndex:0];
    
    CGRect oldMenuFrame = menu.frame;
    oldMenuFrame.size.height = self.view.frame.size.height;
    oldMenuFrame.origin.x = 0 - oldMenuFrame.size.width;
    
    [menu setFrame:oldMenuFrame];
    
    menu.delegate = self;
    
    [self.view addSubview:menu];
    
    UISwipeGestureRecognizer * hideMenuGes = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(shouldHideMenu:)];
    hideMenuGes.direction = UISwipeGestureRecognizerDirectionLeft;
    [self.view addGestureRecognizer:hideMenuGes];
    
}

-(void)shouldHideMenu:(UISwipeGestureRecognizer *)recog{
    [self hideMenu];
}
-(void)hideMenu{
    CGRect oldMenuFrame = menu.frame;
    oldMenuFrame.origin.x = 0 -oldMenuFrame.size.width;
    
    [UIView beginAnimations:@"showMenu" context:nil];
    [UIView setAnimationDuration:0.3];
    [menu setFrame:oldMenuFrame];
    [UIView commitAnimations];
    
    [blurMenuView removeFromSuperview];
    blurMenuView = nil;
}
-(void)showMenu{
    
    CGRect oldMenuFrame = menu.frame;
    oldMenuFrame.origin.x = 0 ;
    
    [UIView beginAnimations:@"showMenu" context:nil];
    [UIView setAnimationDuration:0.3];
    [menu setFrame:oldMenuFrame];
    [UIView commitAnimations];
    
    blurMenuView.backgroundColor = [UIColor clearColor];
    
    if(blurMenuView  == nil){
        
        UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];
        UIVisualEffectView * blur= [[UIVisualEffectView alloc] initWithEffect:blurEffect];
        blur.frame = self.view.bounds;
        blur.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [self.view addSubview:blur];
        
        blurMenuView = blur;
        [self.view bringSubviewToFront:menu];
    }
}

-(void)swiped:(UISwipeGestureRecognizer *)recog{
    [self showMenu];
}



-(void)closeSubPalette{
    [self cancelSubpaletteSelection:self];
}

-(void)didReceiveAppDeleLetsgoToEditor{
    NSLog(@"Received AppDelegate from server. Showing editor");
    [self performSegueWithIdentifier:@"showEditor" sender:self];
}



- (void)refresh:(UIRefreshControl *)refreshControl {
    
    
    [self reloadServerPalettes:self];
    }




-(void)viewWillAppear:(BOOL)animated{
    dele.loadingADiagram = NO;
}

#pragma mark Recover files from server and local device

-(void)loadLocalFiles{
    
    //Remove local files from array
    NSMutableArray * toRemove = [[NSMutableArray alloc] init];
    for(PaletteFile * pf in filesArray){
        if(pf.fromServer == NO){
            [toRemove addObject:pf];
        }
    }
    
    [filesArray removeObjectsInArray:toRemove];
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0]; // Get documents folder
    
    NSString *palettePath = [documentsDirectory stringByAppendingPathComponent:@"/Palettes"];
    
    
    NSArray *directoryContent = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:palettePath error:NULL];
    
    
    for (int count = 0; count < (int)[directoryContent count]; count++)
    {
        NSString * path = [NSString stringWithFormat:@"%@/%@", palettePath, directoryContent[count]];
        NSString * fileContent = [NSString stringWithContentsOfFile:path
                                                         encoding:NSUTF8StringEncoding
                                                            error:NULL];
        
        NSError * jsonError;
        NSData *objectData = [fileContent dataUsingEncoding:NSUTF8StringEncoding];
        NSDictionary *json = [NSJSONSerialization JSONObjectWithData:objectData
                                                             options:NSJSONReadingMutableContainers
                                                               error:&jsonError];
        
        
        PaletteFile * pf = [[PaletteFile alloc] init];
        
        NSArray * components = [path componentsSeparatedByString:@"/"];
        
        pf.name = [components objectAtIndex:components.count -1];
        pf.content = [json objectForKey:@"content"];
        pf.fromServer = false;
        pf.ecoreURI = [json objectForKey:@"ecoreURI"];
        
        [filesArray addObject:pf];
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [filesTable reloadData];
    });
    
    
    //NSFileManager  *manager = [NSFileManager defaultManager];
    // the preferred way to get the apps documents directory
    //NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    //NSString *documentsDirectory = [paths objectAtIndex:0];
    
    
    /*
     //Load from bundle
     NSArray * bpaths = [[NSBundle mainBundle] pathsForResourcesOfType:@".graphicR" inDirectory:nil];
     NSString * contentstr = nil;
     for(NSString * path in bpaths){
     contentstr = [NSString stringWithContentsOfFile:path
     encoding:NSUTF8StringEncoding
     error:nil];
     PaletteFile * pf = [[PaletteFile alloc] init];
     NSArray * components = [path componentsSeparatedByString:@"/"];
     
     pf.name = [components objectAtIndex:components.count -1];
     pf.content = contentstr;
     pf.fromServer = false;
     
     [filesArray addObject:pf];
     }
     
     dispatch_async(dispatch_get_main_queue(), ^{
     [filesTable reloadData];
     });*/
    
    
}

-(void)loadPalettesFromServer{
    NSLog(@"Loading palettes from server");
    NSNumber * versionNumber =  [NSNumber numberWithInteger:graphicRVersion];
    NSString * urlStr = [NSString stringWithFormat:@"%@&version=%@", getPalettes, [versionNumber description]];
    //NSURL *url = [NSURL URLWithString:getPalettes];
    NSURL *url = [NSURL URLWithString:urlStr];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    [NSURLConnection sendAsynchronousRequest:request
                                       queue:[NSOperationQueue mainQueue]
                           completionHandler:^(NSURLResponse *response,
                                               NSData *data, NSError *connectionError)
     {
         if (data.length > 0 && connectionError == nil)
         {
             NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:data
                                                                 options:0
                                                                   error:NULL];
             
             //[serverFilesArray removeAllObjects];
             
             NSString * code = [dic objectForKey:@"code"];
             
             if([code isEqualToString:@"200"]){
                 NSArray * array = [dic objectForKey:@"array"];
                 
                 [self removeServerPalettesFromArray];
                 
                 for(int i = 0; i< [array count]; i++){
                     NSDictionary * ins = [array objectAtIndex:i];
                     PaletteFile * pf = [[PaletteFile alloc] init];
                     pf.name = [ins objectForKey:@"name"];
                     pf.content = [ins objectForKey:@"content"];
                     pf.fromServer = true;
                     pf.ecoreURI = [ins objectForKey:@"ecoreURI"];
                     pf.extension = [ins objectForKey:@"extension"];
                     [filesArray addObject:pf];
                 }
                 
                 
                 dispatch_async(dispatch_get_main_queue(), ^{
                     [filesTable reloadData];
                 });
                 
                 
                 
                 
             }else{
                 NSLog(@"Error: %@", connectionError);
             }
             
         }
         
         // Do your job, when done:
         [refreshControl endRefreshing];

     }];
}

-(void)removeServerPalettesFromArray{
    
    NSMutableArray * toRemove = [[NSMutableArray alloc] init];
    
    for(PaletteFile * pf in filesArray){
        if(pf.fromServer == YES){
            [toRemove addObject:pf];
        }
    }
    
    for(PaletteFile * pf in toRemove){
        [filesArray removeObject:pf];
    }
}

#pragma mark Read file/palette and proccess

/*  Read file and proccess  */

-(Palette *)extractSubPalette: (NSString *)name{
    for(int i = 0; i< palettes.count; i++){
        Palette * pal = [palettes objectAtIndex:i];
        
        if ([pal.name isEqualToString:name]) {
            return pal;
        }
    }
    
    return nil;
}

+(NSArray *)getPalettesForContent:(NSString *)c{
    NSDictionary * conf = [NSDictionary dictionaryWithXMLString:c];
    
    NSMutableArray * tempPalettes = [[NSMutableArray alloc] init];
    
    NSArray * allGraphicRepresentations = (NSArray *)[conf objectForKey:@"allGraphicRepresentation"];
    
    
    //Por si el fichero tiene un solo "allGraphicrepresentation
    //En ese caso, la llamada a "dictionaryWithXMLString" devuelve un NSDictionary, que añadimos al array
    if([allGraphicRepresentations isKindOfClass:[NSDictionary class]]){
        allGraphicRepresentations = [[NSArray alloc] initWithObjects:[conf objectForKey:@"allGraphicRepresentation"], nil];
    }
    
    
    
    
    for(int gr = 0; gr < allGraphicRepresentations.count; gr++){
        
        
        NSDictionary * listRepresentations =[[allGraphicRepresentations objectAtIndex:gr]objectForKey:@"listRepresentations"];
        
        NSString * isgeopaletteStr = [[allGraphicRepresentations objectAtIndex:gr]objectForKey:@"_isGeopalette"];
        BOOL isGeopalette = false;
        
        if([isgeopaletteStr isEqualToString:@"true"]){
            isGeopalette = YES;
        }else if([isgeopaletteStr isEqualToString:@"false"]){
            isGeopalette = NO;
        }else{
            isGeopalette = NO;
        }
        
        NSArray * lRArray;
        
        if([listRepresentations isKindOfClass:[NSDictionary class]]){
            lRArray = [[NSArray alloc] initWithObjects:listRepresentations, nil];
        }else{
            lRArray = [[NSArray alloc] init];
        }
        
        
        for(int i = 0; i< lRArray.count; i++){   //Create a temp palette
            Palette * tempPalete = [[Palette alloc] init];
            [tempPalete preparePalette];
            
            NSDictionary * allGraphicRepresentation = [lRArray objectAtIndex:i];
            tempPalete.isGeopalette = isGeopalette;
            
            //dele.isGeoPalette = isGeopalette;
            
            //NSString * paletteName = [allGraphicRepresentation objectForKey:@"_extension"];
            //tempPalete.name = paletteName;
            //tempPalete.extension = file.extension;
            //tempPalete.name = file.name;
            
            
            NSDictionary * layers = [allGraphicRepresentation objectForKey:@"layers"];
            NSArray * elements = [layers objectForKey:@"elements"];
            
            
            for(int i  = 0; i< elements.count; i++){
                
                PaletteItem * item = [[PaletteItem alloc] init];
                
                NSDictionary * dic = [elements objectAtIndex:i];
                NSString * type = [dic objectForKey:@"_xsi:type"];
                
                item.type = type;
                
                NSDictionary * className = [dic objectForKey:@"anEClass"];
                NSString * classStr = [className objectForKey:@"_href"];
                NSArray * arraystr = [classStr componentsSeparatedByString:@"/"];
                NSString * parsedClass = [arraystr objectAtIndex: arraystr.count -1];
                item.className = parsedClass;
                
                NSDictionary * diagPalette = [dic objectForKey:@"diag_palette"];
                NSString * paleteName = [diagPalette objectForKey:@"_palette_name"];
                NSLog(@"\n\ntype: %@     	\n name: %@", type, paleteName);
                
                
                //Is expandable?
                NSString * expandableStr = [dic objectForKey:@"_expandable"];
                BOOL isExpandable = [expandableStr boolValue];
                item.isExpandable = isExpandable;
                
                //In order to get node label
                NSDictionary * nodeElementsDic = [dic objectForKey:@"node_elements"];
                NSArray * labelAnEAttributeArray = [nodeElementsDic objectForKey:@"LabelanEAttribute"];
                
                if([labelAnEAttributeArray isKindOfClass:[NSDictionary class]]){
                    labelAnEAttributeArray = [[NSArray alloc]initWithObjects:labelAnEAttributeArray, nil];
                }
                
                //labelAnEAttributeArray tendrá un array con el o los atributos que serán label
                
                item.labelsAttributesArray = [[NSMutableArray alloc] init];
                
                for(int i = 0; i<labelAnEAttributeArray.count; i++){
                    NSDictionary * labelanEattributeDic = labelAnEAttributeArray[i];
                    NSDictionary * anEattributeDic = [labelanEattributeDic objectForKey:@"anEAttribute"];
                    
                    NSString * labelReference = [anEattributeDic objectForKey:@"_href"];
                    
                    NSString * labelPosition = [labelanEattributeDic objectForKey:@"_labelPosition"];
                    
                    if(labelPosition == nil){
                        labelPosition = @"border";
                    }
                    item.labelPosition = labelPosition;
                    
                    NSArray * parts = [labelReference componentsSeparatedByString:@"/"];
                    NSString * attrName = [parts objectAtIndex:parts.count-1];
                    [item.labelsAttributesArray addObject:attrName];
                }
                
                //Get linkPalette
                NSArray * linkPaletteArray = [nodeElementsDic objectForKey:@"linkPalette"];
                if([linkPaletteArray isKindOfClass:[NSDictionary class]]){
                    linkPaletteArray = [NSArray arrayWithObjects:linkPaletteArray, nil];
                } //linkPaletteArray will hold my connected things
                
                item.linkPaletteDic = [[NSMutableDictionary alloc] init];
                
                for(NSDictionary * lpDic in linkPaletteArray){
                    LinkPalette * lp = [[LinkPalette alloc] init];
                    lp.anDiagramElement = [lpDic objectForKey:@"_anDiagramElement"];
                    lp.paletteName = [lpDic objectForKey:@"_palette_name"];
                    lp.targetDecoratorName = [lpDic objectForKey:@"_decoratorName"];
                    lp.targetDecoratorName = [lp.targetDecoratorName lowercaseString];
                    lp.colorDic = [lpDic objectForKey:@"color"];
                    NSString * sourceDecName = [lpDic objectForKey:@"_sourceDecoratorName"];
                    if(sourceDecName == nil){
                        sourceDecName = NO_DECORATION;
                    }
                    lp.sourceDecoratorName = [sourceDecName lowercaseString];
                    
                    NSDictionary * refDic =[lpDic objectForKey:@"anEReference"];
                    lp.anEReference = [refDic objectForKey:@"_href"];
                    lp.colorDic = [lpDic objectForKey:@"color"];
                    lp.lineStyle = [lpDic objectForKey:@"_LineStyle"];
                    
                    NSArray * classParts = [lp.anEReference componentsSeparatedByString:@"/"];
                    lp.className = [classParts objectAtIndex:classParts.count -2];
                    lp.referenceInClass = [classParts objectAtIndex:classParts.count-1];
                    
                    [item.linkPaletteDic setObject:lp forKey:lp.referenceInClass];
                }
                
                NSArray * expandableItems = [nodeElementsDic objectForKey:@"expandableItems"];
                if([expandableItems isKindOfClass:[NSDictionary class]]){
                    expandableItems = [NSArray arrayWithObjects:expandableItems, nil];
                }
                
                item.expandableItems = [[NSMutableArray alloc] init];
                
                for(NSDictionary * expItem in expandableItems){
                    
                    NSDictionary * refDic = [expItem objectForKey:@"anEReference"];
                    NSString * reference = [refDic objectForKey:@"_href"];  //Con esta referencia marco el palete link como expandable
                    
                    NSArray * parts = [reference componentsSeparatedByString:@"/"];
                    NSString * clasSName = [parts objectAtIndex:parts.count-2];
                    NSString * refName = parts[parts.count-1];
                    
                    NSString * indexStr = [expItem objectForKey:@"_index"];
                    if(indexStr == nil){
                        indexStr = @"0";
                    }
                    int index = [indexStr intValue];
                    
                    NSArray * keys = [item.linkPaletteDic allKeys];
                    for(NSString * key in keys){
                        LinkPalette * lp  = [item.linkPaletteDic objectForKey:key];
                        
                        if([lp.className isEqualToString:clasSName] && [lp.referenceInClass isEqualToString:refName]){
                            lp.isExpandableItem = YES;
                            lp.expandableIndex = index;
                            [item.expandableItems addObject:lp];
                        }
                    }
                }
                
                
                
                
                
                NSString * draggablestr = [diagPalette objectForKey:@"_isDraggable"];
                if(draggablestr == nil){ //Default = true
                    item.isDragable = true;
                }else if([draggablestr isEqualToString:@"true"]){
                    item.isDragable = true;
                }else if([draggablestr isEqualToString:@"false"]){
                    item.isDragable = false;
                }
                
                NSDictionary * containerDic = [dic objectForKey:@"containerReference"];
                NSString * containerReference = [containerDic objectForKey:@"_href"];
                item.containerReference = containerReference;
                
                
                item.dialog = parsedClass;
                
                NSDictionary * nodeShapeDic = [dic objectForKey:@"node_shape"];
                NSNumberFormatter * f = [[NSNumberFormatter alloc] init];
                f.numberStyle = NSNumberFormatterDecimalStyle;
                
                if(nodeShapeDic != nil){
                    NSString * wstr = [nodeShapeDic objectForKey:@"_width"];
                    NSString * hstr = [nodeShapeDic objectForKey:@"_height"];
                    NSString * shapeType = [nodeShapeDic objectForKey:@"_xsi:type"];
                    
                    NSDictionary * colorDic = [nodeShapeDic objectForKey:@"color"];
                    NSString * color = [colorDic objectForKey:@"_name"];
                    
                    //NSString * sizeStr = [nodeShapeDic objectForKey:@"_size"];
                    
                    
                    NSDictionary * borderColorDic = [nodeShapeDic objectForKey:@"borderColor"];
                    NSString * borderColorString = [borderColorDic objectForKey:@"_name"];
                    NSString * borderStyleString = [nodeShapeDic objectForKey:@"_borderStyle"];
                    NSString * borderWidthString = [nodeShapeDic objectForKey:@"_borderWidth"];
                    
                    item.borderColorString = borderColorString;
                    item.borderColor = [ColorPalette colorForString:borderColorString];
                    item.borderWidth = [f numberFromString:borderWidthString];
                    item.borderStyleString = borderStyleString;
                    
                    NSNumber * w = [f numberFromString:wstr];
                    NSNumber * h = [f numberFromString:hstr];
                    
                    float scaledW = w.floatValue * scale;
                    float scaledH = h.floatValue * scale;
                    item.width = [NSNumber numberWithFloat:scaledW];
                    item.height = [NSNumber numberWithFloat:scaledH];
                    
                    /*if(sizeStr != nil){
                     //There is size value, but with and height
                     NSNumber * s = [f numberFromString:sizeStr];
                     float scaledS = s.floatValue * scale;
                     item.width = [NSNumber numberWithFloat:scaledS];
                     item.height = [NSNumber numberWithFloat:scaledS];
                     }else{
                     float scaledW = w.floatValue * scale;
                     float scaledH = h.floatValue * scale;
                     item.width = [NSNumber numberWithFloat:scaledW];
                     item.height = [NSNumber numberWithFloat:scaledH];
                     
                     }*/
                    
                    
                    
                    item.shapeType = shapeType;
                    
                    if(color == nil){
                        item.fillColor = [ColorPalette white];
                        item.colorString = @"white";
                    }else{
                        item.fillColor = [ColorPalette colorForString:color];
                        item.colorString = color;
                    }
                    
                    if(w.floatValue <= 0.0){
                        item.width = [NSNumber numberWithFloat:defaultwidth];
                    }
                    
                    if(h.floatValue <= 0.0){
                        item.height = [NSNumber numberWithFloat:defaultheight];
                    }
                    
                    if([shapeType isEqualToString:@"graphicR:IconElement"]){
                        item.isImage = YES;
                        
                        
                        NSString * base64String = [nodeShapeDic objectForKey:@"_embeddedImage"];
                        NSData * imageData = [[NSData alloc] initWithBase64EncodedString:base64String options:0];
                        
                        UIImage * image = [UIImage imageWithData:imageData];
                        
                        item.image = image;
                    }
                }
                
                
                //Set frame
                if(item.width != nil && item.height != nil){
                    item.frame = CGRectMake(0, 0, item.width.floatValue , item.height.floatValue);
                }else{
                    //Default values
                    item.frame = CGRectMake(0, 0, defaultwidth, defaultheight);
                }
                
                
                if([item.type isEqualToString:@"graphicR:Edge"]){
                    //Extract directions
                    
                    NSDictionary * edgeStyleDic = [dic objectForKey:@"edge_style"];
                    NSString * edgeStyle = [edgeStyleDic objectForKey:@"_color"];
                    NSDictionary * directions = [dic objectForKey:@"directions"];
                    
                    NSString * lineStyle = [edgeStyleDic objectForKey:@"_LineStyle"];
                    NSString * lineWidth = [edgeStyleDic objectForKey:@"_LineWidth"];
                    NSDictionary * colorDic = [edgeStyleDic objectForKey:@"color"];
                    NSString * lineColorName = [colorDic objectForKey:@"_name"];
                    
                    if(lineWidth == nil){
                        item.lineWidth = [NSNumber numberWithFloat:2.0];
                    }else{
                        item.lineWidth = [f numberFromString:lineWidth];
                    }
                    
                    if(lineStyle == nil){
                        item.lineStyle = SOLID;
                    }else{
                        item.lineStyle = lineStyle;
                    }
                    
                    if(lineColorName == nil){
                        item.lineColorNameString = @"black";
                    }else{
                        item.lineColorNameString = lineColorName;
                    }
                    
                    
                    if(lineColorName == nil)
                        item.lineColor = [ColorPalette colorForString:@"black"];
                    else
                        item.lineColor = [ColorPalette colorForString:lineColorName];
                    
                    NSDictionary * sourceDic = [directions objectForKey:@"sourceLink"];
                    NSDictionary * targetDic = [directions objectForKey:@"targetLink"];
                    
                    NSString * sourceDecoName = [[sourceDic objectForKey:@"_decoratorName"] lowercaseString];
                    NSString * targetDecoName = [[targetDic objectForKey:@"_decoratorName"] lowercaseString];
                    
                    NSDictionary * sourRefeDic = [sourceDic objectForKey:@"anEReference"];
                    NSDictionary * targRefeDic = [targetDic objectForKey:@"anEReference"];
                    
                    NSString * sourceReference = [sourRefeDic objectForKey:@"_href"];
                    NSString * targetReference = [targRefeDic objectForKey:@"_href"];
                    //Split by / ang
                    NSArray * sourceRefArray = [sourceReference componentsSeparatedByString:@"/"];
                    NSString * sClass = [sourceRefArray objectAtIndex:sourceRefArray.count-2];
                    NSString *sPart = [sourceRefArray objectAtIndex:sourceRefArray.count-1];
                    
                    NSArray * targetRefArray = [targetReference componentsSeparatedByString:@"/"];
                    NSString * tClass = [targetRefArray objectAtIndex:targetRefArray.count-2];
                    NSString * tPart = [targetRefArray objectAtIndex:targetRefArray.count-1];
                    
                    
                    item.edgeStyle = edgeStyle;
                    item.sourceDecoratorName = sourceDecoName;
                    item.targetDecoratorName = targetDecoName;
                    item.sourceName = sClass;
                    item.targetName = tClass;
                    item.sourcePart = sPart;
                    item.targetPart = tPart;
                    
                    
                }
                
                
                
                //[dele.paletteItems addObject:item];
                [tempPalete.paletteItems addObject:item];
                
                
            }
            
            [tempPalettes addObject:tempPalete];
        }
        
        
        
    }
    return  tempPalettes;

}

-(void)extractPalettesForContentsOfFile: (PaletteFile *) file{
    // [palette resetPalette];
    
    NSLog(@"extractPalettesForContentsOfFile");
    
    [palettes removeAllObjects];
    
    if(palettes == nil){
        palettes = [[NSMutableArray alloc] init];
    }
    
    
    configuration = [NSDictionary dictionaryWithXMLString:file.content];
    
    NSArray * allGraphicRepresentations = (NSArray *)[configuration objectForKey:@"allGraphicRepresentation"];
    
    
    //Por si el fichero tiene un solo "allGraphicrepresentation
    //En ese caso, la llamada a "dictionaryWithXMLString" devuelve un NSDictionary, que añadimos al array
    if([allGraphicRepresentations isKindOfClass:[NSDictionary class]]){
        allGraphicRepresentations = [[NSArray alloc] initWithObjects:[configuration objectForKey:@"allGraphicRepresentation"], nil];
    }
    
    
    
    
    for(int gr = 0; gr < allGraphicRepresentations.count; gr++){
        
        
        NSDictionary * listRepresentations =[[allGraphicRepresentations objectAtIndex:gr]objectForKey:@"listRepresentations"];
        
        NSString * isgeopaletteStr = [[allGraphicRepresentations objectAtIndex:gr]objectForKey:@"_isGeopalette"];
        BOOL isGeopalette = false;
        
        if([isgeopaletteStr isEqualToString:@"true"]){
            isGeopalette = YES;
        }else if([isgeopaletteStr isEqualToString:@"false"]){
            isGeopalette = NO;
        }else{
            isGeopalette = NO;
        }
        
        NSArray * lRArray;
        
        if([listRepresentations isKindOfClass:[NSDictionary class]]){
            lRArray = [[NSArray alloc] initWithObjects:listRepresentations, nil];
        }else{
            lRArray = [[NSArray alloc] init];
        }
        
        
        for(int i = 0; i< lRArray.count; i++){   //Create a temp palette
            Palette * tempPalete = [[Palette alloc] init];
            [tempPalete preparePalette];
            
            NSDictionary * allGraphicRepresentation = [lRArray objectAtIndex:i];
            tempPalete.isGeopalette = isGeopalette;
            
            dele.isGeoPalette = isGeopalette;
            
            //NSString * paletteName = [allGraphicRepresentation objectForKey:@"_extension"];
            //tempPalete.name = paletteName;
            tempPalete.extension = file.extension;
            tempPalete.name = file.name;
            
            
            NSDictionary * layers = [allGraphicRepresentation objectForKey:@"layers"];
            NSArray * elements = [layers objectForKey:@"elements"];
            
            
            for(int i  = 0; i< elements.count; i++){
                
                PaletteItem * item = [[PaletteItem alloc] init];
                
                NSDictionary * dic = [elements objectAtIndex:i];
                NSString * type = [dic objectForKey:@"_xsi:type"];
                
                item.type = type;
                
                NSDictionary * className = [dic objectForKey:@"anEClass"];
                NSString * classStr = [className objectForKey:@"_href"];
                NSArray * arraystr = [classStr componentsSeparatedByString:@"/"];
                NSString * parsedClass = [arraystr objectAtIndex: arraystr.count -1];
                item.className = parsedClass;
                
                NSDictionary * diagPalette = [dic objectForKey:@"diag_palette"];
                NSString * paleteName = [diagPalette objectForKey:@"_palette_name"];
                NSLog(@"\n\ntype: %@     	\n name: %@", type, paleteName);
                
                
                //Is expandable?
                NSString * expandableStr = [dic objectForKey:@"_expandable"];
                BOOL isExpandable = [expandableStr boolValue];
                item.isExpandable = isExpandable;
                
                //In order to get node label
                NSDictionary * nodeElementsDic = [dic objectForKey:@"node_elements"];
                NSArray * labelAnEAttributeArray = [nodeElementsDic objectForKey:@"LabelanEAttribute"];
                
                if([labelAnEAttributeArray isKindOfClass:[NSDictionary class]]){
                    labelAnEAttributeArray = [[NSArray alloc]initWithObjects:labelAnEAttributeArray, nil];
                }
                
                //labelAnEAttributeArray tendrá un array con el o los atributos que serán label
                
                item.labelsAttributesArray = [[NSMutableArray alloc] init];
                
                for(int i = 0; i<labelAnEAttributeArray.count; i++){
                    NSDictionary * labelanEattributeDic = labelAnEAttributeArray[i];
                    NSDictionary * anEattributeDic = [labelanEattributeDic objectForKey:@"anEAttribute"];
                    
                    NSString * labelReference = [anEattributeDic objectForKey:@"_href"];
                    
                    NSString * labelPosition = [labelanEattributeDic objectForKey:@"_labelPosition"];
                    
                    if(labelPosition == nil){
                        labelPosition = @"border";
                    }
                    item.labelPosition = labelPosition;
                    
                    NSArray * parts = [labelReference componentsSeparatedByString:@"/"];
                    NSString * attrName = [parts objectAtIndex:parts.count-1];
                    [item.labelsAttributesArray addObject:attrName];
                }
                
                //Get linkPalette
                NSArray * linkPaletteArray = [nodeElementsDic objectForKey:@"linkPalette"];
                if([linkPaletteArray isKindOfClass:[NSDictionary class]]){
                    linkPaletteArray = [NSArray arrayWithObjects:linkPaletteArray, nil];
                } //linkPaletteArray will hold my connected things
                
                item.linkPaletteDic = [[NSMutableDictionary alloc] init];
                
                for(NSDictionary * lpDic in linkPaletteArray){
                    LinkPalette * lp = [[LinkPalette alloc] init];
                    lp.anDiagramElement = [lpDic objectForKey:@"_anDiagramElement"];
                    lp.paletteName = [lpDic objectForKey:@"_palette_name"];
                    lp.targetDecoratorName = [lpDic objectForKey:@"_decoratorName"];
                    lp.targetDecoratorName = [lp.targetDecoratorName lowercaseString];
                    lp.colorDic = [lpDic objectForKey:@"color"];
                    NSString * sourceDecName = [lpDic objectForKey:@"_sourceDecoratorName"];
                    if(sourceDecName == nil){
                        sourceDecName = NO_DECORATION;
                    }
                    lp.sourceDecoratorName = [sourceDecName lowercaseString];
                    
                    NSDictionary * refDic =[lpDic objectForKey:@"anEReference"];
                    lp.anEReference = [refDic objectForKey:@"_href"];
                    lp.colorDic = [lpDic objectForKey:@"color"];
                    lp.lineStyle = [lpDic objectForKey:@"_LineStyle"];
                    
                    NSArray * classParts = [lp.anEReference componentsSeparatedByString:@"/"];
                    lp.className = [classParts objectAtIndex:classParts.count -2];
                    lp.referenceInClass = [classParts objectAtIndex:classParts.count-1];
                    
                    [item.linkPaletteDic setObject:lp forKey:lp.referenceInClass];
                }
                
                NSArray * expandableItems = [nodeElementsDic objectForKey:@"expandableItems"];
                if([expandableItems isKindOfClass:[NSDictionary class]]){
                    expandableItems = [NSArray arrayWithObjects:expandableItems, nil];
                }
                
                item.expandableItems = [[NSMutableArray alloc] init];
                if(expandableItems.count > 0){
                    item.isExpandable = YES;
                }
                
                for(NSDictionary * expItem in expandableItems){
                    
                    NSDictionary * refDic = [expItem objectForKey:@"anEReference"];
                    NSString * reference = [refDic objectForKey:@"_href"];  //Con esta referencia marco el palete link como expandable
                    
                    NSArray * parts = [reference componentsSeparatedByString:@"/"];
                    NSString * clasSName = [parts objectAtIndex:parts.count-2];
                    NSString * refName = parts[parts.count-1];
                    
                    NSString * indexStr = [expItem objectForKey:@"_index"];
                    if(indexStr == nil){
                        indexStr = @"0";
                    }
                    int index = [indexStr intValue];
                    
                    NSArray * keys = [item.linkPaletteDic allKeys];
                    for(NSString * key in keys){
                        LinkPalette * lp  = [item.linkPaletteDic objectForKey:key];
                        
                        if([lp.className isEqualToString:clasSName] && [lp.referenceInClass isEqualToString:refName]){
                            lp.isExpandableItem = YES;
                            lp.expandableIndex = index;
                            [item.expandableItems addObject:lp];
                        }
                    }
                }
                
                
                
                
                
                NSString * draggablestr = [diagPalette objectForKey:@"_isDraggable"];
                if(draggablestr == nil){ //Default = true
                    item.isDragable = true;
                }else if([draggablestr isEqualToString:@"true"]){
                    item.isDragable = true;
                }else if([draggablestr isEqualToString:@"false"]){
                    item.isDragable = false;
                }
                
                NSDictionary * containerDic = [dic objectForKey:@"containerReference"];
                NSString * containerReference = [containerDic objectForKey:@"_href"];
                item.containerReference = containerReference;
                
                
                item.dialog = parsedClass;
                
                NSDictionary * nodeShapeDic = [dic objectForKey:@"node_shape"];
                NSNumberFormatter * f = [[NSNumberFormatter alloc] init];
                f.numberStyle = NSNumberFormatterDecimalStyle;
                
                if(nodeShapeDic != nil){
                    NSString * wstr = [nodeShapeDic objectForKey:@"_width"];
                    NSString * hstr = [nodeShapeDic objectForKey:@"_height"];
                    NSString * shapeType = [nodeShapeDic objectForKey:@"_xsi:type"];
                    
                    NSDictionary * colorDic = [nodeShapeDic objectForKey:@"color"];
                    NSString * color = [colorDic objectForKey:@"_name"];
                    
                    //NSString * sizeStr = [nodeShapeDic objectForKey:@"_size"];
                    
                    
                    NSDictionary * borderColorDic = [nodeShapeDic objectForKey:@"borderColor"];
                    NSString * borderColorString = [borderColorDic objectForKey:@"_name"];
                    NSString * borderStyleString = [nodeShapeDic objectForKey:@"_borderStyle"];
                    NSString * borderWidthString = [nodeShapeDic objectForKey:@"_borderWidth"];
                    
                    item.borderColorString = borderColorString;
                    item.borderColor = [ColorPalette colorForString:borderColorString];
                    item.borderWidth = [f numberFromString:borderWidthString];
                    item.borderStyleString = borderStyleString;
                    
                    NSNumber * w = [f numberFromString:wstr];
                    NSNumber * h = [f numberFromString:hstr];
                    
                    float scaledW = w.floatValue * scale;
                    float scaledH = h.floatValue * scale;
                    item.width = [NSNumber numberWithFloat:scaledW];
                    item.height = [NSNumber numberWithFloat:scaledH];
                    
                    /*if(sizeStr != nil){
                     //There is size value, but with and height
                     NSNumber * s = [f numberFromString:sizeStr];
                     float scaledS = s.floatValue * scale;
                     item.width = [NSNumber numberWithFloat:scaledS];
                     item.height = [NSNumber numberWithFloat:scaledS];
                     }else{
                     float scaledW = w.floatValue * scale;
                     float scaledH = h.floatValue * scale;
                     item.width = [NSNumber numberWithFloat:scaledW];
                     item.height = [NSNumber numberWithFloat:scaledH];
                     
                     }*/
                    
                    
                    
                    item.shapeType = shapeType;
                    
                    if(color == nil){
                        item.fillColor = [ColorPalette white];
                        item.colorString = @"white";
                    }else{
                        item.fillColor = [ColorPalette colorForString:color];
                        item.colorString = color;
                    }
                    
                    if(w.floatValue <= 0.0){
                        item.width = [NSNumber numberWithFloat:defaultwidth];
                    }
                    
                    if(h.floatValue <= 0.0){
                        item.height = [NSNumber numberWithFloat:defaultheight];
                    }
                    
                    if([shapeType isEqualToString:@"graphicR:IconElement"]){
                        item.isImage = YES;
                        
                        
                        NSString * base64String = [nodeShapeDic objectForKey:@"_embeddedImage"];
                        NSData * imageData = [[NSData alloc] initWithBase64EncodedString:base64String options:0];
                        
                        UIImage * image = [UIImage imageWithData:imageData];
                        
                        item.image = image;
                    }
                }
                
                
                //Set frame
                if(item.width != nil && item.height != nil){
                    item.frame = CGRectMake(0, 0, item.width.floatValue , item.height.floatValue);
                }else{
                    //Default values
                    item.frame = CGRectMake(0, 0, defaultwidth, defaultheight);
                }
                
                
                if([item.type isEqualToString:@"graphicR:Edge"]){
                    //Extract directions
                    
                    NSDictionary * edgeStyleDic = [dic objectForKey:@"edge_style"];
                    NSString * edgeStyle = [edgeStyleDic objectForKey:@"_color"];
                    NSDictionary * directions = [dic objectForKey:@"directions"];
                    
                    NSString * lineStyle = [edgeStyleDic objectForKey:@"_LineStyle"];
                    NSString * lineWidth = [edgeStyleDic objectForKey:@"_LineWidth"];
                    NSDictionary * colorDic = [edgeStyleDic objectForKey:@"color"];
                    NSString * lineColorName = [colorDic objectForKey:@"_name"];
                    
                    if(lineWidth == nil){
                        item.lineWidth = [NSNumber numberWithFloat:2.0];
                    }else{
                        item.lineWidth = [f numberFromString:lineWidth];
                    }
                    
                    if(lineStyle == nil){
                        item.lineStyle = SOLID;
                    }else{
                        item.lineStyle = lineStyle;
                    }
                    
                    if(lineColorName == nil){
                        item.lineColorNameString = @"black";
                    }else{
                        item.lineColorNameString = lineColorName;
                    }
                    
                    
                    if(lineColorName == nil)
                        item.lineColor = [ColorPalette colorForString:@"black"];
                    else
                        item.lineColor = [ColorPalette colorForString:lineColorName];
                    
                    NSDictionary * sourceDic = [directions objectForKey:@"sourceLink"];
                    NSDictionary * targetDic = [directions objectForKey:@"targetLink"];
                    
                    NSString * sourceDecoName = [[sourceDic objectForKey:@"_decoratorName"] lowercaseString];
                    NSString * targetDecoName = [[targetDic objectForKey:@"_decoratorName"] lowercaseString];
                    
                    NSDictionary * sourRefeDic = [sourceDic objectForKey:@"anEReference"];
                    NSDictionary * targRefeDic = [targetDic objectForKey:@"anEReference"];
                    
                    NSString * sourceReference = [sourRefeDic objectForKey:@"_href"];
                    NSString * targetReference = [targRefeDic objectForKey:@"_href"];
                    //Split by / ang
                    NSArray * sourceRefArray = [sourceReference componentsSeparatedByString:@"/"];
                    NSString * sClass = [sourceRefArray objectAtIndex:sourceRefArray.count-2];
                    NSString *sPart = [sourceRefArray objectAtIndex:sourceRefArray.count-1];
                    
                    NSArray * targetRefArray = [targetReference componentsSeparatedByString:@"/"];
                    NSString * tClass = [targetRefArray objectAtIndex:targetRefArray.count-2];
                    NSString * tPart = [targetRefArray objectAtIndex:targetRefArray.count-1];
                    
                    
                    item.edgeStyle = edgeStyle;
                    item.sourceDecoratorName = sourceDecoName;
                    item.targetDecoratorName = targetDecoName;
                    item.sourceName = sClass;
                    item.targetName = tClass;
                    item.sourcePart = sPart;
                    item.targetPart = tPart;
                    
                    
                }
                
                
                
                //[dele.paletteItems addObject:item];
                [tempPalete.paletteItems addObject:item];
                
                
            }
            
            [palettes addObject:tempPalete];
        }
        
        
        
    }
    
    
    [palettesTable reloadData];
    
    //[palette preparePalette];
    
    
    if(palettes.count == 0){
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@""
                                                        message:@"This palette doesn't have items"
                                                       delegate:self
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
    }
    
}

#pragma mark UIGesture recognizer methods

-(void)addRecognizers{
    //Add longPressGestureRecognizer in order to show palette dialog
    for(int i = 0; i<palette.paletteItems.count; i++){
        PaletteItem * item = [palette.paletteItems objectAtIndex:i];
        UILongPressGestureRecognizer * gr = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
        gr.delegate = self;
        gr.minimumPressDuration = 0.0;
        [item addGestureRecognizer:gr];
    }
    
}

-(void)handleLongPress:(UILongPressGestureRecognizer *)gesture{
    PaletteItem * owner = (PaletteItem *)gesture.view;
    
    CGPoint p = [gesture locationInView:self.view];
    
    //NSLog(@"%@",[NSString stringWithFormat:@"(%.2f,%.2f)", p.x, p.y]);
    
    
    if(gesture.state == UIGestureRecognizerStateBegan){
        [infoView setCenter:CGPointMake(p.x, p.y -70)];
        infoLabel.text = owner.dialog;
        
    }else if(gesture.state == UIGestureRecognizerStateEnded){
        infoLabel.text = @"";
        [infoView setHidden:YES];
    }else if(gesture.state == UIGestureRecognizerStateChanged){
        [infoView setHidden:NO];
        [infoView setCenter:CGPointMake(p.x, p.y-70)];
        
    }
}


#pragma mark Did receive memory warning
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark Show editor
- (IBAction)showEditor:(id)sender {
    
    if(palette.paletteItems.count != 0){
        dele.paletteItems = [[NSMutableArray alloc] initWithArray:palette.paletteItems];
        [refreshTimer invalidate];
        
        dele.paletteView = palette;
        dele.paletteH= palette.frame.size.height;
        dele.paletteW = palette.frame.size.width;
        
        UIView * spinnerView = [[UIView alloc] initWithFrame:self.view.frame];
        spinnerView.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.5];
        UIActivityIndicatorView * spinner = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(0,
                                                                                                      0,
                                                                                                      30, 30)];
        [spinner setCenter:spinnerView.center];
        [spinnerView addSubview:spinner];
        [spinner startAnimating];
        
        [self.view addSubview:spinnerView];
        
        BOOL result = [self completePaletteForJSONAttributes];
        
        if(result == YES){
            dele.currentPaletteFile = tempPaletteFile;
            
            [searchSessionsOutlet setOn:NO];
            [dele.manager stopAdvertising];
            
            
            [spinnerView removeFromSuperview];
            
            //Finish ConfigureView tutorial
            doingTutorial = NO;
            
            [blurEffectView removeFromSuperview];
            [dele.tutSheet removeFromSuperview];
            
            [[NSUserDefaults standardUserDefaults] setObject:@"done" forKey:@"configureTutorialStatus"];
            dele.shouldShowConfigureTutorial = NO;
            
            [self performSegueWithIdentifier:@"showEditor" sender:self];
        }else{
            
            [spinnerView removeFromSuperview];
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                            message:@"Json is not accesible"
                                                           delegate:self
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
            [alert show];
        }
        
        
    }else{
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                        message:@"Any palette must be selected in order to perform this action."
                                                       delegate:self
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
        
    }
    
    //This is done for that we will not be able to receive invitations if we are on editor
    [searchSessionsOutlet setOn:NO];
    [dele.manager stopAdvertising];
}




#pragma mark UItableView delegate methods

-(void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Remove seperator inset
    if ([cell respondsToSelector:@selector(setSeparatorInset:)]) {
        [cell setSeparatorInset:UIEdgeInsetsZero];
    }
    
    // Prevent the cell from inheriting the Table View's margin settings
    if ([cell respondsToSelector:@selector(setPreservesSuperviewLayoutMargins:)]) {
        [cell setPreservesSuperviewLayoutMargins:NO];
    }
    
    // Explictly set your cell's layout margins
    if ([cell respondsToSelector:@selector(setLayoutMargins:)]) {
        [cell setLayoutMargins:UIEdgeInsetsZero];
    }
}


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if(tableView == filesTable){
        return 2; //One for local files and one for server files
    }else if(tableView == palettesTable){
        return 1;
    }else
        return 0;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    
    localPalettes = [[NSMutableArray alloc] init];
    serverPalettes = [[NSMutableArray alloc] init];
    
    for(PaletteFile * pf in filesArray){
        if(pf.fromServer == YES){
            [serverPalettes addObject:pf];
        }else{
            [localPalettes addObject:pf];
        }
    }
    
    if(tableView == palettesTable)
        return [palettes count];
    else if(tableView == filesTable){
        //return [filesArray count];
        if(section == 0){ //Local palettes
            return localPalettes.count;
        }else{ //Server palettes
            return serverPalettes.count;
        }
    }
    else
        return 0;
}



- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *MyIdentifier = @"MyIdentifier";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:MyIdentifier];
    
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                      reuseIdentifier:MyIdentifier] ;
    }
    
    [cell setLayoutMargins:UIEdgeInsetsZero];
    
    if(tableView == palettesTable){
        
        Palette * temp = [palettes objectAtIndex:indexPath.row];
        cell.textLabel.text = temp.name;
    }else if(tableView == filesTable){
        
        PaletteFile * pf = nil;
        UIImage * image = nil;
        if(indexPath.section == 0){ //Local palettes
            pf = [localPalettes objectAtIndex:indexPath.row];
            image = [UIImage imageNamed:@"localFilled"];
            NSArray * array = [pf.name componentsSeparatedByString:@"."];
            cell.textLabel.text = array[0];
            cell.accessoryView = [[ UIImageView alloc ] initWithImage:image];
            [cell.accessoryView setFrame:CGRectMake(0, 0, 20, 20)];
        }else if(indexPath.section == 1){ //Server palettes
            pf = [serverPalettes objectAtIndex:indexPath.row];
            image = [UIImage imageNamed:@"cloudFilled"];
            NSArray * array = [pf.name componentsSeparatedByString:@"."];
            cell.textLabel.text = array[0];
            cell.accessoryView = [[ UIImageView alloc ] initWithImage:image];
            [cell.accessoryView setFrame:CGRectMake(0, 0, 20, 20)];
        }
        /*
         UIImage * image ;
         
         
         PaletteFile * pf = [filesArray objectAtIndex:indexPath.row];
         
         if(pf.fromServer == true){
         image = [UIImage imageNamed:@"cloudFilled"];
         }else{
         image = [UIImage imageNamed:@"localFilled"];
         }
         
         NSArray * array = [pf.name componentsSeparatedByString:@"."];
         cell.textLabel.text = array[0];
         cell.accessoryView = [[ UIImageView alloc ] initWithImage:image];
         [cell.accessoryView setFrame:CGRectMake(0, 0, 20, 20)];*/
        
    }
    
    cell.backgroundColor = [UIColor clearColor];
    cell.textLabel.adjustsFontSizeToFitWidth = YES;
    [cell.textLabel setMinimumScaleFactor:7.0/[UIFont labelFontSize]];
    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    
    if(tableView == palettesTable){
        
        [palette resetPalette];
        Palette * selected = [palettes objectAtIndex:indexPath.row];
        //[selected setFrame:palette.frame];
        palette.paletteItems = selected.paletteItems;
        
        dele.subPalette = selected.name;
        
        dele.paletteExtension = selected.extension;
        
        
        [palette setHidden:NO];
        [palette setAlpha:0];
        
        [paletteFileGroup setHidden:YES];
        //Muestro el palette
        [UIView animateWithDuration:1.0
                              delay:0.0
                            options:UIViewAnimationOptionCurveEaseOut
                         animations:^{
                             selected.center = palette.center;
                             [palette setAlpha:1.0];
                             
                         }
                         completion:^(BOOL finished) {
                             
                         }];
        
        
        [palette preparePalette];
        [confirmButton setHidden:NO];
        
        
        if(doingTutorial == YES){
            [self.view bringSubviewToFront:dele.tutSheet];
            [dele.tutSheet.textView setText:@"Now you can preview the subpalette at the bottom of the screen.\n"
             "You can go back to palette selection by tapping the left arrow"
             "Tap the \"Go\" button when you are ready"];
            
            //CGFloat fixedWidth = dele.tutSheet.textView.frame.size.width + 40;
            CGFloat fixedWidth = 150;
            CGSize newSize = [dele.tutSheet.textView sizeThatFits:CGSizeMake(fixedWidth, MAXFLOAT)];
            [dele.tutSheet setFrame:CGRectMake(self.view.frame.size.width - 2*newSize.width,
                                               self.view.frame.size.height /2 - newSize.height/2,
                                               dele.tutSheet.frame.size.width,
                                               newSize.height)];
            
            [self.view bringSubviewToFront:palette];
            [self.view bringSubviewToFront:confirmButton];
        }
        
        
        
    }else if(tableView == filesTable){
        
        //[palette resetPalette];
        PaletteFile * file = nil;
        if(indexPath.section == 0){ //Local palettes
            file = [localPalettes objectAtIndex:indexPath.row];
        }else{ //server palettes
            file = [serverPalettes objectAtIndex:indexPath.row];
        }
        [filesArray objectAtIndex:indexPath.row];
        tempPaletteFile = file;
        
        dele.graphicRContent = file.content;
        
        tempPaletteFile = file;
        
        [subPaletteGroup setHidden:NO];
        
        [subPaletteGroup setCenter:CGPointMake(self.view.frame.size.width + subPaletteGroup.frame.size.width, self.view.center.y)];
        oldSubPaletteGroupFrame = subPaletteGroup.frame;
        
        oldPaletteFileGroupFrame = paletteFileGroup.frame;
        
        [cancelSubpaletteSelectionOutlet setHidden:NO];
        [cancelSubpaletteSelectionOutlet setAlpha:0];
        
        
        [UIView animateWithDuration:0.5
                              delay:0.0
                            options:UIViewAnimationOptionCurveEaseOut
                         animations:^{
                             //[sender.view setCenter:newCenter];
                             [subPaletteGroup setCenter:self.view.center];
                             [paletteFileGroup setFrame:CGRectMake(0-paletteFileGroup.frame.size.width, 0, paletteFileGroup.frame.size.width, paletteFileGroup.frame.size.height)];
                             outCenterForFileGroup = paletteFileGroup.center;
                         }
                         completion:^(BOOL finished) {
                             
                             
                             [UIView animateWithDuration:0.2
                                                   delay:0.0
                                                 options:UIViewAnimationOptionCurveEaseOut
                                              animations:^{
                                                  [cancelSubpaletteSelectionOutlet setAlpha:1.0];
                                                  
                                              }
                                              completion:^(BOOL finished) {
                                                  [self extractPalettesForContentsOfFile:file];
                                                  
                                                  
                                                  if(doingTutorial == YES){
                                                      [dele.tutSheet setFrame:CGRectMake(dele.tutSheet.frame.origin.x,
                                                                                         0,
                                                                                         dele.tutSheet.frame.size.width,
                                                                                         70)];
                                                      [dele.tutSheet.textView setText:@"Select a subpalette..."];
                                                      
                                                      CGFloat fixedWidth = dele.tutSheet.textView.frame.size.width;
                                                      CGSize newSize = [dele.tutSheet.textView sizeThatFits:CGSizeMake(fixedWidth, MAXFLOAT)];
                                                      
                                                      [dele.tutSheet setFrame:CGRectMake(dele.tutSheet.frame.origin.x,
                                                                                         dele.tutSheet.frame.origin.y,
                                                                                         dele.tutSheet.frame.size.width,
                                                                                         newSize.height)];
                                                      [self.view addSubview:dele.tutSheet];
                                                      [self.view sendSubviewToBack:paletteFileGroup];
                                                      [self.view bringSubviewToFront:subPaletteGroup];
                                                      
                                                  }
                                                  
                                              }];
                         }];
        
        
    }
    
}


- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    //Obviously, if this returns no, the edit option won't even populate
    if(tableView == filesTable)
        return YES;
    else
        return NO;
}


- (void)tableView:(UITableView *)tableView
commitEditingStyle:(UITableViewCellEditingStyle)editingStyle
forRowAtIndexPath:(NSIndexPath *)indexPath {
    //Nothing gets called here if you invoke `tableView:editActionsForRowAtIndexPath:` according to Apple docs so just leave this method blank
}


- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    
    UILabel *myLabel = [[UILabel alloc] init];
    
    myLabel.frame = CGRectMake(0, 0, tableView.frame.size.width, 25);
    myLabel.font = [UIFont boldSystemFontOfSize:16];
    myLabel.text = [self tableView:tableView titleForHeaderInSection:section];
    myLabel.textColor = dele.blue1;
    myLabel.textAlignment = NSTextAlignmentCenter;
    myLabel.backgroundColor = dele.blue4;
    
    UIView *headerView = [[UIView alloc] init];
    [headerView addSubview:myLabel];
    
    return headerView;
    
    
}

-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section{
    if(tableView == filesTable){
        if(section == 0){
            return @"Local palettes";
        }else{
            return @"Palettes from server";
        }
    }else{
        return @"Subpalettes";
    }
}

-(NSArray *)tableView:(UITableView *)tableView
editActionsForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if(indexPath.section == 0){ //Local files
        //PaletteFile * pf = [localPalettes objectAtIndex:indexPath.row];
        UITableViewRowAction *remove = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleDestructive
                                                                          title:@"Delete"
                                                                        handler:^(UITableViewRowAction *action, NSIndexPath *indexPath)
                                        {
                                            [self removeFileAtIndexPath:indexPath];
                                        }];
        return @[remove];
    }else if(indexPath.section == 1){ //server files
        //PaletteFile * pf = [serverPalettes objectAtIndex:indexPath.row];
        UITableViewRowAction *download = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleDefault
                                                                            title:@"Download"
                                                                          handler:^(UITableViewRowAction *action, NSIndexPath *indexPath)
                                          {
                                              download.backgroundColor = dele.blue1;
                                              [self downloadFileAtIndexPath:indexPath];
                                          }];
        download.backgroundColor = dele.blue1;
        
        return @[download];
        
    }else{
        return nil;
    }
    
}

-(void)downloadFileAtIndexPath:(NSIndexPath *)ip{
    
    PaletteFile * pf = filesArray[ip.row];
    
    NSError * error = nil;
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0]; // Get documents folder
    NSString *palettePath = [documentsDirectory stringByAppendingPathComponent:@"/Palettes"];
    
    NSString * fileName = [NSString stringWithFormat:@"%@/%@", palettePath, pf.name];
    
    
    //NSString * beautyContent = [pf.content stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""];
    NSMutableDictionary * dic = [[NSMutableDictionary alloc] init];
    [dic setObject:pf.content forKey:@"content"];
    [dic setObject:pf.ecoreURI forKey:@"ecoreURI"];
    
    
    
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dic
                                                       options:NSJSONWritingPrettyPrinted // Pass 0 if you don't care about the readability of the generated string
                                                         error:&error];

    NSString *text = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    
    
    
    [text writeToFile:fileName
                 atomically:NO
                   encoding:NSStringEncodingConversionAllowLossy
                      error:&error];
    
    if(error != nil){
        NSLog(@"%@", [error localizedDescription]);
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                        message:@"There was a problem downloading file"
                                                       delegate:self
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
    }else{
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Info"
                                                        message:@"The palette has been download"
                                                       delegate:self
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self loadLocalFiles];
    });
    
    
    //Download Json with this uri
    NSString * jsonContent = [self searchJSONonServer:pf.ecoreURI];
    NSError * jsonError = nil;
    
    if(jsonContent == nil){
        NSLog(@"Json was not found on server");
    }else{
        NSLog(@"Json was found on server. Let's save it");
        NSString * jsonPath = [documentsDirectory stringByAppendingPathComponent:@"/Jsons"];
        
        //Save json with the ecore URI
        NSString * jsonName = [NSString stringWithFormat:@"%@/%@", jsonPath, pf.ecoreURI];
        [jsonContent writeToFile:jsonName
                      atomically:NO
                        encoding:NSStringEncodingConversionAllowLossy
                           error:&jsonError];
        
        if(jsonError == nil){
            NSLog(@"json was properly saved");
        }else{
            NSLog(@"Error downloading the json");
        }
        
    }
    
}

-(void)removeFileAtIndexPath:(NSIndexPath *)ip{
    PaletteFile * pf = filesArray[ip.row];
    
    NSError * error = nil;
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0]; // Get documents folder
    NSString *palettePath = [documentsDirectory stringByAppendingPathComponent:@"/Palettes"];
    
    NSString * fileName = [NSString stringWithFormat:@"%@/%@", palettePath, pf.name];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL success = [fileManager removeItemAtPath:fileName error:&error];
    if (success) {
        UIAlertView *removedSuccessFullyAlert = [[UIAlertView alloc] initWithTitle:@"Congratulations:"
                                                                           message:@"Successfully removed"
                                                                          delegate:self
                                                                 cancelButtonTitle:@"Ok"
                                                                 otherButtonTitles:nil];
        [removedSuccessFullyAlert show];
    }
    else
    {
        UIAlertView *removedSuccessFullyAlert = [[UIAlertView alloc] initWithTitle:@"Error:"
                                                                           message:@"Palette was not removed"
                                                                          delegate:self
                                                                 cancelButtonTitle:@"Ok"
                                                                 otherButtonTitles:nil];
        [removedSuccessFullyAlert show];
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        [self loadLocalFiles];
    });
    
    NSError * jsonError;
    NSString * jsonPath = [documentsDirectory stringByAppendingPathComponent:@"/Jsons"];
    NSString * jsonName = [NSString stringWithFormat:@"%@/%@", jsonPath, pf.name];
    BOOL jsonSuccess = [fileManager removeItemAtPath:jsonName error:&jsonError];
    
    if (jsonSuccess) {
        NSLog(@"Json %@ removed", pf.name);
    }
    else
    {
        NSLog(@"Error removing json");
    }
    //Remove json
}

#pragma mark ShowOptions popup


-(void)showOptionsPopup{
    
    UIAlertController * ac  = [UIAlertController alertControllerWithTitle:nil
                                                                  message:nil
                                                           preferredStyle:UIAlertControllerStyleActionSheet];
    
    
    
    UIAlertAction * loadFromServer = [UIAlertAction actionWithTitle:@"Load from server"
                                                              style:UIAlertActionStyleDefault
                                                            handler:^(UIAlertAction * _Nonnull action) {
                                                                CloudDiagramsExplorer * cde = [[[NSBundle mainBundle]loadNibNamed:@"CloudDiagramsExplorer"
                                                                                                                            owner:self
                                                                                                                          options:nil]objectAtIndex:0];
                                                                [cde setFrame:self.view.frame];
                                                                cde.delegate = self;
                                                                [self.view addSubview:cde];
                                                            }];
    
    UIAlertAction * pasteFromText = [UIAlertAction actionWithTitle:@"Paste from text"
                                                             style:UIAlertActionStyleDefault
                                                           handler:^(UIAlertAction * _Nonnull action) {
                                                               
                                                               
                                                               rootView = [[[NSBundle mainBundle] loadNibNamed:@"PasteView"
                                                                                                         owner:self
                                                                                                       options:nil] objectAtIndex:0];
                                                               
                                                               [rootView setFrame:self.view.frame];
                                                               
                                                               [rootView.background setFrame:self.view.frame];
                                                               
                                                               [rootView setDelegate:self];
                                                               [rootView.background setCenter:self.view.center];
                                                               [self.view addSubview:rootView];
                                                               
                                                           }];
    UIAlertAction * loadFromLocal = [UIAlertAction actionWithTitle:@"Load a local file"
                                                             style:UIAlertActionStyleDefault
                                                           handler:^(UIAlertAction * _Nonnull action) {
                                                               ExploreFilesView * efv = [[[NSBundle mainBundle] loadNibNamed:@"ExploreFilesView"
                                                                                                                       owner:self
                                                                                                                     options:nil] objectAtIndex:0];
                                                               [efv setFrame:self.view.frame];
                                                               [efv.background setFrame:self.view.frame];
                                                               efv.delegate = self;
                                                               
                                                               [self.view addSubview:efv];
                                                               
                                                           }];
    
    UIAlertAction * cancel = [UIAlertAction actionWithTitle:@"Cancel"
                                                      style:UIAlertActionStyleCancel
                                                    handler:^(UIAlertAction * _Nonnull action) {
                                                        
                                                    }];
    
    [ac addAction:loadFromServer];
    [ac addAction:loadFromLocal];
    //[ac addAction:pasteFromText];
    [ac addAction:cancel];
    
    
    UIPopoverPresentationController * popover = ac.popoverPresentationController;
    if(popover){
        
        popover.sourceView = confirmButton;
        popover.permittedArrowDirections = UIPopoverArrowDirectionAny;
    }
    
    [self presentViewController:ac animated:YES completion:nil];
}


- (IBAction)openOldDiagram:(id)sender {
    [self showOptionsPopup];
}


#pragma mark PasteViewDelegate

-(void)saveTextFromPasteView: (PasteView *) pasteView{
    NSString * text = [pasteView.textview text];
    
    //Open diagram with that text
    
    //We need palette name
    
    
    //Do we have JSON for this old diagram?
    NSString * paletteFile = [self extractPaletteNameFromXMLDiagram:text];
    NSArray * parts = [paletteFile componentsSeparatedByString:@"."];
    tempPaletteFile = parts[0];
    
    
    //TODO: Recover json for this palette
    
    [self parseXMLDiagramWithText:text ];
}


#pragma mark Parse exported json / ecore
-(BOOL)completePaletteForJSONAttributes{
    //dele.paletteIttems
    //Para cada item de la paleta, tendré que rellenar el array de atributos
    PaletteItem * pi = nil;

    //Pasamos el json a un nsdictionary
    
    
    NSString * jsonString = [self searchJsonNamed:tempPaletteFile.ecoreURI];
    
    if(jsonString == nil){
        NSLog(@"Error, we don't have the Json");
        return NO;
    }else{ //We have the json :)
        NSError *jsonError;
        
        //JsonDic es el fichero JSON (ecore)
        NSMutableDictionary *jsonDict = [NSJSONSerialization
                                         JSONObjectWithData:[jsonString dataUsingEncoding:NSUTF8StringEncoding]
                                         options:NSJSONReadingMutableContainers
                                         error:&jsonError];
        
        NSArray * classes = [jsonDict objectForKey:@"classes"];
        
        
        //Para cada item de la paleta, vamos a obtener sus atributos y sus referencias
        for(int i = 0; i< dele.paletteItems.count; i++){
            pi = [dele.paletteItems objectAtIndex:i];
            //pi.className tendrá el nombre de la clase
            
            pi.attributes = [[NSMutableArray alloc] init];
            pi.references = [[NSMutableArray alloc] init];
            pi.parentsClassArray = [[NSMutableArray alloc] init];
            
            
            [self getAttributesForClass:pi.className
                           onClassArray:classes
                 storeOnAttributesArray:pi.attributes
                     andReferencesArray:pi.references];
            
            
            //Tengo los atributos y las referencias para cada clase.
            
            //Extraemos las clases padre
            [self getParentsForClass:pi.className
                        onClassArray:classes
             storeOnParentClassArray:pi.parentsClassArray];
            
            //Para cada clase padre añadimos las referencias correspondientes
            
            /*for(NSString * str in pi.parentsClassArray){
             //str tendrá el nombre de la clase padre
             [self getAttributesForClass:str
             onClassArray:classes
             storeOnAttributesArray:pi.attributes
             andReferencesArray:pi.references];
             }*/
            
            
            //Marcamos los atributos si procede como label
            for(int i = 0; i< pi.attributes.count; i++){
                ClassAttribute * temp = pi.attributes[i];
                if([pi.labelsAttributesArray containsObject:temp.name]){ //EL nombre de este atributo está entre los marcados como label
                    temp.isLabel = YES;
                }
            }
            
            
            
        }
        
        
        dele.noVisibleItems = [[NSMutableArray alloc] init];
        //Load no visible elements
        for(NSDictionary * classDic in classes){
            
            NSString * name = [classDic objectForKey:@"name"];
            
            //Check if I don't have a palette item with this name
            BOOL exists = false;
            for(PaletteItem * pi in dele.paletteItems){
                NSString * piClass = pi.className;
                if([piClass isEqualToString:name]){
                    exists = true;
                    break;
                }
            }
            
            if(exists == false){ //There is no palette item with this class name, add it
                BOOL isAbstract = [[classDic objectForKey:@"abstract"]boolValue];
                
                PaletteItem * pi = [[PaletteItem alloc] init];
                
                pi.className = name;
                
                
                pi.attributes = [[NSMutableArray alloc] init];
                pi.references = [[NSMutableArray alloc] init];
                pi.parentsClassArray = [[NSMutableArray alloc] init];
                
                
                [self getAttributesForClass:pi.className
                               onClassArray:classes
                     storeOnAttributesArray:pi.attributes
                         andReferencesArray:pi.references];
                
                
                //Tengo los atributos y las referencias para cada clase.
                
                //Extraemos las clases padre
                [self getParentsForClass:pi.className
                            onClassArray:classes
                 storeOnParentClassArray:pi.parentsClassArray];
                
                
                
                //Marcamos los atributos si procede como label
                for(int i = 0; i< pi.attributes.count; i++){
                    ClassAttribute * temp = pi.attributes[i];
                    if([pi.labelsAttributesArray containsObject:temp.name]){ //EL nombre de este atributo está entre los marcados como label
                        temp.isLabel = YES;
                    }
                }
                
                [dele.noVisibleItems addObject:pi];
            }
            
            
        }
        
        
        //so we have the JSON, let's get associated ecore
        
        NSString * ecoreContent = [self getEcoreNamed:tempPaletteFile.ecoreURI];
        
        dele.ecoreContent = ecoreContent;
        
        
        //Parse enums
        dele.enumsDic = [[NSMutableDictionary alloc] init];
        
        NSArray * enums = [jsonDict objectForKey:@"enums"];
          dele.enumsDic = [[NSMutableDictionary alloc] init];
        
        if([enums isKindOfClass:[NSDictionary class]]){
            enums = [NSArray arrayWithObject:enums];
        }
        
        for(int i = 0; i< enums.count; i++){
            NSDictionary * temp = [enums objectAtIndex:i];
            NSString * name = [temp objectForKey:@"name"];
            NSArray * values = [temp objectForKey:@"values"];
            
            [dele.enumsDic setObject:values forKey:name];
        }
        
        return YES;
    }
    
    
    return NO;
    
    
}

-(void)getParentsForClass: (NSString *) key
             onClassArray: (NSArray * ) classArray
  storeOnParentClassArray: (NSMutableArray *) parents{
    
    NSDictionary * dic = nil;
    NSString * name ;
    
    for(int i = 0; i< classArray.count; i++){
        name = nil;
        dic = [classArray objectAtIndex:i];
        name = [dic objectForKey:@"name"];
        
        NSMutableArray * superClassToProcess = [[NSMutableArray alloc] init];
        
        if([name isEqualToString:key]){ //Fill me
            
            NSDictionary * hasParentDic = dic;
            NSArray * itsParents = [hasParentDic objectForKey:@"parents"];
            for(int p = 0; p< itsParents.count; p++){
                [superClassToProcess addObject: itsParents[p]];
            }
            while(superClassToProcess.count != 0) {
                
                NSString * nextToControl = [superClassToProcess objectAtIndex:0];
                [superClassToProcess removeObjectAtIndex:0];
                
                [parents addObject:nextToControl];
                
                for(int c = 0; c<classArray.count; c++){
                    NSDictionary * thisDic = [classArray objectAtIndex:c];
                    NSString * thisName = [thisDic objectForKey:@"name"];
                    if([thisName isEqualToString:nextToControl]){
                        NSArray * ps = [thisDic objectForKey:@"parents"];
                        for(NSString * otherP in ps){
                            [superClassToProcess addObject:otherP];
                        }
                    }
                }
                //add itsParents
                /*for(int p = 0; p< itsParents.count; p++){
                 if(![superClassToProcess containsObject:itsParents[p]])
                 [superClassToProcess addObject:itsParents[p]];
                 }*/
                
            }
        }
    }
    
    /* NSDictionary * dic = nil;
     NSString * name;
     
     NSNumberFormatter *f = [[NSNumberFormatter alloc] init];
     f.numberStyle = NSNumberFormatterDecimalStyle;
     
     for(int i = 0; i< classArray.count; i++){
     name = nil;
     dic = [classArray objectAtIndex:i];
     name = [dic objectForKey:@"name"];
     NSArray * thisParents = [dic objectForKey:@"parents"];
     
     if([name isEqualToString:key]){
     NSArray * pars = [dic objectForKey:@"parents"];
     
     if(pars.count != 0){
     
     for(NSString * str in pars){
     [parents addObject:str];
     }
     }
     }
     }*/
    //TODO: Recursive
}

-(void)getAttributesForClass: (NSString *) key
                onClassArray: (NSArray *)classArray
      storeOnAttributesArray:(NSMutableArray *)attrsArray
          andReferencesArray:(NSMutableArray *)refsArray{
    ClassAttribute * temp;
    
    NSDictionary * dic = nil;
    NSString * name;
    
    NSNumberFormatter *f = [[NSNumberFormatter alloc] init];
    f.numberStyle = NSNumberFormatterDecimalStyle;
    
    //NSMutableArray * attributes = [[NSMutableArray alloc] init];
    
    
    for(int i = 0; i< classArray.count; i++){
        name = nil;
        dic = [classArray objectAtIndex:i];
        name = [dic objectForKey:@"name"];
        
        if([name isEqualToString:key]){
            
            
            //Sacamos los atributos
            NSArray * attrs = [dic objectForKey:@"attributes"];
            for(int a = 0; a < attrs.count; a++){
                NSDictionary * atrDic = [attrs objectAtIndex:a];
                temp = [[ClassAttribute alloc]init];
                temp.name = [atrDic objectForKey:@"name"];
                temp.type = [atrDic objectForKey:@"type"];
                temp.min = [f numberFromString:[atrDic objectForKey:@"min"]];
                temp.max = [f numberFromString:[atrDic objectForKey:@"max"]];
                temp.defaultValue = [atrDic objectForKey:@"default"];
                if([temp.defaultValue isEqualToString:@"null"]){
                    temp.defaultValue = @"";
                }
                
                [attrsArray addObject:temp];
            }
            
            
            
            //Sacamos las references
            NSArray * refs = [dic objectForKey:@"references"];
            for(int a = 0; a < refs.count; a++){
                NSDictionary * rdic = [refs objectAtIndex:a];
                Reference * ref = [[Reference alloc]init];
                ref.name = [rdic objectForKey:@"name"];
                NSString * maxstr = [rdic objectForKey:@"max"];
                if([maxstr isEqualToString:@"-1"]){
                    ref.max = [NSNumber numberWithInt:-1];
                }else{
                    ref.max = [f numberFromString:maxstr];
                }
                
                if([[rdic objectForKey:@"min"] isEqualToString:@""]){
                    ref.min = [NSNumber numberWithInt:-1];
                }else{
                    ref.min = [f numberFromString:[rdic objectForKey:@"min"]];
                }
                
                ref.containment = [[rdic objectForKey:@"containment"]boolValue];
                ref.target = [rdic objectForKey:@"target"];
                ref.opposite = [rdic objectForKey:@"opposite"];
                
                [refsArray addObject: ref];
            }
            
            
        }
    }
    
}

-(void)parseXMLDiagram: (NSString *)text{
    
}

-(void)parseJSONDiagram: (NSString *)text{
    
}

#pragma mark ExploreFilesView delegate
-(void)reactToFile:(NSString *)path{
    
    //Tenemos el fichero del diagrama
    
    //NSLog(path);
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    
    NSString * finalPath = [documentsDirectory stringByAppendingString:@"/diagrams/"];
    finalPath = [finalPath stringByAppendingString:path];
    
    NSError * error = nil;
    
    NSString * jsonString = [NSString stringWithContentsOfFile:finalPath
                                        encoding:NSUTF8StringEncoding
                                           error:&error];
    
    NSError * jsonError;
    NSData *objectData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *json = [NSJSONSerialization JSONObjectWithData:objectData
                                                         options:NSJSONReadingMutableContainers
                                                           error:&jsonError];
    
    dele.loadingADiagram = YES;
    
    
    
    
    //Do we have JSON for this old diagram?
    //TODO: Get palette with this extension
    //NSString * paletteFile = [self extractPaletteNameFromXMLDiagram:[json objectForKey:@"content"]];
    dele.paletteExtension = [json objectForKey:@"paletteExtension"];
    tempPaletteFile  = [self paletteWithExtension:dele.paletteExtension];
    //NSArray * parts = [paletteFile. componentsSeparatedByString:@"."];
    //tempPaletteFile = parts[0];
    
    NSString * c = [json objectForKey:@"content"];
    
    //TODO: Recover json for this palette
    
    [self parseXMLDiagramWithText:c];
    
    
    
}


-(PaletteFile *)paletteWithExtension:(NSString *)ext{
    
    for(PaletteFile * p in localPalettes){
        if([p.extension isEqualToString:ext]){
            return p;
        }
    }
    
    for(PaletteFile * p in serverPalettes){
        if([p.extension isEqualToString:ext]){
            return p;
        }
    }
    
    return nil;
}



#pragma mark UIViewController
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Make sure your segue name in storyboard is the same as this line
    if ([[segue identifier] isEqualToString:@"showEditor"])
    {
        // Get reference to the destination view controller
        //EditorViewController *vc = [segue destinationViewController];
        
    }
}


#pragma mark Load old diagram
/*-(void)parseContent{
 [self parseXMLDiagramWithText:content andJSONInfo:jsonResult];
 }*/

-(NSString *)extractPaletteNameFromXMLDiagram:(NSString *)cont{
    NSDictionary * dic = [NSDictionary dictionaryWithXMLString:cont];
    
    NSDictionary * diag = [dic objectForKey:@"diagram"];
    NSDictionary * palDic = [diag objectForKey:@"palette_name"];
    NSString * paletteName = [palDic objectForKey:@"_name"];
    
    return paletteName;
}

-(void)parseXMLDiagramWithText:(NSString *)text{
    NSDictionary * dic = [NSDictionary dictionaryWithXMLString:text];
    
    
    
    
    //diagram
    NSDictionary * diagramDic = [dic objectForKey:@"diagram"];
    
    NSDictionary * nodeDic = [diagramDic objectForKey:@"nodes"];
    
    NSArray * nodes = [nodeDic objectForKey:@"node"];
    
    if([nodes isKindOfClass:[NSDictionary class]]){
        nodes = [[NSArray alloc]initWithObjects:nodes, nil];
    }
    
    NSDictionary * edgesDic = [diagramDic objectForKey:@"edges"];
    NSArray * edges = [edgesDic objectForKey:@"edge"];
    
    if([edges isKindOfClass:[NSDictionary class]]){
        edges = [[NSArray alloc]initWithObjects:edges, nil];
    }
    /*NSDictionary * palDic = [dic objectForKey:@"palette_name"];
     NSString * paletteName = [palDic objectForKey:@"_name"];*/
    
    NSDictionary * subpaldic = [diagramDic objectForKey:@"subpalette"];
    NSString * subpalette= [subpaldic objectForKey:@"_name"];
    
    dele = (AppDelegate *)[[UIApplication sharedApplication]delegate];
    dele.subPalette = subpalette;
    
    
    //TODO: it may have palette content embedded
    
    //Load notes
    NSDictionary * notesDic = [diagramDic objectForKey:@"notes"];
    NSArray * notes = [notesDic objectForKey:@"note"];
    if([notes isKindOfClass:[NSDictionary class]]){
        notes = [[NSArray alloc]initWithObjects:notes, nil];
    }
    
    dele.notesArray = [[NSMutableArray alloc] init];
    dele.drawnsArray = [[NSMutableArray alloc] init];
    
    for(NSDictionary * note in notes){
        Alert * alert = [[Alert alloc]initWithFrame:CGRectMake(0, 0, 40, 40)];
        alert.who = [[MCPeerID alloc]initWithDisplayName:[note objectForKey:@"_who"]];
        alert.date = [note objectForKey:@"_date"];
        alert.text = [note objectForKey:@"_content"];
        alert.identifier = [[note objectForKey:@"_identifier"]intValue];
        //TODO: Load attach from xml
        NSString * base64str = [note objectForKey:@"_attach"];
        if(base64str != nil){
            UIImage * att = [AppDelegate getImageFromBase64String:base64str];
            alert.attach = att;
        }
        
        NSString * nodeId = [note objectForKey:@"_associated_node_id"];
        alert.aCId = nodeId;
        
        float x = [[note objectForKey:@"_x"]floatValue];
        float y = [[note objectForKey:@"_y"]floatValue];
        [alert setCenter:CGPointMake(x, y)];
        [dele.notesArray addObject:alert];
    }
    
    //Load drawns
    NSDictionary * drDic = [diagramDic objectForKey:@"drawns"];
    NSArray * drawns = [drDic objectForKey:@"drawn"];
    if([drawns isKindOfClass:[NSDictionary class]]){
        drawns = [[NSArray alloc]initWithObjects:drawns, nil];
    }
    for(NSDictionary * dr in drawns){
        DrawnAlert * da = [[DrawnAlert alloc] init];
        da.who = [[MCPeerID alloc]initWithDisplayName:[dr objectForKey:@"_who"]];
        da.date = [dr objectForKey:@"_date"];
        da.identifier = [[dr objectForKey:@"_identifier"]intValue];
        NSString * tempC =  [dr objectForKey:@"_color"];
        tempC = [NSString stringWithFormat:@"#%@",tempC];
        da.color = [ColorPalette colorFromHexString:tempC];
        
        
        UIBezierPath * path = [[UIBezierPath alloc] init];
        NSMutableArray * partsHolder = [[NSMutableArray alloc] init];
        
        NSDictionary * pointsDic = [dr objectForKey:@"path"];
        NSArray * pointsArray = [pointsDic objectForKey:@"p"];
        
        for (NSDictionary * pdic in pointsArray){
            NSString * xstr = [pdic objectForKey:@"_x"];
            NSString * ystr = [pdic objectForKey:@"_y"];
            NSString * type = [pdic objectForKey:@"_type"];
            float x = [xstr floatValue];
            float y = [ystr floatValue];
            CGPoint p  = CGPointMake(x, y);
            PathPiece * pp = [[PathPiece alloc] init];
            pp.point = p;
            pp.type = type;
            [partsHolder addObject:pp];
        }
        
        
        for(PathPiece * pp in partsHolder){
            
            if([pp.type isEqualToString:CGPathElementMoveToPoint]){
                [path moveToPoint:pp.point];
            }else if([pp.type isEqualToString:CGPathElementAddLineToPoint]){
                [path addLineToPoint:pp.point];
            }else if([pp.type isEqualToString:CGPathElementCloseSubpath]){
                [path closePath];
            }else{
                
            }
            
        }
        
        da.path = path;
        [dele.drawnsArray addObject:da];
        
        
    }
    
   // NSDictionary * paletteNameDic = [diagramDic objectForKey:@"palette_name"];
    //NSString * paletteName = [paletteNameDic objectForKey:@"_name"];
    //NSArray * parts = [paletteName componentsSeparatedByString:@"."];
    //tempPaletteFile = parts[0];
    //paletteName = parts[0];
    
    //Try loading palette with that name
    
    //TODO: Load palette with extension
    PaletteFile * pal = [self paletteWithExtension:tempPaletteFile.extension];
   // NSString * paletteContent = [self loadPaletteNamed:tempPaletteFile.name];
    
    if(pal == nil){ //Error, we don't have this palette
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                        message:@"This diagram uses an unknown palette."
                                                       delegate:self
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
    }else{
        [self extractPalettesForContentsOfFile:pal];
        
        dele.subPalette = pal.name;
        
        Palette * paletteForUse = [self extractSubPalette:dele.subPalette];
        
        
        if(paletteForUse == nil){
            //Error, esta paleta no tiene la subpaleta indicada
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                            message:@"This palette file doesn't contain indicated subpalette."
                                                           delegate:self
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
            [alert show];
            
            
            //Reset things
            dele.loadingADiagram = NO;
            dele.subPalette = nil;
            pal = nil;
        }else{
            palette = paletteForUse;
            
            
            [palette preparePalette];
            
            dele.paletteItems = [[NSMutableArray alloc] initWithArray:palette.paletteItems];
            
            [refreshTimer invalidate];
            
            
            dele.currentPaletteFile = tempPaletteFile;
            BOOL result = [self completePaletteForJSONAttributes];
            
            
            
            NSMutableArray * loadedComponents = [[NSMutableArray alloc] init];
            for(NSDictionary * dic in nodes){
                Component * comp = [self componentFromDictionary:dic];
                //aa
                if(comp.isDragable == NO){
                    //Add this node to the dictionary
                    NSMutableArray * array = [dele.elementsDictionary objectForKey:comp.className];
                    if(array == nil){
                        array = [[NSMutableArray alloc] init];
                        [dele.elementsDictionary setObject:array forKey:comp.className];
                    }
                    
                    [array addObject: comp];
                    
                }else{
                    [loadedComponents addObject:comp];
                }
                
                
            }
            
            NSMutableArray * loadedConnections = [[NSMutableArray alloc] init];
            for(NSDictionary * dic in edges){
                Connection * conn = [self connectionFromDictionary:dic andComponentsArray:loadedComponents];
                [loadedConnections addObject:conn];
            }
            
            dele.components = loadedComponents;
            dele.connections = loadedConnections;
            
            
            
            //Match notes with components
            for(Alert * al in dele.notesArray){
                if(al.associatedComponent == nil){
                    Component * asso = [self getComponentByStringId:al.aCId];
                    al.associatedComponent = asso;
                    
                }
            }
            
            
            if(result == YES){ //Tenemos el json y todo lo demás
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    
                    dele.loadingADiagram = YES;
                    
                    [self performSegueWithIdentifier:@"showEditor" sender:self];
                    
                });
                
                
                
            }else{ //No se ha podido encontrar el json
                NSLog(@"No te dejo seguir");
            }
            
        }
        
        
    }
    
    
    
    //TODO: Creo que no es buena idea hacer aquí el segue
}

-(Component *)getComponentByStringId:(NSString *)str{
    for(Component * com in dele.components){
        if([com.componentId isEqualToString:str]){
            return com;
        }
    }
    return nil;
}

#pragma mark Search palette (server-local)

-(NSString *)loadPaletteNamed: (NSString *)name{
    
    //Search on local palettes
    NSString * pal  = nil;
    pal = [self searchOnLocalPalettes:name];
    
    if(pal == nil)
        pal= [self searchOnServerPalettes:name];
    
    /*if(pal == nil){
     
     }*/
    return pal;
}


-(NSString *)searchOnServerPalettes: (NSString *)name{ //Name = design.graphicR
    
    NSString * temp = nil;
    
    
    //Tengo que rellenar filesArray
    
    if (filesArray == nil) {
        filesArray = [[NSMutableArray alloc] init];
        
        
        
        NSLog(@"Loading files from server");
        NSURL *url = [NSURL URLWithString:getPalettes];
        NSURLRequest *request = [NSURLRequest requestWithURL:url];
        NSError *connectionError;
        NSURLResponse *response;
        
        NSData * data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&connectionError];
        
        
        if (data.length > 0 && connectionError == nil)
        {
            NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:data
                                                                options:0
                                                                  error:NULL];
            
            NSString * code = [dic objectForKey:@"code"];
            
            if([code isEqualToString:@"200"]){
                NSArray * array = [dic objectForKey:@"array"];
                
                [self removeServerPalettesFromArray];
                
                for(int i = 0; i< [array count]; i++){
                    NSDictionary * ins = [array objectAtIndex:i];
                    PaletteFile * pf = [[PaletteFile alloc] init];
                    pf.name = [ins objectForKey:@"name"];
                    pf.content = [ins objectForKey:@"content"];
                    pf.fromServer = true;
                    [filesArray addObject:pf];
                }
            }else{
                NSLog(@"Error: %@", connectionError);
            }
            
        }
    }else{
        
    }
    /*
     //Load local files
     NSArray * bpaths = [[NSBundle mainBundle] pathsForResourcesOfType:@".graphicR" inDirectory:nil];
     NSString * contentstr = nil;
     for(NSString * path in bpaths){
     contentstr = [NSString stringWithContentsOfFile:path
     encoding:NSUTF8StringEncoding
     error:nil];
     PaletteFile * pf = [[PaletteFile alloc] init];
     NSArray * components = [path componentsSeparatedByString:@"/"];
     
     pf.name = [components objectAtIndex:components.count -1];
     pf.content = contentstr;
     pf.fromServer = false;
     
     [filesArray addObject:pf];
     }*/
    
    
    for(PaletteFile * pf in filesArray){
        
        NSString * n = pf.name;
        NSArray * array = [n componentsSeparatedByString:@"."];
        n = array[0];
        if([n isEqualToString:name]){
            //Tengo un match, devuelvo el contenido
            //Pido al servidor esa
            NSArray * parts = [name componentsSeparatedByString:@"."];
            NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/palettes/%@?json=true", baseURL, parts[0]]];
            
            NSURLRequest * urlRequest = [NSURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData timeoutInterval:2.0];
            NSURLResponse * response = nil;
            NSError * error = nil;
            NSData * data = [NSURLConnection sendSynchronousRequest:urlRequest returningResponse:&response error:&error];
            
            
            NSDictionary *dictionary = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
            if([[dictionary objectForKey:@"code"] isEqualToString:@"200"]){ //Ok
                NSDictionary * dicArray = [dictionary objectForKey:@"array"];
                NSDictionary * bodyDic = [dicArray objectForKey:@"body"];
                NSString * con = [bodyDic objectForKey:@"content"];
                con = [con stringByReplacingOccurrencesOfString:@"\n" withString:@""];
                con = [con stringByReplacingOccurrencesOfString:@"\r" withString:@""];
                con = [con stringByReplacingOccurrencesOfString:@"\\\"" withString:@""];
                return con;
            }else{
                //Error
            }
        }
    }
    
    //If temp == nil, then we don't have this palette
    return temp;
}

-(NSString *)searchOnLocalPalettes: (NSString *)name{
    /*NSString * temp = nil;
     
     NSArray * bpaths = [[NSBundle mainBundle] pathsForResourcesOfType:@".graphicR" inDirectory:nil];
     for(NSString * path in bpaths){
     NSArray * components = [path componentsSeparatedByString:@"/"];
     
     NSString * n = [components objectAtIndex:components.count -1];
     if([n isEqualToString:name]){
     temp = [NSString stringWithContentsOfFile:path
     encoding:NSUTF8StringEncoding
     error:nil];
     return temp;
     }
     }
     
     
     return temp;*/
    
    //Load local palettes
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0]; // Get documents folder
    
    NSString *palettePath = [documentsDirectory stringByAppendingPathComponent:@"/Palettes"];
    
    
    NSArray *directoryContent = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:palettePath error:NULL];
    
    
    for (int count = 0; count < (int)[directoryContent count]; count++)
    {
        NSString * nameins = directoryContent[count];
        if([nameins isEqualToString:name]){
            NSString * path = [NSString stringWithFormat:@"%@/%@", palettePath, directoryContent[count]];
            NSString* contentins = [NSString stringWithContentsOfFile:path
                                                             encoding:NSUTF8StringEncoding
                                                                error:NULL];
            return contentins;
        }
        /*NSString * path = [NSString stringWithFormat:@"%@/%@", palettePath, directoryContent[count]];
         NSString* contentins = [NSString stringWithContentsOfFile:path
         encoding:NSUTF8StringEncoding
         error:NULL];
         
         */
        
    }
    
    return nil;
}

#pragma mark Component methods

-(Component *)componentFromDictionary: (NSDictionary *)dic{
    
    
    
    
    
    NSNumberFormatter *f = [[NSNumberFormatter alloc] init];
    f.numberStyle = NSNumberFormatterDecimalStyle;
    
    
    NSString * compId = [dic objectForKey:@"_id"];
    
    
    float x = [[dic objectForKey:@"_x"]floatValue];
    float y = [[dic objectForKey:@"_y"]floatValue];
    float width = [[dic objectForKey:@"_width"]floatValue];
    float height = [[dic objectForKey:@"_height"]floatValue];
    
   
    
    NSString * dragstr = [dic objectForKey:@"_isDraggable"];
    
    
    Component * temp = [[Component alloc] initWithFrame:CGRectMake(x, y, width, height)];
    [temp prepare];
    
    
    NSString * isGeoCompStr = [dic objectForKey:@"_isGeoComponent"];
    BOOL isGeoComp = false;
    if([isGeoCompStr isEqualToString:@"true"]){
        isGeoComp = true;
    }else if([isGeoCompStr isEqualToString:@"false"]){
        isGeoComp = false;
    }else{
        isGeoComp = false;
    }
    float lat  = 0.0;
    float longitude = 0.0;
    if(isGeoComp == true){
        lat= [[dic objectForKey:@"_lat"]floatValue];
        longitude = [[dic objectForKey:@"_long"]floatValue];
        
        temp.latitude = lat;
        temp.longitude = longitude;
    }
    

    
    NSString * colorString = [dic objectForKey:@"_color"];
    NSString * type = [dic objectForKey:@"_type"];
    
    NSString * labelPosition = [dic objectForKey:@"_labelPosition"];
    temp.labelPosition = labelPosition;
    
    NSString * className = [dic objectForKey:@"_className"];
    
    [temp setFrame:CGRectMake(0, 0, width, height)];
    temp.center = CGPointMake(x, y);
    //temp.shapeType = shape;
    temp.componentId = compId;
    temp.colorString = colorString;
    temp.fillColor = [ColorPalette colorForString:colorString];
    temp.type = type;
    
    temp.attributes = [[NSMutableArray alloc] init];
    temp.className = className;
    
    
    if(dragstr == NULL){
        temp.isDragable = YES;
    }else{
        temp.isDragable = NO;
    }
    //Fill attributes
    NSArray * attrDic = [dic objectForKey:@"attribute"];
    //NSArray * attrArray = nil;
    if([attrDic isKindOfClass:[NSDictionary class]]){
        attrDic =[[NSArray alloc] initWithObjects:attrDic, nil];
    }
    
    
    for(NSDictionary * ad in attrDic){
        NSString * aname = [ad objectForKey:@"_name"];
        //NSString * adefVal = [ad objectForKey:@"_default_value"];
        //NSString * maxStr = [ad objectForKey:@"_max"];
        //NSString * minStr = [ad objectForKey:@"_min"];
        
        //NSNumber *amax = [f numberFromString:maxStr];
        //NSNumber *amin = [f numberFromString:minStr];
        
        NSString * acurrVal = [ad objectForKey:@"_current_value"];
        //NSString * atype = [ad objectForKey:@"_type"];
        
        ClassAttribute * atr = [[ClassAttribute alloc] init];
        atr.name = aname;
        atr.type = type;
        
        
        //atr.defaultValue = adefVal;
        //atr.max = amax;
        //atr.min = amin;
        //atr.type = atype;
        atr.currentValue = acurrVal;
        
        
        
        
        [dele completeClassAttribute:atr withClasName:temp.className];
        
        [temp.attributes addObject:atr];
        
    }
    
    temp.expandableItems = [[NSMutableArray alloc] init];
    //Link_palettes
    NSDictionary * linkPalettesDic = [dic objectForKey:@"link_palettes"];
    if(linkPalettesDic != nil){
        temp.isExpandable = YES;
        NSArray * linksPalettes = [linkPalettesDic objectForKey:@"link_palette"];
        if([linksPalettes isKindOfClass:[NSDictionary class]]){
            linksPalettes = [[NSArray alloc] initWithObjects:linksPalettes, nil];
        }
        
        for(NSDictionary * d in linksPalettes){
            LinkPalette * lp = [[LinkPalette alloc] init];
            lp.anEReference = [d objectForKey:@"_anEReference"];
            lp.className = [d objectForKey:@"_className"];
            lp.expandableIndex = [[d objectForKey:@"_expandableIndex"]intValue];
            lp.lineStyle = [d objectForKey:@"_lineStyle"];
            lp.paletteName = [d objectForKey:@"_paletteName"];
            lp.referenceInClass = [d objectForKey:@"_referenceInClass"];
            lp.sourceDecoratorName = [d objectForKey:@"_sourceDecoratorName"];
            lp.targetDecoratorName = [d objectForKey:@"_targetDecoratorName"];
            
            
            NSArray * instances = [d objectForKey:@"link_palette_instance"];
            if([instances isKindOfClass:[NSDictionary class]]){
                instances = [[NSArray alloc] initWithObjects:instances, nil];
            }
            
            lp.instances = [[NSMutableArray alloc] init];
            
            
            for(NSDictionary * instance in instances){
                //A new component instance
                Component * comp = [[Component alloc] init];
                comp.attributes = [[NSMutableArray alloc]init];
                
                comp.className = [instance objectForKey:@"_className"];
                comp.componentId = [instance objectForKey:@"_id"];
                
                NSArray * atrsArray = [instance objectForKey:@"attribute"];
                if([atrsArray isKindOfClass:[NSDictionary class]]){
                    atrsArray = [[NSArray alloc] initWithObjects:atrsArray, nil];
                }
                
                for(NSDictionary * atrDic in atrsArray){
                    ClassAttribute * ca = [[ClassAttribute alloc] init];
                    ca.currentValue = [atrDic objectForKey:@"_current_value"];
                    ca.name = [atrDic objectForKey:@"_name"];
                    NSString * type = [atrDic objectForKey:@"_type"];
                    if(type == nil){
                        type = @"EString";
                    }
                    ca.type = type;
                    [comp.attributes addObject:ca];
                }
                [lp.instances addObject:comp];
                
            }
            
            [temp.expandableItems addObject:lp];
            
        }
    }
    
    
    //Complete this Component for its paletteItem
    
    for(PaletteItem * pi in dele.paletteItems){
        if([pi.className isEqualToString:temp.className]){
            //Me falta shape type
            temp.shapeType = pi.shapeType;
            temp.colorString = pi.colorString;
            temp.fillColor = pi.fillColor;
            temp.borderColor = pi.borderColor;
            temp.isImage = pi.isImage;
            temp.borderStyleString = pi.borderStyleString;
            temp.borderWidth = pi.borderWidth;
            
            temp.image = [pi.image copy];
            
            
            
            //Load linkPalettes
            
            NSArray * keys = [pi.linkPaletteDic allKeys];
            temp.linkPaletteDic = [[NSMutableDictionary alloc] init];
            for(NSString * key in keys){
                LinkPalette * lp = [pi.linkPaletteDic objectForKey:key];
                NSData * buffer = [NSKeyedArchiver archivedDataWithRootObject: lp];
                LinkPalette * extracted =  [NSKeyedUnarchiver unarchiveObjectWithData: buffer];
                [temp.linkPaletteDic setObject:extracted forKey:key];
            }
            

            [temp updateNameLabel];
        }
    }
    
    
    return temp;
}

-(Connection *)connectionFromDictionary: (NSDictionary *)dic
                     andComponentsArray: (NSMutableArray *)components{
    Connection * conn = [[Connection alloc]init];
    
    //TODO Error aquí
    
    NSString * sourceId = [dic objectForKey:@"_source"];
    NSString * targetId = [dic objectForKey:@"_target"];
    NSString * className = [dic objectForKey:@"_className"];
    NSString * link = [dic objectForKey:@"_link"];
    
    Component * source = nil;
    Component * target = nil;
    
    //Get source
    for(Component * c in components){
        if([c.componentId isEqualToString:sourceId]){
            source = c;
        }
        
        if([c.componentId isEqualToString:targetId]){
            target = c;
        }
    }
    
    //conn.name = name;
    conn.source = source;
    conn.target = target;
    conn.className = className;
    
    if(link != nil){ //It is a linkPalette
        for(PaletteItem * pi in dele.paletteItems){ //Get the class linkpalette
            if([pi.className isEqualToString:conn.className]){
                
                //Pi = the class that has that linkPalette (e.g class)
                LinkPalette * lp = [pi.linkPaletteDic objectForKey:link];
                
                conn.lineColorNameString = [lp.colorDic objectForKey:@"_name"];
                conn.lineColor = [ColorPalette colorForString:conn.lineColorNameString];
                conn.lineWidth = [NSNumber numberWithFloat:2.0]; //TODO: FIX THIS
                conn.lineStyle = lp.lineStyle;
                conn.sourceDecorator = lp.sourceDecoratorName;
                conn.targetDecorator = lp.targetDecoratorName;
                
            }
        }
    }else{
        for(PaletteItem * pi in dele.paletteItems){
            if([pi.className isEqualToString:conn.className]){
                conn.lineColor = pi.lineColor;
                conn.lineColorNameString = pi.lineColorNameString;
                conn.lineWidth = pi.lineWidth;
                conn.lineStyle = pi.lineStyle;
                
                conn.sourceDecorator = pi.sourceDecoratorName;
                conn.targetDecorator = pi.targetDecoratorName;
            }
        }
    }
    
    return conn;
}


#pragma mark Look for json with name...

-(NSString *)getEcoreNamed:(NSString *)name{
    NSArray * nameParts = [name componentsSeparatedByString:@"."];
    NSString * nameToSearch = nameParts[0];
    
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/ecores/%@?json=true", baseURL, nameToSearch]];
    
    NSURLRequest * urlRequest = [NSURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData timeoutInterval:2.0];
    NSURLResponse * response = nil;
    NSError * error = nil;
    NSData * data = [NSURLConnection sendSynchronousRequest:urlRequest returningResponse:&response error:&error];
    
    
    if(error != nil){ //Some error
    }
    else{ //No error
        NSDictionary *dictionary = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
        if(error == nil){
            NSString * code = [dictionary objectForKey:@"code"];
            if([code isEqualToString:@"200"]){
                NSDictionary * dicArray = [dictionary objectForKey:@"array"];
                
                NSDictionary * insArray = [dicArray objectForKey:@"body"];
                
                
                NSString * bodystr = [insArray objectForKey:@"content"];
                bodystr = [bodystr stringByReplacingOccurrencesOfString:@"\\n" withString:@""];
                bodystr = [bodystr stringByReplacingOccurrencesOfString:@"\\\"" withString:@"\""];
                bodystr = [bodystr stringByReplacingOccurrencesOfString:@"\\" withString:@""];
                
                return bodystr;
            }
            
        }else{ //Some error
            NSLog(@"Error parsing data");
            return nil;
        }
    }
    
    return nil;
}
-(NSString *)searchJsonNamed:(NSString *)uri{
    NSString * result = nil;
    
    result = [self searchLocalJSONByURI:uri];
    
    if(result == nil)
        result = [self searchJSONonServer:uri];
    
    return result;
}

-(NSString *)searchLocalJSON:(NSString *)name{
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    
    NSString *documentsDirectory = [paths objectAtIndex:0]; // Get documents folder
    
    NSString *palettePath = [documentsDirectory stringByAppendingPathComponent:@"/Jsons"];
    
    
    NSArray *directoryContent = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:palettePath error:NULL];
    
    for (int count = 0; count < (int)[directoryContent count]; count++){
        NSString * jname = directoryContent[count];
        if([jname isEqualToString:name]){
            
            //Read this and return
            NSString * path = [NSString stringWithFormat:@"%@/%@", palettePath, directoryContent[count]];
            NSString* contentins = [NSString stringWithContentsOfFile:path
                                                             encoding:NSUTF8StringEncoding
                                                                error:NULL];
            return contentins;
            
            
        }
    }
    return nil;
}
-(NSString *)searchLocalJSONByURI:(NSString *)uri{
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    
    NSString *documentsDirectory = [paths objectAtIndex:0]; // Get documents folder
    
    NSString *palettePath = [documentsDirectory stringByAppendingPathComponent:@"/Jsons"];
    
    /*
    NSArray *directoryContent = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:palettePath error:NULL];
    
    for (int count = 0; count < (int)[directoryContent count]; count++){
        NSString * jname = directoryContent[count];
        if([jname isEqualToString:name]){
            
            //Read this and return
            NSString * path = [NSString stringWithFormat:@"%@/%@", palettePath, directoryContent[count]];
            NSString* contentins = [NSString stringWithContentsOfFile:path
                                                             encoding:NSUTF8StringEncoding
                                                                error:NULL];
            return contentins;
            
            
        }
    }*/
    return nil;
}


-(NSString *)searchJSONonServer:(NSString *)uri{
    
    //ThinkingView * thinking = [[[NSBundle mainBundle] loadNibNamed:@"ThinkingView"
    //                                                                    owner:self
    //                                                                 options:nil] objectAtIndex:0];
    //[self.view addSubview:thinking];
    //[thinking setFrame:self.view.frame];
    
    
    /*NSArray * parts = [name componentsSeparatedByString:@"."];
    NSString * trueName = parts[0] ;*/
    //Get json content from
    NSLog(@"Loading files from server");
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/jsonbyuri?json=true&uri=%@", baseURL, uri]];
    
    NSURLRequest * urlRequest = [NSURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData timeoutInterval:2.0];
    NSURLResponse * response = nil;
    NSError * error = nil;
    NSData * data = [NSURLConnection sendSynchronousRequest:urlRequest returningResponse:&response error:&error];
    
    //[thinking removeFromSuperview];
    
    
    if(error != nil){ //Some error
    }
    else{ //No error
        NSDictionary *dictionary = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
        if(error == nil){
            NSString * code = [dictionary objectForKey:@"code"];
            if([code isEqualToString:@"200"]){
                NSDictionary * dicArray = [dictionary objectForKey:@"array"];
                NSString * bodystr = [dicArray objectForKey:@"content"];
                bodystr = [bodystr stringByReplacingOccurrencesOfString:@"\\n" withString:@""];
                bodystr = [bodystr stringByReplacingOccurrencesOfString:@"\\\"" withString:@"\""];
                bodystr = [bodystr stringByReplacingOccurrencesOfString:@"\\" withString:@""];
                NSDictionary * body = [NSJSONSerialization JSONObjectWithData:[bodystr dataUsingEncoding:NSUTF8StringEncoding]
                                                                      options:kNilOptions
                                                                        error:&error];
                NSArray * bodyKeys = [body allKeys];
                
                if(bodyKeys.count != 0){
                    
                    return bodystr;
                }
                
            }else if([code isEqualToString:@"300"]){
                NSLog(@"%@", [dictionary objectForKey:@"msg"]);
                return nil;
            }else{
                NSLog(@"%@", [dictionary objectForKey:@"msg"]);
                return nil;
            }
        }else{
            NSLog(@"Error parsing data");
            return nil;
        }
    }
    
    return nil;
}


- (IBAction)cancelSubpaletteSelection:(id)sender {
    
    
    [folder setHidden:NO];
    
    [infoButton setHidden:NO];
    
    [palette resetPalette];
    
    palette.paletteItems = [[NSMutableArray alloc ]init];
    
    dele.paletteItems = [[NSMutableArray alloc ]init];
    dele.currentPaletteFile = nil;
    dele.subPalette = nil;
    dele.graphicR = nil;
    dele.loadingADiagram = NO;
    content = nil;
    palettes = [[NSMutableArray alloc ]init];
    tempPaletteFile = nil;
    
    dele.graphicR = nil;
    dele.graphicRContent = nil;
    
    [palette setNeedsDisplay];
    
    
    
    if(doingTutorial == YES){
        [self.view sendSubviewToBack:confirmButton];
        [self.view sendSubviewToBack:subPaletteGroup];
        [self.view bringSubviewToFront:paletteFileGroup];
        
        [dele.tutSheet.textView setText:@"Okay. You didn't like that.\nChoose another palette"];
        CGFloat fixedWidth = dele.tutSheet.textView.frame.size.width;
        CGSize newSize = [dele.tutSheet.textView sizeThatFits:CGSizeMake(fixedWidth, MAXFLOAT)];
        
        [dele.tutSheet setFrame:CGRectMake(dele.tutSheet.frame.origin.x,
                                           dele.tutSheet.frame.origin.y,
                                           dele.tutSheet.frame.size.width,
                                           newSize.height)];
        
    }
    
    //Quitar el subpalette y mostrar el palettefilegroup
    
    [paletteFileGroup setCenter:outCenterForFileGroup];
    [paletteFileGroup setHidden:NO];
    [UIView animateWithDuration:0.5
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
                         //Quito el botón de volver
                         [cancelSubpaletteSelectionOutlet setAlpha:0.0];
                         [cancelSubpaletteSelectionOutlet setHidden:YES];
                         
                         [subPaletteGroup setFrame:oldSubPaletteGroupFrame];
                         
                         [paletteFileGroup setFrame:oldPaletteFileGroupFrame];
                         
                         //Quitar la paleta
                         [palette setAlpha:0.0];
                     }
                     completion:^(BOOL finished) {
                         [subPaletteGroup setHidden:YES];
                         [palettes removeAllObjects];
                         [palettesTable reloadData];
                         [palette setHidden:YES];
                     }];
}


#pragma mark Reload server palettes
- (IBAction)reloadServerPalettes:(id)sender {
    //Load files from server
    NSThread * thread = [[NSThread alloc] initWithTarget:self
                                                selector:@selector(loadPalettesFromServer)
                                                  object:nil];
    [thread start];
}


#pragma mark CloudDiagramExplorer delegate
-(void)closeExplorerWithSelectedDiagramFile:(DiagramFile *)file{
    //file será el diagrama seleccionado
    
    if(file.content == nil){ //Error
        
    }else{
        
        NSString * fileContent = file.content;
        
        tempPaletteFile = [self paletteWithExtension:file.paletteExtension];
        
        
        //TODO: Recover json for this palette
        
        [self parseXMLDiagramWithText:fileContent ];
    }
}

-(BOOL)parseRemainingContent{
    NSString * palettefile = [self extractPaletteNameFromXMLDiagram:contentToParse];
    
    NSArray * parts = [palettefile componentsSeparatedByString:@"."];
    tempPaletteFile = parts[0];
    
    //TODO: Get palette for this name
    
    
    //fill filesArray
    
    NSURL *url = [NSURL URLWithString:getPalettes];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    NSError * error;
    NSURLResponse *response;
    NSData * data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
    
    if (data.length > 0 && error == nil)
    {
        NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:data
                                                            options:0
                                                              error:NULL];
        
        //[serverFilesArray removeAllObjects];
        
        NSString * code = [dic objectForKey:@"code"];
        
        if([code isEqualToString:@"200"]){
            NSArray * array = [dic objectForKey:@"array"];
            
            [self removeServerPalettesFromArray];
            
            for(int i = 0; i< [array count]; i++){
                NSDictionary * ins = [array objectAtIndex:i];
                PaletteFile * pf = [[PaletteFile alloc] init];
                pf.name = [ins objectForKey:@"name"];
                pf.content = [ins objectForKey:@"content"];
                pf.fromServer = true;
                [filesArray addObject:pf];
            }
            
        }else{
            NSLog(@"Error");
        }
        
    }
    //TODO: Todo está a ni O.O
    dele.paletteItems = [[NSMutableArray alloc] initWithArray:palette.paletteItems];
    [refreshTimer invalidate];
    
    
    
    dele.loadingADiagram = YES;
    [self parseXMLDiagramWithText:contentToParse];
    
    
    //Go to editor
    
    
    
    //Complete everything
    return YES;
}


#pragma mark Multipeer Connectivity
- (IBAction)changeSearchSessions:(id)sender {
    if(searchSessionsOutlet.isOn == YES){
        [dele.manager startAdvertising];
    }else{
        [dele.manager stopAdvertising];
    }
}

#pragma mark Tutorial

-(void)startConfigureCVTutorial{
    //self.view.backgroundColor = [UIColor clearColor];
    
    UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
    blurEffectView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
    blurEffectView.frame = self.view.bounds;
    blurEffectView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
    [self.view addSubview:blurEffectView];
    
    
    
    UIAlertController * alert=   [UIAlertController
                                  alertControllerWithTitle:@"Welcome"
                                  message:@"This is the first time you use this tool.\nLet me show you some tips."
                                  preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction* yesButton = [UIAlertAction
                                actionWithTitle:@"Ok"
                                style:UIAlertActionStyleDefault
                                handler:^(UIAlertAction * action)
                                {
                                    [self dismissViewControllerAnimated:YES completion:nil];
                                    [self showAndDisablePaletteFileGroup];
                                    
                                    
                                    
                                }];
    UIAlertAction* noButton = [UIAlertAction
                               actionWithTitle:@"No, thanks"
                               style:UIAlertActionStyleDefault
                               handler:^(UIAlertAction * action)
                               {
                                   [self dismissViewControllerAnimated:YES completion:nil];
                                   //Finish ConfigureView tutorial
                                   doingTutorial = NO;
                                   
                                   [blurEffectView removeFromSuperview];
                                   [dele.tutSheet removeFromSuperview];
                                   
                                   [[NSUserDefaults standardUserDefaults] setObject:@"done" forKey:@"configureTutorialStatus"];
                                   dele.shouldShowConfigureTutorial = NO;
                                   
                               }];
    
    
    [alert addAction:noButton];
    [alert addAction:yesButton];
    
    [self presentViewController:alert animated:YES completion:nil];
}
-(void)showAndDisablePaletteFileGroup{
    [self.view bringSubviewToFront:paletteFileGroup];
    [paletteFileGroup setUserInteractionEnabled:NO];
    dele.tutSheet = [[[NSBundle mainBundle]loadNibNamed:@"TutorialSheet"
                                                  owner:self
                                                options:nil]objectAtIndex:0];
    
    [dele.tutSheet prepare];
    [dele.tutSheet.textView setSelectable:NO];
    [dele.tutSheet.textView setFont:[UIFont fontWithName:@"HelveticaNeue-Light" size:15.0]];
    
    [dele.tutSheet.textView setText:@"This is the files table. From here you can select the desired palette or you can download one of them (making a swipe).\nTap here to continue..."];
    CGFloat fixedWidth = dele.tutSheet.textView.frame.size.width;
    CGSize newSize = [dele.tutSheet.textView sizeThatFits:CGSizeMake(fixedWidth, MAXFLOAT)];
    
    [dele.tutSheet setFrame:CGRectMake(self.view.center.x - dele.tutSheet.frame.size.width/2,
                                       self.view.frame.size.height-dele.tutSheet.frame.size.height,
                                       dele.tutSheet.frame.size.width,
                                       newSize.height +10)];
    
    
    [self.view addSubview:dele.tutSheet];
    
    UITapGestureRecognizer * showFolderInfoGR = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                                        action:@selector(hidePaletteFileGroupAndShowFolderInfo:)];
    [dele.tutSheet addGestureRecognizer:showFolderInfoGR];
    [dele.tutSheet setUserInteractionEnabled:YES];
}
-(void)hidePaletteFileGroupAndShowFolderInfo:(UITapGestureRecognizer *)recog{
    [dele.tutSheet removeFromSuperview];
    [dele.tutSheet removeGestureRecognizer:recog];
    
    [self.view sendSubviewToBack:paletteFileGroup];
    [paletteFileGroup setUserInteractionEnabled:YES];
    
    //Bring here folder group
    [self.view bringSubviewToFront:folder];
    [folder setUserInteractionEnabled:NO];
    
    [dele.tutSheet.textView setText:@"You can swipe from left to show menu. Give it a try.\nTap here to continue..."];
    
    CGFloat fixedWidth = dele.tutSheet.textView.frame.size.width;
    CGSize newSize = [dele.tutSheet.textView sizeThatFits:CGSizeMake(fixedWidth, MAXFLOAT)];
    
    [dele.tutSheet setFrame:CGRectMake(folder.frame.origin.x ,
                                       folder.frame.origin.y + folder.frame.size.height +10,
                                       dele.tutSheet.frame.size.width - 100,
                                       newSize.height +10)];
    
    [self.view addSubview:dele.tutSheet];
    UITapGestureRecognizer * showSubPalGR = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                                    action:@selector(showSubPaletteInfo:)];
    [dele.tutSheet addGestureRecognizer:showSubPalGR];
}
-(void)showSubPaletteInfo:(UITapGestureRecognizer *)recog{
    [dele.tutSheet removeGestureRecognizer:recog];
    [dele.tutSheet removeFromSuperview];
    
    [self.view sendSubviewToBack:folder];
    [folder setUserInteractionEnabled:YES];
    
    //Show table again in order to create a new diagram
    [self.view bringSubviewToFront:paletteFileGroup];
    [dele.tutSheet.textView setText:@"Now let's try to create a diagram. First of all select a palette from the list.\n If the list is empty, try to pull down the table to download palettes from server (you need an internet connection in order to doing that)..."];
    
    
    CGFloat fixedWidth = dele.tutSheet.textView.frame.size.width;
    CGSize newSize = [dele.tutSheet.textView sizeThatFits:CGSizeMake(fixedWidth, MAXFLOAT)];
    
    [dele.tutSheet setFrame:CGRectMake(self.view.center.x - dele.tutSheet.frame.size.width/2,
                                       self.view.frame.size.height - newSize.height -10,
                                       dele.tutSheet.frame.size.width,
                                       newSize.height +10)];
    [self.view addSubview:dele.tutSheet];
}



#pragma mark Create New palette

- (IBAction)createANewPalette:(id)sender {
    
}


#pragma mark SlideMenuDelegate
-(void)menuSelectedOption:(int)option
                inSection:(int)section{
    
    [self hideMenu];
    
    
    switch (section) {
        case 0: //Load old model
            [self showOptionsPopup];
            break;
            
        case 1: //Create a palette
            [self performSegueWithIdentifier:@"showCreatePalette" sender:self];
            break;
            
        case 2: //Show info
            if(option == 0) //Who are we
                [self showInfo];
            else if(option == 1){ //Tutorial
                doingTutorial = YES;
                [self startConfigureCVTutorial];
            }
            break;
            
        default:
            break;
    }
    
}

-(void)showInfo{
    NSString * str = @"Created in Miso Group \nhttp://www.miso.es\n\nCreated by \nDiego Vaquero Melchor";
    
    UIAlertController * alert=   [UIAlertController
                                  alertControllerWithTitle:@"Info"
                                  message:str
                                  preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction* ok = [UIAlertAction
                         actionWithTitle:@"OK"
                         style:UIAlertActionStyleDefault
                         handler:^(UIAlertAction * action)
                         {
                             [alert dismissViewControllerAnimated:YES completion:nil];
                             
                         }];
    
    [alert addAction:ok];
    
    
    [self presentViewController:alert animated:YES completion:nil];
}

@end
