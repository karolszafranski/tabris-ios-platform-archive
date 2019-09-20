//
//  tabris_app_test.m
//  tabris_app_test
//
//  Created by Karol Szafrański on 20.09.19.
//

#import <XCTest/XCTest.h>

@interface tabris_ios_test : XCTestCase
@property (strong, nonatomic) XCTestExpectation* expectation;
@property (strong, nonatomic) NSObject* unitTest;
@property (strong, nonatomic) NSMutableArray *unitTestPerformance;
@property (strong, nonatomic) NSMutableArray *unitTestNativeDroppingFramesStacks;
@end

@implementation tabris_ios_test

- (NSObject *)unitTest {
    if (!_unitTest) {
        Class TabrisClientAppDelegateClass = NSClassFromString(@"TabrisClientAppDelegate");
        SEL remoteObjectTypeSelector = NSSelectorFromString(@"remoteObjectType");
        NSString* unitTestRemoteObjectType = @"com.eclipsesource.native-unit-testing";

        id appDelegate = [[UIApplication sharedApplication] delegate];
        if (![appDelegate isKindOfClass:TabrisClientAppDelegateClass]) {
            XCTFail(@"appDelegate is not TabrisClientAppDelegate class");
        }

        __block NSObject* unitTest = nil;
        NSDictionary* registry = [appDelegate valueForKeyPath:@"client.mainScope.objectRegistry.registry"];
        [registry.allValues enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([[obj class] respondsToSelector:remoteObjectTypeSelector]) {
                NSString* remoteObjectType = [[obj class] performSelector:remoteObjectTypeSelector];
                if ([remoteObjectType isEqualToString:unitTestRemoteObjectType]) {
                    unitTest = obj;
                    *stop = YES;
                }
            }
        }];

        if (!unitTest ||
            ![unitTest respondsToSelector:@selector(setDelegate:)]) {
            XCTFail(@"Returned `unitTest`: %@ does not meet expectations", unitTest);
        }
        else {
            _unitTest = unitTest;
        }
    }
    return _unitTest;
}

- (void)testJavaScriptApp {

    if (!self.unitTest) {
        XCTFail(@"self.unitTest does not exist");
        return;
    }

    self.unitTestPerformance = [[NSMutableArray alloc] init];
    self.unitTestNativeDroppingFramesStacks = [[NSMutableArray alloc] init];

    self.expectation = [self expectationWithDescription:@"expecting"];

    SEL fireReadyToTestSelector = NSSelectorFromString(@"fireReadyToTesEvent");

    [self.unitTest setValue:self forKey:@"delegate"];
    [self.unitTest performSelector:fireReadyToTestSelector];

    NSNumber* timeout = [self.unitTest valueForKey:@"timeout"];
    timeout = timeout ? timeout : @10000;
    [self waitForExpectationsWithTimeout:timeout.doubleValue / 1000.0
                                 handler:^(NSError * _Nullable error) {
                                     NSLog(@"%@", error);
                                 }];
}

- (void)startAnimationPerformanceTracker {

}

- (void)stopAnimationPerformanceTracker {
    
}

- (void)testFinished:(BOOL)successfully withData:(NSDictionary *)data {
    NSLog(@"ESUnitTest finished successfully: %i with data: %@", successfully, data);
    NSLog(@"ESUnitTest nativeData: %@", [self.unitTest valueForKey:@"nativeData"]);
    NSLog(@"ESUnitTest performance: %@", self.unitTestPerformance);
    NSLog(@"ESUnitTest dropped frames: %@", self.unitTestNativeDroppingFramesStacks);
    if (successfully) {
        [self.expectation fulfill];
    } else {
        [self.expectation fulfill];
        XCTFail();
    }
}


- (void)reportDurationInMS:(NSInteger)duration smallDropEvent:(double)smallDropEvent largeDropEvent:(double)largeDropEvent {
    [self.unitTestPerformance addObject:@{@"duration":@(duration),
                                          @"smallDropEvent":@(smallDropEvent),
                                          @"largeDropEvent":@(largeDropEvent)}];
}

- (void)reportStackTrace:(NSString *)stack withSlide:(NSString *)slide {
    [self.unitTestNativeDroppingFramesStacks addObject:@[stack, slide]];
}

@end
