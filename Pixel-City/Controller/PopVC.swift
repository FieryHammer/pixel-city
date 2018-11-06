//
//  PopVC.swift
//  Pixel-City
//
//  Created by Horvath, Mate on 2018. 11. 06..
//  Copyright © 2018. Finastra. All rights reserved.
//

import UIKit

class PopVC: UIViewController {

    @IBOutlet weak var popImageView: UIImageView!
    
    var passedImage: UIImage!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        popImageView.image = passedImage
        
        setupGestureRecognizers()
    }
    
    func setImage(_ image: UIImage) {
        passedImage = image
    }
    
    func setupGestureRecognizers() {
        let doubleTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(doubleTapHandler))
        doubleTapGestureRecognizer.numberOfTapsRequired = 2
        view.addGestureRecognizer(doubleTapGestureRecognizer)
    }
    
    @objc func doubleTapHandler() {
        dismiss(animated: true, completion: nil)
    }
}
