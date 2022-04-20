//
//  ViewController.swift
//  WhatFlower
//
//  Created by Ashwini Rao on 03/12/21.
//

import UIKit
import CoreML
import Vision
import Alamofire
import SwiftyJSON
import SDWebImage

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var imageView: UIImageView!
    
    let wikipideaURL = "https://en.wikipidea.org/w/api.php"
 
    let imagePicker = UIImagePickerController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        imagePicker.delegate = self
        imagePicker.sourceType = .photoLibrary
        imagePicker.allowsEditing = false
    }
    
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            imageView.image = image
            guard let ciimage = CIImage(image: image)  else {
                fatalError("Could not convert to CIImage")
            }
        detect(flowerImage: ciimage)
        }
        imagePicker.dismiss(animated: true, completion: nil)
    }
    
    func detect(flowerImage: CIImage) {
        
        guard let model = try? VNCoreMLModel(for: Flowers().model) else {
            fatalError("Loading CoreML model failed")
        }
        
        let request = VNCoreMLRequest(model: model) { request, error in
            guard let results = request.results as? [VNClassificationObservation] else
            {
                fatalError("Model failed to process image")
            }
            
            if let firstResult = results.first {
                self.navigationItem.title = firstResult.identifier.capitalized
                self.requestInfo(flowerName: firstResult.identifier)
            }
        }
        
        let handler = VNImageRequestHandler(ciImage: flowerImage)
        
        do {
        try handler.perform([request])
        }
        catch {
            print(error)
        }
    }
    
    func requestInfo(flowerName: String) {
        
        let parameters: [String : String] = ["format" : "json",
                                             "action" : "query",
                                             "prop" : "extracts|pageimages", //flowerdescription | image in URL
                                             "exintro" : "",
                                             "explaintext" : "",
                                             "titles" : flowerName,
                                             "indexpageids" : "",
                                             "redirects" : "1",
                                             "pithumbsize" : "500" //imagesize
        ]
        
        Alamofire.request(wikipideaURL, method: .get, parameters: parameters).responseJSON { response in
            if response.result.isSuccess {
                print("Got Wikipidea response")
                print(response)
                
                let flowerJSON : JSON = JSON(response.result.value!)
                let pageID = flowerJSON["query"]["pageids"][0].stringValue
                let flowerDescription = flowerJSON["query"]["pages"][pageID]["extract"].stringValue
                let flowerImageURL = flowerJSON["query"]["pages"][pageID]["thumbnail"]["source"].stringValue
                
                self.imageView.sd_setImage(with: URL(string: flowerImageURL))
                self.descriptionLabel.text = flowerDescription
                
            }
        }
        
        
    }

    @IBAction func cameraClicked(_ sender: UIBarButtonItem) {
        present(imagePicker, animated: true, completion: nil)
    }
    
}

