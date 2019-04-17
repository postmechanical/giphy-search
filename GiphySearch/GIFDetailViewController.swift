//
//  GIFDetailViewController.swift
//  GiphySearch
//
//  Created by Aaron London on 4/17/19.
//  Copyright © 2019 postmechanical. All rights reserved.
//

import CoreServices.UTType
import Gifu
import Photos
import UIKit

class GIFDetailViewController: UIViewController {
    
    @IBOutlet var imageView: GIFImageView!
    var url: URL?
    
    fileprivate var data: Data?

    override func viewDidLoad() {
        super.viewDidLoad()
        setUpGIF()
        setUpDragInteraction()
    }
    
    override var previewActionItems: [UIPreviewActionItem] {
        let copy = UIPreviewAction(title: "Copy", style: .default) { (_, _) in
            guard let data = self.data else { return }
            UIPasteboard.general.setData(data, forPasteboardType: kUTTypeGIF as String)
        }
        let save = UIPreviewAction(title: "Save", style: .default) { (_, _) in
            guard let data = self.data else { return }
            PHPhotoLibrary.shared().saveGIF(data)
        }
        return [copy, save]
    }
    
    @IBAction func share() {
        guard let data = data else { return }
        let activityController = UIActivityViewController(activityItems: [data], applicationActivities: nil)
        present(activityController, animated: true, completion: nil)
    }
    
    fileprivate func setUpGIF() {
        guard let url = url as NSURL? else { return }
        if let data = ImageDownloader.imageCache.object(forKey: url) as Data? {
            self.data = data
            imageView.animate(withGIFData: data)
            return
        }
        ImageDownloader.downloadImage(from: url as URL) { [weak self] (data) in
            guard let data = data else { return }
            self?.data = data
            self?.imageView.animate(withGIFData: data)
        }
    }
    
    fileprivate func setUpDragInteraction() {
        let dragInteraction = UIDragInteraction(delegate: self)
        imageView.addInteraction(dragInteraction)
    }
    
}

extension GIFDetailViewController: UIDragInteractionDelegate {
    func dragInteraction(_ interaction: UIDragInteraction, itemsForBeginning session: UIDragSession) -> [UIDragItem] {
        guard let data = data else { return [] }
        let provider = NSItemProvider(item: data as NSData, typeIdentifier: kUTTypeGIF as String)
        let item = UIDragItem(itemProvider: provider)
        return [item]
    }
}
