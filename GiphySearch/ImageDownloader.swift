//
//  ImageDownloader.swift
//  GiphySearch
//
//  Created by Aaron London on 4/16/19.
//  Copyright © 2019 postmechanical. All rights reserved.
//

import UIKit

class ImageDownloader {
    static let imageCache = NSCache<NSURL, NSData>()
    static var requests = [URL: URLSessionDataTask]()
    
    static func image(for url: URL, completion: @escaping ((_ data: Data?) -> Void)) {
        if let key = url as NSURL?, let data = ImageDownloader.imageCache.object(forKey: key) as Data? {
            completion(data)
            return
        }
        ImageDownloader.downloadImage(from: url, completion: completion)
    }
    
    static func downloadImage(from url: URL, completion: ((_ data: Data?) -> Void)? = nil) {
        let request = URLRequest(url: url)
        let task = URLSession.shared.dataTask(with: request) { (data, _, error) in
            guard let data = data as NSData? else {
                DispatchQueue.main.async {
                    completion?(nil)
                }
                return
            }
            ImageDownloader.imageCache.setObject(data, forKey: url as NSURL)
            DispatchQueue.main.async {
                completion?(data as Data)
            }
        }
        task.resume()
        ImageDownloader.requests[url] = task
    }
}
