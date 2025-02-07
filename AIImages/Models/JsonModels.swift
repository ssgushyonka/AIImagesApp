
import Foundation

struct GenerateParams: Codable {
    let query: String
}

struct GenerateImageRequest: Codable {
    let type: String
    let style: String
    let width: Int
    let height: Int
    let numImages: Int
    let negativePromptUnclip: String?
    let generateParams: GenerateParams
   // let modelId: Int
    
    enum CodingKeys: String, CodingKey {
        case type, style, width, height
        case numImages = "num_images"
        case negativePromptUnclip, generateParams
        //case modelId = "model_id"
    }
}


// Структура для post запроса со статусом (DONE, INITIAL)
struct GenerateImageResponse: Codable {
    let uuid: String
    let status: String
    let statusTime: Int
    
    enum CodingKeys: String, CodingKey {
        case status, uuid
        case statusTime = "status_time"
    }
}


// Структура для get запроса
struct ImageStatusResponse: Codable {
    let uuid: String
    let status: String
    let images: [String]?
    let censored: Bool
    let generationTime: Int?
}
