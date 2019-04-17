//
//  GIFImageView+Extensions.swift
//  GiphySearch
//
//  Created by Aaron London on 4/16/19.
//  Copyright © 2019 postmechanical. All rights reserved.
//

import Gifu

extension GIFImageView {
    struct AssociatedObjectKeys {
        static var url: UInt8 = 0
    }

    private(set) var url: URL? {
        get {
            return objc_getAssociatedObject(self, &AssociatedObjectKeys.url) as? URL
        }
        set {
            objc_setAssociatedObject(self, &AssociatedObjectKeys.url, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    func animateGIF(from url: URL?) {
        self.url = url
        if let key = url as NSURL?, let data = ImageDownloader.imageCache.object(forKey: key) as Data? {
            prepareForAnimation(withGIFData: data)
            return
        }
        guard let url = url else { return }
        ImageDownloader.downloadImage(from: url) { [weak self] (data) in
            guard let data = data else { return }
            self?.animate(withGIFData: data)
        }
    }
    
    func cancelGIFDownload() {
        guard
            let url = url,
            let task = ImageDownloader.requests[url]
            else { return }
        task.cancel()
        self.url = nil
        ImageDownloader.requests[url] = nil
    }
}
