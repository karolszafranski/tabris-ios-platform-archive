/*
 Licensed to the Apache Software Foundation (ASF) under one
 or more contributor license agreements.  See the NOTICE file
 distributed with this work for additional information
 regarding copyright ownership.  The ASF licenses this file
 to you under the Apache License, Version 2.0 (the
 "License"); you may not use this file except in compliance
 with the License.  You may obtain a copy of the License at

 http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing,
 software distributed under the License is distributed on an
 "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 KIND, either express or implied.  See the License for the
 specific language governing permissions and limitations
 under the License.
 */

//
//  AppDelegate.m
//  __PROJECT_NAME__
//
//  Created by ___FULLUSERNAME___ on ___DATE___.
//  Copyright ___ORGANIZATIONNAME___ ___YEAR___. All rights reserved.
//

#import "AppDelegate.h"
#import <Cordova/CDVPlugin.h>
#import "CordovaPluginBridge.h"
#import "CordovaConfig.h"
/* HOOK: import classes for registration */

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [super application:application didFinishLaunchingWithOptions:launchOptions];
    /* HOOK: applicationDidFinishLaunching */
    return YES;
}

- (NSURL *)packageJsonUrl {
    return [[[[NSBundle mainBundle] resourceURL] URLByAppendingPathComponent:@"www" isDirectory:YES] URLByAppendingPathComponent:[CordovaConfig config].packageJsonPath];
}

- (BOOL)useSSLStrict {
    id sslSetting = [[CordovaConfig config].settings objectForKey:@"usestrictssl"];
    if( sslSetting ) {
        return [sslSetting boolValue];
    }
    return YES;
}

- (BOOL)prefersStatusBarHidden {
    id fullscreenSetting = [[CordovaConfig config].settings objectForKey:@"fullscreen"];
    if( fullscreenSetting ) {
        return [fullscreenSetting boolValue];
    }
    return NO;
}

- (BOOL)enableDeveloperConsole {
    return [[[CordovaConfig config].settings objectForKey:@"enabledeveloperconsole"] boolValue];
}

- (void)tabrisClientWillStartExecuting:(TabrisClient *)tabrisClient {
    [tabrisClient addRemoteObject:[CordovaPluginBridge class]];
    /* HOOK: tabrisClientWillStartExecuting */
}

@end
