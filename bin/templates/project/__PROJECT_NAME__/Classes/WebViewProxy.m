//
//  WebViewProxy.m
//  Tabris
//
//  Created by Jordi Böhme López on 27.11.14.
//  Copyright (c) 2014 EclipseSource. All rights reserved.
//

#import "WebViewProxy.h"
#import <WebKit/WebKit.h>
#import <JavaScriptCore/JavaScriptCore.h>

@interface WebViewProxy ()
@property (strong, nonatomic) id<TabrisContext> context;
@property (nonatomic, readonly) UIView *forwardView;
@property (nonatomic, readonly) NSURL *baseURL;
@end

@implementation WebViewProxy

@synthesize forwardView = _forwardView;
@synthesize request = _request;
@synthesize engineWebView = _engineWebView;

- (instancetype)initWithContext:(id<TabrisContext>)context {
    self = [super init];
    if (self) {
        self.context = context;
    }
    return self;
}

- (UIView *)forwardView {
    return self.context.viewController.view;
}

- (NSURL *)baseURL {
    return self.context.URL;
}

- (void)forwardInvocation:(NSInvocation *)invocation {
    if( !self.forwardView) {
        [self doesNotRecognizeSelector: [invocation selector]];
    }
    [invocation invokeWithTarget:self.forwardView];
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)selector {
    NSMethodSignature *signature = [super methodSignatureForSelector:selector];
    if (!signature) {
        signature = [self.forwardView methodSignatureForSelector:selector];
    }
    return signature;
}

- (BOOL)isKindOfClass:(Class)aClass {
    BOOL isKindOf = [super isKindOfClass:aClass];
    if( !isKindOf && self.forwardView ) {
        isKindOf = [self.forwardView isKindOfClass:aClass];
    }
    if( !isKindOf && aClass == [WKWebView class] ) {
        isKindOf = YES;
    }
    if( !isKindOf && aClass == NSClassFromString(@"UIWebView") ) {
        isKindOf = YES;
    }
    return isKindOf;
}

- (BOOL)isMemberOfClass:(Class)aClass {
    BOOL isMember = [super isMemberOfClass:aClass];
    if( !isMember && self.forwardView ) {
        isMember = [self.forwardView isMemberOfClass:aClass];
    }
    if( !isMember && aClass == [WKWebView class] ) {
        isMember = YES;
    }
    if( !isMember && aClass == NSClassFromString(@"UIWebView") ) {
        isMember = YES;
    }
    return isMember;
}

- (NSString *)stringByEvaluatingJavaScriptFromString:(NSString *)script {
    __block JSValue *jsResult;
    __weak __typeof(self) weakSelf = self;
    [self.context.syncCodeDispatcher dispatch:^{
        jsResult = [weakSelf.context.jsContext evaluateScript:script withSourceURL:nil];
    }];
    return [jsResult toString];
}

- (NSURLRequest *)request {
    if( !_request ) {
        _request = [NSURLRequest requestWithURL:self.baseURL];
    }
    return _request;
}

#pragma mark - CDVWebViewEngineProtocol

- (UIView *)engineWebView {
    return self.forwardView;
}

- (NSURL *)URL {
    return nil;
}

- (void)evaluateJavaScript:(NSString *)javaScriptString completionHandler:(void (^)(id, NSError *))completionHandler {
    __weak __typeof(self) weakSelf = self;
    [self.context.asyncCodeDispatcher dispatch:^{
        JSValue *jsResult = [weakSelf.context.jsContext evaluateScript:javaScriptString withSourceURL:nil];
        completionHandler([jsResult toString], nil);
    }];
}

- (BOOL)canLoadRequest:(NSURLRequest *)request {
    return YES;
}

- (id)loadRequest:(NSURLRequest *)request {
    return nil;
}

- (id)loadHTMLString:(NSString *)string baseURL:(NSURL *)baseURL {
    return nil;
}

- (void)updateWithInfo:(NSDictionary *)info {
}

- (id)initWithFrame:(CGRect)frame {
    return self;
}

@end
