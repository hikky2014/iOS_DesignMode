//
//  AESEncryption.m
//  Encryption_Strategy_Demo
//
//  Created by Hikky on 17/6/7.
//  Copyright © 2017年 MH. All rights reserved.
//

#import "AESEncryption.h"


@interface AESEncryption()
@property (nonatomic, assign) int keySize;
@property (nonatomic, assign) int blockSize;
/**
 @constant   kCCAlgorithmAES     高级加密标准，128位(默认)
 @constant   kCCAlgorithmDES     数据加密标准
 */
@property (nonatomic, assign) uint32_t algorithm;

@end

@implementation AESEncryption

- (instancetype)initWithAlgorithm:(uint32_t)algorithm {
    if(self=[super init]) {
        _algorithm = algorithm;
        switch (algorithm) {
            case kCCAlgorithmAES:
                self.keySize = kCCKeySizeAES128;
                self.blockSize = kCCBlockSizeAES128;
                break;
            case kCCAlgorithmDES:
                self.keySize = kCCKeySizeDES;
                self.blockSize = kCCBlockSizeDES;
                break;
            default:
                break;
        }
    }
    
    return self;
}

//加密
- (NSString*)encryptWithData:(NSString *)dataStr keyString:(NSString *)keyString iv:(NSData *)iv {
    // 设置秘钥
    NSData *keyData = [keyString dataUsingEncoding:NSUTF8StringEncoding];
    uint8_t cKey[self.keySize];
    bzero(cKey, sizeof(cKey));
    [keyData getBytes:cKey length:self.keySize];
    
    // 设置iv
    /*
     kCCOptionPKCS7Padding                      CBC 的加密方式
     kCCOptionPKCS7Padding | kCCOptionECBMode   ECB 的加密方式
     */
    uint8_t cIv[self.blockSize];
    bzero(cIv, self.blockSize);
    int option = 0;
    if (iv) {
        [iv getBytes:cIv length:self.blockSize];
        option = kCCOptionPKCS7Padding;
    } else {
        option = kCCOptionPKCS7Padding | kCCOptionECBMode;
    }
    
    // 设置输出缓冲区
    NSData *data = [dataStr dataUsingEncoding:NSUTF8StringEncoding];
    size_t bufferSize = [data length] + self.blockSize;
    void *buffer = malloc(bufferSize);
    
    // 开始加密
    size_t encryptedSize = 0;
    /***
     CCCrypt 对称加密算法的核心函数(加密/解密)
     参数:
     1.kCCEncrypt  加密/kCCDecrypt 解密
     2.加密算法,默认使用的是  AES/DES
     3.加密选项  ECB/CBC
     kCCOptionPKCS7Padding                      CBC 的加密方式
     kCCOptionPKCS7Padding | kCCOptionECBMode   ECB 的加密方式
     4.加密密钥
     5.密钥长度
     6.iv 初始化向量,ECB 不需要指定
     7.加密的数据
     8.加密的数据的长度
     9.密文的内存地址
     10.密文缓冲区的大小
     11.加密结果大小
     */
    CCCryptorStatus cryptStatus = CCCrypt(kCCEncrypt,
                                          self.algorithm,
                                          option,
                                          cKey,
                                          self.keySize,
                                          cIv,
                                          [data bytes],
                                          [data length],
                                          buffer,
                                          bufferSize,
                                          &encryptedSize);
    
    NSData *result = nil;
    if (cryptStatus == kCCSuccess) {
        result = [NSData dataWithBytesNoCopy:buffer length:encryptedSize];
    } else {
        free(buffer);
        NSLog(@"[错误] 加密失败|状态编码: %d", cryptStatus);
    }
    
    return [result base64EncodedStringWithOptions:0];

}

//解密
- (NSString *)decryptString:(NSString *)string keyString:(NSString *)keyString iv:(NSData *)iv {
    // 设置秘钥
    NSData *keyData = [keyString dataUsingEncoding:NSUTF8StringEncoding];
    uint8_t cKey[self.keySize];
    bzero(cKey, sizeof(cKey));
    [keyData getBytes:cKey length:self.keySize];
    
    // 设置iv
    uint8_t cIv[self.blockSize];
    bzero(cIv, self.blockSize);
    int option = 0;
    if (iv) {
        [iv getBytes:cIv length:self.blockSize];
        option = kCCOptionPKCS7Padding;
    } else {
        option = kCCOptionPKCS7Padding | kCCOptionECBMode;
    }
    
    // 设置输出缓冲区
    NSData *data = [[NSData alloc] initWithBase64EncodedString:string options:0];
    size_t bufferSize = [data length] + self.blockSize;
    void *buffer = malloc(bufferSize);
    
    // 开始解密
    size_t decryptedSize = 0;
    CCCryptorStatus cryptStatus = CCCrypt(kCCDecrypt,
                                          self.algorithm,
                                          option,
                                          cKey,
                                          self.keySize,
                                          cIv,
                                          [data bytes],
                                          [data length],
                                          buffer,
                                          bufferSize,
                                          &decryptedSize);
    
    NSData *result = nil;
    if (cryptStatus == kCCSuccess) {
        result = [NSData dataWithBytesNoCopy:buffer length:decryptedSize];
    } else {
        free(buffer);
        NSLog(@"[错误] 解密失败|状态编码: %d", cryptStatus);
    }
    
    return [[NSString alloc] initWithData:result encoding:NSUTF8StringEncoding];
}

@end
