#import "DPKGParser.h"

@implementation DPKGParser

+ (NSDictionary<NSString *, NSString *> *)parsePackageEntry:(NSString *)fullEntry error:(NSError **)errorPt {
#define hasWhitespacePrefix(var) ([var hasPrefix:@" "] || [var hasPrefix:@"\t"])
#define isWhitespace(c) (c == ' ' || c == '\t')
#define fail(errCode, message) { \
	if (errorPt) *errorPt = [NSError errorWithDomain:@"com.pixelomer.DPKGParser.file-parse-failure" code:errCode userInfo:@{ \
		NSLocalizedDescriptionKey : message \
	}]; \
	return nil; \
}
	NSArray<NSString *> *components;
	if (!(components = [fullEntry componentsSeparatedByString:@"\n"])) {
		fail(1, @"Failed to split the file contents.")
	}
	else if (components.count <= 0) fail(2, @"File doesn't contain anything.")
	NSMutableDictionary *result = [[NSMutableDictionary alloc] init];
	for (int i = (int)components.count-1; i >= 0; i--) {
		if ([components[i] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]].length <= 0) continue;
		int endIndex = i;
		while (hasWhitespacePrefix(components[i])) if (--i < 0) fail(3, ([NSString stringWithFormat:@"Multi-line value doesn't belong to any key. Line: %dd", endIndex+1]))
		NSMutableArray *fieldComponents = [[components[i] componentsSeparatedByString:@":"] mutableCopy];
		if (fieldComponents.count <= 0) fail(4, ([NSString stringWithFormat:@"Empty line: %d", i+1]))
		else if (fieldComponents.count == 1) [fieldComponents addObject:@""];
		NSString *key = [(NSString *)fieldComponents[0] lowercaseString];
		[fieldComponents removeObjectAtIndex:0];
		NSMutableString *value = [[fieldComponents componentsJoinedByString:@":"] mutableCopy];
		while (value.length > 0 && hasWhitespacePrefix(value)) [value deleteCharactersInRange:NSMakeRange(0, 1)];
		if (endIndex != i) {
			unsigned int indentation = 0;
			for (int j=i+1; j <= endIndex; j++) {
				NSString *indentedLine = components[j];
				if (!indentation) while ((indentation < indentedLine.length) && isWhitespace([indentedLine characterAtIndex:indentation])) indentation++;
				[value appendFormat:@"\n%@", [indentedLine substringWithRange:NSMakeRange(indentation, indentedLine.length - indentation)]];
			}
		}
		result[key] = [value copy];
	}
	return [result copy];
#undef fail
#undef isWhitespace
#undef hasWhitespacePrefix
}

+ (NSArray<NSDictionary<NSString *, NSString *> *> *)parseFileContents:(NSString *)fileContents error:(NSError **)errorPt {
	NSArray *rawEntries = [fileContents componentsSeparatedByString:@"\n\n"];
	NSMutableArray *parsedEntries = [NSMutableArray arrayWithCapacity:rawEntries.count];
	for (NSString *rawEntry in rawEntries) {
		if ([rawEntry isEqualToString:@""]) continue;
		NSError *error;
		NSDictionary *parsedEntry = [self parsePackageEntry:rawEntry error:&error];
		if (error) {
			if (errorPt) *errorPt = error;
			return nil;
		}
		[parsedEntries addObject:parsedEntry];
	}
	return [parsedEntries copy];
}

+ (NSArray<NSDictionary<NSString *, NSString *> *> *)parseFileAtPath:(NSString *)path error:(NSError **)errorPt {
	NSError *error;
	NSString *fileContents = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:&error];
	if (error || !fileContents) {
		if (errorPt) *errorPt = error;
		return nil;
	}
	return [self parseFileContents:fileContents error:errorPt];
}

// WARNING: Contains unnecessary optimization
+ (NSArray<NSString *> *)findFirstLinesForFields:(NSArray<NSString *> *)fields inString:(NSString *)string {
	NSMutableArray *values = [NSMutableArray arrayWithCapacity:fields.count];
	int expectedValue = 0;
	int currentValue = 0;
	for (int i = 0; i < fields.count; values[i++] = NSNull.null) expectedValue += (1 << i);
	for (NSString *line in [string componentsSeparatedByString:@"\n"]) {
		if (expectedValue == currentValue) break;
		NSInteger index = 0;
		NSMutableArray<NSString *> *components = [line componentsSeparatedByString:@": "].mutableCopy;
		if ((components.count > 0) && ((index = [fields indexOfObject:components[0].lowercaseString]) != NSNotFound)) {
			[components removeObjectAtIndex:0];
			values[index] = [components componentsJoinedByString:@": "];
			currentValue |= (1 << index);
		}
	}
	return values.copy;
}

@end
