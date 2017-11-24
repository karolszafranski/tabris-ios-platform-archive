//
//  CordovaPluginBridge.h
//  Tabris
//
//  Created by Holger Staudacher & Jordi Böhme López on 17/10/14.
//  Copyright (c) 2014 EclipseSource. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Tabris/BasicObject.h>
#import <Cordova/CDVCommandDelegate.h>

@interface CordovaPluginBridge : BasicObject <CDVCommandDelegate>

@property (assign) BOOL finishListener;
@property (strong) NSString* service;
@property (nonatomic, readonly) NSDictionary* settings;

- (void)exec:(NSDictionary *)parameters;
+ (CordovaPluginBridge *)bridgeInstance;

@end
