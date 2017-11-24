//
//  CordovaPluginLoader.m
//  Tabris
//
//  Created by Jordi Böhme López on 27.11.14.
//  Copyright (c) 2014 EclipseSource. All rights reserved.
//

#import "CordovaPluginLoader.h"
#import "CordovaConfig.h"

@interface CDVPlugin ()
- (instancetype)initWithWebViewEngine:(id <CDVWebViewEngineProtocol>)theWebViewEngine;
@end

@interface CordovaPluginLoader ()
@property (strong) WebViewProxy *webViewProxy;
@end

@implementation CordovaPluginLoader

@synthesize webViewProxy = _webViewProxy;

- (instancetype)initWithWebView:(WebViewProxy *)webViewProxy {
    self = [super init];
    if (self) {
        _webViewProxy = webViewProxy;
        [self.class initializePlugins];
    }
    return self;
}

static NSMutableDictionary *plugins;

- (NSDictionary *)pluginRegistry {
    return [CordovaConfig config].plugins;
}

- (NSMutableDictionary *)plugins {
    return plugins;
}

+ (void)initializePlugins {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        plugins = [NSMutableDictionary dictionary];
    });
}

- (CDVPlugin *)load:(NSString *)service {
    CDVPlugin *plugin = [plugins objectForKey:service];
    if( !plugin ) {
        plugin = [self createPlugin:service];
        if( plugin ) {
            [plugins setObject:plugin forKey:service];
        }
    }
    return plugin;
}

- (void)unload:(NSString *)service {
    [plugins removeObjectForKey:service];
}

- (CDVPlugin *)createPlugin:(NSString *)service {
    NSString *className = [[self pluginRegistry] objectForKey:[service lowercaseString]];
    Class pluginClass = NSClassFromString(className);
    if( pluginClass ) {
        return (CDVPlugin *)[[pluginClass alloc] initWithWebViewEngine:self.webViewProxy];
    }
    return nil;
}

@end
