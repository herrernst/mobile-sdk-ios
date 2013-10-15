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

#import <Foundation/Foundation.h>
#import "ANAdResponse.h"
#import "ANLocation.h"

@protocol ANCustomAdapterDelegate <NSObject>
@end

@protocol ANCustomAdapter <NSObject>
@property (nonatomic, readwrite, copy) NSString *responseURLString;
@property (nonatomic, readwrite, weak) id<ANCustomAdapterDelegate> delegate;
@end

@protocol ANCustomAdapterBannerDelegate;

@protocol ANCustomAdapterBanner <ANCustomAdapter>
- (void)requestBannerAdWithSize:(CGSize)size
                serverParameter:(NSString *)parameterString
                       adUnitId:(NSString *)idString
                       location:(ANLocation *)location;
@property (nonatomic, readwrite, weak) id<ANCustomAdapterBannerDelegate, ANCustomAdapterDelegate> delegate;
@end


@protocol ANCustomAdapterInterstitialDelegate;

@protocol ANCustomAdapterInterstitial <ANCustomAdapter>
- (void)requestInterstitialAdWithParameter:(NSString *)parameterString
                                  adUnitId:(NSString *)idString
                                  location:(ANLocation *)location;
- (void)presentFromViewController:(UIViewController *)viewController;
@property (nonatomic, readwrite, weak) id<ANCustomAdapterInterstitialDelegate, ANCustomAdapterDelegate> delegate;
@end


@protocol ANCustomAdapterBannerDelegate <ANCustomAdapterDelegate>

- (void)adapterBanner:(id<ANCustomAdapterBanner>)adapter didReceiveBannerAdView:(UIView *)view;
- (void)adapterBanner:(id<ANCustomAdapterBanner>)adapter didFailToReceiveBannerAdView:(ANAdResponseCode)errorCode;

@end

@protocol ANCustomAdapterInterstitialDelegate <ANCustomAdapterDelegate>

- (void)adapterInterstitial:(id<ANCustomAdapterInterstitial>)adapter didLoadInterstitialAd:(id)interstitialAd;
- (void)adapterInterstitial:(id<ANCustomAdapterInterstitial>)adapter didFailToReceiveInterstitialAd:(ANAdResponseCode)errorCode;

@end