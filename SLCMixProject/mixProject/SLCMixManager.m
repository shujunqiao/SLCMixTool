//
//  SLCMixManager.m
//  mixProject
//
//  Created by 魏昆超 on 2018/7/9.
//  Copyright © 2018年 WeiKunChao. All rights reserved.
//

#import "SLCMixManager.h"
#import "SLCDataManager.h"

@interface SLCMixManager()

@property (nonatomic, assign) NSUInteger randomBodyNum; //body随机数
@property (nonatomic, assign) NSUInteger randomTailNum; //tail随机数
@property (nonatomic, copy) NSString *bodyString; //body字符串
@property (nonatomic, copy) NSString * tailString; //tail字符串
@property (nonatomic, copy) NSString *defaultFullPath; //默认全路径 - 桌面
@property (nonatomic, strong) NSMutableArray <NSString *>* classArray; //classArray

@end

@implementation SLCMixManager

- (instancetype)init {
    if (self = [super init]) {
        self.fileNum = 120;
        self.fileName = @"mixProject";
        self.fullPath = [self defaultFullPath];
        self.fileHeader = @"SLC";
        self.classArray = [NSMutableArray array];
    }
    return self;
}

#pragma mark ------<fireOnBorn>-----

- (void)setFileName:(NSString *)fileName {
    _fileName = fileName;
    self.fullPath = [self defaultFullPath];
}

- (void)fireOnBorn {
    
    BOOL isCreateDirectory = [self createDirectory];
    dispatch_semaphore_t semaphore = GCD_Semaphore(1);
    if (isCreateDirectory) {
        GCD_Lock(semaphore);
        for (NSInteger i = 0; i < self.fileNum; i ++) { //垃圾文件
            [self createFile];
            GCD_Unlock(semaphore);
        }
        
        [self createBulletsFile];
        NSLog(@"====%ld组文件创建完成",self.fileNum);
    }
}

#pragma mark ---<PrivateMethod>---

- (void)createBulletsFile {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *fileName = [NSString stringWithFormat:@"%@Bullets",self.fileHeader];
    NSString *filePath = [self.fullPath stringByAppendingPathComponent:fileName];
    BOOL isFileExists = [fileManager fileExistsAtPath:[NSString stringWithFormat:@"%@.h",filePath]];
    if (isFileExists) return; //文件已存在,立即停止
    
    NSString *methodString = @"/**调用所有方法 - (模拟调用,fire完所有局部对象会立即被释放)*/\n- (void)fire;";
    NSString *hString = [NSString stringWithFormat:@"\n\n\n\n\n#import <Foundation/Foundation.h>\n\n\n\n@interface %@ : NSObject\n\n\n%@\n@end",fileName,methodString]; //.h文件内容
    NSString *mString = [self createBulletsM:fileName methodString:methodString]; //.m文件内容
    
    
    BOOL isCreateH = [fileManager createFileAtPath:[NSString stringWithFormat:@"%@.h",filePath] contents:[hString dataUsingEncoding:NSUTF8StringEncoding] attributes:nil];
    if (isCreateH) {
        NSLog(@"%@___文件创建成功!",fileName);
        [fileManager createFileAtPath:[NSString stringWithFormat:@"%@.m",filePath] contents:[mString dataUsingEncoding:NSUTF8StringEncoding] attributes:nil];
    }else {
        NSLog(@"%@文件创建失败,重名了!",fileName);
    }
}

- (NSString *)createBulletsM:(NSString *)fileName
                methodString:(NSString *)method {
    
    NSString *bulletsM = [NSString stringWithFormat:@"\n\n\n\n\n#import \"%@.h\"\n#import <objc/runtime.h>\n@interface %@()\n@property (nonatomic, strong) NSArray <NSString *>* classArray;\n@end\n\n\n@implementation %@\n",fileName,fileName,fileName];
    
    NSString *classString = @"@[";
    for (NSInteger i = 0; i < self.fileNum; i ++) {
        NSString *aClass = self.classArray[i];
        classString = [classString stringByAppendingString:[NSString stringWithFormat:@"@\"%@\",",aClass]];
    }
    classString = [classString stringByAppendingString:@"]"];
    
    NSString *methodClass = [NSString stringWithFormat:@"- (NSArray <NSString *>*)classArray {\n    if (!_classArray) {\n     _classArray = %@;\n    }\n    return _classArray;\n}",classString];
    
      bulletsM = [bulletsM stringByAppendingString:[NSString stringWithFormat:@"%@",methodClass]];
    
    NSString *methodFire = [NSString stringWithFormat:@"\n- (void)fire\n{\n\t@autoreleasepool {\n\t\tNSLog(@\"===生成了%@对象\");\n\t\tfor (NSString *className in self.classArray) {\n\t\t\tClass aClass = NSClassFromString(className);\n\t\t\tid object = [aClass new];\n\t\t\t[self getAllMethods:object];\n\t\t}\n\t}\n}\n",fileName]; //fire方法
    
     bulletsM = [bulletsM stringByAppendingString:[NSString stringWithFormat:@"%@",methodFire]];
    
    NSString *methodLists = @"- (NSArray <NSString *>*)getAllMethods:(id)obj\n{\n\tunsigned int methodCount =0;\n\tMethod* methodList = class_copyMethodList([obj class],&methodCount);\n\tNSMutableArray *methodsArray = [NSMutableArray arrayWithCapacity:methodCount];\n\tfor(int i = 0; i < methodCount; i++) {\n\t\tMethod temp = methodList[i];\n\t\tmethod_getImplementation(temp);\n\t\tmethod_getName(temp);\n\t\tconst char* name_s =sel_getName(method_getName(temp));\n\t\tint arguments = method_getNumberOfArguments(temp);\n\t\tchar dst[32];\n\t\tfor (int j = 0; j<arguments; j++) {\n\t\t\tmethod_getArgumentType(temp, j, dst+j, 32);\n\t\t}\n\t\tBOOL flag = NO;\n\t\tNSMutableArray *parameters = [NSMutableArray array];\n\t\tfor (int k = 0; k < 32; k++) {\n\t\t\tif (dst[k] != '\\0') {\n\t\t\t\tif (dst[k] == ':') {\n\t\t\t\t\tflag = YES;\n\t\t\t\t\tcontinue;\n\t\t\t\t}\n\t\t\t\tif (flag) {\n\t\t\t\t\tchar type[2];\n\t\t\t\t\ttype[0] = dst[k];\n\t\t\t\t\ttype[1] = '\\0';\n\t\t\t\t\t[parameters addObject:[self parameterWithType:type]];\n\t\t\t\t}\n\t\t\t} else {\n\t\t\t\tbreak;\n\t\t\t}\n\t\t}\n\t\tif (![[NSString stringWithUTF8String:name_s] containsString:@\"set\"]) {\n\t\t\t[methodsArray addObject:[NSString stringWithUTF8String:name_s]];\n\t\t\t[self performSelector:NSSelectorFromString([NSString stringWithUTF8String:name_s]) target:obj withArguments:parameters];\n\t\t}\n\t}\n\tfree(methodList);\n\treturn methodsArray;\n}\n\n- (id)parameterWithType:(char *)type\n{\n\tif (strcmp(type, @encode(id)) == 0) {\n\t\treturn [NSNull null];\n\t} else if (strcmp(type, @encode(short)) == 0) {\n\t\treturn [NSNumber numberWithShort:0];\n\t} else if (strcmp(type, @encode(unsigned short)) == 0) {\n\t\treturn [NSNumber numberWithUnsignedShort:0];\n\t} else if (strcmp(type, @encode(int)) == 0) {\n\t\treturn [NSNumber numberWithInt:0];\n\t} else if (strcmp(type, @encode(unsigned int)) == 0) {\n\t\treturn [NSNumber numberWithUnsignedInt:0];\n\t} else if (strcmp(type, @encode(long)) == 0) {\n\t\treturn [NSNumber numberWithLong:0];\n\t} else if (strcmp(type, @encode(unsigned long)) == 0) {\n\t\treturn [NSNumber numberWithUnsignedLong:0];\n\t} else if (strcmp(type, @encode(long long)) == 0) {\n\t\treturn [NSNumber numberWithLongLong:0];\n\t} else if (strcmp(type, @encode(unsigned long long)) == 0) {\n\t\treturn [NSNumber numberWithUnsignedLongLong:0];\n\t} else if (strcmp(type, @encode(NSInteger)) == 0) {\n\t\treturn [NSNumber numberWithInteger:0];\n\t} else if (strcmp(type, @encode(NSUInteger)) == 0) {\n\t\treturn [NSNumber numberWithUnsignedInteger:0];\n\t} else if (strcmp(type, @encode(float)) == 0) {\n\t\treturn [NSNumber numberWithFloat:0.f];\n\t} else if (strcmp(type, @encode(double)) == 0) {\n\t\treturn [NSNumber numberWithDouble:0.f];\n\t} else if (strcmp(type, @encode(BOOL)) == 0) {\n\t\treturn [NSNumber numberWithBool:YES];\n\t}\n\n\treturn [NSNull null];\n}\n- (id)performSelector:(SEL)aSelector target:(id)target withArguments:(NSArray *)arguments\n{\n\tif (aSelector == nil) {\n\t\treturn nil;\n\t}\n\n\tNSMethodSignature *signature = [[target class] instanceMethodSignatureForSelector:aSelector];\n\tif (signature == nil) {\n\t\treturn nil;\n\t}\n\n\tNSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];\n\tif (invocation == nil) {\n\t\treturn nil;\n\t}\n\n\tinvocation.target = target;\n\tinvocation.selector = aSelector;\n\n\tif ([arguments isKindOfClass:[NSArray class]]) {\n\t\tNSInteger count = MIN(arguments.count, signature.numberOfArguments - 2);\n\t\tfor (int i = 0; i < count; i++) {\n\t\t\tconst char *type = [signature getArgumentTypeAtIndex:2 + i];\n\n\t\t\tid argument = arguments[i];\n\t\t\tif (strcmp(type, @encode(id)) == 0) {\n\t\t\t\t[invocation setArgument:&argument atIndex:2 + i];\n\t\t\t} else if (strcmp(type, @encode(short)) == 0) {\n\t\t\t\tshort arg = [argument shortValue];\n\t\t\t\t[invocation setArgument:&arg atIndex:2 + i];\n\t\t\t} else if (strcmp(type, @encode(unsigned short)) == 0) {\n\t\t\t\tshort arg = [argument unsignedShortValue];\n\t\t\t\t[invocation setArgument:&arg atIndex:2 + i];\n\t\t\t} else if (strcmp(type, @encode(int)) == 0) {\n\t\t\t\tint arg = [argument intValue];\n\t\t\t\t[invocation setArgument:&arg atIndex:2 + i];\n\t\t\t} else if (strcmp(type, @encode(unsigned int)) == 0) {\n\t\t\t\tint arg = [argument unsignedIntValue];\n\t\t\t\t[invocation setArgument:&arg atIndex:2 + i];\n\t\t\t} else if (strcmp(type, @encode(long)) == 0) {\n\t\t\t\tlong arg = [argument longValue];\n\t\t\t\t[invocation setArgument:&arg atIndex:2 + i];\n\t\t\t} else if (strcmp(type, @encode(unsigned long)) == 0) {\n\t\t\t\tlong arg = [argument unsignedLongValue];\n\t\t\t\t[invocation setArgument:&arg atIndex:2 + i];\n\t\t\t} else if (strcmp(type, @encode(long long)) == 0) {\n\t\t\t\tlong long arg = [argument longLongValue];\n\t\t\t\t[invocation setArgument:&arg atIndex:2 + i];\n\t\t\t} else if (strcmp(type, @encode(unsigned long long)) == 0) {\n\t\t\t\tlong long arg = [argument unsignedLongLongValue];\n\t\t\t\t[invocation setArgument:&arg atIndex:2 + i];\n\t\t\t} else if (strcmp(type, @encode(NSInteger)) == 0) {\n\t\t\t\tlong long arg = [argument integerValue];\n\t\t\t\t[invocation setArgument:&arg atIndex:2 + i];\n\t\t\t} else if (strcmp(type, @encode(NSUInteger)) == 0) {\n\t\t\t\tlong long arg = [argument unsignedIntValue];\n\t\t\t\t[invocation setArgument:&arg atIndex:2 + i];\n\t\t\t} else if (strcmp(type, @encode(float)) == 0) {\n\t\t\t\tfloat arg = [argument floatValue];\n\t\t\t\t[invocation setArgument:&arg atIndex:2 + i];\n\t\t\t} else if (strcmp(type, @encode(double)) == 0) {\n\t\t\t\tdouble arg = [argument doubleValue];\n\t\t\t\t[invocation setArgument:&arg atIndex:2 + i];\n\t\t\t} else if (strcmp(type, @encode(BOOL)) == 0) {\n\t\t\t\tBOOL arg = [argument boolValue];\n\t\t\t\t[invocation setArgument:&arg atIndex:2 + i];\n\t\t\t}\n\t\t}\n\t}\n\n\t[invocation invoke];\n\n\tid returnVal;\n\tif (strcmp(signature.methodReturnType, @encode(id)) == 0) {\n\t\t[invocation getReturnValue:&returnVal];\n\t}\n\n\treturn returnVal;\n}\n";
    
    bulletsM = [bulletsM stringByAppendingString:[NSString stringWithFormat:@"%@",methodLists]];
    
    NSString *methodRemove = @"\n+ (NSString*)removeLastOneChar:(NSString*)origin{\n    NSString* cutted = [origin length] > 0 ? [origin substringToIndex:([origin length]-2)] : origin;\n    return cutted;\n}\n";
    
    bulletsM = [bulletsM stringByAppendingString:[NSString stringWithFormat:@"%@",methodRemove]];
    
     bulletsM = [bulletsM stringByAppendingString:@"@end"];
    
    return bulletsM;
}

- (void)createFile {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    NSString *file = [NSString stringWithFormat:@"%@%@%@",self.fileHeader,self.bodyString,self.tailString];
    NSString *filePath = [self.fullPath stringByAppendingPathComponent:file];
    [self.classArray addObject:file];
    
    BOOL isFileExists = [fileManager fileExistsAtPath:[NSString stringWithFormat:@"%@.h",filePath]];
    if (isFileExists) return; //文件已存在,立即停止
    
   __block NSString *hString = [NSString stringWithFormat:@"\n\n\n\n\n#import <Foundation/Foundation.h>\n\n\n\n@interface %@ : NSObject\n%@\n",file,[self randomProperty]]; //.h文件内容
    
    __block NSString *mString = [NSString stringWithFormat:@"\n\n\n\n\n#import \"%@.h\"\n\n\n\n@implementation %@",file,file]; //.m文件内容
    
    void(^handle)(NSArray <NSString *>*methodArray) = ^(NSArray <NSString *>*methodArray){
        
        for (NSString *method in methodArray) {
            hString = [hString stringByAppendingString:[NSString stringWithFormat:@"\n\n%@",method]];
        }
        
        for (NSString *method in methodArray) {
            if ([mString containsString:method]) continue; //如果有,跳过
            
            mString = [mString stringByAppendingString:[NSString stringWithFormat:@"\n\n%@",[self removeLastOneChar:method]]];
            mString = [mString stringByAppendingString:[NSString stringWithFormat:@"\n{\n\tfor (NSInteger i = 0; i < 3; i++) {\n\t\tNSString *str = @\"func name = %@\";\n\t\t[str stringByAppendingString:@\"time is 3\"];\n\t}\n\tNSLog(@\"Method = %@\\n\");\n}\n",method, method]];
        }
    };
    
    [self randomMethod:handle];
    
    
    hString = [hString stringByAppendingString:@"\n@end"];
    BOOL isCreateH = [fileManager createFileAtPath:[NSString stringWithFormat:@"%@.h",filePath] contents:[hString dataUsingEncoding:NSUTF8StringEncoding] attributes:nil];
    if (isCreateH) {
        NSLog(@"%@___文件创建成功!",file);
        mString = [mString stringByAppendingString:@"\n@end"];
        [fileManager createFileAtPath:[NSString stringWithFormat:@"%@.m",filePath] contents:[mString dataUsingEncoding:NSUTF8StringEncoding] attributes:nil];
    }else {
        NSLog(@"%@文件创建失败,重名了!",file);
    }
}

//随机变量
- (NSString *)randomProperty {
    NSUInteger randomNum = arc4random() % 6;
    if (randomNum == 0) return @"\n";
    NSString *property = @"\n";
    for (NSInteger i = 0; i < randomNum; i ++) {
        if ([property containsString:[self randomPerProperty]]) continue; //如果有,跳过
        property = [NSString stringWithFormat:@"%@\n%@",property,[self randomPerProperty]];
    }
    return property;
}

//随机一个变量
- (NSString *)randomPerProperty {
    NSString *propertyName = [NSString stringWithFormat:@"%@%@",bodyArray()[self.randomBodyNum],[self randomChar]];
    NSArray <NSString *>*propertyArray = @[
                                           @"\n",
                                           [NSString stringWithFormat:@"@property (nonatomic, assign) BOOL %@;",propertyName],
                                           [NSString stringWithFormat:@"@property (nonatomic, assign) NSInteger %@;",propertyName],
                                           [NSString stringWithFormat:@"@property (nonatomic, copy) NSString *%@;",propertyName],
                                           [NSString stringWithFormat:@"@property (nonatomic, strong) NSArray *%@;",propertyName],
                                           [NSString stringWithFormat:@"@property (nonatomic, strong) NSDictionary *%@;",propertyName],
                                           ];
    NSUInteger randomNum = arc4random() % 5;
    return propertyArray[randomNum];
}

//随机方法
- (void)randomMethod:(void(^)(NSArray <NSString *>*methodArray))handle {
    NSUInteger randomNum = 1 + arc4random() % 6;
    NSMutableArray *array = [NSMutableArray array];
    for (NSInteger i = 0; i < randomNum; i ++) {
        NSString *methodString = [self randomPerMethod];
        [array addObject:methodString];
    }
    if (handle) handle(array);
}

//随机一个方法
- (NSString *)randomPerMethod {
    NSUInteger randomNum = arc4random() % 4;
    return [self recursiveMethod:randomNum];
}

- (NSString *)recursiveMethod:(NSInteger)times {
    if (times == 0) {
        NSString *methodName = bodyArray()[self.randomBodyNum];
        return [NSString stringWithFormat:@"- (void)%@;",methodName];
    }else {
        NSString *methodName = bodyArray()[self.randomBodyNum];
        for (NSInteger i = 0; i < times; i ++ ) {
            NSString *newMethod = bodyArray()[self.randomBodyNum];
            NSUInteger randomM = arc4random() % 4;
            if (![methodName containsString:newMethod]) { //不包含拼接的新串
                if (i == 0) {
                    methodName = [NSString stringWithFormat:@"%@%@:(%@)%@",methodName,newMethod.capitalizedString,typesArray()[randomM],newMethod];
                }else {
                  methodName = [NSString stringWithFormat:@"%@ and%@:(%@)%@",methodName,newMethod.capitalizedString,typesArray()[randomM],newMethod];
                }
            }else { //包含,跳过
                break;
            }
        }
        return [NSString stringWithFormat:@"- (void)%@;",methodName];
    }
}

- (BOOL)createDirectory {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL create = [fileManager createDirectoryAtPath:self.fullPath withIntermediateDirectories:YES attributes:nil error:nil];
    if (create) {
        NSLog(@"%@文件夹创建成功!",self.fullPath.lastPathComponent);
    }else {
        NSLog(@"文件夹创建失败,重名!");
    }
    return create;
}

- (NSString *)defaultFullPath {
    NSString *desk = [NSSearchPathForDirectoriesInDomains(NSDesktopDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    return  [desk stringByAppendingPathComponent:self.fileName];
}

- (NSString *)bodyString {
    NSString *body = self.mixedBody && self.mixedBody.length != 0 ? self.mixedBody : bodyArray()[self.randomBodyNum];
    return body;
}

- (NSString *)tailString {
    NSString *tail = self.tailS && self.tailS.length != 0 ? self.tailS : tailArray()[self.randomTailNum];
    return tail;
}

- (NSUInteger)randomBodyNum {
    return arc4random() % (int)(bodyArray().count - 1);
}

- (NSUInteger)randomTailNum {
    return arc4random() % (int)(tailArray().count - 1);
}

//随机一个字母
- (NSString *)randomChar {
    NSArray *array = @[@"a",@"b",@"c",@"d",@"e",@"f",@"g",@"h",@"i",@"g",@"k",@"l",@"m",@"n",@"o",@"p",@"q",@"r",@"s",@"t",@"u",@"v",@"w",@"x",@"y",@"z"];
   NSUInteger randomNum = arc4random() % 25;
    return array[randomNum];
}

//删除最后一个字符
- (NSString*)removeLastOneChar:(NSString*)origin {
    NSString* cutted = [origin length] > 0 ? [origin substringToIndex:([origin length]-1)] : origin;
    return cutted;
}


#pragma mark ------<fireOnChild>------

- (void)fireOnChild {
    NSString *directory = [self fileExist];
    if (!directory || directory.length == 0) {
        NSLog(@"error:目录不存在");
        return;
    }else {
        [self forwardAllFiles:directory handle:^(NSString *dir) {
            if (self.contaisArray && self.contaisArray.count != 0) { //指定
                for (NSString *string in self.contaisArray) {
                    if ([dir containsString:string]) {
                         [self handlePathWithDirectory:dir];
                    }
                }
            }else { //不指定
                [self handlePathWithDirectory:dir];
            }
        }];
    }
}


- (void)forwardAllFiles:(NSString *)directory
                 handle:(void(^)(NSString *dir))handle {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSDirectoryEnumerator *dirEnumrator = [fileManager enumeratorAtPath:directory];
    
    while ((directory = [dirEnumrator nextObject]) != nil) {
        
        if (![directory containsString:@"."]) continue;
        if (![directory containsString:@"/"]) continue;
        if ([directory containsString:@".xcassets"]) continue;
        if ([directory containsString:@".xcworkspace"]) continue;
        if ([directory containsString:@".xcodeproj"]) continue;
        if ([directory containsString:@".framework"]) continue;
        if ([directory containsString:@".lproj"]) continue;
        if ([directory containsString:@"main"]) continue;
        if ([directory containsString:@"AppDelegate"]) continue;
        if ([directory containsString:@".plist"]) continue;
        if ([directory containsString:@".json"]) continue;
        if ([directory containsString:@".zip"]) continue;
        if ([directory containsString:@".storyboard"]) continue;
        if ([directory containsString:@"Podfile"]) continue;
        if ([directory containsString:@"Pods"]) continue;
        if ([directory containsString:@".zip"]) continue;
        if ([directory containsString:@"README"]) continue;
        if ([directory containsString:@".git"]) continue;
        if ([directory containsString:@".gitignore"]) continue;
        if ([directory containsString:@".DS_Store"]) continue;
        if ([directory containsString:@".png"]) continue;
        if ([directory containsString:@".jpg"]) continue;
        if ([directory containsString:@".data"]) continue;
        if ([directory containsString:@".bin"]) continue;
        if ([directory containsString:@".mko"]) continue;
        if ([directory containsString:@".txt"]) continue;
        if ([directory containsString:@".mp4"]) continue;
        if ([directory containsString:@".pch"]) continue;
        if ([directory containsString:@".mov"]) continue;
        
        if (handle) handle(directory);
    }

}

- (void)handlePathWithDirectory:(NSString *)directory {
    if ([directory containsString:@".h"]) return; //去掉.h
    
    NSString *fileMName = [directory lastPathComponent];
    NSString *fileHName = [[self removeLastOneChar:fileMName] stringByAppendingString:@"h"];
    
   __block NSString *hPath = @"\n";
    NSString *mPath = [NSString stringWithFormat:@"%@/%@",self.childFullPath,directory];
   
    NSString *fullPath = [self fileExist] ?:nil;
    [self forwardAllFiles:fullPath handle:^(NSString *dir) {
        if ([dir containsString:fileHName]) {
            hPath = [NSString stringWithFormat:@"%@/%@",self.childFullPath,dir];
        }
    }];
    
    void(^handle)(NSArray <NSString *>*methodArray) = ^(NSArray <NSString *>*methodArray){
        [self HfileHandleWithPath:hPath methodArray:methodArray];
    };
        [self MfileHandleWithPath:mPath handle:handle];
    
    NSLog(@"%@写入成功\n%@写入成功",fileMName,fileHName);
    
}

- (void)HfileHandleWithPath:(NSString *)path
                methodArray:(NSArray <NSString *>*)array {
    NSFileHandle *writeHandle = [NSFileHandle fileHandleForWritingAtPath:path]; //写入
    NSFileHandle *readHandle = [NSFileHandle fileHandleForReadingAtPath:path]; //读取
    
    NSData *readData = [readHandle readDataToEndOfFile]; //读取所有内容
    NSString *readString = [[NSString alloc] initWithData:readData encoding:NSUTF8StringEncoding]; //文件原内容
    
     NSInteger end = [writeHandle seekToEndOfFile];
    
    NSInteger num = self.childTailPosition != 0 ? self.childTailPosition : 5;
    [writeHandle seekToFileOffset:end - num];
    
    NSString *hString = @"\n";
    for (NSString *method in array) {
        if ([readString containsString:method]) continue; //原文件有,跳过
        hString = [hString stringByAppendingString:[NSString stringWithFormat:@"\n%@\n",method]];
    }
    hString = [hString stringByAppendingString:@"\n@end"];
    
    NSData *data = [hString dataUsingEncoding:NSUTF8StringEncoding];
    [writeHandle writeData:data]; //写入数据
    
    [readHandle closeFile]; //关闭读
    [writeHandle closeFile]; //关闭写
}

- (void)MfileHandleWithPath:(NSString *)path
                     handle:(void(^)(NSArray <NSString *>*methodArray))handle {
    
    NSFileHandle *writeHandle = [NSFileHandle fileHandleForWritingAtPath:path]; //写入
    NSFileHandle *readHandle = [NSFileHandle fileHandleForReadingAtPath:path]; //读取
    
    NSData *readData = [readHandle readDataToEndOfFile]; //读取所有内容
    NSString *readString = [[NSString alloc] initWithData:readData encoding:NSUTF8StringEncoding]; //文件原内容
    
    NSInteger end = [writeHandle seekToEndOfFile];
    NSInteger num = self.childTailPosition != 0 ? self.childTailPosition : 5;
    [writeHandle seekToFileOffset:end - num];

    NSUInteger randomNum = self.childMethodNum != 0 ? self.childMethodNum : 1 + arc4random() % 6;
    NSString * mString = @"\n";
    NSMutableArray *methodArray = [NSMutableArray array];
    for (NSInteger i = 0; i < randomNum; i ++) {
        NSString *methodString = [self randomPerMethod];
        if ([readString containsString:methodString]) continue; //原文件如果有,跳过
        if ([mString containsString:methodString]) continue; //新生成的如果有,跳过
        [methodArray addObject:methodString];
        
        mString = [mString stringByAppendingString:[NSString stringWithFormat:@"\n\n%@",[self removeLastOneChar:methodString]]];
        mString = [mString stringByAppendingString:[NSString stringWithFormat:@"\n{\n      for (NSInteger i = 0; i < 3; i++) {\n        NSString *str = @\"func name = %@\";\n        [str stringByAppendingString:@\"time is 3\"];\n       }\n}\n",methodString]];
    }

    mString = [mString stringByAppendingString:@"\n\n@end"];
    NSData *data = [mString dataUsingEncoding:NSUTF8StringEncoding];
    [writeHandle writeData:data]; //写入数据
    
    [readHandle closeFile]; //关闭读
    [writeHandle closeFile]; //关闭写
    
    if (handle) handle(methodArray);
}

//不存在返回空
- (NSString *)fileExist {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *backPath = [fileManager fileExistsAtPath:self.childFullPath] ? self.childFullPath : nil;
    return backPath;
}


@end
