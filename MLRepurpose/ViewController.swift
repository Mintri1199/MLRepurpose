//
//  ViewController.swift
//  MLRepurpose
//
//  Created by Jackson Ho on 1/7/20.
//  Copyright © 2020 Jackson Ho. All rights reserved.
//

import UIKit


class ViewController: UIViewController {
    
    private lazy var cameraButton: UIButton = {
        var button = UIButton(frame: .zero)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Take a Picture", for: .normal)
        button.setTitleColor(.blue, for: .normal)
        button.layer.cornerRadius = 10
        button.layer.borderWidth = 5
        button.layer.borderColor = UIColor.blue.cgColor
        return button
    }()
    private lazy var pickerButton: UIButton = {
        var button = UIButton(frame: .zero)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Choose a Picture", for: .normal)
        button.setTitleColor(.blue, for: .normal)
        button.layer.cornerRadius = 10
        button.layer.borderWidth = 5
        button.layer.borderColor = UIColor.blue.cgColor
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        view.backgroundColor = .white
        setupUI()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.navigationBar.isHidden = true
    }

}

//MARK: - Setup UI functions
extension ViewController {
    private func setupUI() {
        let stackView = UIStackView(frame: .zero)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.distribution = .fillEqually
        stackView.axis = .vertical
        stackView.spacing = 30
        stackView.addArrangedSubview(cameraButton)
        stackView.addArrangedSubview(pickerButton)

        view.addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.widthAnchor.constraint(equalToConstant: view.bounds.width / 2.5),
            stackView.heightAnchor.constraint(equalToConstant: view.bounds.width / 2),
            stackView.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor),
        ])

        cameraButton.addTarget(self, action: #selector(showCamera), for: .touchUpInside)
        pickerButton.addTarget(self, action: #selector(showPicker), for: .touchUpInside)
    }
    
    private func presentPhotoPicker(sourceType: UIImagePickerController.SourceType) {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = sourceType
        present(picker, animated: true)
    }
}

//MARK: - @Objc functions
extension ViewController {
    
    @objc private func showCamera() {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            return
        }
        let cameraController = UIImagePickerController()
        cameraController.delegate = self
        cameraController.sourceType = .camera
        present(cameraController, animated: true, completion: nil)
    }
    
    @objc private func showPicker() {
        let pickerController = UIImagePickerController()
        pickerController.sourceType = .photoLibrary
        pickerController.modalPresentationStyle = .popover
        pickerController.delegate = self 
        present(pickerController, animated: true, completion: nil)
    }
}

//MARK: - ImagePickerDelegate
extension ViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        return
    }
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        guard let image = info[.originalImage] as? UIImage  else {
            return
        }
        let resultVC = ResultViewController()
        resultVC.show(image)
        
        let cgOrientation = CGImagePropertyOrientation(image.imageOrientation)
        
        resultVC.performVisionRequest(image: image.cgImage!, orientation: cgOrientation)
        picker.dismiss(animated: true, completion: nil)
        self.navigationController?.pushViewController(resultVC, animated: true)
    }
}
