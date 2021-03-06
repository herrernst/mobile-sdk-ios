/*   Copyright 2015 APPNEXUS INC
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */

#import "ANAdAdapterNativeInMobi.h"
#import "ANAdAdapterBaseInMobi.h"
#import "ANAdAdapterBaseInMobi+PrivateMethods.h"
#import "ANLogging.h"
#import "ANGlobal.h"
#import "IMSdk.h"
#import "IMNative.h"

static NSInteger const kANAdAdapterNativeInMobiRatingScaleDefault = 5;
static NSString *const kANAdAdapterNativeInMobiImageURLKey = @"url";

@interface ANAdAdapterNativeInMobi () <IMNativeDelegate>

@property (nonatomic, readwrite, strong) IMNative *nativeAd;
@property (nonatomic, readwrite, strong) NSDictionary *nativeContent;
@property (nonatomic, readwrite, weak) UIView *boundView;

@end

@implementation ANAdAdapterNativeInMobi

@synthesize requestDelegate = _requestDelegate;
@synthesize nativeAdDelegate = _nativeAdDelegate;
@synthesize expired = _expired;

#pragma mark - InMobi Key Names

static NSString *kANAdAdapterNativeInMobiTitleKey = @"title";
static NSString *kANAdAdapterNativeInMobiDescriptionKey = @"description";
static NSString *kANAdAdapterNativeInMobiCTAKey = @"cta";
static NSString *kANAdAdapterNativeInMobiIconKey = @"icon";
static NSString *kANAdAdapterNativeInMobiScreenshotsKey = @"screenshots";
static NSString *kANAdAdapterNativeInMobiRatingKey = @"rating";
static NSString *kANAdAdapterNativeInMobiLandingURLKey = @"landingURL";

+ (void)setTitleKey:(NSString *)key {
    kANAdAdapterNativeInMobiTitleKey = key;
}

+ (void)setDescriptionTextKey:(NSString *)key {
    kANAdAdapterNativeInMobiDescriptionKey = key;
}

+ (void)setCallToActionKey:(NSString *)key {
    kANAdAdapterNativeInMobiCTAKey = key;
}

+ (void)setIconKey:(NSString *)key {
    kANAdAdapterNativeInMobiIconKey = key;
}

+ (void)setScreenshotKey:(NSString *)key {
    kANAdAdapterNativeInMobiScreenshotsKey = key;
}

+ (void)setRatingCountKey:(NSString *)key {
    kANAdAdapterNativeInMobiRatingKey = key;
}

+ (void)setLandingURLKey:(NSString *)key {
    kANAdAdapterNativeInMobiLandingURLKey = key;
}

# pragma mark - ANNativeCustomAdapter

- (void)requestNativeAdWithServerParameter:(NSString *)parameterString
                                  adUnitId:(NSString *)adUnitId
                       targetingParameters:(ANTargetingParameters *)targetingParameters {
    ANLogTrace(@"%@ %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
    if (![ANAdAdapterBaseInMobi appId].length) {
        ANLogError(@"InMobi mediation failed. Call [ANAdAdapterBaseInMobi setInMobiAppID:@\"YOUR_PROPERTY_ID\"] to set the InMobi global App Id");
        [self.requestDelegate didFailToLoadNativeAd:ANAdResponseMediatedSDKUnavailable];
        return;
    }
    if (!adUnitId.length) {
        ANLogError(@"Unable to load InMobi native ad due to empty ad unit id");
        [self.requestDelegate didFailToLoadNativeAd:ANAdResponseUnableToFill];
        return;
    }
    NSString *appId;
    if (adUnitId.length) {
        appId = adUnitId;
    } else {
        appId = [ANAdAdapterBaseInMobi appId];
    }
    self.nativeAd = [[IMNative alloc] initWithPlacementId:[adUnitId longLongValue]];
    self.nativeAd.delegate = self;
    self.nativeAd.extras = targetingParameters.customKeywords;
    self.nativeAd.keywords = [ANAdAdapterBaseInMobi keywordsFromTargetingParameters:targetingParameters];
    [self.nativeAd load];
}

- (void)registerViewForImpressionTracking:(UIView *)view {
    ANLogTrace(@"%@ %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
    [IMNative bindNative:self.nativeAd
                  toView:view];
    self.boundView = view;
    self.expired = YES;
}

- (void)handleClickFromRootViewController:(UIViewController *)rvc {
    ANLogTrace(@"%@ %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
    id landingPageURLValue = self.nativeContent[kANAdAdapterNativeInMobiLandingURLKey];
    if ([landingPageURLValue isKindOfClass:[NSString class]]) {
        NSString *landingPageURLString = (NSString *)landingPageURLValue;
        [self.nativeAdDelegate adWasClicked];
        [self.nativeAd reportAdClick:nil];
        NSURL *landingPageURL = [NSURL URLWithString:landingPageURLString];
        if (landingPageURL) {
            [self.nativeAdDelegate willLeaveApplication];
            [ANGlobal openURL:[landingPageURL absoluteString]];
        }
    } else {
        ANLogDebug(@"InMobi ad was clicked, but adapter was unable to find landing url –– Ignoring request to handle click.");
    }
}

- (void)unregisterViewFromTracking {
    ANLogTrace(@"%@ %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
    if (self.boundView) {
        [IMNative unBindView:self.boundView];
    }
    self.nativeAd.delegate = nil;
    self.nativeAd = nil;
}

#pragma mark - IMNativeDelegate

- (void)nativeDidFinishLoading:(IMNative *)native {
    ANLogTrace(@"%@ %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
    NSDictionary *nativeContent = [[self class] nativeContentFromContentString:native.adContent];
    if (!nativeContent) {
        [self.requestDelegate didFailToLoadNativeAd:ANAdResponseInternalError];
        return;
    }
    self.nativeContent = nativeContent;
    ANNativeMediatedAdResponse *adResponse = [self nativeAdResponseFromNativeContent:nativeContent];
    if (!adResponse) {
        [self.requestDelegate didFailToLoadNativeAd:ANAdResponseInternalError];
        return;
    }
    [self.requestDelegate didLoadNativeAd:adResponse];
}

- (void)native:(IMNative*)native didFailToLoadWithError:(IMRequestStatus *)error {
    ANLogTrace(@"%@ %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
    ANLogDebug(@"Received InMobi Error: %@", error);
    [self.requestDelegate didFailToLoadNativeAd:[ANAdAdapterBaseInMobi responseCodeFromInMobiRequestStatus:error]];
}

-(void)nativeWillPresentScreen:(IMNative *)native {
    ANLogTrace(@"%@ %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
    [self.nativeAdDelegate willPresentAd];
}

- (void)nativeDidPresentScreen:(IMNative *)native {
    ANLogTrace(@"%@ %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
    [self.nativeAdDelegate didPresentAd];
}

- (void)nativeWillDismissScreen:(IMNative *)native {
    ANLogTrace(@"%@ %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
    [self.nativeAdDelegate willCloseAd];

}

- (void)nativeDidDismissScreen:(IMNative *)native {
    ANLogTrace(@"%@ %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
    [self.nativeAdDelegate didCloseAd];
}

- (void)userWillLeaveApplicationFromNative:(IMNative *)native {
    ANLogTrace(@"%@ %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
    [self.nativeAdDelegate willLeaveApplication];
}

#pragma mark - Helper

+ (NSDictionary *)nativeContentFromContentString:(NSString *)content {
    NSData *data = [content dataUsingEncoding:NSUTF8StringEncoding];
    NSError *error = nil;
    id jsonObject = [NSJSONSerialization JSONObjectWithData:data
                                                    options:kNilOptions
                                                      error:&error];
    if ([jsonObject isKindOfClass:[NSDictionary class]]) {
        return (NSDictionary *)jsonObject;
    }
    return nil;
}

- (ANNativeMediatedAdResponse *)nativeAdResponseFromNativeContent:(NSDictionary *)nativeContent {
    ANNativeMediatedAdResponse *adResponse = [[ANNativeMediatedAdResponse alloc] initWithCustomAdapter:self
                                                                                           networkCode:ANNativeAdNetworkCodeInMobi];
    adResponse.customElements = nativeContent;
    
    id titleValue = nativeContent[kANAdAdapterNativeInMobiTitleKey];
    if ([titleValue isKindOfClass:[NSString class]]) {
        adResponse.title = (NSString *)titleValue;
    }
    
    id bodyValue = nativeContent[kANAdAdapterNativeInMobiDescriptionKey];
    if ([bodyValue isKindOfClass:[NSString class]]) {
        adResponse.body = (NSString *)bodyValue;
    }
    
    id ctaValue = [nativeContent valueForKey:kANAdAdapterNativeInMobiCTAKey];
    if ([ctaValue isKindOfClass:[NSString class]]) {
        adResponse.callToAction = (NSString *)ctaValue;
    }
    
    id iconValue = nativeContent[kANAdAdapterNativeInMobiIconKey];
    if ([iconValue isKindOfClass:[NSDictionary class]]) {
        NSDictionary *imageDict = (NSDictionary *)iconValue;
        id imageUrlValue = imageDict[kANAdAdapterNativeInMobiImageURLKey];
        if ([imageUrlValue isKindOfClass:[NSString class]]) {
            adResponse.iconImageURL = [NSURL URLWithString:(NSString *)imageUrlValue];
        }
    }
    
    id screenshotsValue = nativeContent[kANAdAdapterNativeInMobiScreenshotsKey];
    if ([screenshotsValue isKindOfClass:[NSDictionary class]]) {
        NSDictionary *imageDict = (NSDictionary *)screenshotsValue;
        id imageUrlValue = imageDict[kANAdAdapterNativeInMobiImageURLKey];
        if ([imageUrlValue isKindOfClass:[NSString class]]) {
            adResponse.mainImageURL = [NSURL URLWithString:(NSString *)imageUrlValue];
        }
    }
    
    id ratingValue = nativeContent[kANAdAdapterNativeInMobiRatingKey];
    if ([ratingValue isKindOfClass:[NSNumber class]]) {
        NSNumber *rating = (NSNumber *)ratingValue;
        adResponse.rating = [[ANNativeAdStarRating alloc] initWithValue:[rating floatValue]
                                                                  scale:kANAdAdapterNativeInMobiRatingScaleDefault];
    }

    return adResponse;
}

- (void)dealloc {
    [self unregisterViewFromTracking];
}

@end
