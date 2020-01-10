//
//  ResultViewController.swift
//  MLRepurpose
//
//  Created by Jackson Ho on 1/7/20.
//  Copyright © 2020 Jackson Ho. All rights reserved.
//

import UIKit
import Vision
import ImageIO
import LinkPresentation
import AVFoundation

class ResultViewController: UIViewController {
    private var linkPreviewTableView = UITableView(frame: .zero)
    private lazy var detectionLayer: CALayer! = nil
    private lazy var rootLayer: CALayer! = nil
    private lazy var urls: [URL] = []
    private lazy var imageView: UIImageView = {
        var imageView = UIImageView(frame: UIScreen.main.coordinateSpace.bounds)
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    // Image parameters for reuse throughout app
    var imageWidth: CGFloat = 0
    var imageHeight: CGFloat = 0
    
    private lazy var imageRect: CGRect = .zero
    private var innerImageView: UIView = UIView(frame: .zero)

    private let manager = NetworkManager()
    
    private var requests = [VNRequest]()
    
    private let resultView: DraggableResultView = DraggableResultView(frame: UIScreen.main.coordinateSpace.bounds)
    private let yolo = YOLOv3()
    var pathLayer: CALayer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.navigationBar.isHidden = false
        setupUI()
        setupTableView()
        setupVision()
        
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        configTimeStampView()
    }
    // MARK: - Vision
    
    /// - Tag: PerformRequests
    func performVisionRequest(image: CGImage, orientation: CGImagePropertyOrientation) {
        
        // Fetch desired requests based on switch status.
        let requests = [self.coreMLDetectRequest]
        // Create a request handler.
        let imageRequestHandler = VNImageRequestHandler(cgImage: image,
                                                        orientation: orientation,
                                                        options: [:])
        
        // Send the requests to the request handler.
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try imageRequestHandler.perform(requests)
            } catch let error as NSError {
                print("Failed to perform image request: \(error)")
                return
            }
        }
    }
    
    func setupVision() -> NSError? {
        // Setup Vision parts
        
        do {
            let visionModel = try VNCoreMLModel(for: yolo.model)
            let objectRecognition = VNCoreMLRequest(model: visionModel, completionHandler: { (request, error) in
                DispatchQueue.main.async(execute: {
                    // perform all the UI updates on the main queue
                    if let results = request.results {
                    }
                })
            })
            self.requests = [objectRecognition]
        } catch let error as NSError {
            print("Model loading went wrong: \(error)")
        }

        return nil
    }

    lazy var coreMLDetectRequest: VNCoreMLRequest = {
        do {
            let model = try VNCoreMLModel(for: yolo.model)
            let modelDetectRequest = VNCoreMLRequest(model: model, completionHandler: self.handleCoreMLRequest)
            modelDetectRequest.imageCropAndScaleOption = .scaleFit
            return modelDetectRequest
        } catch {
            fatalError("Can't load model")
        }
    }()
    
    func handleCoreMLRequest(request: VNRequest?, error: Error?) {
        if let nsError = error as NSError? {
            return
        }
        // Since handlers are executing on a background thread, explicitly send draw calls to the main thread.
        DispatchQueue.main.async {
            guard let drawLayer = self.pathLayer,
                let results = request?.results as? [VNRecognizedObjectObservation] else {
                    return
            }
            self.draw(interests: results, onImageWithBounds: drawLayer.bounds)
            drawLayer.setNeedsDisplay()
        }
    }
    
    func draw(interests: [VNRecognizedObjectObservation], onImageWithBounds: CGRect ) {
        for observation in interests {
            let rectBox = boundingBox(forRegionOfInterest: observation.boundingBox, withinImageBounds: onImageWithBounds)
            let topConfident = observation.labels[0]
            createButton(name: topConfident.identifier, frame: rectBox)
        }
    }
    
    func updateClassification(for image: UIImage) {
        let orientation = CGImagePropertyOrientation(image.imageOrientation)
        guard let ciImage = CIImage(image: image) else {
            return
        }
        
        DispatchQueue.global(qos: .userInteractive).async {
            let hander = VNImageRequestHandler(ciImage: ciImage, orientation: orientation)
            do {
                try hander.perform(self.requests)
            } catch {
                print("Failed to perform classification.\n\(error.localizedDescription)")
            }
        
        }
    }


    lazy var rectangleDetectionRequest: VNDetectRectanglesRequest = {
        let rectDetectRequest = VNDetectRectanglesRequest(completionHandler: self.handleDetectedRectangles)
        // Customize & configure the request to detect only certain rectangles.
        rectDetectRequest.maximumObservations = 8 // Vision currently supports up to 16.
        rectDetectRequest.minimumConfidence = 0.6 // Be confident.
        rectDetectRequest.minimumAspectRatio = 0.3 // height / width
        return rectDetectRequest
    }()
    
    
}

//MARK: - VISION

extension ResultViewController {
    
    // tags: scale image first
    func scaleAndOrient(image: UIImage) -> UIImage {
        
        // Set a default value for limiting image size.
        let maxResolution: CGFloat = 640
        
        guard let cgImage = image.cgImage else {
            print("UIImage has no CGImage backing it!")
            return image
        }
        
        // Compute parameters for transform.
        let width = CGFloat(cgImage.width)
        let height = CGFloat(cgImage.height)
        var transform = CGAffineTransform.identity
        
        var bounds = CGRect(x: 0, y: 0, width: width, height: height)
        
        if width > maxResolution ||
            height > maxResolution {
            let ratio = width / height
            if width > height {
                bounds.size.width = maxResolution
                bounds.size.height = round(maxResolution / ratio)
            } else {
                bounds.size.width = round(maxResolution * ratio)
                bounds.size.height = maxResolution
            }
        }
        
        let scaleRatio = bounds.size.width / width
        let orientation = image.imageOrientation
        switch orientation {
        case .up:
            transform = .identity
        case .down:
            transform = CGAffineTransform(translationX: width, y: height).rotated(by: .pi)
        case .left:
            let boundsHeight = bounds.size.height
            bounds.size.height = bounds.size.width
            bounds.size.width = boundsHeight
            transform = CGAffineTransform(translationX: 0, y: width).rotated(by: 3.0 * .pi / 2.0)
        case .right:
            let boundsHeight = bounds.size.height
            bounds.size.height = bounds.size.width
            bounds.size.width = boundsHeight
            transform = CGAffineTransform(translationX: height, y: 0).rotated(by: .pi / 2.0)
        case .upMirrored:
            transform = CGAffineTransform(translationX: width, y: 0).scaledBy(x: -1, y: 1)
        case .downMirrored:
            transform = CGAffineTransform(translationX: 0, y: height).scaledBy(x: 1, y: -1)
        case .leftMirrored:
            let boundsHeight = bounds.size.height
            bounds.size.height = bounds.size.width
            bounds.size.width = boundsHeight
            transform = CGAffineTransform(translationX: height, y: width).scaledBy(x: -1, y: 1).rotated(by: 3.0 * .pi / 2.0)
        case .rightMirrored:
            let boundsHeight = bounds.size.height
            bounds.size.height = bounds.size.width
            bounds.size.width = boundsHeight
            transform = CGAffineTransform(scaleX: -1, y: 1).rotated(by: .pi / 2.0)
        }
        
        return UIGraphicsImageRenderer(size: bounds.size).image { rendererContext in
            let context = rendererContext.cgContext
            
            if orientation == .right || orientation == .left {
                context.scaleBy(x: -scaleRatio, y: scaleRatio)
                context.translateBy(x: -height, y: 0)
            } else {
                context.scaleBy(x: scaleRatio, y: -scaleRatio)
                context.translateBy(x: 0, y: -height)
            }
            context.concatenate(transform)
            context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        }
    }
    
    // tags: preparing layer to draw
    func show(_ image: UIImage) {
        
        // Remove previous paths & image
        pathLayer?.removeFromSuperlayer()
        pathLayer = nil
        imageView.image = nil
        
        // Account for image orientation by transforming view.
        let correctedImage = scaleAndOrient(image: image)
        
        // Place photo inside imageView.
        imageView.image = correctedImage
        
        // Transform image to fit screen.
        guard let cgImage = correctedImage.cgImage else {
            print("Trying to show an image not backed by CGImage!")
            return
        }
        
        let fullImageWidth = CGFloat(cgImage.width)
        let fullImageHeight = CGFloat(cgImage.height)
        
        let imageFrame = imageView.frame
        let widthRatio = fullImageWidth / imageFrame.width
        let heightRatio = fullImageHeight / imageFrame.height
        
        // ScaleAspectFit: The image will be scaled down according to the stricter dimension.
        let scaleDownRatio = max(widthRatio, heightRatio)
        
        // Cache image dimensions to reference when drawing CALayer paths.
        imageWidth = fullImageWidth / scaleDownRatio
        imageHeight = fullImageHeight / scaleDownRatio
        
        // Prepare pathLayer to hold Vision results.
        let xLayer = (imageFrame.width - imageWidth) / 2
        let yLayer = imageView.frame.minY + (imageFrame.height - imageHeight) / 2
        let drawingLayer = CALayer()
        drawingLayer.bounds = CGRect(x: xLayer, y: yLayer, width: imageWidth, height: imageHeight)
        drawingLayer.anchorPoint = CGPoint.zero
        drawingLayer.position = CGPoint(x: xLayer, y: yLayer)
        drawingLayer.opacity = 0.5
        pathLayer = drawingLayer
        imageView.isUserInteractionEnabled = true
    }
    
    // tags: rectangle request handler
    fileprivate func handleDetectedRectangles(request: VNRequest?, error: Error?) {
        if let nsError = error as NSError? {
            return
        }
        // Since handlers are executing on a background thread, explicitly send draw calls to the main thread.
        DispatchQueue.main.async {
            guard let drawLayer = self.pathLayer,
                let results = request?.results as? [VNRectangleObservation] else {
                    return
            }
            self.draw(rectangles: results, onImageWithBounds: drawLayer.bounds)
            drawLayer.setNeedsDisplay()
        }
    }
    
    // tags: draw rectangle based on requests
    fileprivate func draw(rectangles: [VNRectangleObservation], onImageWithBounds bounds: CGRect) {
        CATransaction.begin()
        for observation in rectangles {
            let rectBox = boundingBox(forRegionOfInterest: observation.boundingBox, withinImageBounds: bounds)
            let rectLayer = shapeLayer(color: .blue, frame: rectBox)
            
            // Add to pathLayer on top of image.
            pathLayer?.addSublayer(rectLayer)
        }
        CATransaction.commit()
    }
    
    // tags: give the bounding box rect for the shapelayer
    fileprivate func boundingBox(forRegionOfInterest: CGRect, withinImageBounds bounds: CGRect) -> CGRect {
        
        let imageWidth = bounds.width
        let imageHeight = bounds.height
        
        // Begin with input rect.
        var rect = forRegionOfInterest
        
        // Reposition origin.
        rect.origin.x *= imageWidth
        rect.origin.x += bounds.origin.x
        rect.origin.y = (1 - rect.origin.y) * imageHeight + bounds.origin.y
        
        // Rescale normalized coordinates.
        rect.size.width *= imageWidth
        rect.size.height *= imageHeight
        return rect
    }
    
    // tags: draw the shapelayer after draw
    fileprivate func shapeLayer(color: UIColor, frame: CGRect) -> CAShapeLayer {
        // Create a new layer.
        let layer = CAShapeLayer()
        
        // Configure layer's appearance.
        layer.fillColor = nil // No fill to show boxed object
        layer.shadowOpacity = 0
        layer.shadowRadius = 0
        layer.borderWidth = 2
        
        // Vary the line color according to input.
        layer.borderColor = color.cgColor
        
        // Locate the layer.
        layer.anchorPoint = .zero
        layer.frame = frame
        layer.masksToBounds = true
        
        // Transform the layer to have same coordinate system as the imageView underneath it.
        layer.transform = CATransform3DMakeScale(1, -1, 1)
        
        let button = UIButton(frame: layer.frame)
        button.backgroundColor = .clear
        button.layer.borderColor = UIColor.blue.cgColor
        button.layer.borderWidth = 2
        button.transform3D = layer.transform
        imageView.addSubview(button)
        
        return layer
    }
    
    fileprivate func createButton(name: String, frame: CGRect) {
        // Create a new layer.
        let layer = CAShapeLayer()
        layer.anchorPoint = .zero
        layer.frame = frame
        // Transform the layer to have same coordinate system as the imageView underneath it.
        layer.transform = CATransform3DMakeScale(1, -1, 1)
        
        let detectionButton = DetectionButton(frame: layer.frame)
        detectionButton.setTitle(name, for: .normal)
        detectionButton.transform3D = layer.transform
        detectionButton.addTarget(self, action: #selector(startQuery(button:)), for: .touchUpInside)
        imageView.addSubview(detectionButton)
    }
}


//MARK: - Setup UIs functions
extension ResultViewController {
    
    private func setupUI() {
        view.addSubview(resultView)
        resultView.insertSubview(imageView, belowSubview: resultView.timeStampView)
        resultView.timeStampTitle.text = "Not Searching"
        let panGesture = UIPanGestureRecognizer()
        panGesture.addTarget(self, action: #selector(resultViewSwiped(gesture:)))
        resultView.timeStampView.addGestureRecognizer(panGesture)
    }
    
    private func setupTableView() {
        linkPreviewTableView.register(LinkPreviewCell.self, forCellReuseIdentifier: "urlCell")
        linkPreviewTableView.dataSource = self
        linkPreviewTableView.rowHeight = 200
        linkPreviewTableView.separatorStyle = .none
        resultView.timeStampView.addSubview(linkPreviewTableView)
    }
    
    private func configTimeStampView() {
        let tableViewFrame = CGRect(x: 0, y: resultView.timeStampView.frame.height * 0.08, width: resultView.timeStampView.frame.width, height: resultView.safeAreaLayoutGuide.layoutFrame.height * 0.85)
        linkPreviewTableView.frame = tableViewFrame
    }
    
    private func getOneMetadata(url: URL, index: IndexPath) {
        let provider = LPMetadataProvider()
        provider.startFetchingMetadata(for: url) { (data, error) in
            if error != nil {
                return
            }
            
            DispatchQueue.main.async {
                guard let cell = self.linkPreviewTableView.cellForRow(at: index) as? LinkPreviewCell else {
                    return
                }
                cell.loading.stopAnimating()
                let linkView = data != nil ? LPLinkView(metadata: data!) : LPLinkView(url: url)
                linkView.frame = cell.contentView.bounds
                cell.linkPreview = linkView
            }
        }
    }
}

//MARK: - OBJC functions
extension ResultViewController {
    
    @objc private func resultViewSwiped(gesture: UIPanGestureRecognizer) {
        resultView.viewDragged(gesture: gesture)
    }
    
    @objc private func startQuery(button: DetectionButton) {
        if !self.urls.isEmpty {
            self.urls = []
            DispatchQueue.main.async {
                self.linkPreviewTableView.reloadData()
            }
        }
        guard let name = button.titleLabel?.text else {
            #if DEBUG
            print("There's no title")
            #endif
            self.urls = []
            DispatchQueue.main.async {
                self.resultView.timeStampTitle.text = "Not Searching"
                self.linkPreviewTableView.reloadData()
            }
            return
        }
        resultView.timeStampTitle.text = "How to repurpose \(name)"
        manager.searchApi(item_name: name) { (result) in
            switch result {
            case let .success(model):
                self.urls = model.compactMap{ URL(string: $0.link) }
                DispatchQueue.main.async {
                    self.linkPreviewTableView.reloadData()
                }
            case let .failure(error):
                #if DEBUG
                print(error.localizedDescription)
                #endif
                self.urls = []
                DispatchQueue.main.async {
                    self.linkPreviewTableView.reloadData()
                }
            }
        }
    }
}

// MARK: - TableViewDataSource
extension ResultViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        tableView.backgroundView = urls.isEmpty ? EmptyView() : nil
        return urls.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "urlCell", for: indexPath) as? LinkPreviewCell else {
            return UITableViewCell()
        }

        
        getOneMetadata(url: urls[indexPath.row], index: indexPath)
        return cell
    }
}
