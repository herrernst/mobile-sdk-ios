/*   Copyright 2013 APPNEXUS INC
 
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

#import "ANAdAdapterBannerMillennialMedia.h"
#import "ANLogging.h"
#import <MMAdSDK/MMAdSDK.h>

@interface ANAdAdapterBannerMillennialMedia () <MMInlineDelegate>

@property (nonatomic, readwrite, strong) MMInlineAd *inlineAd;
@property (nonatomic, readwrite, weak) UIViewController *rootViewController;

@end

@implementation ANAdAdapterBannerMillennialMedia
@synthesize delegate;

#pragma mark ANCustomAdapterBanner

- (void)requestBannerAdWithSize:(CGSize)size
             rootViewController:(UIViewController *)rootViewController
                serverParameter:(NSString *)parameterString
                       adUnitId:(NSString *)idString
            targetingParameters:(ANTargetingParameters *)targetingParameters {
    ANLogTrace(@"%@ %@ | Requesting MillennialMedia banner with size %fx%f",
               NSStringFromClass([self class]), NSStringFromSelector(_cmd), size.width, size.height);
    if (!idString) {
        [self.delegate didFailToLoadAd:ANAdResponseUnableToFill];
        return;
    }
    [self configureMillennialSettingsWithTargetingParameters:targetingParameters];
    self.inlineAd = [[MMInlineAd alloc] initWithPlacementId:idString
                                                       size:size];
    self.inlineAd.delegate = self;
    self.inlineAd.refreshInterval = MMInlineDisableRefresh;
    self.rootViewController = rootViewController;
    
    MMRequestInfo *requestInfo = [[MMRequestInfo alloc] init];
    requestInfo.keywords = [[targetingParameters.customKeywords allValues] copy];
    
    [self.inlineAd request:requestInfo];
}

- (void)dealloc {
    self.inlineAd.delegate = nil;
}

#pragma mark - MMInlineDelegate

- (UIViewController * __nonnull)viewControllerForPresentingModalView {
    ANLogTrace(@"%@ %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
    return self.rootViewController;
}

- (void)inlineAdRequestDidSucceed:(MMInlineAd * __nonnull)ad {
    ANLogTrace(@"%@ %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
    if (self.inlineAd.view) {
        [self.delegate didLoadBannerAd:self.inlineAd.view];
    } else {
        [self.delegate didFailToLoadAd:ANAdResponseUnableToFill];
    }
}

- (void)inlineAd:(MMInlineAd * __nonnull)ad requestDidFailWithError:(NSError * __nonnull)error {
    ANLogDebug(@"MillennialMedia banner failed to load with error: %@", error);
    ANAdResponseCode code = ANAdResponseInternalError;
    
    switch (error.code) {
        case MMSDKErrorServerResponseBadStatus:
            code = ANAdResponseInvalidRequest;
            break;
        case MMSDKErrorServerResponseNoContent:
            code = ANAdResponseUnableToFill;
            break;
        case MMSDKErrorPlacementRequestInProgress:
            code = ANAdResponseInternalError;
            break;
        case MMSDKErrorRequestsDisabled:
            ANLogDebug(@"%@ - MMSDKErrorRequestsDisabled", NSStringFromSelector(_cmd));
            code = ANAdResponseMediatedSDKUnavailable;
            break;
        case MMSDKErrorNoFill:
            code = ANAdResponseUnableToFill;
            break;
        case MMSDKErrorVersionMismatch:
            code = ANAdResponseInternalError;
            break;
        case MMSDKErrorMediaDownloadFailed:
            code = ANAdResponseNetworkError;
            break;
        case MMSDKErrorRequestTimeout:
            code = ANAdResponseNetworkError;
            break;
        case MMSDKErrorNotInitialized:
            ANLogDebug(@"%@ - MMSDKErrorNotInitialized", NSStringFromSelector(_cmd));
            code = ANAdResponseInternalError;
            break;
        default:
            code = ANAdResponseInternalError;
            break;
    }
    
    [self.delegate didFailToLoadAd:code];
}

- (void)inlineAdContentTapped:(MMInlineAd * __nonnull)ad {
    ANLogTrace(@"%@ %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
    [self.delegate adWasClicked];
}

- (void)inlineAd:(MMInlineAd * __nonnull)ad
    willResizeTo:(CGRect)frame
       isClosing:(BOOL)isClosingResize {
    ANLogTrace(@"%@ %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
    // Do nothing
}

- (void)inlineAd:(MMInlineAd * __nonnull)ad
     didResizeTo:(CGRect)frame
       isClosing:(BOOL)isClosingResize {
    ANLogTrace(@"%@ %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
    // Do nothing
}

- (void)inlineAdWillPresentModal:(MMInlineAd * __nonnull)ad {
    ANLogTrace(@"%@ %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
    [self.delegate willPresentAd];
}

- (void)inlineAdDidPresentModal:(MMInlineAd * __nonnull)ad {
    ANLogTrace(@"%@ %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
    [self.delegate didPresentAd];
}

- (void)inlineAdWillCloseModal:(MMInlineAd * __nonnull)ad {
    ANLogTrace(@"%@ %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
    [self.delegate willCloseAd];
}

- (void)inlineAdDidCloseModal:(MMInlineAd * __nonnull)ad {
    ANLogTrace(@"%@ %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
    [self.delegate didCloseAd];
}

- (void)inlineAdWillLeaveApplication:(MMInlineAd * __nonnull)ad {
    ANLogTrace(@"%@ %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
    [self.delegate willLeaveApplication];
}

@end
