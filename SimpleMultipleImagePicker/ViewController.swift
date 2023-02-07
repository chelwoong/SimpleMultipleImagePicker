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
        Task {
            async let status = PHPhotoLibrary.authorizationStatus()
            switch await status {
            case .authorized:
                DispatchQueue.main.async {
                    self.showPicker()
                }
            case .notDetermined:
                PHPhotoLibrary.requestAuthorization { status in
                    if status == .authorized {
                        DispatchQueue.main.async {
                            self.showPicker()
                        }
                    } else {
                        // TODO: 권한 없음
                        return
                    }
                }
            default:
                await print(status)
            }
        }
    }
    
    private func checkPhotoLibraryAuthorization() async {
        
    }
    
    private func showPicker() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        guard let picker = storyboard.instantiateViewController(withIdentifier: "PickerViewController") as? PickerViewController else { return }
        picker.modalPresentationStyle = .fullScreen
        picker.delegate = self
        
        self.present(picker, animated: true)
    }
}

extension ViewController: PickerViewControllerDelegate {
    
    func pickerViewController(_ picker: PickerViewController, didFinishPickingWithImages selectedImages: [UIImage]) {
        print(selectedImages)
        picker.dismiss(animated: true)
    }
}
