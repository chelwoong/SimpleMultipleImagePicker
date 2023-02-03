//
//  ViewController.swift
//  SimpleMultipleImagePicker
//
//  Copyright (c) 2023 woongs All rights reserved.
//


import UIKit
import Photos

class ViewController: UIViewController, UIImagePickerControllerDelegate {
    
    private var albums: [PHAssetCollection] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
    }
    
    @IBAction
    private func didPickImagesButtonTap(_ sender: UIButton) {
        PHPhotoLibrary.requestAuthorization(for: .readWrite) { [weak self] state in
            guard let self = self else { return }
            switch state {
            case .authorized:
                self.albums = self.loadAlbumsList()
            default:
                print(state)
            }
        }
    }
    
    private func loadAlbumsList() -> [PHAssetCollection] {
        var result: [PHAssetCollection] = [PHAssetCollection]()
        
        let options = PHFetchOptions()
        let cameraRoll = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: options)
        let favoriteList = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .smartAlbumUserLibrary, options: nil)
        let albumList = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .albumRegular, options: nil)
        
        [cameraRoll, favoriteList, albumList].forEach {
            $0.enumerateObjects { collection, _, _ in
                if !result.contains(collection) {
                    result.append(collection)
                }
            }
        }
        
        return result
    }
}

