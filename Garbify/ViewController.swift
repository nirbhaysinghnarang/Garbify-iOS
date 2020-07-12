//
//  ViewController.swift
//  Garbify
//
//  Created by Nirbhay Singh on 12/07/20.
//  Copyright © 2020 Nirbhay Singh. All rights reserved.
//

import UIKit
import AVKit
import CoreML
import SCLAlertView
import JGProgressHUD

var predi:String!
var confidence_str:String!
var plastic:Bool!
var plasticPred:String!
var photo:UIImage!

class ViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate, AVCapturePhotoCaptureDelegate{
    private let captureSession = AVCaptureSession()
    private let videoOutput = AVCaptureVideoDataOutput()
    private let photoOutput = AVCapturePhotoOutput()
    private lazy var previewLayer: AVCaptureVideoPreviewLayer = {
        let preview = AVCaptureVideoPreviewLayer(session: self.captureSession)
        preview.videoGravity = .resizeAspect
        return preview
    }()
    private var imgData:Data!
    private var imgBuffer:CVPixelBuffer!
    private var img:UIImage!

    override func viewDidLoad() {
        super.viewDidLoad()
        self.addCameraInput()
        self.addPreviewLayer()
        self.addVideoOutput()
        self.captureSession.startRunning()
    
    }
    override func viewDidLayoutSubviews() {
         super.viewDidLayoutSubviews()
        self.previewLayer.frame = CGRect(x: -5, y: 150, width: self.view.frame.width+10, height: self.view.frame.height-150)
     }
     
     private func addCameraInput() {
         let device = AVCaptureDevice.default(for: .video)!
         let cameraInput = try! AVCaptureDeviceInput(device: device)
         self.captureSession.addInput(cameraInput)
     }
     private func addPreviewLayer() {
         self.view.layer.addSublayer(self.previewLayer)
     }

     func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard CMSampleBufferGetImageBuffer(sampleBuffer) != nil else {
             debugPrint("unable to get image from sample buffer")
             return
         }
         debugPrint("did receive image frame")
     }
         
     private func addVideoOutput() {
         self.videoOutput.videoSettings = [(kCVPixelBufferPixelFormatTypeKey as NSString) : NSNumber(value: kCVPixelFormatType_32BGRA)] as [String : Any]
        self.videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "my.image.handling.queue"))
        self.captureSession.addOutput(self.videoOutput)
        self.captureSession.addOutput(self.photoOutput)
     }
    @IBAction func runModelPressed(_ sender: Any) {
        self.capturePhoto(cameraOutput: self.photoOutput)        
    }
    func capturePhoto(cameraOutput:AVCapturePhotoOutput) {
      let settings = AVCapturePhotoSettings()
      let previewPixelType = settings.availablePreviewPhotoPixelFormatTypes.first!
      let previewFormat = [kCVPixelBufferPixelFormatTypeKey as String: previewPixelType,
                           kCVPixelBufferWidthKey as String: 160,
                           kCVPixelBufferHeightKey as String: 160]
      settings.previewPhotoFormat = previewFormat
      cameraOutput.capturePhoto(with: settings, delegate: self)
    }
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photoSampleBuffer: CMSampleBuffer?, previewPhoto previewPhotoSampleBuffer: CMSampleBuffer?, resolvedSettings: AVCaptureResolvedPhotoSettings, bracketSettings: AVCaptureBracketedStillImageSettings?, error: Error?){
            if let error = error {
                print(error.localizedDescription)
            }

            if let sampleBuffer = photoSampleBuffer, let previewBuffer = previewPhotoSampleBuffer, let dataImage = AVCapturePhotoOutput.jpegPhotoDataRepresentation(forJPEGSampleBuffer: sampleBuffer, previewPhotoSampleBuffer: previewBuffer) {
                print("image: \(String(describing: UIImage(data: dataImage)?.size))")
                self.imgData = dataImage
                self.img = UIImage(data: self.imgData)
                self.imgBuffer = buffer(from: self.img)
                runModel()
        }
        
    }
    func buffer(from image: UIImage) -> CVPixelBuffer? {
      let attrs = [kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue, kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue] as CFDictionary
      var pixelBuffer : CVPixelBuffer?
      let status = CVPixelBufferCreate(kCFAllocatorDefault, Int(image.size.width), Int(image.size.height), kCVPixelFormatType_32ARGB, attrs, &pixelBuffer)
      guard (status == kCVReturnSuccess) else {
        return nil
      }

      CVPixelBufferLockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))
      let pixelData = CVPixelBufferGetBaseAddress(pixelBuffer!)
      let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
      let context = CGContext(data: pixelData, width: Int(image.size.width), height: Int(image.size.height), bitsPerComponent: 8, bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer!), space: rgbColorSpace, bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue)
      context?.translateBy(x: 0, y: image.size.height)
      context?.scaleBy(x: 1.0, y: -1.0)
      UIGraphicsPushContext(context!)
      image.draw(in: CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height))
      UIGraphicsPopContext()
      CVPixelBufferUnlockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))

      return pixelBuffer
    }
    func sanitisePlasticInput(str:String)->String{
        var newStr = ""
        for char in str{
            if(char != "_"){
                newStr = newStr + String(char)
            }else{
                newStr = newStr + " "
            }
        }
        return newStr
    }
    func runModel(){
        if(self.imgBuffer==nil){
            showAlert(msg: "An error occured while capturing the image")
        }else{
            photo = self.img
            let hud = JGProgressHUD.init()
            hud.show(in: self.view)
            let trashModel = trashClassifier()
            let plasticModel = plasticClassifier()
            guard let trashPrediction = try? trashModel.prediction(image: self.imgBuffer) else{
                print("FatalErrorOccured")
                showAlert(msg:"An unexpected error occured. Please try again.")
                hud.dismiss()
                return
            }
            print("PredictedClass:\(trashPrediction.classLabel)")
            predi = trashPrediction.classLabel
            var confidence = trashPrediction.classLabelProbs[trashPrediction.classLabel]
            confidence! *= 100
            confidence = confidence?.rounded()
            let cString:String = String(format:"%.1f", confidence!)
            confidence_str = cString
            if (trashPrediction.classLabel != "plastic"){
                plastic = false
                hud.dismiss()
                self.performSegue(withIdentifier: "DETAIL", sender: nil)
            }else{
                plastic = true
                guard let plasticPrediction = try? plasticModel.prediction(image: self.imgBuffer)
                else {
                    print("FatalErrorOccured")
                    showAlert(msg:"An unexpected error occured. Please try again.")
                    hud.dismiss()
                    return
                }
                var confidence = plasticPrediction.classLabelProbs[plasticPrediction.classLabel]
                confidence! *= 100
                confidence! = confidence?.rounded() as! Double
                let cString:String = String(format:"%.1f", confidence as! CVarArg)
                predi = trashPrediction.classLabel + " trash"
                plasticPred = plasticPrediction.classLabel
                plasticPred = "a " + sanitisePlasticInput(str:plasticPred)
                confidence_str = String(cString) + "%"
                hud.dismiss()
                self.performSegue(withIdentifier: "DETAIL", sender: nil)
                
            }
        }
    }

    
}

func showAlert(msg:String){
    SCLAlertView().showError("Oops!", subTitle:msg)
}
func showSuccess(msg:String){
    SCLAlertView().showSuccess("Success", subTitle: msg)
}
func showNotice(msg:String){
    SCLAlertView().showNotice("Loading",subTitle:msg)
}
func showInfo(msg:String,title:String){
    SCLAlertView().showInfo(title,subTitle:msg)
}
