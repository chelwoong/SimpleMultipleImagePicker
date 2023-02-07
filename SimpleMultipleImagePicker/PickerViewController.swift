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
        Task {
            self.albumImages = await self.loadImages()
            DispatchQueue.main.async {
                self.collectionView.reloadData()
            }
        }
    }
    
    private func setupCollectionView() {
        self.collectionView.dataSource = self
        self.collectionView.delegate = self
    }
    
    private func loadImages() async -> [UIImage] {
        var result = [UIImage]()
        let albums = await self.loadAlbumsList()
        let assets = await self.loadAssets(from: albums)
        
        for asset in assets {
            if let image = await self.loadImage(asset: asset, size: PHImageManagerMaximumSize) {
                result.append(image)
            }
        }
        
        return result
    }
    
    private func loadAlbumsList() async -> [PHAssetCollection] {
        var result: [PHAssetCollection] = [PHAssetCollection]()
        
        async let smartAlbums = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .albumRegular, options: nil)
        async let photoStreamAlbums = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: nil)
        async let userLibrary = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .smartAlbumUserLibrary, options: nil)
        
        await [smartAlbums, photoStreamAlbums, userLibrary].forEach {
            $0.enumerateObjects { collection, _, _ in
                if collection.estimatedAssetCount > 0, !result.contains(collection) {
                    result.append(collection)
                }
            }
        }
        
        return result
    }
    
    private func loadAssets(from albums: [PHAssetCollection]) async -> [PHAsset] {
        var result = [PHAsset]()
        let fetchOptions = PHFetchOptions()
        for album in albums {
            async let asset = PHAsset.fetchAssets(in: album, options: fetchOptions)
            await asset.enumerateObjects { asset, _, _ in
                result.append(asset)
            }
        }
        return result
    }
    
    private func loadImage(asset: PHAsset, size: CGSize, resizeMode: PHImageRequestOptionsResizeMode = .exact, deliveryMode: PHImageRequestOptionsDeliveryMode? = nil) async -> UIImage? {
        return await withCheckedContinuation { continuation in
            let option = PHImageRequestOptions()
            option.isSynchronous = true
            PHCachingImageManager.default().requestImage(for: asset, targetSize: PHImageManagerMaximumSize, contentMode: .aspectFit, options: option) { image, info in
                if let image = image {
                    continuation.resume(returning: image)
                }
            }
        }
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
