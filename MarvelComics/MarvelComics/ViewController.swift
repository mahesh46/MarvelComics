//
//  ViewController.swift
//  MarvelComics
//
//  Created by Administrator on 04/03/2016.
//  Copyright © 2016 mahesh lad. All rights reserved.
//

import UIKit
import SwiftyDropbox
import CryptoSwift
import Alamofire

import CoreData
import MobileCoreServices
import Photos

class ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UIImagePickerControllerDelegate , UINavigationControllerDelegate, UIPickerViewDelegate {

    @IBOutlet weak var tableView: UITableView!
    var ComicUrlArray : [String] = []
    
    var pickerData =  []
    var imagePicker = UIImagePickerController()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
     
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "showComics:",name:"showComics", object: nil)
        
        //register cell from xib
        tableView.registerNib(UINib(nibName: "ComicTableViewCell", bundle: nil), forCellReuseIdentifier: "Cell")
        
       listDropBoxFiles()
       
    
    }
    override func     viewDidAppear(animated: Bool) {
        ComicUrlArray  = []
      //  self.findComic()
    }
   
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func linkButtonPressed(sender: AnyObject) {
        if (Dropbox.authorizedClient == nil) {
            Dropbox.authorizeFromController(self)
        } else {
            print("User is already authorized!")
        }
    }

    func getTimestamp()->String {
        let now = NSDate()
        let formatter = NSDateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
        formatter.timeZone = NSTimeZone(forSecondsFromGMT: 0)
        return  (formatter.stringFromDate(now))
       
    }
    
    func getComicUrl(publicKey : String , hash : String , ts: String)->String {
         return   "http://gateway.marvel.com/v1/public/comics?apikey=\(publicKey)&hash=\(hash)&ts=\(ts)"
    }
    
    
    
    
   // MARK: - TableView
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // Return the number of sections.
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        // Return the number of rows in the section.
      //return 0
        return ComicUrlArray.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath) as! ComicTableViewCell
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0))
            {
        
               let url = NSURL(string: self.ComicUrlArray[indexPath.row])
      
               if  let data = NSData(contentsOfURL: url!)
                  {
            
                   dispatch_async(dispatch_get_main_queue())
                        {
            
                            cell.comicImageView.image = UIImage(data: data)
        
                             cell.comicImageView.contentMode = UIViewContentMode.ScaleAspectFill
                             cell.comicImageView.clipsToBounds = true
                        }
  
                  }
           }
           return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath)
    {
        //   _ = tableView.cellForRowAtIndexPath(indexPath)
        /*
        if cell!.selected == true
        {
        cell!.accessoryType = UITableViewCellAccessoryType.Checkmark
        }
        else
        {
        cell!.accessoryType = UITableViewCellAccessoryType.None
        }
        
        */
    }

    // MARK: - CoreData

    
    
     func findComic() {
       
        let managedContext = (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext
        
        let entityDescription =
        NSEntityDescription.entityForName("ComicBook",
            inManagedObjectContext: managedContext)
        
        
        
        let request = NSFetchRequest()
        request.entity = entityDescription
        
       // let pred = NSPredicate(format: "(name = %@)", name.text!)
     //   request.predicate = pred
        
        var error: NSError?
        
        do {
            let  results = try managedContext.executeFetchRequest(request)
            // success ...
            
            if results.count > 0 {
                for result in results {
                    print(result)
                //self.ComicUrlArray  = results as NSArray as! [String]
           
                    let rl = (result.valueForKey("bookUrl") as! String)
                    print(rl)
            self.ComicUrlArray.append(rl)
                }
              //  dispatch_async(dispatch_get_main_queue(),{
                    self.tableView.reloadData()
             //   })
            } else {
                //       status.text = "No Match"
            }
            
        } catch let error as NSError {
            // failure
            print("Fetch failed: \(error.localizedDescription)")
        }
        
        
        
        
    }
    
    func showComics(notification: NSNotification){
         self.findComic()
    }
    
    override func viewWillDisappear(animated: Bool) {
  
        
        NSNotificationCenter.defaultCenter().removeObserver("showComics")
      
        
    }
    
    
    //Mark:- camera
   @IBAction  func capture(sender : UIButton) {
        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.Camera){
            
          //  let imagePicker = UIImagePickerController()
            imagePicker.delegate = self
            imagePicker.sourceType = UIImagePickerControllerSourceType.Camera;
            imagePicker.modalPresentationStyle = .FullScreen
            imagePicker.mediaTypes = [kUTTypeImage as String]
            imagePicker.allowsEditing = true
            
            imagePicker.showsCameraControls = true
            
            self.presentViewController(imagePicker, animated: true, completion: nil)
        }
    }

    
    
    func presentImagePicker() {
        UIApplication.sharedApplication().statusBarStyle = UIStatusBarStyle.LightContent
        
        imagePicker.delegate = self
        imagePicker.sourceType = UIImagePickerControllerSourceType.PhotoLibrary
        imagePicker.mediaTypes = [kUTTypeImage as String]
        imagePicker.allowsEditing = false
        
        self.presentViewController(imagePicker, animated: true, completion: nil)
        
    }
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject])
    {
        UIApplication.sharedApplication().statusBarStyle = UIStatusBarStyle.LightContent
        
        let mediaType = info[UIImagePickerControllerMediaType] as! NSString
        
        if mediaType.isEqualToString(kUTTypeImage as String) {
            
            // Media is an image
            var image = UIImage()
            
            
            if let imageEdited = info[UIImagePickerControllerEditedImage] as? UIImage {
                
               image = imageEdited
                
            } else {
                image = (info[UIImagePickerControllerOriginalImage] as? UIImage)!
               
            }
            
            
           let PhotoData = UIImagePNGRepresentation(image)!
           uploadImageToDropBox(PhotoData)
  //          self.PhotoImage.image = image
            
            // self.PhotoImage.contentMode = UIViewContentMode.ScaleAspectFill
            
            /*
            let imageJPEG = UIImageJPEGRepresentation(image, 0.5)
            //   thumbnailData = UIImagePNGRepresentation(imageJPEG)
            self.thumbnailData = imageJPEG
            */
            //check size
            let formatter = NSByteCountFormatter()
            
            formatter.allowedUnits = NSByteCountFormatterUnits.UseBytes
            formatter.countStyle = NSByteCountFormatterCountStyle.File
            
            //PFFile cannot be larger than 10485760 bytes  !!!!!!!!!!!
          //  PhotoFile = PFFile(name: "photo.png", data: PhotoData)!
          //  PhotoSelected = true
            //-----
        }
        self.dismissViewControllerAnimated(false, completion: nil)
        
    }
    
    func imagePickerControllerDidCancel(picker: UIImagePickerController) {
        self.dismissViewControllerAnimated(true, completion: nil)
        UIApplication.sharedApplication().statusBarStyle = UIStatusBarStyle.LightContent
    }

    func uploadImageToDropBox(  fileData : NSData) {
        // Verify user is logged into Dropbox
        if let client = Dropbox.authorizedClient {
           
        //    let fileData = "Hello!".dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)
            client.files.upload(path: "/\(self.getDateTimeString())Image.png", body: fileData).response { response, error in
                if let metadata = response {
                    print("*** Upload file ****")
                    print("Uploaded file name: \(metadata.name)")
                    print("Uploaded file revision: \(metadata.rev)")
                   /*
                    // Get file (or folder) metadata
                    client.files.getMetadata(path: "/\(self.getDateTimeString())Image.png").response { response, error in
                        print("*** Get file metadata ***")
                        if let metadata = response {
                            if let file = metadata as? Files.FileMetadata {
                                print("This is a file with path: \(file.pathLower)")
                                print("File size: \(file.size)")
                            } else if let folder = metadata as? Files.FolderMetadata {
                                print("This is a folder with path: \(folder.pathLower)")
                            }
                        } else {
                            print(error!)
                        }
                    }
                 */
                }
                
              }
        }
   }
    
    func listDropBoxFiles() {
        // Verify user is logged into Dropbox
        if let client = Dropbox.authorizedClient {
            // List folder
            client.files.listFolder(path: "").response { response, error in
                print("*** List folder ***")
                if let result = response {
                    print("Folder contents:")
                    for entry in result.entries {
                        print(entry.name)
                    }
                } else {
                    print(error!)
                }
            }
        }
    }
    
    func getDateTimeString()->String {
        let now = NSDate()
        let formatter = NSDateFormatter()
        formatter.dateFormat = "yyyyMMddHHmmss"
        formatter.timeZone = NSTimeZone(forSecondsFromGMT: 0)
        return  (formatter.stringFromDate(now))
        
    }

    
}
