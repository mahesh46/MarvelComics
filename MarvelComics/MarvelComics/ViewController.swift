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

class ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UIImagePickerControllerDelegate , UINavigationControllerDelegate {

    @IBOutlet weak var tableView: UITableView!
     var ComicUrlArray : [String] = []
    var ComicDataArray : [NSData] = []
      private var ComicUrlsImageCache = NSMutableDictionary()    //cachefile
    
    var pickerData =  []
  
    var imagePicker: UIImagePickerController!
    
    
    var   PhotoData :NSData?
    var   PhotoImage : UIImage?
    
     var comicSender : AnyObject?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
     
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "showComics:",name:"showComics", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "takenPhoto:",name:"takenPhoto", object: nil)
        //register cell from xib
        tableView.registerNib(UINib(nibName: "ComicTableViewCell", bundle: nil), forCellReuseIdentifier: "Cell")
        
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
     
      //  return ComicUrlArray.count
        return ComicDataArray.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
           let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath) as! ComicTableViewCell
        
           cell.comicButton.tag = indexPath.row
           cell.comicButton.addTarget(self, action: "ShowCamera:", forControlEvents: UIControlEvents.TouchUpInside)
        
           cell.comicImageView.image = UIImage(data: self.ComicDataArray[indexPath.row])
           cell.comicImageView.contentMode = UIViewContentMode.ScaleAspectFill
        
           return cell
    }
    
    

    // MARK: - CoreData
    
     func findComic() {
       
        let managedContext = (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext
        
        let entityDescription =
        NSEntityDescription.entityForName("ComicBook",
            inManagedObjectContext: managedContext)
        
        let request = NSFetchRequest()
        request.entity = entityDescription
        
        
        do {
            let  results = try managedContext.executeFetchRequest(request)
            // success ...
            
            if results.count > 0 {
                for result in results {
                
                    let urlstr = (result.valueForKey("bookUrl") as! String)
                     let data = (result.valueForKey("bookImage") as! NSData)
            self.ComicUrlArray.append(urlstr)
             self.ComicDataArray.append(data)
                }
                dispatch_async(dispatch_get_main_queue(),{
                    self.tableView.reloadData()
               })
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
         NSNotificationCenter.defaultCenter().removeObserver("takenPhoto")
    }
    

    //Mark:- camera
    @IBAction func ShowCamera(sender: AnyObject) {
        
            self.comicSender  = sender
        
            imagePicker =  UIImagePickerController()
            imagePicker.delegate = self
            imagePicker.sourceType = .Camera
            
            presentViewController(imagePicker, animated: true, completion: nil)
    }

    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject])
    {
       
        let mediaType = info[UIImagePickerControllerMediaType] as! NSString
        
        if mediaType.isEqualToString(kUTTypeImage as String) {
            
            // Media is an image
            var image = UIImage()
            
            
            if let imageEdited = info[UIImagePickerControllerEditedImage] as? UIImage {
                
               image = imageEdited
                
            } else {
                image = (info[UIImagePickerControllerOriginalImage] as? UIImage)!
               
            }
            
            self.PhotoImage = image
            
            self.PhotoData =  UIImageJPEGRepresentation(image, 1.0)
            
            
            //update cell with photo image
            NSNotificationCenter.defaultCenter().postNotificationName("takenPhoto", object: nil)
            
            //send to dropbox
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
        
                   self.uploadImageToDropBox(self.PhotoData!)
              }
         
        }
        
        imagePicker.dismissViewControllerAnimated(true, completion: nil)
      
    }
    
    func imagePickerControllerDidCancel(picker: UIImagePickerController) {
           imagePicker.dismissViewControllerAnimated(true, completion: nil)
       
    }

    func uploadImageToDropBox(  fileData : NSData) {
        // Verify user is logged into Dropbox
        if let client = Dropbox.authorizedClient {
           
            client.files.upload(path: "/\(self.getDateTimeString())Image.png", body: fileData).response { response, error in
                if let metadata = response {
                    print("*** Upload file ****")
                    print("Uploaded file name: \(metadata.name)")
                    print("Uploaded file revision: \(metadata.rev)")
                   
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


    func takenPhoto(notification: NSNotification){
         let row = comicSender!.tag
        
          updateCoreData( ComicUrlArray[row], data: self.PhotoData!)
        
          self.ComicDataArray[row] = self.PhotoData!
      
        if comicSender != nil {
            //update cell  image
            if var currentCell = comicSender as? UIView   {
                while (true) {
                    currentCell = currentCell.superview!
                    if let cell  =  currentCell as? ComicTableViewCell {
                        if let cellImageView = cell.comicImageView {
                            
                               cellImageView.image =  self.PhotoImage
                          
                            break;
                        }
                    }
                }
            }

        }
    }
    
    
    
    @IBAction func ResetTable(sender: AnyObject) {
       
        
        deleteAllData("ComicBook")
        ComicUrlArray  = []
        ComicDataArray  = []
        tableView.reloadData()
        let ts = getTimestamp()
        let hash = (ts+privateKey+publicKey).md5()
        let  url = getComicUrl(publicKey, hash: hash, ts: ts)
        getComicImages(url)
    }
    
    
   }
