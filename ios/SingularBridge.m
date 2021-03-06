#import "SingularBridge.h"

#import <Singular/Singular.h>

#if __has_include(<React/RCTBridge.h>)
#import <React/RCTBridge.h>
#elif __has_include(“RCTBridge.h”)
#else
#import “RCTBridge.h”
#endif

#if __has_include(<React/RCTEventDispatcher.h>)
#import <React/RCTEventDispatcher.h>
#elif __has_include(“RCTEventDispatcher.h”)
#else
#import “RCTEventDispatcher.h”
#endif

@implementation SingularBridge
@synthesize bridge = _bridge;

static NSString* apikey;
static NSString* secret;
static NSDictionary* launchOptions;
static BOOL isSingularLinkEnabled = NO;
static RCTEventEmitter* eventEmitter;

// Saving the launchOptions for later when the SDK is initialized to handle Singular Links.
// The client will need to call this method is the AppDelegate in didFinishLaunchingWithOptions.
+(void)startSessionWithLaunchOptions:(NSDictionary*)options{
    launchOptions = options;
}

// Handling Singular Link when the app is opened from a Singular Link while it was in the background.
// The client will need to call this method in the AppDelegate in continueUserActivity.
+(void)startSessionWithUserActivity:(NSUserActivity*)userActivity{
    if(!isSingularLinkEnabled){
        return;
    }
    
    [Singular startSession:apikey
                   withKey:secret
           andUserActivity:userActivity
   withSingularLinkHandler:^(SingularLinkParams * params){
        [SingularBridge handleSingularLink:params];
    }];
}

RCT_EXPORT_MODULE();

- (NSArray<NSString *> *)supportedEvents
{
    return @[@"SingularLinkHandler"];
}

RCT_EXPORT_METHOD(init:(NSString*)apikey
                  secret:(NSString*)secret
                  customUserId:(NSString*)customUserId
                  sessionTimeout:(nonnull NSNumber*)sessionTimeout){
    if(customUserId){
        [Singular setCustomUserId:customUserId];
    }
    
    if([sessionTimeout intValue] >= 0){
        [Singular setSessionTimeout:[sessionTimeout intValue]];
    }
    
    [Singular startSession:apikey withKey:secret];
}

RCT_EXPORT_METHOD(initWithSingularLink:(NSString*)apikey
                  secret:(NSString*)secret
                  customUserId:(NSString*)customUserId
                  sessionTimeout:(nonnull NSNumber*)sessionTimeout){
    if(customUserId){
        [Singular setCustomUserId:customUserId];
    }
    
    if([sessionTimeout intValue] >= 0){
        [Singular setSessionTimeout:[sessionTimeout intValue]];
    }
    
    isSingularLinkEnabled = YES;
    eventEmitter = self;
    
    [Singular startSession:apikey
                   withKey:secret
          andLaunchOptions:launchOptions
   withSingularLinkHandler:^(SingularLinkParams * params){
        [SingularBridge handleSingularLink:params];
    }];
}

RCT_EXPORT_METHOD(setCustomUserId:(NSString*)customUserId){
    [Singular setCustomUserId:customUserId];
}

RCT_EXPORT_METHOD(unsetCustomUserId){
    [Singular unsetCustomUserId];
}

RCT_EXPORT_METHOD(event:(NSString*)eventName){
    [Singular event:eventName];
}

RCT_EXPORT_METHOD(eventWithArgs:(NSString*)eventName args:(NSString*)args){
    [Singular event:eventName withArgs:[SingularBridge jsonToDictionary:args]];
}

RCT_EXPORT_METHOD(revenue:(NSString*)currency amount:(double)amount){
    [Singular revenue:currency amount:amount];
}

RCT_EXPORT_METHOD(revenueWithArgs:(NSString*)currency amount:(double)amount args:(NSString*)args){
    [Singular revenue:currency amount:amount withAttributes:[SingularBridge jsonToDictionary:args]];
}

RCT_EXPORT_METHOD(customRevenue:(NSString*)eventName currency:(NSString*)currency amount:(double)amount){
    [Singular customRevenue:eventName currency:currency amount:amount];
}

RCT_EXPORT_METHOD(customRevenueWithArgs:(NSString*)eventName currency:(NSString*)currency amount:(double)amount args:(NSString*)args){
    [Singular customRevenue:eventName currency:currency amount:amount withAttributes:[SingularBridge jsonToDictionary:args]];
}

RCT_EXPORT_METHOD(setUninstallToken:(NSString*)token){
    [Singular registerDeviceTokenForUninstall:[token dataUsingEncoding:NSUTF8StringEncoding]];
}

RCT_EXPORT_METHOD(trackingOptIn){
    [Singular trackingOptIn];
}

RCT_EXPORT_METHOD(trackingUnder13){
    [Singular trackingUnder13];
}

RCT_EXPORT_METHOD(stopAllTracking){
    [Singular stopAllTracking];
}

RCT_EXPORT_METHOD(resumeAllTracking){
    [Singular resumeAllTracking];
}

RCT_EXPORT_BLOCKING_SYNCHRONOUS_METHOD(isAllTrackingStopped){
    return [Singular isAllTrackingStopped] ? @YES : @NO;
}

RCT_EXPORT_METHOD(limitDataSharing:(BOOL)limitDataSharingValue){
    [Singular limitDataSharing:limitDataSharingValue];
}

RCT_EXPORT_BLOCKING_SYNCHRONOUS_METHOD(getLimitDataSharing){
    return [Singular getLimitDataSharing] ? @YES : @NO;
}

RCT_EXPORT_METHOD(setReactSDKVersion:(NSString*)wrapper version:(NSString*)version){
    [Singular setWrapperName:wrapper andVersion:version];
}

#pragma mark - Private methods

+(NSDictionary*)jsonToDictionary:(NSString*)json{
    if(!json){
        return nil;
    }
    
    NSError *jsonError = nil;
    NSData *objectData = [json dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *data = [NSJSONSerialization JSONObjectWithData:objectData
                                                         options:NSJSONReadingMutableContainers
                                                           error:&jsonError];
    
    if(!jsonError){
        return nil;
    }
    
    return data;
}

+(void)handleSingularLink:(SingularLinkParams*)params{
    
    // Raising the Singular Link handler in the react-native code
    [eventEmitter sendEventWithName:@"SingularLinkHandler" body:@{
        @"deeplink": [params getDeepLink],
        @"passthrough": [params getPassthrough],
        @"isDeferred": [params isDeferred] ? @YES : @NO
    }];
}

@end
