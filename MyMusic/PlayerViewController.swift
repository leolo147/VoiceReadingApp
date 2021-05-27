//
//  PlayerViewController.swift
//  MyMusic
//
//  Created by Leo Lo on 14/5/2021.
//  Copyright © 2021 ASN GROUP LLC. All rights reserved.
//

import AVFoundation
import CoreData
import UIKit

class PlayerViewController: UIViewController, AVSpeechSynthesizerDelegate,UIScrollViewDelegate {
    
    
    
    public var position: Int = 0
    public var songs: [Song] = []
    let speechSynthesizer = AVSpeechSynthesizer()
    var utterance = AVSpeechUtterance(string: "")
    var currentRange: NSRange = NSRange(location: 0, length: 0)
    var rate: Float = 0.3
    var spokenTextLengths: Int = 0
    var remainingText : String.SubSequence!
    private var appDelegate = UIApplication.shared.delegate as! AppDelegate
    private let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    
    
    @IBOutlet var holder: UIView!
    @IBOutlet var functionView: UIView!
    @IBOutlet var albumImageView: UITextView!
    
    var player: AVAudioPlayer?
    
    // User Interface elements
    
    
//    private let albumImageView: UILabel = {
//        let label = UILabel()
//        label.textAlignment = .center
//        return label
//    }()
    
    private let songNameLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.numberOfLines = 0 // line wrap
        return label
    }()
    
    
    let playPauseButton = UIButton()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = songs[position].name
        speechSynthesizer.delegate = self
//        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Back", style: .plain, target: self,action: #selector(backViewBtnFnc))
        //setNavigationBar()
        //holder.delegate = self
    }
    
    @objc func backViewBtnFnc(){
            self.navigationController?.popViewController(animated: true)
        }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        print("subviews",holder.subviews.count)
        if holder.subviews.count == 1 {
            configure()
        }
    }
    
    func configure() {
        // set up player
        var bookContent = ""
        let song = songs[position]
//        albumImageView.text = song.bookContent
        
        
        //let urlString = Bundle.main.path(forResource: song.trackName, ofType: "mp3")
        let request = ReadingBook.fetchRequest() as NSFetchRequest<ReadingBook>
        
        let item_name = songs[position].name
        request.predicate = NSPredicate(format: "bookName CONTAINS[cd] %@", item_name)
        
        do {
            let fetch = try context.fetch(request)
            
            if (fetch.count > 0){
                let product = fetch[0]
                bookContent = product.remainingText!
                appDelegate.saveContext()
            }else{
                bookContent = song.bookContent
            }

        } catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
        }
        albumImageView.text = bookContent
        
        utterance = AVSpeechUtterance(string: bookContent)
        //utterance.voice = AVSpeechSynthesisVoice(language: "zh-HK")
        utterance.voice = AVSpeechSynthesisVoice(identifier: "com.apple.ttsbundle.Sin-Ji-compact")
        utterance.pitchMultiplier = 1+rate
        utterance.rate = rate
        utterance.volume = 0.1
        // pitchMultiplier = rate + 1
        
        
        
        do {
            speechSynthesizer.speak(utterance)
        }
        catch {
            print("error occurred")
        }
        
        // set up user interface elements
        
        // album cover
//        albumImageView.frame = CGRect(x: 10,
//                                    y: 0,
//                                    width: holder.frame.size.width-20,
//                                    height: holder.frame.size.width+50)
        //albumImageView.image = UIImage(named: song.imageName)
        //albumImageView.text = song.bookContent
        //albumImageView.isEditable = false
        //albumImageView.font = UIFont.systemFont(ofSize: 40)
        //holder.addSubview(albumImageView)
        
        // Labels: Song name, album, artist
//        songNameLabel.frame = CGRect(x: 10,
//                                     y: albumImageView.frame.size.height + 10,
//                                     width: holder.frame.size.width-20,
//                                     height: 70)
//        albumNameLabel.frame = CGRect(x: 10,
//                                      y: albumImageView.frame.size.height + 10 + 70,
//                                      width: holder.frame.size.width-20,
//                                      height: 70)
//        artistNameLabel.frame = CGRect(x: 10,
//                                       y: albumImageView.frame.size.height + 10 + 140,
//                                       width: holder.frame.size.width-20,
//                                       height: 70)
        
//        songNameLabel.text = song.name
//        albumNameLabel.text = song.albumName
//        artistNameLabel.text = song.artistName
        
        //holder.addSubview(songNameLabel)

        
        // Player controls
        let nextButton = UIButton()
        let backButton = UIButton()
        
        // Frame
        let yPosition = songNameLabel.frame.origin.y + 70 + 20
        let size: CGFloat = 70
        
        playPauseButton.frame = CGRect(x: (holder.frame.size.width - size) / 2.0,
                                       y: holder.frame.size.height - 100,
                                       width: size,
                                       height: size)
        
        nextButton.frame = CGRect(x: holder.frame.size.width - size - 20,
                                  y: yPosition,
                                  width: size,
                                  height: size)
        
        backButton.frame = CGRect(x: 20,
                                  y: yPosition,
                                  width: size,
                                  height: size)
        
        
        
        // Add actions
        playPauseButton.addTarget(self, action: #selector(didTapPlayPauseButton), for: .touchUpInside)
        nextButton.addTarget(self, action: #selector(didTapNextButton), for: .touchUpInside)
        backButton.addTarget(self, action: #selector(didTapBackButton), for: .touchUpInside)
        
        // Styling
        
        playPauseButton.setBackgroundImage(UIImage(systemName: "pause.fill"), for: .normal)
        backButton.setBackgroundImage(UIImage(systemName: "backward.fill"), for: .normal)
        nextButton.setBackgroundImage(UIImage(systemName: "forward.fill"), for: .normal)
        
        playPauseButton.tintColor = .red
        backButton.tintColor = .black
        nextButton.tintColor = .black
        
        holder.addSubview(playPauseButton)
//        holder.addSubview(nextButton)
//        holder.addSubview(backButton)
        
        // slider
        let slider = UISlider(frame: CGRect(x: 20,
                                            y: holder.frame.size.height-60,
                                            width: holder.frame.size.width-40,
                                            height: 50))
        slider.value = 0.5
        slider.addTarget(self, action: #selector(didSlideSlider(_:_:)), for: .valueChanged)
        holder.addSubview(slider)
    }
    
    @objc func didTapBackButton() {
        if position > 0 {
            position = position - 1
            player?.stop()
            for subview in holder.subviews {
                subview.removeFromSuperview()
            }
            configure()
        }
    }
    
    @objc func didTapNextButton() {
        if position < (songs.count - 1) {
            position = position + 1
            player?.stop()
            for subview in holder.subviews {
                subview.removeFromSuperview()
            }
            configure()
        }
    }
    
    func addItems(remainingText:String) {
        let request = ReadingBook.fetchRequest() as NSFetchRequest<ReadingBook>
        
        let item_name = songs[position].name
        request.predicate = NSPredicate(format: "bookName CONTAINS[cd] %@", item_name)
        
        do {
            let fetch = try context.fetch(request)
            
            if (fetch.count > 0){
                let product = fetch[0]
                product.remainingText = remainingText
                appDelegate.saveContext()
            }else{
                print("0000000")
                let item = NSEntityDescription.insertNewObject(forEntityName: "ReadingBook", into: context ) as! ReadingBook
                item.bookName = songs[position].name
                item.bookAuthor = songs[position].albumName
                item.bookContent = songs[position].bookContent
                item.remainingText = remainingText
                appDelegate.saveContext()
            }

        } catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
        }
        
    }
    
    @objc func didTapPlayPauseButton() {
        //utterance.voice = AVSpeechSynthesisVoice(identifier: "com.apple.ttsbundle.Ting-Ting-compact")
        if speechSynthesizer.isPaused == false{
            speechSynthesizer.pauseSpeaking(at: AVSpeechBoundary.immediate)
            playPauseButton.setBackgroundImage(UIImage(systemName: "play.fill"), for: .normal)
            playPauseButton.tintColor = UIColor.green
            
        }else{
            speechSynthesizer.continueSpeaking()
            playPauseButton.setBackgroundImage(UIImage(systemName: "pause.fill")?.withTintColor(.green), for: .normal)
            playPauseButton.tintColor = UIColor.red
            
        }
        //        if player?.isPlaying == true {
        //            // pause
        //            player?.pause()
        //            // show play button
        //            playPauseButton.setBackgroundImage(UIImage(systemName: "play.fill"), for: .normal)
        //            playPauseButton.tintColor = UIColor.green
        //
        //            // shrink image
        //            UIView.animate(withDuration: 0.2, animations: {
        //                self.albumImageView.frame = CGRect(x: 30,
        //                                                   y: 30,
        //                                                   width: self.holder.frame.size.width-60,
        //                                                   height: self.holder.frame.size.width-60)
        //            })
        //        }
        //        else {
        //            // play
        //            player?.play()
        //            playPauseButton.setBackgroundImage(UIImage(systemName: "pause.fill")?.withTintColor(.green), for: .normal)
        //            playPauseButton.tintColor = UIColor.red
        //
        //            // increase image size
        //            UIView.animate(withDuration: 0.2, animations: {
        //                self.albumImageView.frame = CGRect(x: 10,
        //                                              y: 10,
        //                                              width: self.holder.frame.size.width-20,
        //                                              height: self.holder.frame.size.width-20)
        //            })
        //        }
    }
    
    @objc func didSlideSlider(_ slider: UISlider,_ event: UIEvent) {
        let value = slider.value
        print(slider.value)
        if let touchEvent = event.allTouches?.first {
                switch touchEvent.phase {
                case .began:
                    print("began")
                case .moved:
                    print("moved")
                case .ended:
                    speechSynthesizer.stopSpeaking(at: .immediate)
                    
                    if currentRange.length > 0 {
                        utterance = AVSpeechUtterance(string: String(remainingText))
                        //utterance.voice = AVSpeechSynthesisVoice(language: "zh-HK")
                        utterance.voice = AVSpeechSynthesisVoice(identifier: "com.apple.ttsbundle.Sin-Ji-compact")
                        utterance.pitchMultiplier = 1+slider.value
                        utterance.rate = slider.value
                        
                        speechSynthesizer.speak(utterance)
                    }
                default:
                    break
                }
            }
        rate = value
        
    }
    
    
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if let player = player {
            player.stop()
        }
        speechSynthesizer.stopSpeaking(at: AVSpeechBoundary.immediate)
        print("done")
        addItems(remainingText: String(remainingText))
    }
    
    func setNavigationBar() {
        let navBar = UINavigationBar(frame: CGRect(x: 0, y: 0, width: view.frame.size.width, height: 44))
        view.addSubview(navBar)

        let navItem = UINavigationItem(title: "SomeTitle")
        let doneItem = UIBarButtonItem(barButtonSystemItem: .done, target: nil, action: #selector(didTapNextButton))
        navItem.rightBarButtonItem = doneItem

        navBar.setItems([navItem], animated: false)
    }
    
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, willSpeakRangeOfSpeechString characterRange: NSRange, utterance: AVSpeechUtterance) {
        let mutableAttributedString = NSMutableAttributedString(string: utterance.speechString)
        mutableAttributedString.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.white, range:  NSMakeRange(0, (utterance.speechString as NSString).length))
        mutableAttributedString.addAttribute(.foregroundColor, value: UIColor.red, range: characterRange)
        let rangeInTotalText = NSMakeRange(spokenTextLengths + characterRange.location, characterRange.length)
        albumImageView.attributedText = mutableAttributedString
        albumImageView.font = .systemFont(ofSize: 40)
        currentRange = characterRange
        albumImageView.scrollRangeToVisible(rangeInTotalText)
        remainingText = utterance.speechString.dropFirst(characterRange.location)
        print("remainingText", remainingText)
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        spokenTextLengths = spokenTextLengths + utterance.speechString.utf16.count+1
        albumImageView.attributedText = NSAttributedString(string: utterance.speechString)
        albumImageView.font = .systemFont(ofSize: 40)
    }
    
    
    
}

