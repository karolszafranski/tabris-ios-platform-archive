//
//  CordovaPluginBridge.m
//  Tabris
//
//  Created by Holger Staudacher & Jordi Böhme López on 17/10/14.
//  Copyright (c) 2014 EclipseSource. All rights reserved.
//

#import <Tabris/JSBinding.h>
#import <Cordova/CDVPlugin.h>
#import <Cordova/CDVInvokedUrlCommand.h>
#import <Cordova/CDVUserAgentUtil.h>
#import <Tabris/TabrisHTTPClient.h>
#import "CordovaPluginBridge.h"
#import "CordovaPluginLoader.h"

@interface CordovaPluginBridge ()
@property (strong) CDVPlugin *plugin;
@property (strong) CordovaPluginLoader *pluginLoader;
@property (strong, readonly) JSBinding *jsBinding;
@end

static CordovaPluginBridge *bridgeInstance;

@implementation CordovaPluginBridge

@synthesize finishListener = _finishListener;
@synthesize settings = _settings;
@synthesize service = _service;
@synthesize pluginLoader = _pluginLoader;
@synthesize jsBinding = _jsBinding;
@synthesize urlTransformer = _urlTransformer;

+ (NSString *)remoteObjectType {
    return @"cordova.plugin";
}

+ (NSMutableSet *)remoteObjectProperties {
    NSMutableSet *set = [super remoteObjectProperties];
    [set addObject:@"service"];
    return set;
}

+ (CordovaPluginBridge *)bridgeInstance {
    return bridgeInstance;
}

- (id)initWithObjectId:(NSString *)objectId andClient:(TabrisClient *)client {
    self = [super initWithObjectId:objectId andClient:client];
    if( self ) {
        WebViewProxy *webViewProxy = [[WebViewProxy alloc] initWithView:self.client.view
                                                            andJSBinding:self.jsBinding
                                                             andBaseURL:self.client.httpClient.baseURL];
        _pluginLoader = [[CordovaPluginLoader alloc] initWithWebView:webViewProxy];
        _settings = [NSDictionary dictionary];
        [self registerSelector:@selector(exec:) forCall:@"exec"];
        bridgeInstance = self;
    }
    return self;
}

- (NSString *)service {
    return _service;
}

- (void)setService:(NSString *)service {
    _service = service;
    self.plugin = [self.pluginLoader load:service];
    self.plugin.viewController = [self.client viewController];
    self.plugin.commandDelegate = self;
    [self.plugin pluginInitialize];
}

- (void)exec:(NSDictionary *)parameters {
    if( self.plugin ) {
        NSString *action = [parameters objectForKey:@"action"];
        NSArray *arguments = [parameters objectForKey:@"arguments"];
        NSString *callbackId = [parameters objectForKey:@"callbackId"];
        [self invoke:action withArguments:arguments andCallbackId:callbackId];
    }
}

- (void)invoke:(NSString *)action withArguments:(NSArray *)arguments andCallbackId:(NSString *)callbackId {
    CDVInvokedUrlCommand *invocationCommand = [[CDVInvokedUrlCommand alloc] initWithArguments:arguments callbackId:callbackId className:_service methodName:action];
    SEL selector = NSSelectorFromString([NSString stringWithFormat:@"%@%@", action, @":"] );
    IMP method = [self.plugin methodForSelector:selector];
    void (*func)(id, SEL, CDVInvokedUrlCommand *) = (void *)method;
    func(self.plugin, selector, invocationCommand);
}

- (JSBinding *)jsBinding {
    if( !_jsBinding ) {
        NSSet *bindings = [self.client bindings];
        for (id<Binding> binding in bindings) {
            if( [binding isKindOfClass:[JSBinding class]] ) {
                _jsBinding = (JSBinding *)binding;
            }
        }
    }
    return _jsBinding;
}

#pragma mark - CDVCommandDelegate methods

// Sends a plugin result to the JS. This is thread-safe.
- (void)sendPluginResult:(CDVPluginResult *)result callbackId:(NSString *)callbackId {
    if ([@"INVALID" isEqualToString:callbackId]) {
        return;
    } else if( self.finishListener ) {
        dispatch_block_t block = ^{
            [self sendFinishEvent:result callbackId:callbackId];
        };
        if( [NSThread isMainThread] ) {
            block();
        } else {
            dispatch_sync(dispatch_get_main_queue(), block);
        }
    }
}

- (void)sendFinishEvent:(CDVPluginResult *)result callbackId:(NSString *)callbackId {
    Message<Notification> *notification = [[self notifications] forObject:self];
    id message = result.message;
    if( !message ) {
        message = [NSNull null];
    }
    NSDictionary *attributes = @{@"status":result.status,
                                 @"callbackId":callbackId,
                                 @"keepCallback":result.keepCallback,
                                 @"message":message};
    [notification fireEvent:@"finish" withAttributes:attributes];
}

// Evaluates the given JS. This is thread-safe.
- (void)evalJs:(NSString *)js {
    [self.jsBinding execute:js fromSourceURL:nil];
}

// Can be used to evaluate JS right away instead of scheduling it on the run-loop.
// This is required for dispatch resign and pause events, but should not be used
// without reason. Without the run-loop delay, alerts used in JS callbacks may result
// in dead-lock. This method must be called from the UI thread.
- (void)evalJs:(NSString*)js scheduledOnRunLoop:(BOOL)scheduledOnRunLoop {
    [self evalJs:js];
}

// Runs the given block on a background thread using a shared thread-pool.
- (void)runInBackground:(void (^)())block {
    block();
}

// Returns the User-Agent of the associated UIWebView.
- (NSString *)userAgent {
   return [CDVUserAgentUtil originalUserAgent];
}

// Returns whether the given URL passes the white-list.
- (BOOL)URLIsWhitelisted:(NSURL*)url {
    return YES;
}

- (NSString *)pathForResource:(NSString *)resourcepath {
    NSBundle* mainBundle = [NSBundle mainBundle];
    NSMutableArray* directoryParts = [NSMutableArray arrayWithArray:[resourcepath componentsSeparatedByString:@"/"]];
    NSString* filename = [directoryParts lastObject];
    
    [directoryParts removeLastObject];
    
    NSString* directoryPartsJoined = [directoryParts componentsJoinedByString:@"/"];
    NSString* directoryStr = @"www";
    
    if ([directoryPartsJoined length] > 0) {
        directoryStr = [NSString stringWithFormat:@"%@/%@", @"www", [directoryParts componentsJoinedByString:@"/"]];
    }
    
    return [mainBundle pathForResource:filename ofType:@"" inDirectory:directoryStr];
}

- (id)getCommandInstance:(NSString *)pluginName {
    return [self.pluginLoader load:pluginName];
}

- (void)destroy {
    [self.pluginLoader unload:self.service];
    [super destroy];
}

@end
