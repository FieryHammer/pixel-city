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
        registerForPreviewing(with: self, sourceView: collectionView!)
        
        DataService.instance.mapVC = self
    }

    @IBAction func centerMapBtnPressed(_ sender: Any) {
        if authorizationStatus == .authorizedAlways || authorizationStatus == .authorizedWhenInUse {
            centerMapOnUserLocation()
        }
    }
    
    func setupGestureRecognizers() {
        let doubleTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(dropPin(gestureRecognizer:)))
        doubleTapGestureRecognizer.numberOfTapsRequired = 2
        
        mapView.addGestureRecognizer(doubleTapGestureRecognizer)
        
        let swipeGestureRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe))
        swipeGestureRecognizer.direction = .down
        pullUpView.addGestureRecognizer(swipeGestureRecognizer)
    }
    
    @objc func handleSwipe() {
            animateViewDown()
    }
    
    func animateViewUp() {
        DataService.instance.cancelAllSession()
        
        pullUpViewHeightConstraint.constant = 300
        
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
        pullupViewIsUp = true
        
        addSpinner()
        addProgressLbl()
    }
    
    func animateViewDown() {
        DataService.instance.cancelAllSession()
        
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
    
    func updateProgressLbl() {
        self.progressLbl?.text = "\(DataService.instance.imageArray.count)/\(DataService.instance.imageUrlArray.count) IMAGES DOWNLOADED"
    }
    
    func removeProgressLbl() {
        if progressLbl != nil {
            progressLbl?.removeFromSuperview()
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
        DataService.instance.imageUrlArray.removeAll()
        DataService.instance.imageArray.removeAll()
        collectionView?.reloadData()
        
        let touchPoint = gestureRecognizer.location(in: mapView)
        let touchCoordinate = mapView.convert(touchPoint, toCoordinateFrom: mapView)
        let annotation = DroppablePin(coordinate: touchCoordinate, identifier: DROPPABLE_PIN_IDENTIFIER)
        
        mapView.addAnnotation(annotation)
        let coordinateRegion = MKCoordinateRegion(center: touchCoordinate, latitudinalMeters: regionRadius * 2.0, longitudinalMeters: regionRadius * 2.0)
        mapView.setRegion(coordinateRegion, animated: true)
        animateViewUp()
        
        DataService.instance.retrieveUrls(for: annotation) { (success) in
            if success {
                DataService.instance.retrieveImages(completion: { (success) in
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
        return DataService.instance.imageArray.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PHOTO_CELL_IDENTIFIER, for: indexPath) as? PhotoCell {
            let imageView = UIImageView(image: DataService.instance.imageArray[indexPath.item])
            imageView.contentMode = .scaleAspectFill
            imageView.frame = cell.contentView.frame
            imageView.layer.masksToBounds = true
            cell.addSubview(imageView)
            return cell
        }
        
        return UICollectionViewCell()
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let popVC = storyboard?.instantiateViewController(withIdentifier: "PopVC") as? PopVC else { return }
        popVC.setImage(DataService.instance.imageArray[indexPath.item])
        present(popVC, animated: true, completion: nil)
    }
}

extension MapVC: UIViewControllerPreviewingDelegate {
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        guard let indexPath = collectionView?.indexPathForItem(at: location), let cell = collectionView?.cellForItem(at: indexPath) else { return nil }
        
        guard let popVC = storyboard?.instantiateViewController(withIdentifier: "PopVC") as? PopVC else { return nil }
        
        popVC.setImage(DataService.instance.imageArray[indexPath.item])
        previewingContext.sourceRect = cell.contentView.frame
        
        return popVC
    }
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
        show(viewControllerToCommit, sender: self)
    }
}
