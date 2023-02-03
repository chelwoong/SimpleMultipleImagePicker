//
//  ViewController.swift
//  SimpleMultipleImagePicker
//
//  Copyright (c) 2023 woongs All rights reserved.
//


import UIKit
import Photos

class ViewController: UIViewController, UIImagePickerControllerDelegate {
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction
    private func didPickImagesButtonTap(_ sender: UIButton) {
        PHPhotoLibrary.requestAuthorization(for: .readWrite) { [weak self] state in
            guard let self = self else { return }
            switch state {
            case .authorized:
                self.showPicker()
            default:
                print(state)
            }
        }
    }
    
    private func showPicker() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        guard let picker = storyboard.instantiateViewController(withIdentifier: "PickerViewController") as? PickerViewController else { return }
        picker.delegate = self
        self.present(picker, animated: true)
    }
}

extension ViewController: PickerViewControllerDelegate {
    
    func pickerViewController(_ picker: PickerViewController, didFinishPickingWithImages selectedImages: [UIImage]) {
        
    }
}
