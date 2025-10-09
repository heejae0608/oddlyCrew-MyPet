import SwiftUI
import UIKit

struct PetFormData {
    static let speciesOptions = ["강아지", "고양이"]
    static let genderOptions = ["수컷", "암컷"]

    var name: String = ""
    var species: String = PetFormData.speciesOptions.first ?? ""
    var breed: String = ""
    var gender: String = PetFormData.genderOptions.first ?? ""
    var isNeutered: Bool = false
    var weight: String = ""
    var existingConditions: String = ""
    var profileImage: UIImage?
    var profileImageData: String?
    var birthDate: Date = Date()
    var adoptionDate: Date = Date()

    init() { }

    init(pet: Pet) {
        name = pet.name
        species = pet.species
        breed = pet.breed ?? ""
        gender = pet.gender
        isNeutered = pet.isNeutered
        if let petWeight = pet.weight {
            weight = Self.format(weight: petWeight)
        }
        existingConditions = pet.existingConditions ?? ""
        birthDate = pet.birthDate ?? Date()
        adoptionDate = pet.adoptionDate ?? pet.birthDate ?? Date()
        profileImageData = pet.profileImageData
        if let data = pet.decodedProfileImageData,
           let image = UIImage(data: data) {
            profileImage = image
        }
    }

    var isValid: Bool {
        name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
    }

    func makePet(userId: UUID) -> Pet {
        let sanitizedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let sanitizedBreed = breed.trimmingCharacters(in: .whitespacesAndNewlines)
        let sanitizedConditions = existingConditions.trimmingCharacters(in: .whitespacesAndNewlines)

        let normalizedWeight = weight
            .replacingOccurrences(of: ",", with: ".")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let numericWeight = Double(normalizedWeight)
        let finalWeight = (numericWeight ?? 0) > 0 ? numericWeight : nil

        let now = Date()
        let normalizedBirth = min(birthDate, now)
        let normalizedAdoption = min(max(normalizedBirth, adoptionDate), now)

        return Pet(
            userId: userId,
            name: sanitizedName,
            species: species,
            breed: sanitizedBreed.isEmpty ? nil : sanitizedBreed,
            gender: gender,
            isNeutered: isNeutered,
            weight: finalWeight,
            profileImageData: profileImageData,
            existingConditions: sanitizedConditions.isEmpty ? nil : sanitizedConditions,
            birthDate: normalizedBirth,
            adoptionDate: normalizedAdoption
        )
    }

    func applying(to pet: Pet) -> Pet {
        var updated = pet
        let sanitizedBreed = breed.trimmingCharacters(in: .whitespacesAndNewlines)
        let sanitizedConditions = existingConditions.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedWeight = weight
            .replacingOccurrences(of: ",", with: ".")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let numericWeight = Double(normalizedWeight)
        let finalWeight = (numericWeight ?? 0) > 0 ? numericWeight : nil
        let now = Date()
        let normalizedBirth = min(birthDate, now)
        let normalizedAdoption = min(max(normalizedBirth, adoptionDate), now)

        updated.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        updated.species = species
        updated.breed = sanitizedBreed.isEmpty ? nil : sanitizedBreed
        updated.gender = gender
        updated.isNeutered = isNeutered
        updated.weight = finalWeight
        updated.existingConditions = sanitizedConditions.isEmpty ? nil : sanitizedConditions
        updated.birthDate = normalizedBirth
        updated.adoptionDate = normalizedAdoption
        updated.profileImageData = profileImageData

        return updated
    }

    mutating func setImage(_ image: UIImage) {
        let resized = image.resizedToFit(maxDimension: 512)
        profileImage = resized
        profileImageData = resized.jpegData(compressionQuality: 0.7)?.base64EncodedString()
    }

    private static func format(weight: Double) -> String {
        let formatter = NumberFormatter()
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 1
        return formatter.string(from: NSNumber(value: weight)) ?? String(weight)
    }
}

private extension UIImage {
    func resizedToFit(maxDimension: CGFloat) -> UIImage {
        let largestSide = max(size.width, size.height)
        guard largestSide > maxDimension else { return self }

        let scale = maxDimension / largestSide
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)

        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            self.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}
