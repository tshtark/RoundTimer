import Foundation

struct WorkoutRecord: Identifiable, Codable {
    let id: UUID
    let date: Date
    let presetName: String
    let totalDuration: TimeInterval
    let roundsCompleted: Int
    let intervalsCompleted: Int

    init(
        id: UUID = UUID(),
        date: Date = Date(),
        presetName: String,
        totalDuration: TimeInterval,
        roundsCompleted: Int,
        intervalsCompleted: Int
    ) {
        self.id = id
        self.date = date
        self.presetName = presetName
        self.totalDuration = totalDuration
        self.roundsCompleted = roundsCompleted
        self.intervalsCompleted = intervalsCompleted
    }

    var formattedDuration: String {
        let total = max(0, Int(totalDuration))
        let hours = total / 3600
        let minutes = (total % 3600) / 60
        let seconds = total % 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else if minutes > 0 {
            return "\(minutes)m \(seconds)s"
        }
        return "\(seconds)s"
    }

    var formattedDate: String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .none
            return formatter.string(from: date)
        }
    }

    var formattedTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }
}
