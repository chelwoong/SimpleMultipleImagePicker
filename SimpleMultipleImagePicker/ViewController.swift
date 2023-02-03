//
//  ViewController.swift
//  SimpleMultipleImagePicker
//
//  Copyright (c) 2023 woongs All rights reserved.
//


import UIKit
import Photos

class ViewController: UIViewController, UIImagePickerControllerDelegate {
    
    private var albumImages: [UIImage] = []
    private var albums: [PHAssetCollection] = []
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.collectionView.dataSource = self
        self.collectionView.delegate = self
    }
    
    @IBAction
    private func didPickImagesButtonTap(_ sender: UIButton) {
        PHPhotoLibrary.requestAuthorization(for: .readWrite) { [weak self] state in
            guard let self = self else { return }
            switch state {
            case .authorized:
                let albums = self.loadAlbumsList()
                self.albums = albums
                
                var images: [UIImage] = []
                albums.forEach { album in
                    let assets = PHAsset.fetchAssets(in: album, options: nil)
                    assets.enumerateObjects { asset, _, _ in
                        PHCachingImageManager.default().requestImage(for: asset, targetSize: PHImageManagerMaximumSize, contentMode: .aspectFit, options: nil) { image, info in
                            if let image = image {
                                images.append(image)
                            }
                        }
                    }
                }
                self.albumImages = images
                DispatchQueue.main.async {
                    self.collectionView.reloadData()
                }
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

extension ViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.albumImages.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "AlbumImageCollectionViewCell", for: indexPath) as? AlbumImageCollectionViewCell else {
            return UICollectionViewCell()
        }
        
        let image = self.albumImages[indexPath.item]
        
        cell.configure(image: image)
        return cell
    }
}

class AlbumImageCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var albumImageView: UIImageView!
    
    func configure(image: UIImage) {
        self.albumImageView.image = image
    }
}
