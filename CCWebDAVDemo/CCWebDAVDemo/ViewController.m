//
//  ViewController.m
//  CCWebDAVDemo
//
//  Created by Carven on 2022/11/18.
//

#import "ViewController.h"
#import "UOWebDavManager.h"
#import <Masonry/Masonry.h>
#import "NSString+Encode.h"

@interface ViewController ()<UITableViewDataSource, UITableViewDelegate, UIDocumentPickerDelegate>

@property (strong, nonatomic) UITableView *mainTableView;
@property (strong, nonatomic) NSMutableArray *fileArray;

@property (strong, nonatomic) UIDocumentPickerViewController *documentPickerVC;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    
    UIBarButtonItem *item1 = [[UIBarButtonItem alloc] initWithTitle:@"新建" style:UIBarButtonItemStylePlain target:self action:@selector(addButtonClicked1:)];
    UIBarButtonItem *item2 = [[UIBarButtonItem alloc] initWithTitle:@"上传" style:UIBarButtonItemStylePlain target:self action:@selector(addButtonClicked2:)];
    self.navigationItem.rightBarButtonItems = @[item1, item2];

    [self.view addSubview:self.mainTableView];
    [self.mainTableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.mas_equalTo(self.view);
    }];
    if (self.path == nil || self.path.length == 0) {
        self.path = @"/";
    }
    [self loadData];
}

#pragma mark - Action
- (void)addButtonClicked1:(UIBarButtonItem *)item {
    NSString *path = [NSString stringWithFormat:@"%@%zd", self.path, self.fileArray.count];
    [[UOWebDavManager shareInstance] createDirectoryAtURLString:path completeBlock:^(BOOL isSuccess, NSError * _Nonnull error) {
        if (isSuccess) {
            [self loadData];
        }
    }];
}
 
- (void)addButtonClicked2:(UIBarButtonItem *)item {
    [self.navigationController presentViewController:self.documentPickerVC animated:YES completion:^{
            
    }];
}

- (void)uploadFile:(NSData *)data fileName:(NSString *)fileName {
    NSString *fileName_encode = [NSString stringWithFormat:@"%@%@", self.path, [fileName urlEncode]];
    
    [[UOWebDavManager shareInstance] uploadFileToURLString:fileName_encode fileData:data completeBlock:^(BOOL isSuccess, NSError * _Nonnull error) {
        [self loadData];
    }];
}

- (void)deleteFilePath:(NSString *)path {
    [[UOWebDavManager shareInstance] removeFileToURLString:path completeBlock:^(BOOL isSuccess, NSError * _Nonnull error) {
        [self loadData];
    }];
}

#pragma mark - Custome
- (void)loadData {
    __weak typeof(self) weakSelf = self;
    [[UOWebDavManager shareInstance] loadFileListAtPath:self.path completeBlock:^(NSArray * _Nonnull resultList, NSError * _Nonnull error) {
        weakSelf.fileArray = [resultList mutableCopy];
        [weakSelf.mainTableView reloadData];
    }];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.fileArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    
    AFWebDAVMultiStatusResponse *res = [self.fileArray objectAtIndex:indexPath.row];
    if (res.isCollection) {
        cell.imageView.image = [UIImage imageNamed:@"folder"];
    } else {
        cell.imageView.image = [UIImage imageNamed:@"file"];
    }
    
    cell.textLabel.text = res.displayname;
//    cell.detailTextLabel.text = res.modificationDate.;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    AFWebDAVMultiStatusResponse *res = [self.fileArray objectAtIndex:indexPath.row];
    if (res.isCollection) {
        ViewController *vc = [[ViewController alloc] init];
        vc.path = res.href;
        [self.navigationController pushViewController:vc animated:YES];
    }
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        AFWebDAVMultiStatusResponse *res = [self.fileArray objectAtIndex:indexPath.row];
        [self deleteFilePath:res.href];
    }
}

#pragma mark - UIDocumentPickerDelegate
 
- (void)documentPicker:(UIDocumentPickerViewController *)controller didPickDocumentsAtURLs:(NSArray<NSURL *> *)urls {
    // 获取授权
    BOOL fileUrlAuthozied = [urls.firstObject startAccessingSecurityScopedResource];
    if (fileUrlAuthozied) {
        // 通过文件协调工具来得到新的文件地址，以此得到文件保护功能
        NSFileCoordinator *fileCoordinator = [[NSFileCoordinator alloc] init];
        NSError *error;
        [fileCoordinator coordinateReadingItemAtURL:urls.firstObject options:0 error:&error byAccessor:^(NSURL *newURL) {
            // 读取文件
            NSString *fileName = [newURL lastPathComponent];
            fileName = [fileName stringByReplacingOccurrencesOfString:@"MOV" withString:@"mov"];
            NSError *error = nil;
            NSData *fileData = [NSData dataWithContentsOfURL:newURL options:NSDataReadingMappedIfSafe error:&error];
            if (error) {
                // 读取出错
//                [UWCToast showToastWithText:@"暂不支持此文件类型"];
            } else {
                if (fileData.length) {
                    [self uploadFile:fileData fileName:fileName];
                }
            }
            [self.navigationController dismissViewControllerAnimated:YES completion:NULL];
        }];
    } else {
        // 授权失败
    }
}

- (UITableView *)mainTableView {
    if (!_mainTableView) {
        _mainTableView = [[UITableView alloc] init];
        _mainTableView.dataSource = self;
        _mainTableView.delegate = self;
        [_mainTableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"cell"];
    }
    return _mainTableView;
}

- (UIDocumentPickerViewController *)documentPickerVC {
    if (!_documentPickerVC) {
        NSArray *types = @[@"public.text",
                           @"public.content",
                           @"public.data",
                           @"public.movie",
                           @"public.source-code",
                           @"public.image",
                           @"public.xml",
                           @"public.band",
                           @"public.audio",
                           @"public.audiovisual-content",
                           @"com.adobe.pdf",
                           @"com.apple.keynote.key",
                           @"com.microsoft.word.doc",
                           @"com.microsoft.excel.xls",
                           @"com.microsoft.powerpoint.ppt",
                           @"com.microsoft.advanced-​systems-format"];

        _documentPickerVC = [[UIDocumentPickerViewController alloc] initWithDocumentTypes:types inMode:UIDocumentPickerModeOpen];
        // 设置代理
        _documentPickerVC.delegate = self;
        // 设置模态弹出方式
        _documentPickerVC.modalPresentationStyle = UIModalPresentationFullScreen;
    }
    return _documentPickerVC;
}

@end
