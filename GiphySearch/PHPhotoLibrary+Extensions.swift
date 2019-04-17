//
//  PHPhotoLibrary+Extensions.swift
//  GiphySearch
//
//  Created by Aaron London on 4/17/19.
//  Copyright © 2019 postmechanical. All rights reserved.
//

import Photos

extension PHPhotoLibrary {
    func saveGIF(_ data: Data) {
        PHPhotoLibrary.shared().performChanges({
            PHAssetCreationRequest.forAsset().addResource(with: .photo, data: data, options: nil)
        }, completionHandler: { (success, error) in
            guard let error = error else { return }
            print(error as Any)
        })
    }
}
