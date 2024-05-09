//
//  UOWebDavManager.h
//  Gateway_2_0
//
//  Created by Carven on 2022/11/16.
//  Copyright © 2022 Mile. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "UOWebDavSessionManager.h"

NS_ASSUME_NONNULL_BEGIN

@interface UOWebDavManager : NSObject

+ (instancetype)shareInstance;

- (void)checkLink:(void(^)(void))completeBlock;

- (void)loadFileListAtPath:(NSString *)path
             completeBlock:(void(^)(NSArray *resultList, NSError * _Nonnull error))completeBlock;

- (void)createDirectoryAtURLString:(NSString *)path
                     completeBlock:(void(^)(BOOL isSuccess, NSError * _Nonnull error))completeBlock;

- (void)uploadFileToURLString:(NSString *)path
                     fileData:(NSData *)data
                completeBlock:(void(^)(BOOL isSuccess, NSError * _Nonnull error))completeBlock;

- (void)removeFileToURLString:(NSString *)path
                completeBlock:(void(^)(BOOL isSuccess, NSError * _Nonnull error))completeBlock;


@end

NS_ASSUME_NONNULL_END
