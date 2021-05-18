//
//  ViewController.swift
//  FlowerClassification
//
//  Created by Walid Rafei on 9/23/20.
//

import UIKit
import Vision
import CoreML
import Alamofire
import SwiftyJSON
import SDWebImage

class ViewController: UIViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate {

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var labelDescription: UILabel!
    
    let wikipediaURL = "https://en.wikipedia.org/w/api.php"
    let pickerController = UIImagePickerController()
    override func viewDidLoad() {
        super.viewDidLoad()
        
        pickerController.delegate = self
        pickerController.sourceType = .camera
        pickerController.allowsEditing = true
        // Do any additional setup after loading the view.
    }

    @IBAction func cameraTapped(_ sender: UIBarButtonItem) {
        present(pickerController, animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let userPickedImage = info[UIImagePickerController.InfoKey.editedImage] as? UIImage {
            
            guard let ciImage = CIImage(image: userPickedImage) else {
                fatalError("could not convert image to CiImage")
            }
            
            detect(image: ciImage)
        }
        
        pickerController.dismiss(animated: true, completion: nil)
    }
    
    func detect(image: CIImage) {

        guard let model = try? VNCoreMLModel(for: FlowerClassifier().model) else {
            fatalError("loading CoreML Model Failed.")
        }
        
        let request = VNCoreMLRequest(model: model) { (request, error) in
            guard let results = request.results as? [VNClassificationObservation] else {
                fatalError("Model Failed to process image")
            }
            if let firstResult = results.first {
                self.navigationItem.title = firstResult.identifier.capitalized
                self.requestInfo(flowerName: firstResult.identifier)
            }
        }
        
        let handler = VNImageRequestHandler(ciImage: image)
        do {
            try handler.perform([request])
        } catch {
            print(error.localizedDescription)
        }
    }
    
    func requestInfo(flowerName: String) {
        
        let parameters :[String:String] = [
            "format" : "json",
            "action" : "query",
            "prop" : "extracts|pageimages",
            "exintro" : "",
            "explaintext" : "",
            "titles" : flowerName,
            "indexpageids" : "",
            "redirects" : "1",
            "pithumbsize" : "500"
        ]
        Alamofire.request(wikipediaURL, method: .get, parameters: parameters).responseJSON { (response) in
            if response.result.isSuccess {
                print("Got the wikipedia info")
                print(response)
                
                let flowerJSON : JSON = JSON(response.result.value!)
                let pageID = flowerJSON["query"]["pageids"][0].stringValue
                let flowerDescription = flowerJSON["query"]["pages"][pageID]["extract"].stringValue
                let flowerImageURL = flowerJSON["query"]["pages"][pageID]["thumbnail"]["source"].stringValue
                self.imageView.sd_setImage(with: URL(string: flowerImageURL))
                self.labelDescription.text = flowerDescription
                print(flowerDescription)
            }
        }
    }
    
    
}

