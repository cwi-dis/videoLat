//
//  OpenCalibrationTableViewController.m
//  videoLat-iOS
//
//  Created by Jack Jansen on 18/03/15.
//  Copyright (c) 2015 CWI. All rights reserved.
//

#import "OpenDocumentTableViewController.h"
#import "AppDelegate.h"
#import "DocumentViewController.h"

@implementation OpenDocumentTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    showCalibrations = [self.navigationItem.title containsString: @"Calibration"];
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    [self _updateDocuments];
    return self.documents.count;
}

- (void) _updateDocuments
{
    if (self.documents) {
        // Test whether they have changed
        return;
    }
    NSMutableArray *docs = [[NSMutableArray alloc] initWithCapacity:10];
    self.documents = docs;
    // Get Directory to load filenames from
    NSURL *dirUrl;
    if (showCalibrations) {
        dirUrl = [(AppDelegate *)[[UIApplication sharedApplication] delegate] directoryForCalibrations];
    } else {
        dirUrl = [[NSFileManager defaultManager] URLForDirectory:NSDocumentDirectory inDomain:NSUserDomainMask appropriateForURL: nil create:YES error:nil ];
    }
    if (dirUrl == nil) return;
    
    // Get filenames
    NSDirectoryEnumerationOptions opts = NSDirectoryEnumerationSkipsSubdirectoryDescendants | NSDirectoryEnumerationSkipsPackageDescendants | NSDirectoryEnumerationSkipsHiddenFiles;
    NSArray *files = [[NSFileManager defaultManager] contentsOfDirectoryAtURL:dirUrl includingPropertiesForKeys:nil options:opts error:nil];
    if (files == nil) {
        return;
    }
    // Add to table
    for (NSURL *url in files) {
        NSDictionary *item = @{
           @"name" : [url lastPathComponent],
           @"url" : url
           };
        [docs addObject: item];
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ListPrototypeCell" forIndexPath:indexPath];
    
    if (self.documents == nil || self.documents.count == 0) {
        cell.textLabel.text = @"No previous measurements available";
        cell.userInteractionEnabled = cell.textLabel.enabled = cell.detailTextLabel.enabled = NO;
        return cell;
    }
    NSDictionary *item = [self.documents objectAtIndex:indexPath.row];
    NSString *documentName = [item objectForKey:@"name"];
    cell.textLabel.text = documentName;
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return NO;
}

// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        NSDictionary *item = [self.documents objectAtIndex: indexPath.row];
        // Delete the file
        NSLog(@"Should delete %@", [item objectForKey:@"url"]);
        NSError *error;
        BOOL ok = [[NSFileManager defaultManager] removeItemAtURL:[item objectForKey:@"url"] error:&error];
        if (!ok) {
            showErrorAlert(error);
            return;
        }
        self.documents = nil;
        [self _updateDocuments];
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = [self.documents objectAtIndex: indexPath.row];
    assert(item);
    selectedUrl = [item objectForKey:@"url"];
    NSLog(@"Will open %@", selectedUrl);
    [self performSegueWithIdentifier:@"showDocument" sender:self];
    
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    assert(selectedUrl);
    DocumentViewController *dvc = segue.destinationViewController;
    NSLog(@"URL for measurement is %@", selectedUrl);
    Document *newDocument = [[Document alloc] initWithFileURL: selectedUrl];
    selectedUrl = nil;
    [newDocument openWithCompletionHandler:^(BOOL success) {
        if (success) {
            dvc.document = newDocument;
        } else {
            showWarningAlert(@"Cannot open measurement");
        }
    }];
}


@end
