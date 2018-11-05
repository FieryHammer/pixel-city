//
//  Constants.swift
//  Pixel-City
//
//  Created by Horvath, Mate on 2018. 11. 05..
//  Copyright © 2018. Finastra. All rights reserved.
//

import Foundation

let FLICKR_API_KEY = "148a62d63a18f8ab16ca3ae0d10e1f5c"
let DROPPABLE_PIN_IDENTIFIER = "droppablePin"
let PHOTO_CELL_IDENTIFIER = "photoCell"

func flickrURL(apiKey: String, annotation: DroppablePin, numberOfPhotos: Int) -> String {
    let url = "https://api.flickr.com/services/rest?method=flickr.photos.search&api_key=\(apiKey)&lat=\(annotation.coordinate.latitude)&lon=\(annotation.coordinate.longitude)&radius=1&radius_units=mi&per_page=\(numberOfPhotos)&format=json&nojsoncallback=1"
    print(url)
    
    return url
}
