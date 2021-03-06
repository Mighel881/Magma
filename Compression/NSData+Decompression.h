#import <Foundation/Foundation.h>

@interface NSData(Decompression)
+ (BOOL)gunzipFile:(NSString *)inputFile toFile:(NSString *)outputFile;
+ (BOOL)bunzipFile:(NSString *)inputFile toFile:(NSString *)outputFile;
+ (BOOL)unarchiveFileAtPath:(NSString *)path toDirectoryAtPath:(NSString *)targetDir;
+ (BOOL)extractXZFileAtPath:(NSString *)inputFile toFileAtPath:(NSString *)targetPath;
+ (BOOL)extractLZMAFileAtPath:(NSString *)inputFile toFileAtPath:(NSString *)outputFile;
@end
