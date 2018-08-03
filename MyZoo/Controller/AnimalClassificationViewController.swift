//
//  ViewController.swift
//  MyZoo
//
//  Created by Caleb Stultz on 8/3/18.
//  Copyright © 2018 Caleb Stultz. All rights reserved.
//

import UIKit
import CoreML
import Vision

class AnimalClassificationViewController: UIViewController {

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var classificationLbl: UILabel!
    @IBOutlet weak var cameraBtn: UIBarButtonItem!
    
    lazy var classificationRequest: VNCoreMLRequest = {
        do {
            let model = try VNCoreMLModel(for: AnimalClassifier().model)
            
            let request = VNCoreMLRequest(model: model, completionHandler: { [weak self] request, error in
                self?.processClassifications(for: request, error: error)
            })
            request.imageCropAndScaleOption = .centerCrop
            return request
        } catch {
            fatalError("Failed to load Vision ML model: \(error)")
        }
    }()
    
    func updateClassifications(for image: UIImage) {
        classificationLbl.text = "Classifying..."
        
        guard let orientation = CGImagePropertyOrientation(rawValue: UInt32(image.imageOrientation.rawValue)), let ciImage = CIImage(image: image) else {
            displayError()
            return
        }
        
        DispatchQueue.global().async {
            let handler = VNImageRequestHandler(ciImage: ciImage, orientation: orientation)
            do {
                try handler.perform([self.classificationRequest])
            } catch {
                print("Failed to perform classification.\n\(error.localizedDescription)")
            }
        }
    }
    
    func processClassifications(for request: VNRequest, error: Error?) {
        DispatchQueue.main.async {
            guard let classifications = request.results as? [VNClassificationObservation] else {
                self.classificationLbl.text = "Unable to classify image.\n\(error?.localizedDescription ?? "Error")"
                return
            }
            
            if classifications.isEmpty {
                self.classificationLbl.text = "Nothing recognized."
            } else {
                let topClassifications = classifications.prefix(2)
                let descriptions = topClassifications.map { classification in
                    return String(format: "%.2f", classification.confidence * 100) + "% – " + classification.identifier
                }
                self.classificationLbl.text = "Classification:\n" + descriptions.joined(separator: "\n")
            }
        }
    }
    
    func displayError() {
        classificationLbl.text = "Something went wrong...\n Please try again."
    }
    
    @IBAction func cameraBtnWasPressed(_ sender: Any) {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            presentPhotoPicker(sourceType: .photoLibrary)
            return
        }
        
        let photoSourcePicker = UIAlertController()
        let takePhoto = UIAlertAction(title: "Take Photo", style: .default) { [unowned self] _ in
            self.presentPhotoPicker(sourceType: .camera)
        }
        let choosePhoto = UIAlertAction(title: "Choose Photo", style: .default) { [unowned self] _ in
            self.presentPhotoPicker(sourceType: .photoLibrary)
        }
        
        photoSourcePicker.addAction(takePhoto)
        photoSourcePicker.addAction(choosePhoto)
        photoSourcePicker.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        present(photoSourcePicker, animated: true)
    }
    
    func presentPhotoPicker(sourceType: UIImagePickerController.SourceType) {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = sourceType
        present(picker, animated: true)
    }
}

extension AnimalClassificationViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true)
        
        guard let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage else { fatalError("No image returned") }
        imageView.image = image
        updateClassifications(for: image)
    }
}
