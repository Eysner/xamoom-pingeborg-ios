//
//  XMMContentBlocks.m
//  xamoom-pingeborg-ios
//
//  Created by Raphael Seher on 20/04/15.
//  Copyright (c) 2015 xamoom GmbH. All rights reserved.
//

#import "XMMContentBlocks.h"

int const kHorizontalSpaceToSubview = 32;

@interface XMMContentBlocks ()

@property NSString *style;
@property int fontSize;

@end

@implementation XMMContentBlocks

- (instancetype)init {
  self = [super init];
  if(self) {
    self.itemsToDisplay = [[NSMutableArray alloc] init];
    self.fontSize = NormalFontSize;
  }
  
  NSString *notificationName = @"reloadTableViewForContentBlocks";
  
  [[NSNotificationCenter defaultCenter]
   addObserver:self
   selector:@selector(reloadTableView)
   name:notificationName
   object:nil];
  
  return self;
}

# pragma mark - ContentBlock Methods
- (void)displayContentBlocksById:(XMMResponseGetById *)IdResult byLocationIdentifier:(XMMResponseGetByLocationIdentifier *)locationIdentifierResult withScreenWidth:(float)screenWidth {
  NSInteger contentBlockType;
  NSArray *contentBlocks;
  self.screenWidth = screenWidth - kHorizontalSpaceToSubview;
  
  if (IdResult != nil) {
    contentBlocks = IdResult.content.contentBlocks;
  }
  else if (locationIdentifierResult != nil) {
    contentBlocks = locationIdentifierResult.content.contentBlocks;
  }
  else {
    return;
  }
  
  for (XMMResponseContentBlock *contentBlock in contentBlocks) {
    contentBlockType = [contentBlock.contentBlockType integerValue];
    
    switch (contentBlockType) {
      case 0:
      {
        XMMResponseContentBlockType0 *contentBlock0 = (XMMResponseContentBlockType0*)contentBlock;
        [self displayContentBlock0:contentBlock0];
        break;
      }
      case 1:
      {
        XMMResponseContentBlockType1 *contentBlock1 = (XMMResponseContentBlockType1*)contentBlock;
        [self displayContentBlock1:contentBlock1];
        break;
      }
      case 2:
      {
        XMMResponseContentBlockType2 *contentBlock2 = (XMMResponseContentBlockType2*)contentBlock;
        [self displayContentBlock2:contentBlock2];
        break;
      }
      case 3:
      {
        XMMResponseContentBlockType3 *contentBlock3 = (XMMResponseContentBlockType3*)contentBlock;
        [self displayContentBlock3:contentBlock3];
        break;
      }
      case 4:
      {
        XMMResponseContentBlockType4 *contentBlock4 = (XMMResponseContentBlockType4*)contentBlock;
        [self displayContentBlock4:contentBlock4];
        break;
      }
      case 5:
      {
        XMMResponseContentBlockType5 *contentBlock5 = (XMMResponseContentBlockType5*)contentBlock;
        [self displayContentBlock5:contentBlock5];
        break;
      }
      case 6:
      {
        XMMResponseContentBlockType6 *contentBlock6 = (XMMResponseContentBlockType6*)contentBlock;
        [self displayContentBlock6:contentBlock6];
        break;
      }
      case 7:
      {
        XMMResponseContentBlockType7 *contentBlock7 = (XMMResponseContentBlockType7*)contentBlock;
        [self displayContentBlock7:contentBlock7];
        break;
      }
      case 8:
      {
        XMMResponseContentBlockType8 *contentBlock8 = (XMMResponseContentBlockType8*)contentBlock;
        [self displayContentBlock8:contentBlock8];
        break;
      }
      case 9:
      {
        XMMResponseContentBlockType9 *contentBlock9 = (XMMResponseContentBlockType9*)contentBlock;
        [self displayContentBlock9:contentBlock9];
        break;
      }
      default:
        break;
    }
  }
  
  [self reloadTableView];
}

#pragma mark - Display Content Blocks

#pragma mark Text Block
- (void)displayContentBlock0:(XMMResponseContentBlockType0 *)contentBlock {
  
  TextBlockTableViewCell *cell = [[TextBlockTableViewCell alloc] init];
  NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"TextBlockTableViewCell" owner:self options:nil];
  cell = nib[0];
  
  //save text for later use
  cell.titleText = contentBlock.title;
  cell.contentText = contentBlock.text;
  cell.contentBlockType = contentBlock.contentBlockType;
  
  //set title
  cell.titleLabel.text = contentBlock.title;
  if ([contentBlock.contentBlockType isEqualToString:@"title"]) {
    [cell.titleLabel setFont:[UIFont systemFontOfSize:self.fontSize+6]];
  }
  
  if (contentBlock.text != nil)
    cell.contentLabel.attributedText = [self attributedStringFromHTML:contentBlock.text];
  
  //add to array
  [self.itemsToDisplay addObject: cell];
}

#pragma mark Audio Block
- (void)displayContentBlock1:(XMMResponseContentBlockType1 *)contentBlock {
  AudioBlockTableViewCell *cell = [[AudioBlockTableViewCell alloc] init];
  NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"AudioBlockTableViewCell" owner:self options:nil];
  cell = nib[0];
  
  //set title
  cell.audioPlayerControl.mediaUrlString = contentBlock.fileId;
  cell.titleLabel.text = contentBlock.title;
  cell.artistLabel.text = contentBlock.artist;
  
  [self.itemsToDisplay addObject:cell];
}

#pragma mark Youtube Block
- (void)displayContentBlock2:(XMMResponseContentBlockType2 *)contentBlock {
  YoutubeBlockTableViewCell *cell = [[YoutubeBlockTableViewCell alloc] init];
  NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"YoutubeBlockTableViewCell" owner:self options:nil];
  cell = nib[0];
  
  cell.titleLabel.text = contentBlock.title;
  cell.youtubeVideoUrl = contentBlock.youtubeUrl;
  
  //get the videoId from the string
  NSString *regexString = @"((?<=(v|V)/)|(?<=be/)|(?<=(\\?|\\&)v=)|(?<=embed/))([\\w-]++)";
  NSRegularExpression *regExp = [NSRegularExpression regularExpressionWithPattern:regexString
                                                                          options:NSRegularExpressionCaseInsensitive
                                                                            error:nil];
  
  NSArray *array = [regExp matchesInString:cell.youtubeVideoUrl options:0 range:NSMakeRange(0,cell.youtubeVideoUrl.length)];
  if (array.count > 0) {
    NSTextCheckingResult *result = array.firstObject;
    NSString* youtubeVideoId = [cell.youtubeVideoUrl substringWithRange:result.range];
    //load video inside playerView
    [cell.playerView loadWithVideoId:youtubeVideoId];
  }
  
  [self.itemsToDisplay addObject:cell];
}

#pragma mark Image Block
- (void)displayContentBlock3:(XMMResponseContentBlockType3 *)contentBlock {
  
  ImageBlockTableViewCell *cell = [[ImageBlockTableViewCell alloc] init];
  NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"ImageBlockTableViewCell" owner:self options:nil];
  cell = nib[0];
  
  cell.titleLabel.text = contentBlock.title;
  
  //gif support
  if ([contentBlock.fileId containsString:@".gif"]) {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,
                                             (unsigned long)NULL), ^(void) {
      UIImage *gifImage = [UIImage animatedImageWithAnimatedGIFURL:[NSURL URLWithString:contentBlock.fileId]];
      float imageRatio = gifImage.size.width/gifImage.size.height;
      dispatch_async(dispatch_get_main_queue(), ^(void) {
        //smaller images will be displayed normal size and centered
        if (gifImage.size.width < cell.image.frame.size.width) {
          [cell.image setContentMode:UIViewContentModeCenter];
          [cell.imageHeightConstraint setConstant:gifImage.size.height];
        }
        else {
          //bigger images will be resized und displayed full-width
          [cell.imageHeightConstraint setConstant:(self.screenWidth / imageRatio)];
        }

        [cell.image setImage:gifImage];
        [self reloadTableView];
      });
    });
  } else if(cell.image != nil) {
    [self downloadImageWithURL:contentBlock.fileId completionBlock:^(BOOL succeeded, UIImage *image) {
      if (succeeded && image) {
        float imageRatio = image.size.width/image.size.height;
        
        //smaller images will be displayed normal size and centered
        if (image.size.width < cell.image.frame.size.width) {
          [cell.image setContentMode:UIViewContentModeCenter];
          [cell.imageHeightConstraint setConstant:image.size.height];
        }
        else {
          //bigger images will be resized und displayed full-width
          [cell.imageHeightConstraint setConstant:(self.screenWidth / imageRatio)];
        }
        
        [cell.image setImage:image];
        [self reloadTableView];
      }
    }];
  }
  
  [self.itemsToDisplay addObject:cell];
}

#pragma mark Link Block
- (void)displayContentBlock4:(XMMResponseContentBlockType4 *)contentBlock {
  
  LinkBlockTableViewCell *cell = [[LinkBlockTableViewCell alloc] init];
  NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"LinkBlockTableViewCell" owner:self options:nil];
  cell = nib[0];
  
  cell.titleLabel.text = contentBlock.title;
  cell.linkTextLabel.text = contentBlock.text;
  cell.linkUrl = contentBlock.linkUrl;
  cell.linkType = contentBlock.linkType;
  
  [cell changeStyleAccordingToLinkType];
  [self.itemsToDisplay addObject:cell];
}

#pragma mark Ebook Block
- (void)displayContentBlock5:(XMMResponseContentBlockType5 *)contentBlock {
  
  EbookBlockTableViewCell *cell = [[EbookBlockTableViewCell alloc] init];
  NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"EbookBlockTableViewCell" owner:self options:nil];
  cell = nib[0];
  
  cell.titleLabel.text = contentBlock.title;
  cell.artistLabel.text = contentBlock.artist;
  cell.downloadUrl = contentBlock.fileId;
  
  [self.itemsToDisplay addObject:cell];
}

#pragma mark Content Block
- (void)displayContentBlock6:(XMMResponseContentBlockType6 *)contentBlock {
  
  ContentBlockTableViewCell *cell = [[ContentBlockTableViewCell alloc] init];
  NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"ContentBlockTableViewCell" owner:self options:nil];
  cell = nib[0];
  
  cell.contentId = contentBlock.contentId;
  [cell getContent];
  
  [self.itemsToDisplay addObject:cell];
}

#pragma mark Soundcloud Block
- (void)displayContentBlock7:(XMMResponseContentBlockType7 *)contentBlock {
  
  SoundcloudBlockTableViewCell *cell = [[SoundcloudBlockTableViewCell alloc] init];
  NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"SoundcloudBlockTableViewCell" owner:self options:nil];
  cell = nib[0];
  
  //disable scrolling and bouncing
  [cell.webView.scrollView setScrollEnabled:NO];
  [cell.webView.scrollView setBounces:NO];
  
  //set title
  cell.titleLabel.text = contentBlock.title;
  
  //get soundcloud code from file
  NSString *soundcloudJs;
  NSString *soundcloudJsPath = [[NSBundle mainBundle] pathForResource:@"soundcloud" ofType:@"js"];
  NSData *loadedData = [NSData dataWithContentsOfFile:soundcloudJsPath];
  if (loadedData) {
    soundcloudJs = [[NSString alloc] initWithData:loadedData encoding:NSUTF8StringEncoding];
  }
  
  //replace url and height from soundcloudJs
  NSString *soundcloudUrl = contentBlock.soundcloudUrl;
  soundcloudJs = [soundcloudJs stringByReplacingOccurrencesOfString:@"##url##"
                                                         withString:soundcloudUrl];
  
  soundcloudJs = [soundcloudJs stringByReplacingOccurrencesOfString:@"##height##"
                                                         withString:[NSString stringWithFormat:@"%f", cell.webView.frame.size.height]];
  
  //display soundcloud in webview
  [cell.webView loadHTMLString:soundcloudJs baseURL:nil];
  
  [self.itemsToDisplay addObject:cell];
}

- (void)displayContentBlock8:(XMMResponseContentBlockType8 *)contentBlock {
  
  DownloadBlockTableViewCell *cell = [[DownloadBlockTableViewCell alloc] init];
  NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"DownloadBlockTableViewCell" owner:self options:nil];
  cell = nib[0];
  
  cell.titleLabel.text = contentBlock.title;
  cell.contentTextLabel.text = contentBlock.text;
  cell.fileId = contentBlock.fileId;
  cell.downloadType = contentBlock.downloadType;
  
  [self.itemsToDisplay addObject:cell];
}

#pragma mark SpotMap Block
- (void)displayContentBlock9:(XMMResponseContentBlockType9 *)contentBlock {
  
  SpotMapBlockTableViewCell *cell = [[SpotMapBlockTableViewCell alloc] init];
  NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"SpotMapBlockTableViewCell" owner:self options:nil];
  cell = nib[0];
  
  cell.titleLabel.text = contentBlock.title;
  cell.spotMapTags = contentBlock.spotMapTag;
  [cell getSpotMap];
  
  [self.itemsToDisplay addObject:cell];
}

#pragma mark - Custom Methods

- (NSAttributedString*)attributedStringFromHTML:(NSString*)html {
  NSError *err = nil;
  
  self.style = @"<style>html{font-family: 'HelveticaNeue-Light';font-size: ###fontsize###} body{margin:0 !important;} p:last-child, p:last-of-type{margin:1px !important;}</style>";
  
  //set content (html content transform to textview text)
  self.style = [self.style stringByReplacingOccurrencesOfString:@"###fontsize###" withString:[NSString stringWithFormat:@"%d", self.fontSize]];
  html = [html stringByReplacingOccurrencesOfString:@"<br></p>" withString:@"</p>"];
  html = [html stringByAppendingString:self.style];
  
  NSAttributedString *attributedString = [[NSAttributedString alloc] initWithData: [html dataUsingEncoding:NSUTF8StringEncoding]
                                                                          options: @{ NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType,
                                                                                      NSCharacterEncodingDocumentAttribute: @(NSUTF8StringEncoding)}
                                                               documentAttributes: nil
                                                                            error: &err];
  if(err)
    NSLog(@"Unable to parse label text: %@", err);
  
  return attributedString;
}

- (void)updateFontSizeOnTextTo:(TextFontSize)newFontSize {
  if (self.fontSize == newFontSize) {
    return;
  }
  
  self.fontSize = newFontSize;
  
  for (XMMResponseContentBlock *contentItem in self.itemsToDisplay) {
    if ([contentItem isKindOfClass:[TextBlockTableViewCell class]]) {
      TextBlockTableViewCell* textBlock = (TextBlockTableViewCell*)contentItem;
      textBlock.contentLabel.attributedText = [self attributedStringFromHTML:textBlock.contentText];
      [textBlock.titleLabel setFont:[UIFont fontWithName:nil size:self.fontSize]];
      
      if ([contentItem.contentBlockType isEqualToString:@"title"]) {
        [textBlock.titleLabel setFont:[UIFont systemFontOfSize:self.fontSize+6]];
      }
    }
  }
  
  [self reloadTableView];
}

- (void)reloadTableView {
  if ([self.delegate respondsToSelector:@selector(reloadTableViewForContentBlocks)]) {
    [self.delegate performSelector:@selector(reloadTableViewForContentBlocks)];
  }
}

#pragma mark - Image methods

- (void)downloadImageWithURL:(NSString *)url completionBlock:(void (^)(BOOL succeeded, UIImage *image))completionBlock
{
  NSURL *realUrl = [[NSURL alloc]initWithString:url];
  NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:realUrl];
  [NSURLConnection sendAsynchronousRequest:request
                                     queue:[NSOperationQueue mainQueue]
                         completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
                           if ( !error )
                           {
                             UIImage *image = [[UIImage alloc] initWithData:data];
                             completionBlock(YES,image);
                           } else{
                             completionBlock(NO,nil);
                           }
                         }];
}


@end
