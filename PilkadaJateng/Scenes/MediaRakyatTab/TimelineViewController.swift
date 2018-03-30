//
//  TimelineViewController.swift
//  PilkadaJateng
//
//  Created by PondokiOS on 3/27/18.
//  Copyright © 2018 PondokiOS. All rights reserved.
//

import UIKit
import XLPagerTabStrip
import Photos

class TimelineViewController: UIViewController {
    @IBOutlet weak var viewOutlets: TimelineView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        _setupCollectionView()
        _setupCreateNewPostButton()
    }
    
    private let _timelineService = TimelineService()
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        _timelineService.beginListening { (error) in
            if let error = error {
                print(error)
            }
            
            self.viewOutlets.collectionView.reloadData()
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        _timelineService.endListening()
    }
    
    
    private func _setupCollectionView() {
        let cv = viewOutlets.collectionView
        cv?.dataSource = self
        cv?.delegate = self
        
        let nib = UINib(nibName: "TimelineCollectionViewCell", bundle: nil)
        cv?.register(nib, forCellWithReuseIdentifier: "TimelineCell")
    }
    
    private func _setupCreateNewPostButton() {
        viewOutlets.newPostButton
            .addTarget(self,
                       action: .pickImage,
                       for: .touchUpInside)
    }
    
    @objc func pickImage() {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        if (UIImagePickerController.isSourceTypeAvailable(.camera)) {
            imagePicker.sourceType = .camera
        } else {
            imagePicker.sourceType = .photoLibrary
        }
        
        present(imagePicker, animated: true, completion: nil)
    }
    
    private func _sendPost() -> String? {
        return _timelineService.sendTimelinePost(senderId: Application.shared.sender!.id)
    }
    
    private func _setImageURL(_ url: String, forPhotoMessageWithKey key: String) {
        // Send to firebase
    }
    
    private func _editPost(_ image: UIImage) {
        let vc = PostEditorViewController(nibName: "PostEditorViewController", bundle: nil)
        vc.image = image
        vc.delegate = self
        present(vc, animated: true, completion: nil)
    }
}

fileprivate extension Selector {
    static let pickImage = #selector(TimelineViewController.pickImage)
}

class TimelineView: UIView {
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var newPostButton: UIButton!
}

extension TimelineViewController: IndicatorInfoProvider {
    func indicatorInfo(for pagerTabStripController: PagerTabStripViewController) -> IndicatorInfo {
        return IndicatorInfo(title: "Timeline")
    }
}

extension TimelineViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return _timelineService.timelinePosts.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "TimelineCell", for: indexPath) as! TimelineCollectionViewCell
        let post = _timelineService.timelinePosts[indexPath.row]
        cell.titleLabel.text = post.title
        cell.thumbnailImageView.image = post.image
        return cell
    }
}

extension TimelineViewController: UICollectionViewDelegate {
    
}

extension TimelineViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        picker.dismiss(animated: true, completion: nil)
        if let refUrl = info[UIImagePickerControllerReferenceURL] as? URL {
            let assets = PHAsset.fetchAssets(withALAssetURLs: [refUrl], options: nil)
            let asset = assets.firstObject
            
            if let key = _sendPost() {
                asset?.requestContentEditingInput(with: nil) { [unowned self](input, info) in
                    let imageFileURL = input?.fullSizeImageURL
                    let path = "\(UIDevice.current.name)/\(Int(Date.timeIntervalSinceReferenceDate * 1000))/\(refUrl.lastPathComponent))"
                    print("PATH  - \(path), imageFileURL - \(imageFileURL?.absoluteString)")
                    self._timelineService
                        .uploadPhoto(url: imageFileURL!) { (path, error) in
                            if let error = error {
                                print(error)
                            }
                            
                            if let path = path {
                                self._timelineService.setPhotoUrl(path, forPostWithKey: key)
                            }
                    }
                }
            }
        } else {
            let image = info[UIImagePickerControllerOriginalImage] as! UIImage
            if let key = _sendPost() {
                let imageData = UIImageJPEGRepresentation(image, 1.0)
                let path = "\(UIDevice.current.name)/\(Date()).jpg"
                
                self._timelineService
                    .uploadPhoto(with: imageData!, path: path) { (path, error) in
                        if let error = error {
                            print(error)
                        }
                        
                        if let path = path {
                            self._timelineService.setPhotoUrl(path, forPostWithKey: key)
                        }
                }
            }
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
}

extension TimelineViewController: PostEditorDelegate {
    func finishEditing(_ timelinePost: (image: UIImage, caption: String)) {
        print(timelinePost)
    }
}
