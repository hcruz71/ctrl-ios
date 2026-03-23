import SwiftUI
import MessageUI

struct MailComposeView: UIViewControllerRepresentable {
    let recipient: String
    let subject: String
    let body: String
    var onDismiss: (Bool) -> Void

    func makeUIViewController(context: Context) -> MFMailComposeViewController {
        let vc = MFMailComposeViewController()
        vc.setToRecipients([recipient])
        vc.setSubject(subject)
        vc.setMessageBody(body, isHTML: false)
        vc.mailComposeDelegate = context.coordinator
        return vc
    }

    func updateUIViewController(_ uiViewController: MFMailComposeViewController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(onDismiss: onDismiss) }

    class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        let onDismiss: (Bool) -> Void
        init(onDismiss: @escaping (Bool) -> Void) { self.onDismiss = onDismiss }

        func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
            let sent = result == .sent
            controller.dismiss(animated: true) { [self] in
                onDismiss(sent)
            }
        }
    }
}
