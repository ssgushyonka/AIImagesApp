import Foundation
import UIKit

class ImageHelper {
    static func decodeDisplayImage(base64Image: String, imageView: UIImageView, activivtyIndicator: UIActivityIndicatorView?, button: UIButton?) {
        if let imageData = Data(base64Encoded: base64Image), let image = UIImage(data: imageData) {
            DispatchQueue.main.async {
                imageView.image = image
                activivtyIndicator?.stopAnimating()
                button?.isEnabled = true
            }
        } else {
            print("Не удалось декодировать изображение")
            DispatchQueue.main.async {
                activivtyIndicator?.stopAnimating()
                button?.isEnabled = true
            }
        }
    }
}
