//
//  MosaicCollectionViewFlowLayout.swift
//  GiphySearch
//
//  Created by Aaron London on 4/17/19.
//  Copyright © 2019 postmechanical. All rights reserved.
//

import UIKit

@objc protocol MosaicCollectionViewFlowLayoutDelegate: NSObjectProtocol {
    func collectionView(_ collectionView: UICollectionView, sizeForItemAt indexPath: IndexPath) -> CGSize
}

class MosaicCollectionViewFlowLayout: UICollectionViewFlowLayout {
    fileprivate var numberOfColumns = 3
    fileprivate var layoutAttributes = [UICollectionViewLayoutAttributes]()
    fileprivate var contentHeight: CGFloat = 0
    @IBOutlet weak var delegate: MosaicCollectionViewFlowLayoutDelegate?

    override var collectionViewContentSize: CGSize {
        guard let collectionView = collectionView else { return CGSize.zero }
        return CGSize(width: collectionView.bounds.width, height: contentHeight)
    }
    
    override func prepare() {
        super.prepare()
        guard let collectionView = collectionView else { return }
        layoutAttributes.removeAll()
        let columnWidth = collectionView.bounds.width / CGFloat(numberOfColumns)
        var xOffsets = [CGFloat]()
        var yOffsets = [CGFloat](repeating: 0, count: numberOfColumns)
        for column in 0..<numberOfColumns {
            xOffsets.append(CGFloat(column) * columnWidth)
        }
        var column = 0
        for item in 0..<collectionView.numberOfItems(inSection: 0) {
            let indexPath = IndexPath(item: item, section: 0)
            let size = delegate?.collectionView(collectionView, sizeForItemAt: indexPath) ?? CGSize.zero
            let attrs = UICollectionViewLayoutAttributes(forCellWith: indexPath)
            let height = size.height * (columnWidth / size.width)
            attrs.frame = CGRect(x: xOffsets[column], y: yOffsets[column], width: columnWidth, height: height)
            layoutAttributes.append(attrs)
            contentHeight = max(contentHeight, attrs.frame.maxY)
            yOffsets[column] = yOffsets[column] + height
            column = column < (numberOfColumns - 1) ? (column + 1) : 0
        }
    }
    
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        var visibleLayoutAttributes = [UICollectionViewLayoutAttributes]()
        for attrs in layoutAttributes {
            if attrs.frame.intersects(rect) {
                visibleLayoutAttributes.append(attrs)
            }
        }
        return visibleLayoutAttributes
    }
    
    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        return layoutAttributes[indexPath.item]
    }
}
