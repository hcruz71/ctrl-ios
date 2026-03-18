import SwiftUI

struct ContactRowView: View {
    let contact: Contact

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "person.crop.circle.fill")
                .font(.title2)
                .foregroundStyle(Color.ctrlPurple)

            VStack(alignment: .leading, spacing: 4) {
                Text(contact.name)
                    .font(.headline)
                    .lineLimit(1)

                if let company = contact.company, !company.isEmpty {
                    HStack(spacing: 6) {
                        BadgeView(text: company, color: .ctrlPurple)
                        if let role = contact.role, !role.isEmpty {
                            BadgeView(text: role, color: .ctrlBlue)
                        }
                    }
                }

                HStack(spacing: 12) {
                    if let email = contact.email, !email.isEmpty {
                        Label(email, systemImage: "envelope")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                    if let phone = contact.phone, !phone.isEmpty {
                        Label(phone, systemImage: "phone")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    ContactRowView(contact: Contact(
        id: UUID(),
        name: "Juan Perez",
        email: "juan@email.com",
        phone: "555-1234",
        company: "Coppel",
        role: "PM",
        createdAt: nil,
        updatedAt: nil
    ))
}
