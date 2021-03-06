//
//  AddSourceViewController.m
//  Magma
//
//  Created by PixelOmer on 27.07.2019.
//  Copyright © 2019 PixelOmer. All rights reserved.
//

#import "AddSourceViewController.h"
#import <objc/runtime.h>

@implementation AddSourceViewController

static NSArray *cells;

+ (void)load {
	if (self == [AddSourceViewController class]) {
		cells = @[
			@[@"URL", NSNull.null, @"url"],
			@[@"Distribution", @NO, @"dists"],
			@[@"Sections", @YES, @"sections"]
		];
	}
}

- (instancetype)init {
	NSString *className = NSStringFromClass(self.class);
	[NSException raise:NSInvalidArgumentException format:@"-[%@ init] is deprecated, use -[%@ initWithInformationDictionary:] instead.", className, className];
	return nil;
}

- (instancetype)initWithInformationDictionary:(NSDictionary *)dict {
	UITableViewController *tableViewController = [[UITableViewController alloc] initWithStyle:UITableViewStyleGrouped];
	if (dict && (self = [super initWithRootViewController:tableViewController])) {
		_infoDictionary = dict;
		tableViewController.tableView.dataSource = self;
		tableViewController.tableView.delegate = self;
		tableViewController.tableView.cellLayoutMarginsFollowReadableWidth = YES;
		tableViewController.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStyleDone target:self action:@selector(handleCancelButton)];
		tableViewController.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Add" style:UIBarButtonItemStylePlain target:self action:@selector(handleAddButton)];
		tableViewController.title = _infoDictionary[@"title"];
		self->tableViewController = tableViewController;
		selectedOptions = [NSMutableArray new];
		for (NSArray *cell in cells) {
			if ([cell[1] isKindOfClass:[NSNumber class]]) {
				[selectedOptions addObject:@[]];
			}
			else [selectedOptions addObject:(id)NSNull.null];
		}
	}
	return self;
}

- (void)handleCancelButton {
	[self dismissViewControllerAnimated:YES completion:nil];
}

- (void)handleAddButton {
	for (NSArray *array in selectedOptions) {
		if ([array isKindOfClass:[NSArray class]] && !array.count) {
			UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Error" message:@"You need to select a distribution and at least one component." preferredStyle:UIAlertControllerStyleAlert];
			[alert addAction:[UIAlertAction
				actionWithTitle:@"OK"
				style:UIAlertActionStyleCancel
				handler:nil
			]];
			[tableViewController presentViewController:alert animated:YES completion:nil];
			return;
		}
	}
	id result = [Database.sharedInstance addSourceWithBaseURL:_infoDictionary[@"url"] architecture:_infoDictionary[@"arch"] distribution:selectedOptions[1][0] components:[selectedOptions[2] componentsJoinedByString:@" "]];
	if ([result isKindOfClass:[NSNull class]]) {
		// This should never happen. AddFeaturedSourceButton should handle this situation.
		UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Error" message:@"This source is already in your sources. If you want to change its components, please remove that source and try again." preferredStyle:UIAlertControllerStyleAlert];
		[alert addAction:[UIAlertAction
			actionWithTitle:@"OK"
			style:UIAlertActionStyleCancel
			handler:nil
		]];
		[tableViewController presentViewController:alert animated:YES completion:nil];
	}
	[self dismissViewControllerAnimated:YES completion:nil];
}

- (void)viewDidLoad {
	[super viewDidLoad];
	self.view.backgroundColor = [UIColor whiteColor];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return cells.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"] ?: [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"cell"];
	cell.textLabel.text = cells[indexPath.row][0];
	if ([cells[indexPath.row][1] isKindOfClass:[NSNull class]]) {
		cell.selectionStyle = UITableViewCellSelectionStyleNone;
		cell.accessoryType = UITableViewCellAccessoryNone;
		cell.detailTextLabel.text = _infoDictionary[cells[indexPath.row][2]];
	}
	else {
		cell.selectionStyle = UITableViewCellSelectionStyleDefault;
		cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
		cell.detailTextLabel.text = [selectedOptions[indexPath.row] componentsJoinedByString:@", "];
	}
	return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	NSArray *cellInfo = cells[indexPath.row];
	if (![cellInfo[1] isKindOfClass:[NSNull class]]) {
		PickerTableViewController *vc = [PickerTableViewController alloc];
		vc.delegate = self;
		vc.showsInternalValues = YES;
		vc.selectedOptions = selectedOptions[indexPath.row];
		vc = [vc initWithOptions:_infoDictionary[cellInfo[2]] allowsMultipleSelections:[cellInfo[1] boolValue]];
		objc_setAssociatedObject(vc, @selector(pickerTableViewController:selectedItemsDidChange:), @(indexPath.row), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
		[self pushViewController:vc animated:YES];
	}
}

- (void)pickerTableViewController:(PickerTableViewController *)vc selectedItemsDidChange:(NSArray *)newItems {
	NSNumber *index = objc_getAssociatedObject(vc, _cmd);
	if (index) {
		selectedOptions[index.integerValue] = newItems;
		[tableViewController.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:index.integerValue inSection:0]] withRowAnimation:UITableViewRowAnimationNone];
	}
}

@end
