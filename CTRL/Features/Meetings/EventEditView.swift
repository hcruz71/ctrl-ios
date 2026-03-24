import SwiftUI
import EventKit
import EventKitUI

struct EventEditView: UIViewControllerRepresentable {
    var onSave: (String, String, String?) -> Void

    func makeUIViewController(context: Context) -> EKEventEditViewController {
        let store = EKEventStore()
        let event = EKEvent(eventStore: store)
        event.startDate = Date()
        event.endDate = Calendar.current.date(byAdding: .hour, value: 1, to: Date())
        event.calendar = store.defaultCalendarForNewEvents

        let vc = EKEventEditViewController()
        vc.event = event
        vc.eventStore = store
        vc.editViewDelegate = context.coordinator
        return vc
    }

    func updateUIViewController(_ uiViewController: EKEventEditViewController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(onSave: onSave) }

    class Coordinator: NSObject, EKEventEditViewDelegate {
        let onSave: (String, String, String?) -> Void

        init(onSave: @escaping (String, String, String?) -> Void) {
            self.onSave = onSave
        }

        func eventEditViewController(_ controller: EKEventEditViewController, didCompleteWith action: EKEventEditViewAction) {
            if action == .saved, let event = controller.event {
                let df = DateFormatter()
                df.dateFormat = "yyyy-MM-dd"
                let tf = DateFormatter()
                tf.dateFormat = "HH:mm"

                let title = event.title ?? "Reunion"
                let date = df.string(from: event.startDate)
                let time = event.isAllDay ? nil : tf.string(from: event.startDate)

                onSave(title, date, time)
            }
            controller.dismiss(animated: true)
        }
    }
}
