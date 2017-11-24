//
//  CordovaConfig.h
//  CordovaLib
//
//  Created by Jordi Böhme López on 11.02.15.
//
//

#import <Foundation/Foundation.h>

@interface CordovaConfig : NSObject
+ (instancetype)config;
- (NSString *)packageJsonPath;
- (NSDictionary *)settings;
- (NSDictionary *)plugins;
@end
