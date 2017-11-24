//
//  WebViewProxy.h
//  Tabris
//
//  Created by Jordi Böhme López on 27.11.14.
//  Copyright (c) 2014 EclipseSource. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Tabris/JSBinding.h>
#import <Cordova/CDVWebViewEngineProtocol.h>

@interface WebViewProxy : NSObject <CDVWebViewEngineProtocol>
- (instancetype)initWithView:(UIView *)forwardView andJSBinding:(JSBinding *)jsBinding andBaseURL:(NSURL *)baseURL;
- (NSString *)stringByEvaluatingJavaScriptFromString:(NSString *)script;
@property (nonatomic, readonly, retain) NSURLRequest *request;
@end
