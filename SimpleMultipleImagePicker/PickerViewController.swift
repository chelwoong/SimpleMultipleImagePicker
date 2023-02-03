import UIKit
import Photos

protocol PickerViewControllerDelegate {
    
    func pickerViewController(_ picker: PickerViewController, didFinishPickingWithImages: [UIImage])
}

class PickerViewController: UIViewController {
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    private var albumImages: [UIImage] = []
    private var albums: [PHAssetCollection] = []
    
    var delegate: PickerViewControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupCollectionView()
        self.albumImages = self.loadImages()
        self.collectionView.reloadData()
    }
    
    private func setupCollectionView() {
        self.collectionView.dataSource = self
        self.collectionView.delegate = self
    }
    
    private func loadImages() -> [UIImage] {
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
        return images
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

// MARK: - UICollectionViewDataSource, UICollectionViewDelegateFlowLayout
extension PickerViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
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

// MARK: - AlbumImageCollectionViewCell
class AlbumImageCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var albumImageView: UIImageView!
    
    func configure(image: UIImage) {
        self.albumImageView.image = image
    }
}
