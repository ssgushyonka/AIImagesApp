//
//  ViewController.swift
//  AIImages
//
//  Created by Элина Борисова on 07.02.2025.
//

import UIKit

class ViewController: UIViewController {

    //MARK: - UI Components
    
    private let imageView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFit
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let generateButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Сгенерировать изображение", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 8
        button.backgroundColor = .systemBlue
        button.addTarget(self, action: #selector(generateButtonTapped), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    private let apiKeyTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "Введите API Key"
        textField.borderStyle = .roundedRect
        textField.textAlignment = .center
        textField.translatesAutoresizingMaskIntoConstraints = false
        return textField
    }()
    
    private let secretKeyTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "Введите Secret Key"
        textField.borderStyle = .roundedRect
        textField.textAlignment = .center
        textField.translatesAutoresizingMaskIntoConstraints = false
        return textField
    }()
    private let activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.translatesAutoresizingMaskIntoConstraints = false
        return indicator
    }()
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupView()
        setupConstraints()
    }

    //MARK: - Setup Views and Constraints
    
    private func setupView() {
        view.addSubview(imageView)
        view.addSubview(generateButton)
        view.addSubview(activityIndicator)
        view.addSubview(apiKeyTextField)
        view.addSubview(secretKeyTextField)
        view.bringSubviewToFront(activityIndicator)
    }
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            imageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            imageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            imageView.widthAnchor.constraint(equalToConstant: 300),
            imageView.heightAnchor.constraint(equalToConstant: 300),
            
            apiKeyTextField.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 30),
            apiKeyTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            apiKeyTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            apiKeyTextField.heightAnchor.constraint(equalToConstant: 40),
            
            secretKeyTextField.topAnchor.constraint(equalTo: apiKeyTextField.bottomAnchor, constant: 15),
            secretKeyTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            secretKeyTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            secretKeyTextField.heightAnchor.constraint(equalToConstant: 40),
            
            activityIndicator.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 200),
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            generateButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            generateButton.heightAnchor.constraint(equalToConstant: 50),
            generateButton.widthAnchor.constraint(equalToConstant: 265),
            generateButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
        ])
    }
}

extension ViewController {
    @objc func generateButtonTapped() {
        print("Generate button tapped")
        
        guard let apiKey = apiKeyTextField.text, !apiKey.isEmpty,
              let apiSecret = secretKeyTextField.text, !apiSecret.isEmpty else {
            print("Ошибка, ключи не введены")
            return
        }
        
        APIService.shared.setApiKeys(key: apiKey, secret: apiSecret)
        print("Ключи успешно введены")
        
        activityIndicator.startAnimating()
        generateButton.isEnabled = false

        APIService.shared.generateImage(query: "Собачка с бантиком") { [weak self] result in
            switch result {
            case .success(let uuid):
                self?.checkImageStatus(uuid: uuid)
            case .failure(let error):
                print("Ошибка при генерации изображения: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self?.activityIndicator.stopAnimating()
                    self?.generateButton.isEnabled = true
                }
            }
        }
    }
}

extension ViewController {
    
    func checkImageStatus(uuid: String) {
        let statusURL = URL(string: "\(APIService.shared.baseURL)/text2image/status/\(uuid)")!
        
        var request = URLRequest(url: statusURL)
        request.httpMethod = "GET"
        request.setValue("Key \(APIService.shared.apiKey)", forHTTPHeaderField: "X-Key")
        request.setValue("Secret \(APIService.shared.apiSecretKey)", forHTTPHeaderField: "X-Secret")
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Ошибка при проверке статуса: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.activityIndicator.stopAnimating()
                    self.generateButton.isEnabled = true
                }
                return
            }
            
            guard let data = data else {
                print("Ошибка: данные отсутствуют")
                DispatchQueue.main.async {
                    self.activityIndicator.stopAnimating()
                    self.generateButton.isEnabled = true
                }
                return
            }
            
            if let jsonString = String(data: data, encoding: .utf8) {
                print("Ответ сервера: \(jsonString)")
            }
            
            do {
                let response = try JSONDecoder().decode(ImageStatusResponse.self, from: data)
                print("Статус: \(response.status)")
                
                switch response.status {
                case "DONE":
                    if let base64Image = response.images?.first {
                        ImageHelper.decodeDisplayImage(
                            base64Image: base64Image,
                            imageView: self.imageView,
                            activivtyIndicator: self.activityIndicator,
                            button: self.generateButton
                        )
                    } else {
                        print("Изображение отсутствует в ответе")
                        DispatchQueue.main.async {
                            self.activityIndicator.stopAnimating()
                            self.generateButton.isEnabled = true
                        }
                    }
                case "INITIAL":
                    DispatchQueue.global().asyncAfter(deadline: .now() + 15) {
                        self.checkImageStatus(uuid: uuid)
                    }
                default:
                    print("Неизвестный статус: \(response.status)")
                    DispatchQueue.main.async {
                        self.activityIndicator.stopAnimating()
                        self.generateButton.isEnabled = true
                    }
                }
            } catch {
                print("Ошибка декодирования: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.activityIndicator.stopAnimating()
                    self.generateButton.isEnabled = true
                }
            }
        }
        task.resume()
    }
    
    func fetchGeneratedImage(uuid: String) {
        let imageURL = URL(string: "\(APIService.shared.baseURL)/text2image/status/\(uuid)")!
        
        var request = URLRequest(url: imageURL)
        request.httpMethod = "GET"
        request.setValue("Key \(APIService.shared.apiKey)", forHTTPHeaderField: "X-Key")
        request.setValue("Secret \(APIService.shared.apiSecretKey)", forHTTPHeaderField: "X-Secret")
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Ошибка при получении изображения: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.activityIndicator.stopAnimating()
                    self.generateButton.isEnabled = true
                }
                return
            }
            
            guard let data = data else {
                print("Ошибка: данные отсутствуют")
                DispatchQueue.main.async {
                    self.activityIndicator.stopAnimating()
                    self.generateButton.isEnabled = true
                }
                return
            }
            
            do {
                let response = try JSONDecoder().decode(ImageStatusResponse.self, from: data)
                if let base64Image = response.images?.first {
                    ImageHelper.decodeDisplayImage(
                        base64Image: base64Image,
                        imageView: self.imageView,
                        activivtyIndicator: self.activityIndicator,
                        button: self.generateButton
                    )
                } else {
                    print("Изображение отсутствует в ответе")
                    DispatchQueue.main.async {
                        self.activityIndicator.stopAnimating()
                        self.generateButton.isEnabled = true
                    }
                }
            } catch {
                print("Ошибка декодирования: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.activityIndicator.stopAnimating()
                    self.generateButton.isEnabled = true
                }
            }
        }
        task.resume()
    }
}
