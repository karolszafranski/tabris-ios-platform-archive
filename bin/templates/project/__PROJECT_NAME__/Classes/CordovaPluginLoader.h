//
//  CordovaPluginLoader.h
//  Tabris
//
//  Created by Jordi Böhme López on 27.11.14.
//  Copyright (c) 2014 EclipseSource. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Cordova/CDVPlugin.h>
#import "WebViewProxy.h"

@interface CordovaPluginLoader : NSObject
- (instancetype)initWithWebView:(WebViewProxy *)webViewProxy;
- (CDVPlugin *)load:(NSString *)service;
- (void)unload:(NSString *)service;
@end
