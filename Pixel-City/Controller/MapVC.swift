//
//  MapVC.swift
//  Pixel-City
//
//  Created by Horvath, Mate on 2018. 10. 31..
//  Copyright © 2018. Finastra. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation
import Alamofire
import AlamofireImage

class MapVC: UIViewController, UIGestureRecognizerDelegate {

    @IBOutlet weak var mapView: MKMapView!
    var locationManager = CLLocationManager()
    let authorizationStatus = CLLocationManager.authorizationStatus()
    let regionRadius: Double = 1000
    
    var pullupViewIsUp = false
    @IBOutlet weak var pullUpViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var pullUpView: UIView!
    
    var spinner: UIActivityIndicatorView?
    var progressLbl: UILabel?
    
    var flowLayout = UICollectionViewFlowLayout()
    var collectionView: UICollectionView?
    
    var imageUrlArray = [String]()
    var imageArray = [UIImage]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView.delegate = self
        locationManager.delegate = self
        configureLocationServices()
        setupGestureRecognizers()
        
        collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: flowLayout)
        collectionView?.register(PhotoCell.self, forCellWithReuseIdentifier: PHOTO_CELL_IDENTIFIER)
        collectionView?.delegate = self
        collectionView?.dataSource = self
        pullUpView.addSubview(collectionView!)
        collectionView?.backgroundColor = UIColor.white
    }

    @IBAction func centerMapBtnPressed(_ sender: Any) {
        if authorizationStatus == .authorizedAlways || authorizationStatus == .authorizedWhenInUse {
            centerMapOnUserLocation()
        }
    }
    
    func setupGestureRecognizers() {
        let doubleTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(dropPin(gestureRecognizer:)))
        doubleTapGestureRecognizer.numberOfTapsRequired = 2
        doubleTapGestureRecognizer.delegate = self
        
        mapView.addGestureRecognizer(doubleTapGestureRecognizer)
        
        let swipeGestureRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe))
        swipeGestureRecognizer.direction = .down
        pullUpView.addGestureRecognizer(swipeGestureRecognizer)
    }
    
    @objc func handleSwipe() {
            animateViewDown()
    }
    
    func animateViewUp() {
        cancelAllSession()
        
        pullUpViewHeightConstraint.constant = 300
        
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
        pullupViewIsUp = true
        
        addSpinner()
        addProgressLbl()
    }
    
    func animateViewDown() {
        cancelAllSession()
        
        pullUpViewHeightConstraint.constant = 0
        
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
        pullupViewIsUp = false
    }
    
    func addSpinner() {
        removeSpinner()
        
        spinner = UIActivityIndicatorView()
        spinner?.center = CGPoint(x: (pullUpView.frame.width / 2) - ((spinner?.frame.width)! / 2), y: pullUpView.frame.height / 2)
        spinner?.style = .whiteLarge
        spinner?.color = UIColor.darkGray
        spinner?.startAnimating()
        
        collectionView?.addSubview(spinner!)
    }
    
    func removeSpinner() {
        if spinner != nil {
            spinner?.removeFromSuperview()
        }
    }
    
    func addProgressLbl() {
        removeProgressLbl()
        
        let labelWidth: CGFloat = 240
        
        progressLbl = UILabel()
        progressLbl?.frame = CGRect(x: (pullUpView.frame.width / 2) - (labelWidth / 2), y: 175, width: labelWidth, height: 40)
        progressLbl?.font = UIFont(name: "Avenir Next", size: 18)
        progressLbl?.textColor = UIColor.darkGray
        progressLbl?.textAlignment = .center
        
        collectionView?.addSubview(progressLbl!)
    }
    
    func removeProgressLbl() {
        if progressLbl != nil {
            progressLbl?.removeFromSuperview()
        }
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
                self.progressLbl?.text = "\(self.imageArray.count)/\(self.imageUrlArray.count) IMAGES DOWNLOADED"
                
                
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

extension MapVC: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation {
            return nil
        }
        
        let pinAnnotation = MKPinAnnotationView(annotation: annotation, reuseIdentifier: DROPPABLE_PIN_IDENTIFIER)
        pinAnnotation.pinTintColor = #colorLiteral(red: 0.9771530032, green: 0.7062081099, blue: 0.1748393774, alpha: 1)
        pinAnnotation.animatesDrop = true
        
        return pinAnnotation
    }
    
    func centerMapOnUserLocation() {
        guard let coordinate = locationManager.location?.coordinate else { return }
        
        let coordinateRegion = MKCoordinateRegion(center: coordinate, latitudinalMeters: regionRadius * 2.0, longitudinalMeters: regionRadius * 2.0)
        
        mapView.setRegion(coordinateRegion, animated: true)
    }
    
    @objc func dropPin(gestureRecognizer: UITapGestureRecognizer) {
        removePins()
        imageUrlArray.removeAll()
        imageArray.removeAll()
        collectionView?.reloadData()
        
        let touchPoint = gestureRecognizer.location(in: mapView)
        let touchCoordinate = mapView.convert(touchPoint, toCoordinateFrom: mapView)
        let annotation = DroppablePin(coordinate: touchCoordinate, identifier: DROPPABLE_PIN_IDENTIFIER)
        
        mapView.addAnnotation(annotation)
        let coordinateRegion = MKCoordinateRegion(center: touchCoordinate, latitudinalMeters: regionRadius * 2.0, longitudinalMeters: regionRadius * 2.0)
        mapView.setRegion(coordinateRegion, animated: true)
        animateViewUp()
        
        retrieveUrls(for: annotation) { (success) in
            if success {
                self.retrieveImages(completion: { (success) in
                    if success {
                        self.removeSpinner()
                        self.removeProgressLbl()
                        self.collectionView?.reloadData()
                    }
                })
            }
        }
    }
    
    func removePins() {
        mapView.removeAnnotations(mapView.annotations)
    }
}

extension MapVC: CLLocationManagerDelegate {
    func configureLocationServices() {
        if authorizationStatus == .notDetermined {
            locationManager.requestAlwaysAuthorization()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        centerMapOnUserLocation()
    }
}

extension MapVC: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return imageArray.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PHOTO_CELL_IDENTIFIER, for: indexPath) as? PhotoCell {
            let imageView = UIImageView(image: imageArray[indexPath.item])
            cell.addSubview(imageView)
            return cell
        }
        
        return UICollectionViewCell()
    }
}
