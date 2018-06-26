//
//  EditPhotoViewController.swift
//  UnderWarrantyv0.2
//
//  Created by Jeff Chimney on 2016-12-14.
//  Copyright © 2016 Jeff Chimney. All rights reserved.
//

import UIKit
import AVFoundation
import CoreData
import CloudKit

class EditPhotoViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var saveButton: UIBarButtonItem!
    @IBOutlet weak var navBar: UINavigationItem!
    @IBOutlet weak var captureButton: UIButton!
    @IBOutlet weak var libraryButton: UIButton!
    @IBOutlet weak var cameraAccessLabel: UILabel!
    @IBOutlet weak var openSettingsButton: UIButton!
    var indexTapped: Int!
    var record: Record!
    var imageID = ""
    
    var imageDataToSave: Data!
    let imagePicker = UIImagePickerController()
    var imagePicked = false
    
    //camera variables
    var session: AVCaptureSession?
    var stillImageOutput: AVCaptureStillImageOutput?
    var videoPreviewLayer: AVCaptureVideoPreviewLayer?
    
    let generator = UIImpactFeedbackGenerator(style: .medium)
    
    weak var editImageDelegate: EditImageDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        imagePicker.delegate = self
        navigationController?.setToolbarHidden(true, animated: true)
        saveButton.isEnabled = false
        
        captureButton.layer.cornerRadius = 25
        generator.prepare()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        if AVCaptureDevice.authorizationStatus(for: AVMediaType.video) ==  AVAuthorizationStatus.authorized
        {
            // Already Authorized
            openSettingsButton.isHidden = true
            cameraAccessLabel.isHidden = true
            imageView.isHidden = false
            setUpCamera()
        }
        else
        {
            AVCaptureDevice.requestAccess(for: AVMediaType.video, completionHandler: { (granted :Bool) -> Void in
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
    
    func setUpCamera() {
        if !imagePicked {
            session = AVCaptureSession()
            session!.sessionPreset = AVCaptureSession.Preset.photo
            let backCamera = AVCaptureDevice.default(for: AVMediaType.video)
            
            var error: NSError?
            var input: AVCaptureDeviceInput!
            do {
                input = try AVCaptureDeviceInput(device: backCamera!)
            } catch let error1 as NSError {
                error = error1
                input = nil
                print(error!.localizedDescription)
            }
            
            if error == nil && session!.canAddInput(input) {
                session!.addInput(input)
                
                stillImageOutput = AVCaptureStillImageOutput()
                stillImageOutput?.outputSettings = [AVVideoCodecKey: AVVideoCodecJPEG]
                
                if session!.canAddOutput(stillImageOutput!) {
                    session!.addOutput(stillImageOutput!)
                    videoPreviewLayer = AVCaptureVideoPreviewLayer(session: session!)
                    videoPreviewLayer!.videoGravity = AVLayerVideoGravity.resizeAspectFill
                    videoPreviewLayer!.connection?.videoOrientation = AVCaptureVideoOrientation.portrait
                    imageView.layer.addSublayer(videoPreviewLayer!)
                    session!.startRunning()
                }
            }
            //videoPreviewLayer!.frame = imageView.bounds
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if AVCaptureDevice.authorizationStatus(for: AVMediaType.video) ==  AVAuthorizationStatus.authorized
        {
            videoPreviewLayer!.frame = imageView.bounds
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func openCameraButton(sender: AnyObject) {
        generator.impactOccurred()
        if let videoConnection = stillImageOutput!.connection(with: AVMediaType.video) {
            stillImageOutput?.captureStillImageAsynchronously(from: videoConnection, completionHandler: { (sampleBuffer, error) -> Void in
                if sampleBuffer != nil {
                    let imageData = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(sampleBuffer!)
                    self.imageDataToSave = imageData
                    let dataProvider = CGDataProvider(data: imageData! as CFData)
                    let cgImageRef = CGImage(jpegDataProviderSource: dataProvider!, decode: nil, shouldInterpolate: true, intent: CGColorRenderingIntent.defaultIntent)
                    let image = UIImage(cgImage: cgImageRef!, scale: 1.0, orientation: UIImageOrientation.right)
                    self.session?.stopRunning()
                    self.imageView.layer.sublayers?.removeAll()
                    self.imageView.contentMode = .scaleAspectFill
                    self.imageView.image = image
                    self.saveButton.isEnabled = true
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
            imageDataToSave = UIImageJPEGRepresentation(pickedImage, 1.0)
            imagePicked = true
            saveButton.isEnabled = true
        }
        
        dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func saveButtonPressed(_ sender: Any) {
        imageID = UUID().uuidString
        saveImageLocally()
        editImageDelegate?.addNewImage(newImage: UIImage(data: imageDataToSave)!, newID: imageID)
        performSegue(withIdentifier: "unwindToEdit", sender: self)
    }
    
    func saveImageToCloudKit() {
        let defaults = UserDefaults.standard
        let username = defaults.string(forKey: "username")
        if username != nil {
            let privateDatabase:CKDatabase = CKContainer.default().privateCloudDatabase
            let zoneID = CKRecordZoneID(zoneName: "Records", ownerName: CKCurrentUserDefaultName)
            let predicate = NSPredicate(format: "recordID = %@", CKRecordID(recordName: record.recordID!, zoneID: zoneID))
            let query = CKQuery(recordType: "Records", predicate: predicate)
            var recordRecord = CKRecord(recordType: "Records")
            
            privateDatabase.perform(query, inZoneWith: zoneID, completionHandler: { (results, error) in
                if error != nil {
                    print("Error retrieving from cloudkit")
                } else {
                    if (results?.count)! > 0 {
                        recordRecord = (results?[0])!
                        
                        let ckImage = CKRecord(recordType: "Images")
                        let reference = CKReference(recordID: recordRecord.recordID, action: CKReferenceAction.deleteSelf)
                        
                        let filename = ProcessInfo.processInfo.globallyUniqueString + ".png"
                        let url = NSURL.fileURL(withPath: NSTemporaryDirectory()).appendingPathComponent(filename)
                        
                        do {
                            try self.imageDataToSave.write(to: url, options: NSData.WritingOptions.atomicWrite)
                            
                            let imageAsset = CKAsset(fileURL: url)
                            
                            ckImage.setObject(reference, forKey: "associatedRecord")
                            ckImage.setObject(imageAsset as CKRecordValue?, forKey: "image")
                            ckImage.setObject(self.imageID as CKRecordValue?, forKey: "id")
                            ckImage.setObject(0 as CKRecordValue?, forKey: "recentlyDeleted")
                            
                            privateDatabase.save(ckImage, completionHandler: { (record, error) in
                                if error != nil {
                                    print(error!)
                                    return
                                }
                                self.saveImageLocally()
                            })
                        }  catch {
                            print("Problems writing to URL")
                        }
                    }
                }
            })
        }
    }
    
    func saveImageLocally() {
        // if not connected to cloudkit, get a new UUID
        guard let appDelegate =
            UIApplication.shared.delegate as? AppDelegate else {
                return
        }
        
        let managedContext = appDelegate.persistentContainer.viewContext
        
        let imageEntity = NSEntityDescription.entity(forEntityName: "Image", in: managedContext)!
        let image = NSManagedObject(entity: imageEntity, insertInto: managedContext) as! Image
        
        image.image = imageDataToSave as NSData? as! Data
        image.record = record!
        image.id = imageID
        
        do {
            try managedContext.save()
            
            // check what the current connection is.  If wifi, refresh.  If data, and sync by data is enabled, refresh.
//            let conn = UserDefaultsHelper.currentConnection()
//            if (conn == "wifi" || (conn == "data" && UserDefaultsHelper.canSyncUsingData())) {
//                CloudKitHelper.saveImageToCloud(imageRecord: image, associatedRecord: record)
//            } else {
//                // queue up the record to sync when you have a good connection
//                UserDefaultsHelper.addRecordToQueue(recordID: record.recordID!)
//            }
            print("Saved image to CoreData")
        } catch {
            print("Problems saving note to CoreData")
        }
    }
    
    @IBAction func openSettings(_ sender: Any) {
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
        if (segue.identifier == "unwindToEdit") {
            if let nextViewController = segue.destination as? DetailsTableViewController {
                if navBar.title == "Item" {
                    if (imageView.image != nil) { // set item image
                        _ = nextViewController.tableView.cellForRow(at: IndexPath(row: 0, section: 0)) as! ImagesTableViewCell
                        //cell.itemImageView.image = imageView.image
                    } else {
                        print("Was nil")
                    }
                } else if navBar.title == "Receipt" {
                    if (imageView.image != nil) { // set receipt image
                        _ = nextViewController.tableView.cellForRow(at: IndexPath(row: 0, section: 0)) as! ImagesTableViewCell
                        //cell.receiptImageView.image = imageView.image
                    } else {
                        print("Was nil")
                    }
                } else {
                    if (imageView.image != nil) { // set receipt image
                        _ = nextViewController.tableView.cellForRow(at: IndexPath(row: 0, section: 0)) as! ImagesTableViewCell
                        //cell.receiptImageView.image = imageView.image
                    } else {
                        print("Was nil")
                    }
                }
            }
        }
    }
}

