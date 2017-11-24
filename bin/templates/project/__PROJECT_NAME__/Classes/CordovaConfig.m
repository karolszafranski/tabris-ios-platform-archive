//
//  CordovaConfig.m
//  CordovaLib
//
//  Created by Jordi Böhme López on 11.02.15.
//
//

#import "CordovaConfig.h"
#import <Cordova/CDVConfigParser.h>

@interface CordovaConfig ()
@property (strong) CDVConfigParser *cdvConfig;
@end

@implementation CordovaConfig

@synthesize cdvConfig = _cdvConfig;

static CordovaConfig *instance;

+ (instancetype)config {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

- (NSDictionary *)plugins {
    return self.cdvConfig.pluginsDict;
}

- (NSDictionary *)settings {
    return self.cdvConfig.settings;
}

- (NSString *)packageJsonPath {
    if( [self.cdvConfig.startPage hasSuffix:@"package.json"] ) {
        return self.cdvConfig.startPage;
    }
    return @"package.json";
}

- (instancetype)init {
    self = [super init];
    if (self) {
        [self readConfig];
    }
    return self;
}

- (void)readConfig {
    self.cdvConfig = [[CDVConfigParser alloc] init];
    NSString* path = [[NSBundle mainBundle] pathForResource:@"config" ofType:@"xml"];
    if (![[NSFileManager defaultManager] fileExistsAtPath:path]) {
        NSAssert(NO, @"ERROR: config.xml does not exist. Please run cordova-ios/bin/cordova_plist_to_config_xml path/to/project.");
        return;
    }
    NSURL* url = [NSURL fileURLWithPath:path];
    NSXMLParser* configParser = [[NSXMLParser alloc] initWithContentsOfURL:url];
    if (configParser == nil) {
        NSLog(@"Failed to initialize XML parser.");
        return;
    }
    [configParser setDelegate:self.cdvConfig];
    [configParser parse];
}

@end
