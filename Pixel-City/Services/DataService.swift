//
//  DataService.swift
//  Pixel-City
//
//  Created by Horvath, Mate on 2018. 11. 06..
//  Copyright © 2018. Finastra. All rights reserved.
//

import Foundation
import Alamofire
import AlamofireImage

class DataService {
    static let instance = DataService()
    
    var mapVC: MapVC!
    
    var imageUrlArray = [String]()
    var imageArray = [UIImage]()
    
    func flickrURL(apiKey: String, annotation: DroppablePin, numberOfPhotos: Int) -> String {
        let url = "https://api.flickr.com/services/rest?method=flickr.photos.search&api_key=\(apiKey)&lat=\(annotation.coordinate.latitude)&lon=\(annotation.coordinate.longitude)&radius=1&radius_units=mi&per_page=\(numberOfPhotos)&format=json&nojsoncallback=1"
        print(url)
        
        return url
    }
    
    func retrieveUrls(for annotation: DroppablePin, completion: @escaping (_ status: Bool) -> ()) {
        Alamofire.request(flickrURL(apiKey: FLICKR_API_KEY, annotation: annotation, numberOfPhotos: 40)).responseJSON { (response) in
            if response.error != nil {
                completion(false)
                return
            }
            
            guard let json = response.result.value as? Dictionary<String, AnyObject> else { completion(false); return }
            let photosDict = json["photos"] as? Dictionary<String, AnyObject>
            guard let photoDictArray = photosDict?["photo"] as? [Dictionary<String, AnyObject>] else { completion(false); return }
            
            for photo in photoDictArray {
                let postUrl = "https://farm\(photo["farm"]!).staticflickr.com/\(photo["server"]!)/\(photo["id"]!)_\(photo["secret"]!)_h_d.jpg"
                self.imageUrlArray.append(postUrl)
            }
            
            completion(true)
        }
    }
    
    func retrieveImages(completion: @escaping (_ status: Bool) -> ()) {
        for url in imageUrlArray {
            Alamofire.request(url).responseImage { (response) in
                guard let image = response.value else { completion(false); return }
                self.imageArray.append(image)
                self.mapVC.updateProgressLbl()
                
                // TODO: Make this async and out of this block
                if self.imageArray.count == self.imageUrlArray.count {
                    completion(true)
                }
            }
        }
    }
    
    func cancelAllSession() {
        Alamofire.SessionManager.default.session.getTasksWithCompletionHandler { (sessionDataTask, _, sessionDownloadTask) in
            sessionDataTask.forEach({ $0.cancel() })
            sessionDownloadTask.forEach({ $0.cancel() })
        }
    }
}
