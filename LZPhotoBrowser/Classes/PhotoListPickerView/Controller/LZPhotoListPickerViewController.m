//
//  LZPhotoListPickerViewController.m
//  LZPhotoBrowser
//
//  Created by Dear.Q on 2020/2/27.
//

#import "LZPhotoListPickerViewController.h"
#import "LZPhotoBrowserManager.h"
#import "LZPhotoListCell.h"

static NSUInteger LZPhotoListMaxCount = 6;
static NSUInteger LZPhotoListColumn = 4;
static CGFloat LZPhotoListMarginTop = 10.0f;
static CGFloat LZPhotoListMarginLeft = 20.0f;
static CGFloat LZPhotoListMarginBottom = 20.0f;
static CGFloat LZPhotoListMarginRight = 20.0f;
static CGFloat LZPhotoListSpacing = 10.0f;

@interface LZPhotoListPickerViewController ()<UICollectionViewDelegateFlowLayout>

@property (nonatomic, strong) NSMutableArray *imageDataSource;
@property (nonatomic, strong) NSMutableArray *assetDataSource;

@end

@implementation LZPhotoListPickerViewController

// MARK: - Lazy Loading
- (NSMutableArray *)imageDataSource {
    if (nil == _imageDataSource) {
        _imageDataSource = [NSMutableArray array];
    }
    return _imageDataSource;
}

- (NSMutableArray *)assetDataSource {
    if (nil == _assetDataSource) {
        _assetDataSource = [NSMutableArray array];
    }
    return _assetDataSource;
}

// MARK: - Initialization
- (instancetype)initWithCoder:(NSCoder *)coder {
    if (self = [super initWithCoder:coder]) {
        self.maxCount = LZPhotoListMaxCount;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setupUI];
    [self updateDataSourceWithImages:@[] assets:@[]];
}

// MARK: - Setter
- (void)setThemeColor:(UIColor *)themeColor {
    _themeColor = themeColor;
    
    [LZPhotoBrowserManager configThemeColor:themeColor];
}

// MARK: - Public
+ (instancetype)instance {
    return [self viewControllerFromstoryboard:@"LZPhotoListPickerViewController"
                                     inBundle:LZPhotoBrowserBundle];
    
}

// MARK: - UI Action
- (void)longPressAction:(UILongPressGestureRecognizer *)longPress {
    // 获取此次点击的坐标，根据坐标获取cell对应的indexPath
    CGPoint point = [longPress locationInView:self.collectionView];
    NSIndexPath *indexPath = [self.collectionView indexPathForItemAtPoint:point];
    // 根据长按手势的状态进行处理。
    switch (longPress.state) {
        case UIGestureRecognizerStateBegan: // 开始移动
            // 当没有点击到cell的时候不进行处理
            if (!indexPath) {
                break;
            }
            [self.collectionView beginInteractiveMovementForItemAtIndexPath:indexPath];
            break;
        case UIGestureRecognizerStateChanged: // 移动过程中更新位置坐标
            [self.collectionView updateInteractiveMovementTargetPosition:point];
            break;
        case UIGestureRecognizerStateEnded: // 停止移动调用此方法
            [self.collectionView endInteractiveMovement];
            break;
        default: // 取消移动
            [self.collectionView cancelInteractiveMovement];
            break;
    }
}

// MARK: - Private
- (void)setupUI {
    [self configCollectionView];
}

- (void)configCollectionView {
    
    self.collectionView.backgroundColor = [UIColor colorWithHexString:@"#EEEEEE"];
    UILongPressGestureRecognizer *longPressGesture =
    [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressAction:)];
    [self.collectionView addGestureRecognizer:longPressGesture];
}

- (BOOL)allowAddPhoto {
    
    BOOL allow = NO;
    NSObject *placeholderObject = [self.imageDataSource firstObject];
    if (placeholderObject && [placeholderObject isKindOfClass:[NSNull class]]) {
        
        allow = self.maxCount + 1 > self.assetDataSource.count;
        if (NO == allow) {
            
            [self.imageDataSource removeObjectAtIndex:0];
            [self.assetDataSource removeObjectAtIndex:0];
        }
    } else {
        
        allow = self.maxCount > self.assetDataSource.count;
        if (allow) {
            
            NSNull *null = [[NSNull alloc] init];
            [self.imageDataSource insertObject:null atIndex:0];
            [self.assetDataSource insertObject:null atIndex:0];
        }
    }
    return  allow;
}

- (void)photoListDidChange {
    if (self.selectPhotoListDidChangeCallback) {
        self.selectPhotoListDidChangeCallback([self fetchAllSelectedImages], [self fetchAllSelectedAssets]);
    }
}
- (void)updateDataSourceWithImages:(NSArray *)images
                            assets:(NSArray *)assets {
    if (nil == images || nil == assets) {
        return;
    }
    if (self.imageDataSource.count
        || self.assetDataSource.count) {
        
        [self.imageDataSource removeAllObjects];
        [self.assetDataSource removeAllObjects];
    }
    [self.imageDataSource addObjectsFromArray:images];
    [self.assetDataSource addObjectsFromArray:assets];
    [self allowAddPhoto];
    [self.collectionView reloadData];
    [self photoListDidChange];
}

- (void)deleteDataSourceWithIndexPath:(NSIndexPath *)indexPath {
    if (self.imageDataSource.count <= indexPath.row
        || self.assetDataSource.count < indexPath.row) {
        return;
    }
    [self.imageDataSource removeObjectAtIndex:indexPath.row];
    [self.assetDataSource removeObjectAtIndex:indexPath.row];
    [self allowAddPhoto];
    [self.collectionView reloadData];
    [self photoListDidChange];
}

- (NSArray *)fetchAllSelectedImages {
    
    NSMutableArray *selectedImages = [NSMutableArray arrayWithArray:self.imageDataSource];
    if ([self allowAddPhoto]) {
        [selectedImages removeObjectAtIndex:0];
    }
    return selectedImages;
}

- (NSMutableArray *)fetchAllSelectedAssets {
    
    NSMutableArray *selectedAssets = [NSMutableArray arrayWithArray:self.assetDataSource];
    if ([self allowAddPhoto]) {
        [selectedAssets removeObjectAtIndex:0];
    }
    return selectedAssets;
}

// MARK: - UICollectionView
// MARK: <UICollectionViewDataSource>
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView
     numberOfItemsInSection:(NSInteger)section {
    return self.imageDataSource.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView
                  cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    LZPhotoListCell *cell =
    [collectionView dequeueReusableCellWithReuseIdentifier:@"LZPhotoListCell"
                                              forIndexPath:indexPath];
    @lzweakify(self);
    cell.deleteDidTouchCallback = ^(LZPhotoListCell * _Nonnull cell) {
        @lzstrongify(self);
        NSIndexPath *indexPath = [collectionView indexPathForCell:cell];
        [self deleteDataSourceWithIndexPath:indexPath];
    };
    cell.photoImg = self.imageDataSource[indexPath.row];
    return cell;
}

- (BOOL)collectionView:(UICollectionView *)collectionView
canMoveItemAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (void)collectionView:(UICollectionView *)collectionView
   moveItemAtIndexPath:(NSIndexPath *)sourceIndexPath
           toIndexPath:(NSIndexPath*)destinationIndexPath {
    
    [self.imageDataSource exchangeObjectAtIndex:sourceIndexPath.row
                              withObjectAtIndex:destinationIndexPath.row];
    [self.assetDataSource exchangeObjectAtIndex:sourceIndexPath.row
                              withObjectAtIndex:destinationIndexPath.row];
    [self.collectionView reloadData];
    [self photoListDidChange];
}

- (NSIndexPath *)collectionView:(UICollectionView *)collectionView
targetIndexPathForMoveFromItemAtIndexPath:(NSIndexPath *)originalIndexPath
            toProposedIndexPath:(NSIndexPath *)proposedIndexPath {
    if ([self allowAddPhoto] && proposedIndexPath.item == 0) {
        return originalIndexPath;
    } else {
        return proposedIndexPath;
    }
}

// MARK: <UICollectionViewDelegate>
- (void)collectionView:(UICollectionView *)collectionView
didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    if ([self allowAddPhoto] && 0 == indexPath.row) {
        LZLog(@"添加图片");
        @lzweakify(self);
        [LZPhotoBrowserManager showPhotoLibraryWithSender:self maxSelectCount:self.maxCount selectCompletionHandler:^(NSArray<UIImage *> * _Nullable images, NSArray<PHAsset *> * _Nonnull assets) {
            @lzstrongify(self);
            [self updateDataSourceWithImages:images assets:assets];
        }];
    } else {
        LZLog(@"浏览图片")
        NSUInteger index = indexPath.row;
        if ([self allowAddPhoto]) --index;
        [LZPhotoBrowserManager previewWithSender:self
                                   photos:[self fetchAllSelectedImages]
                                   assets:[self fetchAllSelectedAssets]
                                    index:index];
    }
}

// MARK: <UICollectionViewDelegateFlowLayout>
- (CGSize)collectionView:(UICollectionView *)collectionView
                  layout:(UICollectionViewLayout *)collectionViewLayout
  sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    CGFloat maxWidth = self.collectionView.frame.size.width;
    CGFloat totalSpacing = (LZPhotoListColumn - 1) * LZPhotoListSpacing;
    CGFloat totalMargin = LZPhotoListMarginLeft + LZPhotoListMarginRight;
    CGFloat size = floorf((maxWidth - totalSpacing -totalMargin) / LZPhotoListColumn);
    return CGSizeMake(size, size);
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView
                        layout:(UICollectionViewLayout *)collectionViewLayout
        insetForSectionAtIndex:(NSInteger)section {
    return UIEdgeInsetsMake(LZPhotoListMarginTop, LZPhotoListMarginLeft, LZPhotoListMarginBottom, LZPhotoListMarginRight);
}

@end