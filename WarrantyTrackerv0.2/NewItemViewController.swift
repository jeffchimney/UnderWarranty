//
//  NewItemViewController.swift
//  UnderWarrantyv0.2
//
//  Created by Jeff Chimney on 2016-11-01.
//  Copyright © 2016 Jeff Chimney. All rights reserved.
//

import UIKit
import AVFoundation

class NewItemViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UICollectionViewDelegate, UICollectionViewDataSource {

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var nextButton: UIBarButtonItem!
    @IBOutlet weak var navBar: UINavigationItem!
    @IBOutlet weak var captureButton: UIButton!
    @IBOutlet weak var libraryButton: UIButton!
    @IBOutlet weak var cameraAccessLabel: UILabel!
    @IBOutlet weak var openSettingsButton: UIButton!
    @IBOutlet weak var imagesCollectionView: UICollectionView!
    @IBOutlet weak var collectionViewTrailingConstraint: NSLayoutConstraint!
    @IBOutlet weak var showHidePhotosView: UIView!
    
    var imageDataToSave: [Data?] = []
    let imagePicker = UIImagePickerController()
    var imagePicked = false
    var photoDrawerIsShowing = false
    var selectedPhotoIndexPath: IndexPath!
    
    // variables that have been passed forward
    var titleString: String! = nil
    var descriptionString: String! = nil
    //
    
    // Collection View Vars
    let rows = 1
    let columns = 5
    var longPressGesture: UILongPressGestureRecognizer!
    var pressedViewCenter = CGPoint()
    //

    let generator = UIImpactFeedbackGenerator(style: .medium)
    //camera variables
    var session: AVCaptureSession?
    var stillImageOutput: AVCaptureStillImageOutput?
    var videoPreviewLayer: AVCaptureVideoPreviewLayer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        imagePicker.delegate = self
        navBar.title = "Item"
        navigationController?.isToolbarHidden = true
        
        imagesCollectionView.delegate = self
        imagesCollectionView.dataSource = self
        //imagesCollectionView.transform = CGAffineTransform(scaleX: -1, y: 1)
        imagesCollectionView.semanticContentAttribute = UISemanticContentAttribute.forceRightToLeft
        
        
        let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(NewItemViewController.swiped(gesture:)))
        swipeLeft.direction = .left
        imagesCollectionView.addGestureRecognizer(swipeLeft)
        let tapped = UITapGestureRecognizer(target: self, action: #selector(NewItemViewController.tapped(gesture:)))
        showHidePhotosView.addGestureRecognizer(tapped)
        longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongGesture(gesture:)))
        imagesCollectionView.addGestureRecognizer(longPressGesture)
        
        let rectShape = CAShapeLayer()
        rectShape.bounds = showHidePhotosView.frame
        rectShape.position = showHidePhotosView.center
        rectShape.path = UIBezierPath(roundedRect: showHidePhotosView.bounds, byRoundingCorners: [.topRight], cornerRadii: CGSize(width: 10, height: 10)).cgPath
        
        showHidePhotosView.layer.mask = rectShape
        
        captureButton.layer.cornerRadius = 25
        generator.prepare()
    }
    
    override func viewWillAppear(_ animated: Bool) {        
        if AVCaptureDevice.authorizationStatus(forMediaType: AVMediaTypeVideo) ==  AVAuthorizationStatus.authorized
        {
            // Already Authorized
            openSettingsButton.isHidden = true
            cameraAccessLabel.isHidden = true
            imageView.isHidden = false
            setUpCamera()
        }
        else
        {
            AVCaptureDevice.requestAccess(forMediaType: AVMediaTypeVideo, completionHandler: { (granted :Bool) -> Void in
                if granted == true
                {
                    // User granted
                    DispatchQueue.main.async {
                        UserDefaultsHelper.setCameraPermissions(to: true)
                        self.imageView.isHidden = false
                        self.openSettingsButton.isHidden = true
                        self.cameraAccessLabel.isHidden = true
                        self.setUpCamera()
                        self.captureButton.isEnabled = true
                    }
                }
                else
                {
                    // User Rejected
                    DispatchQueue.main.async {
                        UserDefaultsHelper.setCameraPermissions(to: false)
                        self.imageView.isHidden = true
                        self.cameraAccessLabel.isHidden = false
                        self.openSettingsButton.isHidden = false
                        self.captureButton.isEnabled = false;
                    }
                }
            });
        }
    }
    
    func swiped(gesture: UISwipeGestureRecognizer)
    {
        switch gesture.direction {
        case UISwipeGestureRecognizerDirection.left:
            let newConstraint = NSLayoutConstraint(item: imagesCollectionView, attribute: .trailing, relatedBy: .lessThanOrEqual, toItem: self.view, attribute: .leading, multiplier: 1.0, constant: CGFloat(0))
            
            // 2
            UIView.animate(withDuration: 0.5, delay: 0.0, options: .curveEaseOut , animations: {
                self.view.removeConstraint(self.collectionViewTrailingConstraint)
                self.view.addConstraint(newConstraint)
                self.view.layoutIfNeeded()
            }, completion: nil)
            
            // 3
            collectionViewTrailingConstraint = newConstraint
            photoDrawerIsShowing = false
            print("Swiped Left")
        default:
            print("other swipe")
        }
    }
    
    func handleLongGesture(gesture: UILongPressGestureRecognizer)
    {
        switch(gesture.state) {
        case UIGestureRecognizerState.began:
            selectedPhotoIndexPath = imagesCollectionView.indexPathForItem(at: gesture.location(in: imagesCollectionView))
            let pressedCell = imagesCollectionView.cellForItem(at: selectedPhotoIndexPath)
            pressedViewCenter = (pressedCell?.center)!
            imagesCollectionView.beginInteractiveMovementForItem(at: selectedPhotoIndexPath)
        case UIGestureRecognizerState.changed:
            imagesCollectionView.updateInteractiveMovementTargetPosition(gesture.location(in: gesture.view!))
        case UIGestureRecognizerState.ended:
            if !imagesCollectionView.point(inside: gesture.location(in: imagesCollectionView), with: nil) {
                imagesCollectionView.performBatchUpdates({ () -> Void in
                    self.imageDataToSave.remove(at: self.selectedPhotoIndexPath.row)
                    self.imagesCollectionView.deleteItems(at: [self.selectedPhotoIndexPath])
                    self.imagesCollectionView.reloadData()
                }, completion: nil)
                self.imagesCollectionView.endInteractiveMovement()
            } else {
                imagesCollectionView.endInteractiveMovement()
            }
        default:
            imagesCollectionView.cancelInteractiveMovement()
        }
    }
    func tapped(gesture: UITapGestureRecognizer) {
        if photoDrawerIsShowing {
            let newConstraint = NSLayoutConstraint(item: imagesCollectionView, attribute: .trailing, relatedBy: .lessThanOrEqual, toItem: self.view, attribute: .leading, multiplier: 1.0, constant: CGFloat(0))
            
            // 2
            UIView.animate(withDuration: 0.5, delay: 0.0, options: .curveEaseOut , animations: {
                self.view.removeConstraint(self.collectionViewTrailingConstraint)
                self.view.addConstraint(newConstraint)
                self.view.layoutIfNeeded()
            }, completion: nil)
            
            // 3
            collectionViewTrailingConstraint = newConstraint
            photoDrawerIsShowing = false
        } else {
            let newConstraint = NSLayoutConstraint(item: imagesCollectionView, attribute: .trailing, relatedBy: .lessThanOrEqual, toItem: self.view, attribute: .leading, multiplier: 1.0, constant: CGFloat(75 * imageDataToSave.count))
            print(imageDataToSave.count)
            UIView.animate(withDuration: 0.5, delay: 0.0, options: .curveEaseOut , animations: {
                self.view.removeConstraint(self.collectionViewTrailingConstraint)
                self.view.addConstraint(newConstraint)
                self.view.layoutIfNeeded()
            }, completion: nil)
            
            collectionViewTrailingConstraint = newConstraint
            photoDrawerIsShowing = true
        }
    }
    
    func setUpCamera() {
        //if !imagePicked {
        session = AVCaptureSession()
        session!.sessionPreset = AVCaptureSessionPresetPhoto
        let backCamera = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeVideo)
        
        var error: NSError?
        var input: AVCaptureDeviceInput!
        do {
            input = try AVCaptureDeviceInput(device: backCamera)
        } catch let error1 as NSError {
            error = error1
            input = nil
            print(error!.localizedDescription)
        }
        
        if error == nil && session!.canAddInput(input) {
            session!.addInput(input)
            
            stillImageOutput = AVCaptureStillImageOutput()
            stillImageOutput?.outputSettings = [AVVideoCodecKey: AVVideoCodecJPEG]
            
            if session!.canAddOutput(stillImageOutput) {
                session!.addOutput(stillImageOutput)
                videoPreviewLayer = AVCaptureVideoPreviewLayer(session: session)
                videoPreviewLayer!.videoGravity = AVLayerVideoGravityResizeAspectFill
                videoPreviewLayer!.connection?.videoOrientation = AVCaptureVideoOrientation.portrait
                imageView.layer.addSublayer(videoPreviewLayer!)
                session!.startRunning()
            }
        }
        videoPreviewLayer!.frame = imageView.bounds
        //}
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func openCameraButton(sender: AnyObject) {
        generator.impactOccurred()
        if let videoConnection = stillImageOutput!.connection(withMediaType: AVMediaTypeVideo) {
            stillImageOutput?.captureStillImageAsynchronously(from: videoConnection, completionHandler: { (sampleBuffer, error) -> Void in
                if sampleBuffer != nil {
                    let imageData = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(sampleBuffer)
                    self.imageDataToSave.append(imageData)
                    self.imagesCollectionView.reloadData()
                    let dataProvider = CGDataProvider(data: imageData! as CFData)
                    let cgImageRef = CGImage(jpegDataProviderSource: dataProvider!, decode: nil, shouldInterpolate: true, intent: CGColorRenderingIntent.defaultIntent)
                    let image = UIImage(cgImage: cgImageRef!, scale: 1.0, orientation: UIImageOrientation.right)
                    self.session?.stopRunning()
                    self.imageView.layer.sublayers?.removeAll()
                    self.imageView.contentMode = .scaleAspectFill
                    self.imageView.image = image
                    
                    let when = DispatchTime.now() + 1 // change 1 to desired number of seconds
                    DispatchQueue.main.asyncAfter(deadline: when) {
                        self.setUpCamera()
                        self.imageView.image = nil
                    }
                }
            })
        }
    }
    
    @IBAction func openPhotoLibraryButton(sender: AnyObject) {
        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.photoLibrary) {
            imagePicker.sourceType = UIImagePickerControllerSourceType.photoLibrary;
            imagePicker.allowsEditing = false
            self.present(imagePicker, animated: true, completion: nil)
        }
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let pickedImage = info[UIImagePickerControllerOriginalImage] as? UIImage {
            imageView.contentMode = .scaleAspectFit
            session?.stopRunning()
            imageView.layer.sublayers?.removeAll()
            imageView.contentMode = .scaleAspectFill
            imageView.image = pickedImage
            imageDataToSave.append(UIImageJPEGRepresentation(pickedImage, 1.0))
            imagesCollectionView.reloadData()
            imagePicked = true
            self.setUpCamera()
        }
        
        dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func nextButtonPressed(_ sender: Any) {
    }
    
    @IBAction func cameraSwitchPressed(_ sender: Any) {
        guard let settingsUrl = URL(string: UIApplicationOpenSettingsURLString) else {
            return
        }
        
        if UIApplication.shared.canOpenURL(settingsUrl) {
            UIApplication.shared.open(settingsUrl, completionHandler: { (success) in
                print("Settings opened: \(success)") // Prints true
            })
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == "toDates") {
            if let nextViewController = segue.destination as? WarrantyBeginsEndsViewController {
                nextViewController.itemImageData = imageDataToSave.reversed()
                nextViewController.titleString = titleString
                nextViewController.descriptionString = descriptionString
            }
        }
    }
    
    // MARK: Collection View Delegate Methods
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let newConstraint = NSLayoutConstraint(item: imagesCollectionView, attribute: .right, relatedBy: .lessThanOrEqual, toItem: self.view, attribute: .left, multiplier: 1.0, constant: CGFloat(75 * imageDataToSave.count))
        print(imageDataToSave.count)
        UIView.animate(withDuration: 0.5, delay: 0, options: .curveEaseOut , animations: {
            self.view.layoutIfNeeded()
            self.view.removeConstraint(self.collectionViewTrailingConstraint)
            self.view.addConstraint(newConstraint)
            self.view.layoutIfNeeded()
        }, completion: nil)
        
        collectionViewTrailingConstraint = newConstraint
        photoDrawerIsShowing = true
        
        if imageDataToSave.count == columns {
            captureButton.isEnabled = false
            libraryButton.isEnabled = false
        } else {
            captureButton.isEnabled = true
            libraryButton.isEnabled = true
        }
        return imageDataToSave.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "photoCell", for: indexPath as IndexPath) as! PhotoCollectionViewCell
        cell.imageView.image = UIImage(data: imageDataToSave[indexPath.row]!)
        //cell.transform = CGAffineTransform(scaleX: -1, y: 1)
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, moveItemAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        // move your data order
        let imageToMove = imageDataToSave[sourceIndexPath.row]
        imageDataToSave.remove(at: sourceIndexPath.row)
        imageDataToSave.insert(imageToMove, at: destinationIndexPath.row)
    }
}

