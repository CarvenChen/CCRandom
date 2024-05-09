//
//  UOWebDavManager.m
//  Gateway_2_0
//
//  Created by Carven on 2022/11/16.
//  Copyright © 2022 Mile. All rights reserved.
//

#import "UOWebDavManager.h"
#import "NSString+Encode.h"

#define UOWebDavBaseUrl @"http://192.168.31.84:8080/"
#define UOWebDavBaseUrl_Test @"http://43.138.222.241:8123/"

@interface UOWebDavManager ()

@property (strong, nonatomic) UOWebDavSessionManager *sessionManager;

@end

@implementation UOWebDavManager

+ (instancetype)shareInstance {
    static UOWebDavManager *_sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedInstance = [[UOWebDavManager alloc] init];
        _sharedInstance.sessionManager = [[UOWebDavSessionManager alloc] initWithBaseURL:[NSURL URLWithString:UOWebDavBaseUrl_Test]];
    });
    return _sharedInstance;
}

- (void)checkLink:(void(^)(void))completeBlock {

}

- (void)loadFileListAtPath:(NSString *)path completeBlock:(void(^)(NSArray *, NSError * _Nonnull ))completeBlock {
    [self.sessionManager contentsOfDirectoryAtURLString:path recursive:NO completionHandler:^(NSArray * _Nonnull items, NSError * _Nonnull error) {
        NSMutableArray *resArray = [items mutableCopy];
        if (items.count > 0) {
            //文件夹内的第一个，是该文件夹本身，需要去除
            AFWebDAVMultiStatusResponse *res = items.firstObject;
            if ([res.href isEqualToString:path]) {
                [resArray removeObjectAtIndex:0];
            }
        }
        if (completeBlock) {
            completeBlock(resArray, error);
        }
    }];
}

- (void)createDirectoryAtURLString:(NSString *)path
                     completeBlock:(void(^)(BOOL isSuccess, NSError * _Nonnull error))completeBlock {
    [self.sessionManager createDirectoryAtURLString:path withIntermediateDirectories:YES completionHandler:^(BOOL isSuccess, NSError * _Nonnull error) {
        if (completeBlock) {
            completeBlock(isSuccess, error);
        }
    }];
}

- (void)uploadFileToURLString:(NSString *)path
                     fileData:(NSData *)data
                completeBlock:(void(^)(BOOL isSuccess, NSError * _Nonnull error))completeBlock {
    [self.sessionManager createFileAtURLString:path withIntermediateDirectories:YES contents:data completionHandler:^(NSURL * _Nonnull fileURL, NSError * _Nonnull error) {
        if (completeBlock) {
            completeBlock(fileURL.absoluteString.length > 0, error);
        }
    }];
}

- (void)removeFileToURLString:(NSString *)path
                completeBlock:(void(^)(BOOL isSuccess, NSError * _Nonnull error))completeBlock {
    [self.sessionManager removeFileAtURLString:path completionHandler:^(NSURL * _Nonnull fileURL, NSError * _Nonnull error) {
        if (completeBlock) {
            completeBlock(fileURL.absoluteString.length > 0, error);
        }
    }];
}
@end
