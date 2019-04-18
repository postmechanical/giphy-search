//
//  GiphySearchViewController.swift
//  GiphySearch
//
//  Created by Aaron London on 4/14/19.
//  Copyright © 2019 postmechanical. All rights reserved.
//

import CoreServices.UTType
import Gifu
import Photos
import UIKit

class GiphySearchViewController: UIViewController {
    
    @IBOutlet var searchBar: UISearchBar!
    @IBOutlet var collectionView: UICollectionView!
    
    let giphyClient = GiphyClient()
    var gifs = [[String: Any]]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.rightBarButtonItem?.isEnabled = false
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        searchBar.becomeFirstResponder()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard
            segue.identifier == "showGIF",
            let detailViewController = segue.destination as? GIFDetailViewController,
            let cell = sender as? GiphySearchResultCell,
            let indexPath = collectionView.indexPath(for: cell),
            let original = originalGIF(at: indexPath.item),
            let urlString = original["url"]
            else { return }
        detailViewController.url = URL(string: urlString)
    }
    
    @IBAction func search() {
        guard let text = searchBar.text, text.count > 0 else { return }
        search(for: text, from: 0)
    }
    
    fileprivate func search(for term: String, from offset: UInt = 0) {
        giphyClient.cancel()
        giphyClient.search(for: term, offset: offset) { (response, error) in
            guard error == nil else {
                print(error as Any)
                return
            }
            guard let data = response["data"] as? [[String: Any]] else { return }
            if offset == 0 {
                self.gifs = data
            } else {
                self.gifs.append(contentsOf: data)
            }
            self.collectionView.reloadData()
            if offset == 0 {
                self.collectionView.contentOffset = CGPoint.zero
            }
        }
    }

    fileprivate func previewGIF(at index: Int) -> [String: String]? {
        guard index < gifs.count, let images = gifs[index]["images"] as? [String: Any] else { return nil }
        if let preview = images["preview_gif"] as? [String: String], preview.count == 4 {
            return preview
        }
        if let downsized = images["downsized"] as? [String: String], downsized.count == 4 {
            return downsized
        }
        return nil
    }

    fileprivate func originalGIF(at index: Int) -> [String: String]? {
        guard index < gifs.count, let images = gifs[index]["images"] as? [String: Any] else { return nil }
        return images["original"] as? [String: String]
    }
}

extension GiphySearchViewController: UISearchBarDelegate {

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        navigationItem.rightBarButtonItem?.isEnabled = (searchBar.text?.count ?? 0 > 0)
        search()
    }

}

extension GiphySearchViewController: UICollectionViewDataSource {

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return gifs.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard indexPath.item < gifs.count else {
            assertionFailure("Index path out of bounds: \(indexPath)")
            return UICollectionViewCell()
        }
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: GiphySearchResultCell.self), for: indexPath) as? GiphySearchResultCell else {
            assertionFailure("Could not dequeue cell with identifier: \(String(describing: GiphySearchResultCell.self))")
            return UICollectionViewCell()
        }
        cell.configure(with: gifs[indexPath.item])
        cell.delegate = self
        return cell
    }

}

extension GiphySearchViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if indexPath.item == gifs.count - 10, let text = searchBar.text {
            search(for: text, from: UInt(gifs.count - 1))
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        guard let cell = cell as? GiphySearchResultCell else { return }
        cell.imageView.stopAnimatingGIF()
    }
}

extension GiphySearchViewController: MosaicCollectionViewFlowLayoutDelegate {
    func collectionView(_ collectionView: UICollectionView, sizeForItemAt indexPath: IndexPath) -> CGSize {
        guard indexPath.item < gifs.count else {
            assertionFailure("Index path out of bounds: \(indexPath)")
            return CGSize.zero
        }
        guard let preview = previewGIF(at: indexPath.item), let width = Int(preview["width"] ?? ""), let height = Int(preview["height"] ?? "") else {
            assertionFailure("Could not get preview at: \(indexPath.item)")
            return CGSize.zero
        }
        return CGSize(width: min(CGFloat(width), collectionView.bounds.width), height: min(CGFloat(height), collectionView.bounds.height))
    }
}

extension GiphySearchViewController: UITableViewDataSourcePrefetching {
    
    func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {
        indexPaths.forEach { indexPath in
            guard
                indexPath.item < gifs.count,
                let images = gifs[indexPath.item]["images"] as? [String: Any],
                let preview = images["preview_gif"] as? [String: Any],
                let urlString = preview["url"] as? String,
                let url = URL(string: urlString) as NSURL?,
                ImageDownloader.imageCache.object(forKey: url) == nil
                else { return }
            ImageDownloader.downloadImage(from: url as URL)
        }
    }

}

extension GiphySearchViewController: GiphySearchResultCellDelegate {
    func didLongPress(_ cell: GiphySearchResultCell) {
        guard
            let indexPath = collectionView.indexPath(for: cell),
            let original = originalGIF(at: indexPath.item),
            let urlString = original["url"],
            let url = URL(string: urlString)
            else { return }
        let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        actionSheet.popoverPresentationController?.sourceView = cell.contentView
        actionSheet.popoverPresentationController?.sourceRect = cell.contentView.bounds.insetBy(dx: cell.contentView.bounds.width / 2.0, dy: cell.contentView.bounds.height / 2.0)
        let copy = UIAlertAction(title: "Copy", style: .default) { (_) in
            ImageDownloader.image(for: url, completion: { (data) in
                guard let data = data else { return }
                UIPasteboard.general.setData(data, forPasteboardType: kUTTypeGIF as String)
            })
        }
        actionSheet.addAction(copy)
        let save = UIAlertAction(title: "Save", style: .default) { (_) in
            ImageDownloader.image(for: url, completion: { (data) in
                guard let data = data else { return }
                PHPhotoLibrary.shared().saveGIF(data)
            })
        }
        actionSheet.addAction(save)
        let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        actionSheet.addAction(cancel)
        present(actionSheet, animated: true, completion: nil)
    }
}

extension GiphySearchViewController: UICollectionViewDragDelegate {
    func collectionView(_ collectionView: UICollectionView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        guard
            let preview = previewGIF(at: indexPath.item),
            let urlString = preview["url"],
            let url = URL(string: urlString),
            let data = ImageDownloader.imageCache.object(forKey: url as NSURL)
            else { return [] }
        let provider = NSItemProvider(item: data, typeIdentifier: kUTTypeGIF as String)
        let item = UIDragItem(itemProvider: provider)
        return [item]
    }
}

extension GiphySearchViewController: UIScrollViewDelegate {
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        searchBar.resignFirstResponder()
    }
}
