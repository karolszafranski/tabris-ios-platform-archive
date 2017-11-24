//
//  WebViewProxy.m
//  Tabris
//
//  Created by Jordi Böhme López on 27.11.14.
//  Copyright (c) 2014 EclipseSource. All rights reserved.
//

#import "WebViewProxy.h"
#import <WebKit/WebKit.h>

@interface WebViewProxy ()
@property (strong) UIView *forwardView;
@property (strong) JSBinding *jsBinding;
@property (strong) NSURL *baseURL;
@end

@implementation WebViewProxy

@synthesize forwardView = _forwardView;
@synthesize jsBinding = _jsBinding;
@synthesize baseURL = _baseURL;
@synthesize request = _request;
@synthesize engineWebView = _engineWebView;

- (instancetype)initWithView:(UIView *)forwardView andJSBinding:(JSBinding *)jsBinding andBaseURL:(NSURL *)baseURL {
    self = [super init];
    if (self) {
        _forwardView = forwardView;
        _jsBinding = jsBinding;
        _baseURL = baseURL;
    }
    return self;
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
    JSValue *jsResult = [self.jsBinding execute:script fromSourceURL:nil];
    [self.jsBinding flushOperationsQueue];
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
    JSValue *jsResult = [self.jsBinding execute:javaScriptString fromSourceURL:nil];
    [self.jsBinding flushOperationsQueue];
    completionHandler([jsResult toString], nil);
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
