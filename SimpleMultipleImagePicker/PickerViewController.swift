import UIKit
import Photos

protocol PickerViewControllerDelegate {
    
    func pickerViewController(_ picker: PickerViewController, didFinishPickingWithImages: [UIImage])
}

class PickerViewController: UIViewController {
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    private var albumImages: [UIImage] = []
    private var albums: [PHAssetCollection] = []
    
    private var selectedIndexPath = Set<IndexPath>()
    
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
    
    @IBAction
    private func didCloseButtonTap(_ sender: UIButton) {
        self.dismiss(animated: true)
    }
    
    @IBAction
    private func didCompleteButtonTap(_ sender: UIButton) {
        let selectedImages = self.selectedIndexPath.compactMap { indexPath -> UIImage? in
            guard 0..<self.albumImages.count ~= indexPath.item else { return nil }
            return self.albumImages[indexPath.item]
        }
        self.delegate?.pickerViewController(self, didFinishPickingWithImages: selectedImages)
    }
}

// MARK: - UICollectionViewDataSource, UICollectionViewDelegateFlowLayout
extension PickerViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    private var numberOfColumns: CGFloat { 3 }
    private var interitemSpacing: CGFloat { 10 }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.albumImages.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "AlbumImageCollectionViewCell", for: indexPath) as? AlbumImageCollectionViewCell else {
            return UICollectionViewCell()
        }
        
        let image = self.albumImages[indexPath.item]
        
        cell.configure(image: image) { [weak self] in
            guard let self = self else { return }
            let isSelected = self.selectedIndexPath.contains(indexPath)
            if isSelected {
                cell.updateToDeselected()
                self.selectedIndexPath.remove(indexPath)
            } else {
                cell.updateToSelected()
                self.selectedIndexPath.insert(indexPath)
            }
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let totalSpacing: CGFloat = self.interitemSpacing * (self.numberOfColumns - 1)
        let width = floor((collectionView.bounds.width - totalSpacing) / self.numberOfColumns)
        let height = width
        return CGSize(width: width, height: height)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return self.interitemSpacing
    }
}

// MARK: - AlbumImageCollectionViewCell
class AlbumImageCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var albumImageView: UIImageView!
    @IBOutlet weak var selectButton: UIButton!
    
    var didSelect: (() -> Void)?
    
    override func prepareForReuse() {
        super.prepareForReuse()
        self.albumImageView.image = nil
        self.updateToDeselected()
    }
    
    func configure(image: UIImage, didSelect: @escaping (() -> Void)) {
        self.albumImageView.contentMode = .scaleAspectFill
        self.albumImageView.image = image
        
        self.didSelect = didSelect
    }
    
    @IBAction
    private func didSelectButtonTap(_ sender: UIButton) {
        self.didSelect?()
    }
    
    func updateToSelected() {
        self.selectButton.isSelected = true
        self.selectButton.backgroundColor = .blue
    }
    
    func updateToDeselected() {
        self.selectButton.isSelected = false
        self.selectButton.backgroundColor = .clear
    }
}
