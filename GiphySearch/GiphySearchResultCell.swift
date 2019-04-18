//
//  GiphySearchResultCell.swift
//  GiphySearch
//
//  Created by Aaron London on 4/16/19.
//  Copyright © 2019 postmechanical. All rights reserved.
//

import UIKit
import Gifu

@objc protocol GiphySearchResultCellDelegate: NSObjectProtocol {
    func didLongPress(_ cell: GiphySearchResultCell)
}

class GiphySearchResultCell: UICollectionViewCell {
    @IBOutlet var imageView: GIFImageView!
    @IBOutlet weak var delegate: GiphySearchResultCellDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        let recognizer = UILongPressGestureRecognizer()
        recognizer.addTarget(self, action: #selector(didRecognizeLongPress(_:)))
        contentView.addGestureRecognizer(recognizer)
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.prepareForReuse()
        imageView.cancelGIFDownload()
        delegate = nil
    }
    
    func configure(with gif: [String: Any]) {
        guard
            let images = gif["images"] as? [String: Any],
            let preview = images["preview_gif"] as? [String: Any],
            let urlString = preview["url"] as? String
            else { return }
        imageView.animateGIF(from: URL(string: urlString))
    }
    
    @IBAction func didRecognizeLongPress(_ recognizer: UILongPressGestureRecognizer) {
        delegate?.didLongPress(self)
    }
}
