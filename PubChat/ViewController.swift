//
//  ViewController.swift
//  PubChat
//
//  Created by Justin Platz on 6/25/15.
//  Copyright (c) 2015 ioJP. All rights reserved.
//

import UIKit
import Foundation



class chatMessage : NSObject{
    var name: String
    var text: String
    var time: String
    var image: String
    var type: String
    
    init(name: String, text: String, time: String, image: String, type: String) {
        self.name = name
        self.text = text
        self.time = time
        self.image = image
        self.type = type
    }

}

func chatMessageToDictionary(chatmessage : chatMessage) -> [String : NSString]{
    return [
        "name": NSString(string: chatmessage.name),
        "text": NSString(string: chatmessage.text),
        "time": NSString(string: chatmessage.time),
        "image": NSString(string: chatmessage.image),
        "type": NSString(string: chatmessage.type)


    ]
}


class ViewController: UIViewController, UITextFieldDelegate, UITableViewDelegate, UITableViewDataSource, MenuTransitionManagerDelegate, PNObjectEventListener {
    
    @IBOutlet weak var MessageTableView: UITableView!
    
    @IBOutlet weak var MessageTextField: UITextField!
    
    @IBOutlet var occupancyButton: UIButton!

    var userName = ""
    
    var chatMessageArray:[chatMessage] = []
    
    var menuTransitionManager = MenuTransitionManager()
    
    var introModalDidDisplay = false
    
    var randomNumber = Int(arc4random_uniform(9))

    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Home"
                
        let appDel = UIApplication.sharedApplication().delegate! as! AppDelegate
        
        appDel.client?.addListener(self)
        
        appDel.client?.subscribeToChannels(["demo"], withPresence: false)
        
        appDel.client?.subscribeToPresenceChannels(["demo"])
        
        self.MessageTextField.delegate = self
        MessageTableView.dataSource = self
        
        self.MessageTableView.separatorStyle = UITableViewCellSeparatorStyle.None

        updateTableview()
        
        showIntroModal()


    }
    
    func showIntroModal() {
        if (!introModalDidDisplay) {
            
            var loginAlert:UIAlertController = UIAlertController(title: "Enter", message: "Please enter your Name", preferredStyle: UIAlertControllerStyle.Alert)
            
            loginAlert.addTextFieldWithConfigurationHandler({
                textfield in
                textfield.placeholder = "What is your name?"
            })
            
            loginAlert.addAction(UIAlertAction(title: "Go", style: UIAlertActionStyle.Default, handler: {alertAction in
                    let textFields:NSArray = loginAlert.textFields! as NSArray
                    let usernameTextField:UITextField = textFields.objectAtIndex(0) as! UITextField
                    self.userName = usernameTextField.text
                    if(self.userName == ""){
                        self.showIntroModal()
                    }
                    else{
                        self.introModalDidDisplay = true
                    }
                }))

            
            self.presentViewController(loginAlert, animated: true, completion: nil)
        
        }
        
    }


    deinit {
        let appDel = UIApplication.sharedApplication().delegate! as! AppDelegate
        
        appDel.client?.removeListener(self)
    }
    
    override func viewWillAppear(animated: Bool) {
        updateTableview()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return false
    }

    @IBAction func SendClick(sender: AnyObject) {
        let appDel = UIApplication.sharedApplication().delegate! as! AppDelegate
        
        var message = MessageTextField.text
        if(message == "") {return}
        else{
            
            
            var pubChat = chatMessage(name: userName, text: MessageTextField.text, time: getTime(), image: String(randomNumber), type: "Chat")

            var newDict = chatMessageToDictionary(pubChat)

            appDel.client?.publish(newDict, toChannel: "demo", compressed: true, withCompletion: nil)
            
            MessageTextField.text = nil
            updateTableview()
        }
        
    }
    
    func getTime() -> String{
        let currentDate = NSDate()  //5 -  get the current date
        var dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "hh:mm a" //format style. Browse online to get a format that fits your needs.
        var dateString = dateFormatter.stringFromDate(currentDate)
        
        return dateString
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.chatMessageArray.count;
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell: TableViewCell = self.MessageTableView.dequeueReusableCellWithIdentifier("Cell") as! TableViewCell
        if(chatMessageArray[indexPath.row].type as String == "Chat"){
            cell.messageTextField.text = chatMessageArray[indexPath.row].text as String
            cell.nameLabel.text = chatMessageArray[indexPath.row].name as String
            cell.timeLabel.text = chatMessageArray[indexPath.row].time as String
            
            let imageName = "emoji\(chatMessageArray[indexPath.row].image as String).png"
            let newImage = UIImage(named: imageName)
            cell.userImage.image = newImage
        }
        
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
    }
    
    func updateTableview(){
        self.MessageTableView.reloadData()
        
        if self.MessageTableView.contentSize.height > self.MessageTableView.frame.size.height {
            MessageTableView.scrollToRowAtIndexPath(NSIndexPath(forRow: chatMessageArray.count - 1, inSection: 0), atScrollPosition: UITableViewScrollPosition.Bottom, animated: true)
        }
    }
    
    @IBAction func ChannelButtonTapped(sender: AnyObject) {
        
    }
    

    
    @IBAction func occupancyButtonTapped(sender: AnyObject) {
        
    }
    
    @IBAction func unwindToHome(segue: UIStoryboardSegue) {
        let sourceController = segue.sourceViewController as! MenuTableViewController
        self.title = sourceController.currentItem
    }
    
     func dismiss(){
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        let menuTableViewController = segue.destinationViewController as! MenuTableViewController
        menuTableViewController.currentItem = self.title!
        menuTableViewController.transitioningDelegate = self.menuTransitionManager
        self.menuTransitionManager.delegate = self
    }
    
    func client(client: PubNub!, didReceiveMessage message: PNMessageResult!, withStatus status: PNErrorStatus!) {
        println("******didReceiveMessage*****")
        
        var stringData = message.data.message as! NSDictionary
        var stringName = stringData["name"] as! String
        var stringText = stringData["text"] as! String
        var stringTime = stringData["time"] as! String
        var stringImage = stringData["image"] as! String
        var stringType = stringData["type"] as! String



        var newMessage = chatMessage(name: stringName, text: stringText, time: stringTime, image: stringImage, type: stringType)
        
        chatMessageArray.append(newMessage)
        MessageTableView.reloadData()

    }
    
    func client(client: PubNub!, didReceivePresenceEvent event: PNPresenceEventResult!) {
        println("******didReceivePresenceEvent*****")
        println(event.data)
        var occ = event.data.presence.occupancy.stringValue
        occupancyButton.setTitle(occ, forState: .Normal)
        
//        var pubChat = chatMessage(name: "", text: "Someone just \(event.data.presenceEvent)", time: getTime())
//        
//        var newDict = chatMessageToDictionary(pubChat)
//        
//        let appDel = UIApplication.sharedApplication().delegate! as! AppDelegate
//        appDel.client?.publish(newDict, toChannel: "demo", compressed: true, withCompletion: nil)
        
        
      
    }
    func client(client: PubNub!, didReceiveStatus status: PNSubscribeStatus!) {
        println("status")
    }
    
}

