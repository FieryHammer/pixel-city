//
//  DroppablePin.swift
//  Pixel-City
//
//  Created by Horvath, Mate on 2018. 11. 03..
//  Copyright © 2018. Finastra. All rights reserved.
//

import Foundation
import UIKit
import MapKit

class DroppablePin: NSObject, MKAnnotation {
    var coordinate: CLLocationCoordinate2D
    var identifier: String
    
    init(coordinate: CLLocationCoordinate2D, identifier: String) {
        self.coordinate = coordinate
        self.identifier = identifier
        
        super.init()
    }
    
}
