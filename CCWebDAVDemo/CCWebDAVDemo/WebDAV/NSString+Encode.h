//
//  NSString+Encode.h
//  Gateway_2_0
//
//  Created by 夏明伟 on 2017/5/22.
//  Copyright © 2017年 Mile. All rights reserved.
//

#import <Foundation/Foundation.h>

#pragma mark - NSString + URLEncoding
@interface NSString (URLEncoding)

/**
 *  为用于URL参数进行编码，":#[]@!$&'()*+,;="都会被编码，
 *  不编码 "?" or "/" due to RFC 3986 - Section 3.4
 *  @return 字符串
 */
- (NSString *)urlEncode;


/**
 *  对URL中参数进行解码
 *
 *  @return 字符串
 */
- (NSString *)urlDecode;

@end


#pragma mark - NSString + JSON
@interface NSString (JSON)

/**
 *  解析JSON字符串
 *
 *  @return 字典或数组
 */
- (id)uo_objectFromJSONString;

@end

#pragma mark - URLQuery

@interface NSString (URLQuery)

/**
 *  @return If the receiver is a valid URL query component, returns
 *  components as key/value pairs. If couldn't split into *any* pairs,
 *  returns nil.
 */
- (NSDictionary*) uo_URLQueryDictionary;

@end
