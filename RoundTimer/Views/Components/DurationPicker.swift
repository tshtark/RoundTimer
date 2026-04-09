import SwiftUI

struct DurationPicker: View {
    let label: String
    @Binding var duration: TimeInterval

    private var minutes: Int {
        Int(duration) / 60
    }

    private var seconds: Int {
        Int(duration) % 60
    }

    var body: some View {
        HStack {
            Text(label)
            Spacer()
            Picker("Minutes", selection: Binding(
                get: { minutes },
                set: { duration = TimeInterval($0 * 60 + seconds) }
            )) {
                ForEach(0..<100, id: \.self) { m in
                    Text("\(m)m").tag(m)
                }
            }
            .pickerStyle(.wheel)
            .frame(width: 80, height: 100)
            .clipped()
            .accessibilityLabel("\(label), minutes")
            .accessibilityValue("\(minutes) minutes")

            Picker("Seconds", selection: Binding(
                get: { seconds },
                set: { duration = TimeInterval(minutes * 60 + $0) }
            )) {
                ForEach(0..<60, id: \.self) { s in
                    Text("\(s)s").tag(s)
                }
            }
            .pickerStyle(.wheel)
            .frame(width: 80, height: 100)
            .clipped()
            .accessibilityLabel("\(label), seconds")
            .accessibilityValue("\(seconds) seconds")
        }
    }
}

#Preview {
    Form {
        DurationPicker(label: "Work", duration: .constant(20))
        DurationPicker(label: "Rest", duration: .constant(10))
    }
}
