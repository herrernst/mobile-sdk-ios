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

#import "ANAdAdapterInterstitialMillennialMedia.h"
#import "ANLogging.h"
#import <MillennialMedia/MMInterstitial.h>

@interface ANAdAdapterInterstitialMillennialMedia ()
@property (nonatomic, readwrite, strong) NSString *apid;
@end

@implementation ANAdAdapterInterstitialMillennialMedia
@synthesize delegate;

#pragma mark ANCustomAdapterInterstitial

- (void)requestInterstitialAdWithParameter:(NSString *)parameterString
                                  adUnitId:(NSString *)idString
                       targetingParameters:(ANTargetingParameters *)targetingParameters
{
    ANLogDebug(@"Requesting MillennialMedia interstitial");
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wexplicit-initialize-call"
    [MMSDK initialize];
#pragma clang diagnostic pop
    [self addMMNotificationObservers];
    
    self.apid = idString;
    
    if ([self isReady]) {
        ANLogDebug(@"MillennialMedia interstitial was already available, attempting to load cached ad");
        [self.delegate didLoadInterstitialAd:self];
        return;
    }
    
    //MMRequest object
    MMRequest *request = [self createRequestFromTargetingParameters:targetingParameters];
    
    [MMInterstitial fetchWithRequest:request
                                apid:idString
                        onCompletion:^(BOOL success, NSError *error) {
                            if (success) {
                                ANLogDebug(@"MillennialMedia interstitial did load");
                                dispatch_async(dispatch_get_main_queue(), ^{
                                    [self.delegate didLoadInterstitialAd:self];
                                });
                            } else {
                                ANLogDebug(@"MillennialMedia interstitial failed to load with error: %@", error);
                                ANAdResponseCode code = ANAdResponseInternalError;
                                
                                switch (error.code) {
                                    case MMAdUnknownError:
                                        code = ANAdResponseInternalError;
                                        break;
                                    case MMAdServerError:
                                        code = ANAdResponseUnableToFill;
                                        break;
                                    case MMAdUnavailable:
                                        code = ANAdResponseUnableToFill;
                                        break;
                                    case MMAdDisabled:
                                        code = ANAdResponseInvalidRequest;
                                        break;
                                    default:
                                        code = ANAdResponseInternalError;
                                        break;
                                }
                                
                                dispatch_async(dispatch_get_main_queue(), ^{
                                    [self.delegate didFailToLoadAd:code];
                                });
                            }
                        }];
    
    
}

- (void)presentFromViewController:(UIViewController *)viewController
{
    if (![self isReady]) {
        ANLogDebug(@"MillennialMedia interstitial no longer available, failed to present ad");
        [self.delegate failedToDisplayAd];
        return;
    }
    
    ANLogDebug(@"Showing MillennialMedia interstitial");
    [MMInterstitial displayForApid:self.apid
                fromViewController:viewController
                   withOrientation:0
                      onCompletion:^(BOOL success, NSError *error) {
                          if (!success) {
                              ANLogDebug(@"MillennialMedia interstitial call to display ad failed");
                              dispatch_async(dispatch_get_main_queue(), ^{
                                  [self.delegate failedToDisplayAd];
                              });
                          }
                      }];
}

- (BOOL)isReady {
    return [MMInterstitial isAdAvailableForApid:self.apid];
}

@end
