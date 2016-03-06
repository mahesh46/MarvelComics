//
//  DataManagement.swift
//  MarvelComics
//
//  Created by Administrator on 06/03/2016.
//  Copyright © 2016 mahesh lad. All rights reserved.
//

import Foundation
import UIKit
import CoreData
import SwiftyDropbox
import Alamofire


// MARK: - CoreData
let  privateKey = "e1008cb7f3840fafc95fbd3c053a3233b0477af9"
let publicKey = "e09f6ccf645d45057b91d04107268698"

var ts = getTimestamp()
var hash = (ts+privateKey+publicKey).md5()



func saveToCoreData( url: String) {
     let managedObjectContext = (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext
    
    let entityDescription =
    NSEntityDescription.entityForName("ComicBook",
        inManagedObjectContext: managedObjectContext)
    
    
    let book = ComicBook(entity: entityDescription!,
        insertIntoManagedObjectContext: managedObjectContext)
    
    
    book.bookUrl  = url
    let image = UIImage(data: NSData(contentsOfURL: NSURL(string: url)!)!)
    book.bookImage = UIImageJPEGRepresentation(image!, 1.0)
    do {
        try managedObjectContext.save()
        print(url)
        //   status.text = "Contact Saved"
    } catch {
        fatalError("Failure to save context: \(error)")
    }
}

func deleteAllData(entity: String)
{
    let managedContext = (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext
    
    let fetchRequest = NSFetchRequest(entityName: entity)
    fetchRequest.returnsObjectsAsFaults = false
    
    do
    {
        let results = try managedContext.executeFetchRequest(fetchRequest)
        for managedObject in results
        {
            let managedObjectData:NSManagedObject = managedObject as! NSManagedObject
            managedContext.deleteObject(managedObjectData)
        }
    } catch let error as NSError {
        print("Detele all data in \(entity) error : \(error) \(error.userInfo)")
    }
}

func updateCoreData( url : String, data : NSData ) {
    
    
    let managedContext = (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext
    let entityDescription =
    NSEntityDescription.entityForName("ComicBook",
        inManagedObjectContext: managedContext)
    
    let request = NSFetchRequest()
    request.entity = entityDescription
    
    let pred = NSPredicate(format: "(bookUrl = %@)", url)
    request.predicate  = pred
    
    
    do { let results = try managedContext.executeFetchRequest(
        request)
        
        if results.count != 0 {
            
            let managedObject = results[0] as! NSManagedObject
            managedObject.setValue(data, forKey: "bookImage")
            
            
            do { try  managedContext.save() }
            catch { print(error) }
        }
        
    } catch {
        print(error)
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

func  getComicImages(url:String)  {
    
    
    Alamofire.request(.GET, url)
        .responseJSON { response in
            /*
            print(response.request)  // original URL request
            print(response.response) // URL response
            print(response.data)     // server data
            print(response.result.value)   // result of response serialization
            */
            let imageSize = "portrait_xlarge."
            
            
            do {          let responseDict =  try NSJSONSerialization.JSONObjectWithData(response.data!, options: .MutableContainers) as! NSDictionary
                
                
                
                if  let dataDict  = responseDict.objectForKey("data")  as? NSDictionary {
                    
                    if  let resultsArray  = dataDict.objectForKey("results")  as? NSArray {
                        for rec in resultsArray {
                            
                            if  let pitcureDict  = rec  as? NSDictionary {
                                var imgext = ""
                                var imgpath = ""
                                
                                if  let imagesArray  = pitcureDict.objectForKey("images")  as? NSArray {
                                    
                                    if imagesArray.count > 0 {
                                        if  let ext =  imagesArray[0].objectForKey("extension")  as? String {
                                            imgext = ext
                                        }
                                        
                                        if  let path =  imagesArray[0].objectForKey("path")  as? String {
                                            imgpath = path
                                        }
                                        let imgUrl = imgpath + "/" + imageSize + imgext
                                        
                                        
                                        
                                        saveToCoreData(imgUrl)
                                        
                                    }
                                }
                                
                                //--
                            }
                            
                        }
                    }
                    
                    
                }
                
                dispatch_async(dispatch_get_main_queue(),{
                    NSNotificationCenter.defaultCenter().postNotificationName("showComics", object: nil)
                })
                
                
            } catch {
                print(error)
            }
            
            
            
    }
    
}
