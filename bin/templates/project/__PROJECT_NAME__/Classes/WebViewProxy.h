//
//  WebViewProxy.h
//  Tabris
//
//  Created by Jordi Böhme López on 27.11.14.
//  Copyright (c) 2014 EclipseSource. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Cordova/CDVWebViewEngineProtocol.h>
#import <Tabris/Tabris.h>

@interface WebViewProxy : NSObject <CDVWebViewEngineProtocol>
- (instancetype)initWithContext:(id<TabrisContext>)context;
- (NSString *)stringByEvaluatingJavaScriptFromString:(NSString *)script;
@property (nonatomic, readonly, retain) NSURLRequest *request;
@end
