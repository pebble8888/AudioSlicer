//
//  ViewController.swift
//  AudioSlicerSample
//
//  Created by pebble8888 on 2017/04/15.
//  Copyright © 2017年 pebble8888. All rights reserved.
//

import UIKit
import AudioSlicer

class ViewController: UIViewController {
    var slicedFiles:[String] = []
    override func viewDidLoad() {
        super.viewDidLoad()
        self.sliceHandler(nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let id = segue.identifier {
            switch id {
            case "id_list":
                if let nav = segue.destination as? UINavigationController {
                    if let vc = nav.topViewController as? TableViewController {
                        vc.items.append(contentsOf: slicedFiles)
                    }
                }
            default:
                break
            }
        }
    }

    
    @IBAction func sliceHandler(_ sender:Any?){
        DispatchQueue.global().async {
            if let path = Bundle.main.path(forResource: "taroandhanako", ofType: "mp3") {
                let audioslicer = AudioSlicer(filePath:path)
                audioslicer.silenceDuration = 2
                audioslicer.silenceThreshold = 0.1
                let docpath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
                self.slicedFiles = try! audioslicer.export(destPath:docpath) 
                DispatchQueue.main.async{
                    self.performSegue(withIdentifier:"id_list", sender: nil)
                }
            }
        }
    }

}

