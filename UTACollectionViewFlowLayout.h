//
//  UTACollectionViewFlowLayout.h
//  UTALib
//
//  Created by David on 16/5/21.
//  Copyright © 2016年 UTA. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UTACollectionViewFlowLayout : UICollectionViewFlowLayout

/**
 *  Header and Footer 是否忽略Insets，默认：NO
 *  YES：忽略insets，header 和 footer 的高度或宽度等UICollectionView的高度或宽度
 */
@property (nonatomic, assign) BOOL shouldHeaderAndFooterIgnoreInsets;

@end

@protocol UTACollectionViewFlowLayoutDelegate <UICollectionViewDelegateFlowLayout>

@optional

/**
 *  section中的分组数量
 *  为了实现瀑布流，如果不实现，默认
 *
 *  @param collectionView       collectionView description
 *  @param collectionViewLayout collectionViewLayout description
 *  @param section              section description
 *
 *  @return return value description
 */
- (NSInteger)collectionView:(nonnull UICollectionView *)collectionView layout:(nonnull UICollectionViewLayout *)collectionViewLayout groupsForSectionAtIndex:(NSInteger)section;

/**
 *  Header and Footer 是否忽略Insets，默认：NO
 *
 *  @param collectionView       collectionView description
 *  @param collectionViewLayout collectionViewLayout description
 *
 *  @return BOOL
 */
- (BOOL)collectionView:(nonnull UICollectionView *)collectionView layout:(nonnull UICollectionViewLayout *)collectionViewLayout shouldHeaderAndFooterIgnoreInsetsOfSectionAtIndex:(NSInteger)section;

/*!
 *  指定section和下一个section的间距
 *
 *  @param collectionView       collectionView description
 *  @param collectionViewLayout collectionViewLayout description
 *  @param section              section description
 *
 *  @return return value description
 */
- (CGFloat)collectionView:(nonnull UICollectionView *)collectionView layout:(nonnull UICollectionViewLayout *)collectionViewLayout spacingBetweenNextSectionOfSectionAtIndex:(NSInteger)section;

@end
