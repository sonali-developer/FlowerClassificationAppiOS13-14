//
//  ViewController.swift
//  FlowerClassifierAppiOS13-14
//
//  Created by Sonali Patel on 12/26/20.
//

import UIKit
import CoreML
import Vision
import Alamofire
import SwiftyJSON
import SDWebImage

class ViewController: UIViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate {

    @IBOutlet weak var flowerImageView: UIImageView!
    
    private var imagePicker = UIImagePickerController()
    
    @IBOutlet weak var flowerDescriptionLabel: UILabel!
    //Networking parameters
    
    let wikipediaURL = "https://en.wikipedia.org/w/api.php"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        imagePicker.delegate = self
        imagePicker.sourceType = .camera
        imagePicker.allowsEditing = true
    }

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        guard let userPickedImage = info[UIImagePickerController.InfoKey.editedImage] as? UIImage else {
           fatalError("Couldn't capture the image from UImagePickerController")
        }
        
        flowerImageView.image = userPickedImage
        imagePicker.dismiss(animated: true, completion: nil)
        
        guard let flowerCIImage = CIImage(image: userPickedImage) else {
            fatalError("Couldn't convert to CIImage")
        }
        
        detect(flowerImage: flowerCIImage)
        
    }
    
    func detect(flowerImage: CIImage) {
        let flowerClassifier = FlowerClassifier()
        let flowerModel = flowerClassifier.model
        guard let model = try? VNCoreMLModel(for: flowerModel) else {
            fatalError("Could not convert to VNCoreMLModel")
        }
        
        let request = VNCoreMLRequest(model: model) { (request, error) in
            guard let results = request.results as? [VNClassificationObservation] else {
                fatalError("Could not convert results from request to VNClassificationObservation")
            }
            
            print(results)
            
            if let firstResult = results.first {
                print(firstResult)
                let flowerName = firstResult.identifier.capitalized
                self.navigationItem.title = flowerName
                self.requestDetails(flowerName: flowerName)
            } else {
                print("Missed first")
            }
             
        }
        
        let handler = VNImageRequestHandler(ciImage: flowerImage)
                
        do {
            try handler.perform([request])
        } catch {
            print("Error executing the VNCoreMLRequest - \(error.localizedDescription)")
        }
    }
    
    func requestDetails(flowerName: String) {
        let parameters : [String:String] = [
          "format" : "json",
          "action" : "query",
          "prop" : "extracts|pageimages",
          "exintro" : "",
          "explaintext" : "",
          "titles" : flowerName,
          "indexpageids" : "",
          "redirects" : "1",
          "pithumbsize": "500"
        ]
        print(parameters)
        
        let wikiResult = Alamofire.request(wikipediaURL, method: .get, parameters: parameters)
        wikiResult.responseJSON { (response) in
            guard response.error == nil else {
                fatalError("Alamofire request to Wikipedia failed with below error - \(response.error!.localizedDescription)")
            }
            
            guard response.result.isSuccess else {
                fatalError("Getting result from response failed")
            }
            
            print(response.result)
            
            let flowerJSON: JSON = JSON(response.result.value!)
            let flowerPageID = flowerJSON["query"]["pageids"][0].stringValue
            let flowerDescription = flowerJSON["query"]["pages"][flowerPageID]["extract"].stringValue
            let flowerImageURL = flowerJSON["query"]["pages"][flowerPageID]["thumbnail"]["source"].stringValue
            print("****************************")
            print(flowerJSON)
            print(flowerPageID)
            print(flowerDescription)
            print(flowerImageURL)
            
            DispatchQueue.main.async {
                self.flowerDescriptionLabel.numberOfLines = 0
                self.flowerDescriptionLabel.text = flowerDescription
                self.flowerImageView.sd_setImage(with: URL(string: flowerImageURL))
            }
        }
    }
    
    @IBAction func cameraTapped(_ sender: UIBarButtonItem) {
        present(imagePicker, animated: true, completion: nil)
    }
}

