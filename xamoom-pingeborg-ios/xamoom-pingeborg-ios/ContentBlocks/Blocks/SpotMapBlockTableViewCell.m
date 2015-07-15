//
//  SpotMapBlockTableViewCell.m
//  xamoom-pingeborg-ios
//
//  Created by Raphael Seher on 15/04/15.
//  Copyright (c) 2015 xamoom GmbH. All rights reserved.
//

#import "SpotMapBlockTableViewCell.h"

#define MINIMUM_ZOOM_ARC 0.014
#define ANNOTATION_REGION_PAD_FACTOR 1.15
#define MAX_DEGREES_ARC 360

@interface CustomMapView2 : MKMapView

@property (nonatomic, strong) SMCalloutView *calloutView;

@end

@implementation SpotMapBlockTableViewCell

- (void)awakeFromNib {
  // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
  [super setSelected:selected animated:animated];
  
  // Configure the view for the selected state
}

- (void)setupMapView {
  //init map
  self.mapKitWithSMCalloutView = [[CustomMapView2 alloc] initWithFrame:self.viewForMap.bounds];
  self.mapKitWithSMCalloutView.delegate = self;
  self.mapKitWithSMCalloutView.showsUserLocation = YES;
  [self.viewForMap addSubview:self.mapKitWithSMCalloutView];
}

- (void)getSpotMapWithSystemId:(NSString*)systemId withLanguage:(NSString*)language {
  [[XMMEnduserApi sharedInstance] spotMapWithSystemId:0 withMapTags:self.spotMapTags withLanguage:language
                                           completion:^(XMMResponseGetSpotMap *result) {
                                             [self.loadingIndicator stopAnimating];
                                             [self setupMapView];
                                             [self showSpotMap:result];
                                           } error:^(XMMError *error) {
                                             NSLog(@"Error: %@", error.message);
                                           }];
}

#pragma mark - XMMEnduser Delegate

- (void)showSpotMap:(XMMResponseGetSpotMap *)result {
  //get the customMarker for the map
  if (result.style.customMarker != nil) {
    [self mapMarkerFromBase64:result.style.customMarker];
  }
  
  // Add annotations
  for (XMMResponseGetSpotMapItem *item in result.items) {
    XMMAnnotation *point = [[XMMAnnotation alloc] initWithLocation: CLLocationCoordinate2DMake(item.lat, item.lon)];
    point.data = item;
    
    [self.mapKitWithSMCalloutView addAnnotation:point];
  }
  
  [self zoomMapViewToFitAnnotations:self.mapKitWithSMCalloutView animated:YES];
}

- (void)mapMarkerFromBase64:(NSString*)base64String {
  NSData *decodedData = [[NSData alloc] initWithBase64EncodedString:base64String options:0];
  NSString *decodedString = [[NSString alloc] initWithData:decodedData encoding:NSUTF8StringEncoding];
  
  if ([decodedString containsString:@"data:image/svg"]) {
    //create svg need to DECODE TWO TIMES!
    decodedString = [decodedString stringByReplacingOccurrencesOfString:@"data:image/svg+xml;base64," withString:@""];
    NSData *decodedData2 = [[NSData alloc] initWithBase64EncodedString:decodedString options:0];
    NSString *decodedString2 = [[NSString alloc] initWithData:decodedData2 encoding:NSUTF8StringEncoding];
    self.customSVGMapMarker = [SVGKImage imageWithSource:[SVGKSourceString sourceFromContentsOfString:decodedString2]];
  } else {
    //create UIImage
    NSData *imageData = [NSData dataWithContentsOfURL:[NSURL URLWithString:decodedString]];
    self.customMapMarker = [XMMImageUtility imageWithImage:[UIImage imageWithData:imageData] scaledToMaxWidth:30.0f maxHeight:30.0f];
  }
}

#pragma mark MKMapView delegate methods

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation {
  //do not touch userLocation
  if ([annotation isKindOfClass:[MKUserLocation class]])
    return nil;
  
  if ([annotation isKindOfClass:[XMMAnnotation class]]) {
    static NSString *identifier = @"xamoomAnnotation";
    XMMAnnotationView *annotationView;
    if (annotationView == nil) {
      annotationView = [[XMMAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:identifier];
      annotationView.enabled = YES;
      annotationView.canShowCallout = NO;
      
      //set mapmarker
      if(self.customMapMarker) {
        annotationView.image = self.customMapMarker;
      } else if (self.customSVGMapMarker) {
        [annotationView displaySVG:self.customSVGMapMarker];
      } else {
        annotationView.image = [UIImage imageNamed:@"mappoint"];//here we use a nice image instead of the default pins
      }
      
      //save data in annotationView
      XMMAnnotation *xamoomAnnotation = (XMMAnnotation*)annotation;
      annotationView.data = xamoomAnnotation.data;
      annotationView.distance = xamoomAnnotation.distance;
      annotationView.coordinate = xamoomAnnotation.coordinate;
      
      //download image
      [XMMImageUtility imageWithUrl:xamoomAnnotation.data.image completionBlock:^(BOOL succeeded, UIImage *image, SVGKImage *svgImage) {
        if (image != nil) {
          annotationView.spotImage = image;
        } else if (svgImage != nil) {
          NSLog(@"There are no svgImages");
        } else {
          annotationView.spotImage = image;
        }
      }];
      
    } else {
      annotationView.annotation = annotation;
    }
    return annotationView;
  }
  
  return nil;
}

- (void)mapView:(MKMapView *)mapView didSelectAnnotationView:(MKAnnotationView *)annotationView {
  // create our custom callout view
  SMCalloutView *calloutView = [SMCalloutView platformCalloutView];
  calloutView.delegate = self;
  [calloutView setContentViewInset:UIEdgeInsetsMake(0.0f, 0.0f, 0.0f, 0.0f)];
  self.mapKitWithSMCalloutView.calloutView = calloutView;
  
  if ([annotationView isKindOfClass:[XMMAnnotationView class]]) {
    calloutView.contentView = [self createMapCalloutFrom:annotationView];
    calloutView.calloutOffset = annotationView.calloutOffset;
    
    [calloutView presentCalloutFromRect:annotationView.bounds inView:annotationView constrainedToView:self.mapKitWithSMCalloutView animated:YES];
  }
}

-(void)mapView:(MKMapView *)mapView didDeselectAnnotationView:(MKAnnotationView *)view {
  [self.mapKitWithSMCalloutView.calloutView dismissCalloutAnimated:YES];
}

#pragma mark - SMCalloutView delegate methods

- (NSTimeInterval)calloutView:(SMCalloutView *)calloutView delayForRepositionWithSize:(CGSize)offset {
  // reposition if offscreen
  CLLocationCoordinate2D coordinate = self.mapKitWithSMCalloutView.centerCoordinate;
  
  // where's the center coordinate in terms of our view?
  CGPoint center = [self.mapKitWithSMCalloutView convertCoordinate:coordinate toPointToView:self.mapKitWithSMCalloutView];
  
  // move it by the requested offset
  center.x -= offset.width;
  center.y -= offset.height;
  
  // and translate it back into map coordinates
  coordinate = [self.mapKitWithSMCalloutView convertPoint:center toCoordinateFromView:self.mapKitWithSMCalloutView];
  
  [self.mapKitWithSMCalloutView setCenterCoordinate:coordinate animated:YES];
  
  return kSMCalloutViewRepositionDelayForUIScrollView;
}

#pragma mark - Custom Methods

//size the mapView region to fit its annotations
- (void)zoomMapViewToFitAnnotations:(MKMapView *)mapView animated:(BOOL)animated {
  NSArray *annotations = mapView.annotations;
  int count = (int)[self.mapKitWithSMCalloutView.annotations count];
  if ( count == 0) { return; } //bail if no annotations
  
  //convert NSArray of id <MKAnnotation> into an MKCoordinateRegion that can be used to set the map size
  //can't use NSArray with MKMapPoint because MKMapPoint is not an id
  MKMapPoint points[count]; //C array of MKMapPoint struct
  for( int i=0; i<count; i++ ) //load points C array by converting coordinates to points
  {
    CLLocationCoordinate2D coordinate = [(id <MKAnnotation>)annotations[i] coordinate];
    points[i] = MKMapPointForCoordinate(coordinate);
  }
  //create MKMapRect from array of MKMapPoint
  MKMapRect mapRect = [[MKPolygon polygonWithPoints:points count:count] boundingMapRect];
  //convert MKCoordinateRegion from MKMapRect
  MKCoordinateRegion region = MKCoordinateRegionForMapRect(mapRect);
  
  //add padding so pins aren't scrunched on the edges
  region.span.latitudeDelta  *= ANNOTATION_REGION_PAD_FACTOR;
  region.span.longitudeDelta *= ANNOTATION_REGION_PAD_FACTOR;
  //but padding can't be bigger than the world
  if( region.span.latitudeDelta > MAX_DEGREES_ARC ) { region.span.latitudeDelta  = MAX_DEGREES_ARC; }
  if( region.span.longitudeDelta > MAX_DEGREES_ARC ){ region.span.longitudeDelta = MAX_DEGREES_ARC; }
  
  //and don't zoom in stupid-close on small samples
  if( region.span.latitudeDelta  < MINIMUM_ZOOM_ARC ) { region.span.latitudeDelta  = MINIMUM_ZOOM_ARC; }
  if( region.span.longitudeDelta < MINIMUM_ZOOM_ARC ) { region.span.longitudeDelta = MINIMUM_ZOOM_ARC; }
  //and if there is a sample of 1 we want the max zoom-in instead of max zoom-out
  if( count == 1 )
  {
    region.span.latitudeDelta = MINIMUM_ZOOM_ARC;
    region.span.longitudeDelta = MINIMUM_ZOOM_ARC;
  }
  [mapView setRegion:region animated:animated];
}

- (XMMCalloutView*)createMapCalloutFrom:(MKAnnotationView *)annotationView {
  XMMAnnotationView* xamoomAnnotationView = (XMMAnnotationView *)annotationView;
  XMMCalloutView* xamoomCalloutView = [[XMMCalloutView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 300.0f, 35.0f)];
  xamoomCalloutView.nameOfSpot = xamoomAnnotationView.data.displayName;
  
  //create titleLabel
  UILabel* titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(10.0f, 10.0f, 280.0f, 25.0f)];
  titleLabel.lineBreakMode = NSLineBreakByWordWrapping;
  titleLabel.numberOfLines = 0;
  titleLabel.text = xamoomAnnotationView.data.displayName;
  
  //size label to fit content
  CGRect titleLabelRect = titleLabel.frame;
  titleLabelRect.size = [titleLabel sizeThatFits:titleLabelRect.size];
  titleLabel.frame = titleLabelRect;
  
  [xamoomCalloutView addSubview:titleLabel];
  
  //increase pingeborCalloutView height
  CGRect xamoomCalloutViewRect = xamoomCalloutView.frame;
  xamoomCalloutViewRect.size.height += titleLabel.frame.size.height;
  xamoomCalloutView.frame = xamoomCalloutViewRect;
  
  UIImageView *spotImageView;
  
  //insert image
  if(xamoomAnnotationView.spotImage != nil) {
    if (xamoomAnnotationView.spotImage.size.width < xamoomAnnotationView.spotImage.size.height) {
      spotImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0.0f, titleLabel.frame.origin.y + titleLabel.frame.size.height, xamoomCalloutView.frame.size.width, xamoomCalloutView.frame.size.width)];
    } else {
      float imageRatio = xamoomAnnotationView.spotImage.size.width / xamoomAnnotationView.spotImage.size.height;
      spotImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0.0f, titleLabel.frame.origin.y + titleLabel.frame.size.height, xamoomCalloutView.frame.size.width, xamoomCalloutView.frame.size.width / imageRatio)];
    }
    
    [spotImageView setContentMode: UIViewContentModeScaleToFill];
    spotImageView.image = xamoomAnnotationView.spotImage;
    
    //increase pingeborCalloutView height
    CGRect xamoomCalloutViewRect = xamoomCalloutView.frame;
    xamoomCalloutViewRect.size.height += spotImageView.frame.size.height;
    xamoomCalloutView.frame = xamoomCalloutViewRect;
    
    [xamoomCalloutView addSubview:spotImageView];
  }
  
  //insert spotdescription
  if (![xamoomAnnotationView.data.descriptionOfSpot isEqualToString:@""]) {
    UILabel *spotDescriptionLabel;
    if ([xamoomCalloutView.subviews count] >= 2) {
      spotDescriptionLabel = [[UILabel alloc] initWithFrame:CGRectMake(10.0f, spotImageView.frame.size.height + spotImageView.frame.origin.y + 5.0f, 280.0f, 25.0f)];
    } else {
      spotDescriptionLabel = [[UILabel alloc] initWithFrame:CGRectMake(10.0f, titleLabel.frame.origin.y + titleLabel.frame.size.height + 5.0f, 280.0f, 25.0f)];
    }
    
    spotDescriptionLabel.lineBreakMode = NSLineBreakByWordWrapping;
    spotDescriptionLabel.numberOfLines = 0;
    spotDescriptionLabel.font = [UIFont systemFontOfSize:12];
    spotDescriptionLabel.textColor = [UIColor darkGrayColor];
    spotDescriptionLabel.text = xamoomAnnotationView.data.descriptionOfSpot;
    
    //resize label depending on content
    CGRect spotDescriptionLabelRect = spotDescriptionLabel.frame;
    spotDescriptionLabelRect.size = [spotDescriptionLabel sizeThatFits:spotDescriptionLabelRect.size];
    spotDescriptionLabel.frame = spotDescriptionLabelRect;
    
    //increase pingeborCalloutView height
    CGRect xamoomCalloutViewRect = xamoomCalloutView.frame;
    xamoomCalloutViewRect.size.height += spotDescriptionLabel.frame.size.height;
    xamoomCalloutView.frame = xamoomCalloutViewRect;
    
    [xamoomCalloutView addSubview:spotDescriptionLabel];
  }
  
  return xamoomCalloutView;
}

#pragma mark - Image Methods

- (UIImage *)imageWithImage:(UIImage *)image scaledToMaxWidth:(CGFloat)width maxHeight:(CGFloat)height {
  CGFloat oldWidth = image.size.width;
  CGFloat oldHeight = image.size.height;
  
  CGFloat scaleFactor = (oldWidth > oldHeight) ? width / oldWidth : height / oldHeight;
  
  CGFloat newHeight = oldHeight * scaleFactor;
  CGFloat newWidth = oldWidth * scaleFactor;
  CGSize newSize = CGSizeMake(newWidth, newHeight);
  
  return [self imageWithImage:image scaledToSize:newSize];
}

- (UIImage *)imageWithImage:(UIImage *)image scaledToSize:(CGSize)size {
  if ([[UIScreen mainScreen] respondsToSelector:@selector(scale)]) {
    UIGraphicsBeginImageContextWithOptions(size, NO, [[UIScreen mainScreen] scale]);
  } else {
    UIGraphicsBeginImageContext(size);
  }
  [image drawInRect:CGRectMake(0, 0, size.width, size.height)];
  UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();
  
  return newImage;
}

@end

#pragma mark - Custom Map View (subclass)

@interface MKMapView (UIGestureRecognizer)

// this tells the compiler that MKMapView actually implements this method
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch;

@end

@implementation CustomMapView2

// override UIGestureRecognizer's delegate method so we can prevent MKMapView's recognizer from firing
// when we interact with UIControl subclasses inside our callout view.
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
  if ([touch.view isKindOfClass:[UIControl class]])
    return NO;
  else
    return [super gestureRecognizer:gestureRecognizer shouldReceiveTouch:touch];
}

// Allow touches to be sent to our calloutview.
// See this for some discussion of why we need to override this: https://github.com/nfarina/calloutview/pull/9
- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
  
  UIView *calloutMaybe = [self.calloutView hitTest:[self.calloutView convertPoint:point fromView:self] withEvent:event];
  if (calloutMaybe) return calloutMaybe;
  
  return [super hitTest:point withEvent:event];
}

@end

