//
//  UTACollectionViewFlowLayout.m
//  UTALib
//
//  Created by David on 16/5/21.
//  Copyright © 2016年 UTA. All rights reserved.
//

#import "UTACollectionViewFlowLayout.h"

@interface UTACollectionViewFlowLayoutSectionInfo : NSObject {
    /*!
     *  @{@(group):[UICollectionViewLayoutAttributes]}
     */
    NSMutableDictionary<NSNumber *,  NSMutableArray<UICollectionViewLayoutAttributes *> *> *_dictGroups;
}

/*!
 *  total of items
 */
@property (nonatomic, assign) NSInteger numbersOfItems;
/*!
 *  分组数量，比如瀑布流实现，支持横向、纵向，默认为1个分组
 */
@property (nonatomic, assign) NSInteger groups;

/*!
 *  默认 UIEdgeInsetsZore:{0,0,0,0}
 */
@property (nonatomic, assign) UIEdgeInsets insets;
/*!
 *  默认为0
 */
@property (nonatomic, assign) CGFloat minimumInteritemSpacing;
/*!
 *  默认为0
 */
@property (nonatomic, assign) CGFloat minimumLineSpacing;
/*!
 *  和下一分组的间距：默认 0
 */
@property (nonatomic, assign) CGFloat spacingBetweenNextSection;

/*!
 *  UTACollectionViewFlowLayout 所属布局对象
 */
@property (nonatomic, strong) UTACollectionViewFlowLayout *collectionViewFlowLayout;

@property (nonatomic, strong) UICollectionViewLayoutAttributes * _Nullable headerAttributes;
@property (nonatomic, strong) UICollectionViewLayoutAttributes * _Nullable footerAttributes;
@property (nonatomic, strong)  NSMutableArray<UICollectionViewLayoutAttributes *> * _Nullable itemsAttributes;

@property (nonatomic, assign) CGRect frame;

+ (_Nonnull instancetype)sectionInfoWithCollectionViewFlowLayout:(UTACollectionViewFlowLayout *)layout insets:(UIEdgeInsets)insets minimumInteritemSpacing:(CGFloat)minimumInteritemSpacing minimumLineSpacing:(CGFloat)minimumLineSpacing;

/*!
 *  添加布局项属性信息
 *
 *  @param attributes 布局项属性
 */
- (void)addItemAttributes:( UICollectionViewLayoutAttributes * _Nonnull )attributes;

/*!
 *  长度最大的分组
 *
 *  @return groupIndex
 */
- (NSInteger)maxLengthGroupIndex;

/*!
 *  长度最小的分组
 *
 *  @return groupIndex
 */
- (NSInteger)minLengthGroupIndex;

/*!
 *  获取section的content length
 *
 *  @return return value description
 */
- (CGFloat)getSectionContentLength;

/*!
 *  下一个追加进来的项的原点坐标
 *
 *  @param index index
 *
 *  @return CGPoint 原点坐标
 */
- (CGPoint)originOfWillAppendItem;

- (void)setSectionOrigin:(CGPoint)origin;

- (void)calcFrame;

@end

@implementation UTACollectionViewFlowLayoutSectionInfo

- (instancetype)init {
    self = [super init];
    if (self) {
        _itemsAttributes = @[].mutableCopy;
        _numbersOfItems = 0;
        _insets = UIEdgeInsetsZero;
        _minimumLineSpacing = 0;
        _minimumInteritemSpacing = 0;
        _spacingBetweenNextSection = 0;
        _dictGroups = @{}.mutableCopy;
        
        [self setGroups:1];
    }
    return self;
}

+ (_Nonnull instancetype)sectionInfoWithCollectionViewFlowLayout:(UTACollectionViewFlowLayout *)layout insets:(UIEdgeInsets)insets minimumInteritemSpacing:(CGFloat)minimumInteritemSpacing minimumLineSpacing:(CGFloat)minimumLineSpacing {
    UTACollectionViewFlowLayoutSectionInfo *sectionInfo = [UTACollectionViewFlowLayoutSectionInfo new];
    if (self) {
        sectionInfo.insets = insets;
        sectionInfo.minimumLineSpacing = minimumLineSpacing;
        sectionInfo.minimumInteritemSpacing = minimumInteritemSpacing;
        sectionInfo.collectionViewFlowLayout = layout;
    }
    return sectionInfo;
}

- (void)setGroups:(NSInteger)groups {
    if (_groups==groups) {
        return;
    }
    _groups = groups;
    
    [_dictGroups removeAllObjects];
    
    // 重建分组
    for (NSInteger group=0; group<groups; group++) {
        NSMutableArray *arrAttributesItems = @[].mutableCopy;
        _dictGroups[@(group)] = arrAttributesItems;
    }
    
    // 重新分配分组
    for (UICollectionViewLayoutAttributes *attributes in _itemsAttributes) {
        NSInteger group = [self minLengthGroupIndex];
        NSMutableArray<UICollectionViewLayoutAttributes *> *arrAttributesItems = _dictGroups[@(group)];
        [arrAttributesItems addObject:attributes];
    }
}

/*!
 *  添加布局项属性信息
 *  并分配到长度最小的分组中
 *
 *  @param attributes 布局项属性
 */
- (void)addItemAttributes:(UICollectionViewLayoutAttributes * _Nonnull)attributes {
    // 分配到最低分组中
    NSInteger group = [self minLengthGroupIndex];
    NSMutableArray<UICollectionViewLayoutAttributes *> *arrAttributesItems = _dictGroups[@(group)];
    [arrAttributesItems addObject:attributes];
    [_itemsAttributes addObject:attributes];
}

/*!
 *  长度最大的分组
 *
 *  @return groupIndex
 */
- (NSInteger)maxLengthGroupIndex {
    NSInteger retGroup = 0;
    NSInteger maxLength = 0;
    for (NSInteger group=0; group<_groups; group++) {
        NSMutableArray<UICollectionViewLayoutAttributes *> *arrAttributesItems = _dictGroups[@(group)];
        UICollectionViewLayoutAttributes *item = [arrAttributesItems lastObject];
        
        if (UICollectionViewScrollDirectionVertical==_collectionViewFlowLayout.scrollDirection) {
            if (CGRectGetMaxY(item.frame)>maxLength) {
                maxLength = CGRectGetMaxY(item.frame);
                retGroup = group;
            }
        } else {
            if (CGRectGetMaxX(item.frame)>maxLength) {
                maxLength = CGRectGetMaxX(item.frame);
                retGroup = group;
            }
        }
    }
    return retGroup;
}

/*!
 *  长度最小的分组
 *
 *  @return groupIndex
 */
- (NSInteger)minLengthGroupIndex {
    NSInteger retGroup = 0;
    CGFloat maxLength = MAXFLOAT;
    for (NSInteger group=0; group<_groups; group++) {
        NSMutableArray<UICollectionViewLayoutAttributes *> *arrAttributesItems = _dictGroups[@(group)];
        UICollectionViewLayoutAttributes *item = [arrAttributesItems lastObject];
        
        if (UICollectionViewScrollDirectionVertical==_collectionViewFlowLayout.scrollDirection) {
            if (CGRectGetMaxY(item.frame)<maxLength) {
                maxLength = CGRectGetMaxY(item.frame);
                retGroup = group;
            }
        } else {
            if (CGRectGetMaxX(item.frame)<maxLength) {
                maxLength = CGRectGetMaxX(item.frame);
                retGroup = group;
            }
        }
    }
    return retGroup;
}

/*!
 *  获取section的content length
 *
 *  @return return value description
 */
- (CGFloat)getSectionContentLength {
    UICollectionViewLayoutAttributes *lastAttri = _dictGroups[@([self maxLengthGroupIndex])].lastObject;
    if (UICollectionViewScrollDirectionVertical==self.collectionViewFlowLayout.scrollDirection) {
        if (lastAttri)
            return CGRectGetMaxY(lastAttri.frame)+_insets.bottom+CGRectGetHeight(_footerAttributes.frame)-CGRectGetMinY(_frame);
        else
            return CGRectGetHeight(_headerAttributes.frame)+_insets.top+_insets.bottom+CGRectGetHeight(_footerAttributes.frame);
    }
    else {
        if (lastAttri)
            return CGRectGetMaxX(lastAttri.frame)+_insets.right+CGRectGetWidth(_footerAttributes.frame)-CGRectGetMinX(_frame);
        else
            return CGRectGetWidth(_headerAttributes.frame)+_insets.left+_insets.right+CGRectGetWidth(_footerAttributes.frame);
    }
}

/*!
 *  下一个追加进来的项的原点坐标
 *
 *  @param index index
 *
 *  @return CGPoint 原点坐标
 */
- (CGPoint)originOfWillAppendItem {
    NSInteger groupIndex = [self minLengthGroupIndex];
    UICollectionViewLayoutAttributes *lastAttri = [_dictGroups[@(groupIndex)] lastObject];
    
    CGPoint origin;
    if (UICollectionViewScrollDirectionVertical==_collectionViewFlowLayout.scrollDirection) {
        if (lastAttri) {
            origin.y = CGRectGetMaxY(lastAttri.frame)+_minimumLineSpacing;
        }
        else {
            origin.y = _frame.origin.y+CGRectGetHeight(_headerAttributes.frame)+_insets.top;
        }
        
        CGFloat itemWidth = (CGRectGetWidth(self.collectionViewFlowLayout.collectionView.frame)-_insets.left-_insets.right-(_groups-1)*_minimumInteritemSpacing)/_groups;
        origin.x = _insets.left+(itemWidth+_minimumInteritemSpacing)*groupIndex;
    } else {
        if (lastAttri) {
            origin.x = CGRectGetMaxX(lastAttri.frame)+_minimumLineSpacing;
        }
        else {
            origin.x = _frame.origin.x+CGRectGetWidth(_headerAttributes.frame)+_insets.left;
        }
        
        CGFloat itemHeight = (CGRectGetHeight(self.collectionViewFlowLayout.collectionView.frame)-_insets.top-_insets.bottom-(_groups-1)*_minimumInteritemSpacing)/_groups;
        origin.y = _insets.top+(itemHeight+_minimumInteritemSpacing)*groupIndex;
    }
    origin.x = round(origin.x);
    origin.y = round(origin.y);
    return origin;
}

- (void)setSectionOrigin:(CGPoint)origin {
    _frame.origin = origin;
    if (UICollectionViewScrollDirectionVertical==_collectionViewFlowLayout.scrollDirection) {
        _frame.size.width = CGRectGetWidth(_collectionViewFlowLayout.collectionView.bounds);
    }
    else {
        _frame.size.height = CGRectGetHeight(_collectionViewFlowLayout.collectionView.bounds);
    }
}

- (void)calcFrame {
    if (UICollectionViewScrollDirectionVertical==_collectionViewFlowLayout.scrollDirection) {
        _frame.size.height = [self getSectionContentLength];
    }
    else {
        _frame.size.width = [self getSectionContentLength];
    }
}

@end

// ----------------------------------

@interface UTACollectionViewFlowLayout () {
    NSMutableDictionary<NSNumber *, UTACollectionViewFlowLayoutSectionInfo *> *_dictSectionsInfo;
}

@end

@implementation UTACollectionViewFlowLayout

- (void)_instance {
    _shouldHeaderAndFooterIgnoreInsets = NO;
    _dictSectionsInfo = @{}.mutableCopy;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        [self _instance];
    }
    return self;
}

- (void)prepareLayout {
    if (_dictSectionsInfo.count>0) {
        [_dictSectionsInfo removeAllObjects];
    }
    
    NSInteger sections = 1;
    if ([self.collectionView.dataSource respondsToSelector:@selector(numberOfSectionsInCollectionView:)]) {
        sections = [self.collectionView.dataSource numberOfSectionsInCollectionView:self.collectionView];
    }
    
    id<UTACollectionViewFlowLayoutDelegate> delegate = (id<UTACollectionViewFlowLayoutDelegate>)self.collectionView.delegate;
    
    for (NSInteger section=0; section<sections; section++) {
        UIEdgeInsets insets = self.sectionInset;
        CGFloat interitemSpacing = self.minimumInteritemSpacing;
        CGFloat lineSpacing = self.minimumLineSpacing;
        
        // insets
        if ([delegate respondsToSelector:@selector(collectionView:layout:insetForSectionAtIndex:)]) {
            insets = [delegate collectionView:self.collectionView layout:self insetForSectionAtIndex:section];
        }
        // interitemSpacing
        if ([delegate respondsToSelector:@selector(collectionView:layout:minimumInteritemSpacingForSectionAtIndex:)]) {
            interitemSpacing = [delegate collectionView:self.collectionView layout:self minimumInteritemSpacingForSectionAtIndex:section];
        }
        // lineSpacing
        if ([delegate respondsToSelector:@selector(collectionView:layout:minimumLineSpacingForSectionAtIndex:)]) {
            lineSpacing = [delegate collectionView:self.collectionView layout:self minimumLineSpacingForSectionAtIndex:section];
        }
        
        // create section info
        UTACollectionViewFlowLayoutSectionInfo *
        sectionInfo = [UTACollectionViewFlowLayoutSectionInfo sectionInfoWithCollectionViewFlowLayout:self
                                                                                               insets:insets
                                                                              minimumInteritemSpacing:interitemSpacing
                                                                                   minimumLineSpacing:lineSpacing];
        sectionInfo.numbersOfItems = [self.collectionView.dataSource collectionView:self.collectionView numberOfItemsInSection:section];
        
        // set section origin
        if (section>0) {
            UTACollectionViewFlowLayoutSectionInfo *sectionInfoPrev = _dictSectionsInfo[@(section-1)];
            if (UICollectionViewScrollDirectionVertical==self.scrollDirection) {
                [sectionInfo setSectionOrigin:CGPointMake(0, CGRectGetMaxY(sectionInfoPrev.frame)+sectionInfoPrev.spacingBetweenNextSection)];
            }
            else {
                [sectionInfo setSectionOrigin:CGPointMake(CGRectGetMaxX(sectionInfoPrev.frame)+sectionInfoPrev.spacingBetweenNextSection, 0)];
            }
        } else {
            [sectionInfo setSectionOrigin:CGPointMake(0, 0)];
        }
        
        // save section info
        _dictSectionsInfo[@(section)] = sectionInfo;
        
        // groups in section
        if ([delegate respondsToSelector:@selector(collectionView:layout:groupsForSectionAtIndex:)]) {
            sectionInfo.groups = [delegate collectionView:self.collectionView layout:self groupsForSectionAtIndex:section];
        }
        
        // sectionSpacing
        if ([delegate respondsToSelector:@selector(collectionView:layout:spacingBetweenNextSectionOfSectionAtIndex:)] && section<(sections-1)) {
            sectionInfo.spacingBetweenNextSection = [delegate collectionView:self.collectionView layout:self spacingBetweenNextSectionOfSectionAtIndex:section];
        }
        
        // section header
        sectionInfo.headerAttributes = [self layoutAttributesForSupplementaryViewOfKind:UICollectionElementKindSectionHeader atIndexPath:[NSIndexPath indexPathForRow:0 inSection:section]];
        
        // section items
        for (NSInteger itemIndex=0; itemIndex<sectionInfo.numbersOfItems; itemIndex++) {
            [sectionInfo addItemAttributes:[self layoutAttributesForItemAtIndexPath:[NSIndexPath indexPathForRow:itemIndex inSection:section]]];
        }
        
        // section footer
        sectionInfo.footerAttributes = [self layoutAttributesForSupplementaryViewOfKind:UICollectionElementKindSectionFooter atIndexPath:[NSIndexPath indexPathForRow:0 inSection:section]];
        
        [sectionInfo calcFrame];
    }
}

- (CGSize)collectionViewContentSize {
    if (_dictSectionsInfo.count>0) {
        CGRect lastFrame = _dictSectionsInfo[@(_dictSectionsInfo.count-1)].frame;
        if (UICollectionViewScrollDirectionVertical==self.scrollDirection) {
            return CGSizeMake(self.collectionView.frame.size.width, CGRectGetMaxY(lastFrame));
        } else {
            return CGSizeMake(CGRectGetMaxX(lastFrame), self.collectionView.frame.size.height);
        }
    } else {
        return [super collectionViewContentSize];
    }
}

- (BOOL)shouldInvalidateLayoutForBoundsChange:(CGRect)newBounds {
    BOOL should = NO;
    CGRect oldBounds = self.collectionView.bounds;
    if (UICollectionViewScrollDirectionVertical==self.scrollDirection) {
        should = CGRectGetWidth(oldBounds)!=CGRectGetWidth(newBounds);
    } else {
        should = CGRectGetHeight(oldBounds)!=CGRectGetHeight(newBounds);
    }
    return should;
}

// return an array layout attributes instances for all the views in the given rect
- (nullable NSArray<__kindof UICollectionViewLayoutAttributes *> *)layoutAttributesForElementsInRect:(CGRect)rect {
    __block NSMutableArray *arrAttributes = @[].mutableCopy;
    [_dictSectionsInfo enumerateKeysAndObjectsUsingBlock:^(NSNumber * _Nonnull key, UTACollectionViewFlowLayoutSectionInfo * _Nonnull sectionInfo, BOOL * _Nonnull stop) {
        if (!CGRectIsEmpty(CGRectIntersection(sectionInfo.frame, rect))) {
            
            if (sectionInfo.headerAttributes && !CGRectIsEmpty(CGRectIntersection(sectionInfo.headerAttributes.frame, rect))) {
                [arrAttributes addObject:sectionInfo.headerAttributes];
            }
            
            for (UICollectionViewLayoutAttributes *attributes in sectionInfo.itemsAttributes) {
                if (CGRectIsEmpty(CGRectIntersection(attributes.frame, rect))) {
                    continue;
                }
                [arrAttributes addObject:attributes];
            }
            
            if (sectionInfo.footerAttributes && !CGRectIsEmpty(CGRectIntersection(sectionInfo.footerAttributes.frame, rect))) {
                [arrAttributes addObject:sectionInfo.footerAttributes];
            }
        }
    }];
    return arrAttributes;
}

- (nullable UICollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewLayoutAttributes *attributes;
    id<UTACollectionViewFlowLayoutDelegate> delegate = (id<UTACollectionViewFlowLayoutDelegate>)self.collectionView.delegate;
    if ([delegate respondsToSelector:@selector(collectionView:layout:sizeForItemAtIndexPath:)]) {
        attributes = [UICollectionViewLayoutAttributes layoutAttributesForCellWithIndexPath:indexPath];
        UTACollectionViewFlowLayoutSectionInfo *sectionInfo = _dictSectionsInfo[@(indexPath.section)];
        CGRect frame = CGRectZero;
        frame.size = [delegate collectionView:self.collectionView layout:self sizeForItemAtIndexPath:indexPath];
        frame.origin = [sectionInfo originOfWillAppendItem];
        
        attributes.frame = frame;
    }
    return attributes;
}

- (nullable UICollectionViewLayoutAttributes *)layoutAttributesForSupplementaryViewOfKind:(NSString *)elementKind atIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewLayoutAttributes *attributes;
    id<UTACollectionViewFlowLayoutDelegate> delegate = (id<UTACollectionViewFlowLayoutDelegate>)self.collectionView.delegate;
    if ([elementKind isEqualToString:UICollectionElementKindSectionHeader]) {
        if ([delegate respondsToSelector:@selector(collectionView:layout:referenceSizeForHeaderInSection:)]) {
            CGRect frame = CGRectZero;
            frame.size = [delegate collectionView:self.collectionView layout:self referenceSizeForHeaderInSection:indexPath.section];
            if (CGSizeEqualToSize(frame.size, CGSizeZero)) {
                return nil;
            }
            
            BOOL shouldHeaderAndFooterIgnoreInsets = _shouldHeaderAndFooterIgnoreInsets;
            // 头尾是否忽略填充距
            if ([delegate respondsToSelector:@selector(collectionView:layout:shouldHeaderAndFooterIgnoreInsetsOfSectionAtIndex:)]) {
                shouldHeaderAndFooterIgnoreInsets = [delegate collectionView:self.collectionView layout:self shouldHeaderAndFooterIgnoreInsetsOfSectionAtIndex:indexPath.section];
            }
            
            attributes = [UICollectionViewLayoutAttributes layoutAttributesForSupplementaryViewOfKind:elementKind withIndexPath:indexPath];
            UTACollectionViewFlowLayoutSectionInfo *sectionInfo = _dictSectionsInfo[@(indexPath.section)];
            if (UICollectionViewScrollDirectionVertical==self.scrollDirection) {
                frame.size.width = self.collectionView.frame.size.width-(shouldHeaderAndFooterIgnoreInsets?0:(sectionInfo.insets.left+sectionInfo.insets.right));
                frame.origin.y = CGRectGetMinY(sectionInfo.frame);
                frame.origin.x = shouldHeaderAndFooterIgnoreInsets?0:sectionInfo.insets.left;
            } else {
                frame.size.height = self.collectionView.frame.size.height-(shouldHeaderAndFooterIgnoreInsets?0:(sectionInfo.insets.top+sectionInfo.insets.right));
                frame.origin.x = CGRectGetMinX(sectionInfo.frame);
                frame.origin.y = shouldHeaderAndFooterIgnoreInsets?0:sectionInfo.insets.top;
            }
            attributes.frame = frame;
        }
    }
    else if ([elementKind isEqualToString:UICollectionElementKindSectionFooter]) {
        if ([delegate respondsToSelector:@selector(collectionView:layout:referenceSizeForFooterInSection:)]) {
            CGRect frame = CGRectZero;
            frame.size = [delegate collectionView:self.collectionView layout:self referenceSizeForFooterInSection:indexPath.section];
            if (CGSizeEqualToSize(frame.size, CGSizeZero)) {
                return nil;
            }
            
            BOOL shouldHeaderAndFooterIgnoreInsets = _shouldHeaderAndFooterIgnoreInsets;
            // 头尾是否忽略填充距
            if ([delegate respondsToSelector:@selector(collectionView:layout:shouldHeaderAndFooterIgnoreInsetsOfSectionAtIndex:)]) {
                shouldHeaderAndFooterIgnoreInsets = [delegate collectionView:self.collectionView layout:self shouldHeaderAndFooterIgnoreInsetsOfSectionAtIndex:indexPath.section];
            }
            
            attributes = [UICollectionViewLayoutAttributes layoutAttributesForSupplementaryViewOfKind:elementKind withIndexPath:indexPath];
            UTACollectionViewFlowLayoutSectionInfo *sectionInfo = _dictSectionsInfo[@(indexPath.section)];
            CGFloat sectionContentLength = [sectionInfo getSectionContentLength];
            if (UICollectionViewScrollDirectionVertical==self.scrollDirection) {
                frame.origin.x = shouldHeaderAndFooterIgnoreInsets?0:sectionInfo.insets.left;
                frame.origin.y = sectionContentLength+sectionInfo.frame.origin.y;
                frame.size.width = self.collectionView.frame.size.width-(shouldHeaderAndFooterIgnoreInsets?0:(sectionInfo.insets.left+sectionInfo.insets.right));
            } else {
                frame.origin.y = shouldHeaderAndFooterIgnoreInsets?0:sectionInfo.insets.top;
                frame.origin.x = sectionContentLength+sectionInfo.frame.origin.x;
                frame.size.height = self.collectionView.frame.size.height-(shouldHeaderAndFooterIgnoreInsets?0:(sectionInfo.insets.top+sectionInfo.insets.right));
            }
            attributes.frame = frame;
        }
    }
    return attributes;
}


@end
