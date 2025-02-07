import UIKit
import Foundation

class APIService {
    static let shared = APIService(); private init() {}
    
     var apiKey: String = ""
     var apiSecretKey: String = ""
    
    func setApiKeys(key: String, secret: String) {
        self.apiKey = key
        self.apiSecretKey = secret
        print("Введены api ключи.")
    }
     //let apiKey = "E5D0AABD6EB76ADDE0A8574037752B0E"
     let baseURL = "https://api-key.fusionbrain.ai/key/api/v1"
    
    
    func generateImage(query: String, completion: @escaping (Result<String, Error>) -> Void) {
        let url = URL(string: "\(baseURL)/text2image/run")!
        
        let params: [String: Any] = [
            "type": "GENERATE",
            "style": "string",
            "width": 1024,
            "height": 1024,
            "num_images": 1,
            "negativePromptUnclip": "яркие цвета, кислотность, высокая контрастность",
            "generateParams": [
                "query": query
            ]
        ]
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: params, options: []),
              let jsonString = String(data: jsonData, encoding: .utf8) else {
            completion(.failure(NSError(domain: "Invalid JSON", code: -1, userInfo: nil)))
            return
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Key \(apiKey)", forHTTPHeaderField: "X-Key")
        request.setValue("Secret \(apiSecretKey)", forHTTPHeaderField: "X-Secret")
        
        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"params\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: application/json\r\n\r\n".data(using: .utf8)!)
        body.append(jsonData)
        body.append("\r\n".data(using: .utf8)!)
        
        // Добавляем model_id
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"model_id\"\r\n\r\n".data(using: .utf8)!)
        body.append("4\r\n".data(using: .utf8)!)
        
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "No data", code: -1, userInfo: nil)))
                return
            }
            
            // Логирование ответа
            if let jsonString = String(data: data, encoding: .utf8) {
                print("Ответ сервера: \(jsonString)")
            }
            
            do {
                let response = try JSONDecoder().decode(GenerateImageResponse.self, from: data)
                completion(.success(response.uuid))
            } catch {
                print("Ошибка декодирования: \(error.localizedDescription)")
                completion(.failure(error))
            }
        }
        task.resume()
    }
    func checkImageStatus(uuid: String, completion: @escaping (Result<ImageStatusResponse, Error>) -> Void) {
        let url = URL(string: "\(baseURL)/text2image/status/\(uuid)")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Key \(apiKey)", forHTTPHeaderField: "X-Key")
        request.setValue("Secret \(apiSecretKey)", forHTTPHeaderField: "X-Secret")
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "No data", code: -1, userInfo: nil)))
                return
            }
            
            do {
                let decoder = JSONDecoder()
                let responce = try decoder.decode(ImageStatusResponse.self, from: data)
            } catch {
                completion(.failure(error))
            }
        }
        task.resume()
    }
}
