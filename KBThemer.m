#import <UIKit/UIKit.h>
#import <CoreGraphics/CoreGraphics.h>
#import <substrate.h>

extern CGColorRef UIKBGetNamedColor(CFStringRef gradientName);

#define kColorSettingsPath @"/var/mobile/Library/Preferences/com.rpetrich.kbthemer.colors.plist"

static NSMutableDictionary *colorSettings;
static CFMutableDictionaryRef namedColors;

MSHook(CGColorRef, UIKBGetNamedColor, CFStringRef colorName)
{
	if (!namedColors) {
		namedColors = CFDictionaryCreateMutable(kCFAllocatorDefault, 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
		colorSettings = [[NSMutableDictionary alloc] initWithContentsOfFile:kColorSettingsPath];
		if (colorSettings) {
			CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
			for (NSString *settingName in [colorSettings allKeys]) {
				NSArray *c = [colorSettings objectForKey:settingName];
				const CGFloat components[] = { [[c objectAtIndex:0] floatValue], [[c objectAtIndex:1] floatValue], [[c objectAtIndex:2] floatValue], [[c objectAtIndex:3] floatValue] };
				CGColorRef color = CGColorCreate(colorSpace, components);
				CFDictionarySetValue(namedColors, settingName, color);
				CFRelease(color);
			}
			CGColorSpaceRelease(colorSpace);
		} else {
			colorSettings = [[NSMutableDictionary alloc] init];
		}
	}
	CGColorRef result = (CGColorRef)CFDictionaryGetValue(namedColors, colorName);
	if (!result) {
		result = _UIKBGetNamedColor(colorName);
		CFDictionarySetValue(namedColors, colorName, result);
		CGFloat components[4];
		const CGFloat *colorComponents = CGColorGetComponents(result);
		size_t count = CGColorGetNumberOfComponents(result);
		switch (count) {
			case 4:
				components[3] = colorComponents[3];
				components[2] = colorComponents[2];
				components[1] = colorComponents[1];
				components[0] = colorComponents[0];
				break;
			case 2:
				components[3] = colorComponents[1];
				components[2] = colorComponents[0];
				components[1] = colorComponents[0];
				components[0] = colorComponents[0];
				break;
			default:
				return result;
		}
		NSArray *c = [NSArray arrayWithObjects:
			[NSNumber numberWithFloat:components[0]],
			[NSNumber numberWithFloat:components[1]],
			[NSNumber numberWithFloat:components[2]],
			[NSNumber numberWithFloat:components[3]],
		nil];
		[colorSettings setObject:c forKey:(id)colorName];
		[colorSettings writeToFile:kColorSettingsPath atomically:YES];
	}
	return result;
}

__attribute__((constructor))
static void constructor()
{
	MSHookFunction(&UIKBGetNamedColor, $UIKBGetNamedColor, (void **)&_UIKBGetNamedColor);
}
