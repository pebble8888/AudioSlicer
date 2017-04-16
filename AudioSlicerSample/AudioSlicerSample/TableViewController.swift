//
//  TableViewController.swift
//  AudioSlicerSample
//
//  Created by pebble8888 on 2017/04/15.
//  Copyright © 2017年 pebble8888. All rights reserved.
//

import UIKit
import AVFoundation

class TableViewController: UITableViewController
{
    var player:AVPlayer?
    public var items:[String] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let newCell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        newCell.textLabel?.text = items[indexPath.row]
        return newCell;
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        player?.pause()
        player = nil
        let docpath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
        let path:String = docpath + "/" + items[indexPath.row]
        //let path = docpath + "/" + "taroandhanako.mp3"
        let url = URL(fileURLWithPath: path)
        player = AVPlayer(url: url)
        player?.play()
    }
    
}
