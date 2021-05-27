//
//  ViewController.swift
//  MyMusic
//
//  Created by Afraz Siddiqui on 4/3/20.
//  Copyright © 2020 ASN GROUP LLC. All rights reserved.
//

import UIKit
import MobileCoreServices
import WebKit
import PDFKit
import Speech
import AVFoundation
import Alamofire

struct loginResults: Decodable {
    var status : String
    let code : String
    let data : data?
    
    struct data: Decodable {
        let token : String
    }
}

struct allBookResuls: Decodable {
    var status : String
    let code : String
    let data : data?
    
    struct data: Decodable {
        let books : [book]?
    }
    
    struct book : Decodable {
        let id : Int
        let name: String
        let content: String
        let create_time: String
        let author: String
    }
}


class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, SFSpeechRecognizerDelegate{

    @IBOutlet var table: UITableView!
    @IBOutlet var nav: UINavigationItem!
    private lazy var addBookButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addBookFromDevice))

    var songs = [Song]()
    let audioEngine = AVAudioEngine()
    let speechReconizer : SFSpeechRecognizer? = SFSpeechRecognizer(locale: Locale.init(identifier: "zh-HK"))
    let request = SFSpeechAudioBufferRecognitionRequest()
    var task : SFSpeechRecognitionTask!
    let speechSynthesizer = AVSpeechSynthesizer()
    var utterance = AVSpeechUtterance(string: "")

    override func viewDidLoad() {
        super.viewDidLoad()
        addBookButton.tintColor = UIColor.systemGreen
        requestPermission()
        getapi()
        table.delegate = self
        table.dataSource = self
        self.navigationItem.rightBarButtonItem = addBookButton
        title="BOOK"
        
        
        navigationController?.navigationBar.tintColor = UIColor.systemFill
        navigationController?.navigationBar.barTintColor = UIColor.systemFill
        let tapTwoTimeRecognizer = UITapGestureRecognizer(target: self, action: #selector(startSpeechRecognization(_:)))
        tapTwoTimeRecognizer.numberOfTapsRequired = 2
        table.addGestureRecognizer(tapTwoTimeRecognizer)
//        getapi()
        
        
        
        
    }
    
    @objc private func addBookFromDevice() {
        let documentPicker = UIDocumentPickerViewController(documentTypes: [kUTTypePDF as String], in: .import)
        documentPicker.delegate = self
        documentPicker.allowsMultipleSelection = false
        present(documentPicker, animated: true, completion: nil)

    }
    
    func requestPermission(){
        SFSpeechRecognizer.requestAuthorization { (authState) in
            OperationQueue.main.addOperation {
                if authState == .authorized{
                    print("ACCEPTED")
                }
            }
        }
    }

    func configureSongs() {
        
    }

    // Table

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return songs.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        let song = songs[indexPath.row]
        // configure
        cell.textLabel?.text = song.name
        cell.detailTextLabel?.text = song.albumName
        cell.accessoryType = .disclosureIndicator
        //cell.imageView?.image = UIImage(named: song.imageName)
        cell.textLabel?.font = UIFont(name: "Helvetica-Bold", size: 30)
        cell.detailTextLabel?.font = UIFont(name: "Helvetica", size: 20)

        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 100
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        // present the player
        let position = indexPath.row
        guard let vc = storyboard?.instantiateViewController(identifier: "player") as? PlayerViewController else {
            return
        }
        vc.songs = songs
        vc.position = position
        vc.modalPresentationStyle = .fullScreen
        let navVC = UINavigationController(rootViewController: vc)
        navVC.modalPresentationStyle = .fullScreen
        navigationController?.pushViewController(vc, animated: true)
    }
    
    func cancelSpeechRecognization(){
        task.finish()
        task.cancel()
        task = nil
        
        request.endAudio()
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
    }
    
    func getapi(){
        let parameters: [String: Any] = [
            "username":"leolo159",
            "password":"56221887"
        ]
    
        
        AF.request("http://192.168.1.120:8443/authenticate", method: .post, parameters: parameters, encoding: JSONEncoding.default)
            .responseDecodable(of: loginResults.self) { response in
                guard let json = response.value, json.status == "success" else {
                    return
                }
                ProjectConfig.token = json.data!.token
                let headers: HTTPHeaders = [.authorization(bearerToken: ProjectConfig.token)]
                AF.request("http://192.168.1.120:8443/sync/allbook", method: .get, headers: headers)
                    .responseDecodable(of: allBookResuls.self) { response in
                        guard let json = response.value, json.status == "success" else {
                            return
                        }
                        json.data?.books?.forEach({ book in
                            self.songs.append(Song(name: book.name, albumName: book.author, bookContent: book.content))
                        })
                        self.table.reloadData()
                        print(self.songs.count)
                        
                    }
            }
        
//        let headers: HTTPHeaders = [.authorization(bearerToken: ProjectConfig.token)]
//        AF.request("http://192.168.1.120:8443/sync/allbook", method: .get, headers: headers)
//            .responseDecodable(of: allBookResuls.self) { response in
//                print(response.request?.allHTTPHeaderFields)
//                guard let json = response.value, json.status == "success" else {
//                    return
//                }
//                print("books", json.data)
//            }
    }
    
    func toReadingPage(index:Int){
        guard let vc = storyboard?.instantiateViewController(identifier: "player") as? PlayerViewController else {
            return
        }
        vc.songs = songs
        vc.position = index
        present(vc, animated: true)
    }
    
    @objc func startSpeechRecognization(_ sender: UITapGestureRecognizer){
        try! AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.playAndRecord, options: AVAudioSession.CategoryOptions.defaultToSpeaker)
        try! AVAudioSession.sharedInstance().setActive(true)
        try! AVAudioSession.sharedInstance().overrideOutputAudioPort(AVAudioSession.PortOverride.none)
        
        utterance = AVSpeechUtterance(string: "請選擇書本")
        utterance.voice = AVSpeechSynthesisVoice(language: "zh-HK")
        //utterance.voice = AVSpeechSynthesisVoice(identifier: "com.apple.ttsbundle.Sin-Ji-compact")
        utterance.pitchMultiplier = 0.3
        utterance.rate = 0.3
        utterance.volume = 0.1
        
        
        speechSynthesizer.speak(utterance)
        
        let node = audioEngine.inputNode
        let recordingFormat = node.outputFormat(forBus: 0)
        
        node.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat){ (buffer, _) in
            self.request.append(buffer)
        }
        
        do{
            try audioEngine.start()
        } catch let error {
            print(error.localizedDescription)
        }
        
        guard let myRecognization = SFSpeechRecognizer() else {
            print("Recognization is not allow on your local")
            return
        }
        
        if !myRecognization.isAvailable{
            print("Recogniztion is free right now, Please try again after some time.")
        }
        
        task = speechReconizer?.recognitionTask(with: request, resultHandler: {(response, error) in
            guard let response = response else{
                if error != nil{
                    print(error.debugDescription)
                }else{
                    print("Problem in giving the response")
                }
                return
            }
            
            let message = response.bestTranscription.formattedString
            
            print("結果",message)
            
            for song in self.songs{
                if message.contains(song.name){
                    print(song.name)
                    let bookIndex = self.songs.filter { bookSong in
                        bookSong.name ==  song.name}.startIndex
                    self.toReadingPage(index: bookIndex)
                    self.cancelSpeechRecognization()
                }
            }
        })
    }


}

struct Song {
    let name: String
    let albumName: String
    let bookContent: String
}

extension ViewController: UIDocumentPickerDelegate{
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls:[URL]){
        print(urls.first)
        if let pdf = PDFDocument(url: urls.first!) {
            let pageCount = pdf.pageCount
            let documentContent = NSMutableAttributedString()

            for i in 1 ..< pageCount {
                guard let page = pdf.page(at: i) else { continue }
                guard let pageContent = page.attributedString else { continue }
                documentContent.append(pageContent)
            }
            print("content ",documentContent.mutableString)
            print("name",urls.first!.lastPathComponent)
            
            guard let vc = storyboard?.instantiateViewController(identifier: "player") as? PlayerViewController else {
                return
            }
            
            songs.append(Song(name:urls.first!.lastPathComponent, albumName:urls.first!.lastPathComponent,bookContent:documentContent.mutableString as String))
            vc.songs = songs
            vc.position = songs.count-1
            present(vc, animated: true)
            
        }
    }
}
