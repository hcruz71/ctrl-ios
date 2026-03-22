import SwiftUI

struct GanttChartView: View {
    let tasks: [CTRLTask]
    private let ptPerDay: CGFloat = 40
    private let rowHeight: CGFloat = 36
    private let labelWidth: CGFloat = 120
    private let headerHeight: CGFloat = 40

    private let df: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    private var dateRange: (min: Date, max: Date) {
        let today = Date()
        let cal = Calendar.current
        var earliest = cal.date(byAdding: .weekOfYear, value: -2, to: today)!
        var latest = cal.date(byAdding: .weekOfYear, value: 2, to: today)!

        for task in tasks {
            if let s = task.startDate, let d = df.date(from: s) {
                earliest = min(earliest, d)
            }
            if let e = task.dueDate, let d = df.date(from: e) {
                latest = max(latest, d)
            }
        }
        // Add padding
        earliest = cal.date(byAdding: .day, value: -3, to: earliest)!
        latest = cal.date(byAdding: .day, value: 7, to: latest)!
        return (earliest, latest)
    }

    private var totalDays: Int {
        let cal = Calendar.current
        return max(1, cal.dateComponents([.day], from: dateRange.min, to: dateRange.max).day ?? 28)
    }

    private var totalWidth: CGFloat {
        CGFloat(totalDays) * ptPerDay
    }

    var body: some View {
        if tasks.isEmpty {
            VStack(spacing: 8) {
                Image(systemName: "chart.gantt")
                    .font(.system(size: 36))
                    .foregroundStyle(.secondary)
                Text("Agrega tareas con fechas para ver el diagrama")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            ScrollView([.horizontal, .vertical]) {
                ZStack(alignment: .topLeading) {
                    // Date header
                    dateHeader

                    // Grid lines
                    gridLines

                    // Today line
                    todayLine

                    // Task bars
                    taskBars
                }
                .frame(
                    width: labelWidth + totalWidth,
                    height: headerHeight + CGFloat(tasks.count) * rowHeight + 20
                )
            }
        }
    }

    // MARK: - Date Header

    private var dateHeader: some View {
        let range = dateRange
        let cal = Calendar.current
        let dayFmt = DateFormatter()
        dayFmt.dateFormat = "d"
        let monthFmt = DateFormatter()
        monthFmt.dateFormat = "MMM"
        monthFmt.locale = Locale(identifier: "es_MX")

        return ForEach(0..<totalDays, id: \.self) { dayIdx in
            let date = cal.date(byAdding: .day, value: dayIdx, to: range.min)!
            let x = labelWidth + CGFloat(dayIdx) * ptPerDay
            let isMonday = cal.component(.weekday, from: date) == 2

            VStack(spacing: 0) {
                if isMonday || dayIdx == 0 {
                    Text(monthFmt.string(from: date))
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
                Text(dayFmt.string(from: date))
                    .font(.caption2.bold())
                    .foregroundStyle(cal.isDateInToday(date) ? .blue : .secondary)
            }
            .frame(width: ptPerDay, height: headerHeight)
            .position(x: x + ptPerDay / 2, y: headerHeight / 2)
        }
    }

    // MARK: - Grid

    private var gridLines: some View {
        let cal = Calendar.current
        let range = dateRange

        return ForEach(0..<totalDays, id: \.self) { dayIdx in
            let date = cal.date(byAdding: .day, value: dayIdx, to: range.min)!
            let isWeekend = cal.isDateInWeekend(date)
            let x = labelWidth + CGFloat(dayIdx) * ptPerDay

            Rectangle()
                .fill(isWeekend ? Color.gray.opacity(0.06) : .clear)
                .frame(width: ptPerDay, height: CGFloat(tasks.count) * rowHeight)
                .position(
                    x: x + ptPerDay / 2,
                    y: headerHeight + CGFloat(tasks.count) * rowHeight / 2
                )

            // Vertical grid line
            Rectangle()
                .fill(Color.gray.opacity(0.1))
                .frame(width: 0.5, height: CGFloat(tasks.count) * rowHeight)
                .position(x: x, y: headerHeight + CGFloat(tasks.count) * rowHeight / 2)
        }
    }

    // MARK: - Today Line

    private var todayLine: some View {
        let cal = Calendar.current
        let daysFromMin = cal.dateComponents([.day], from: dateRange.min, to: Date()).day ?? 0
        let x = labelWidth + CGFloat(daysFromMin) * ptPerDay

        return Rectangle()
            .fill(.blue)
            .frame(width: 2, height: headerHeight + CGFloat(tasks.count) * rowHeight)
            .position(x: x, y: (headerHeight + CGFloat(tasks.count) * rowHeight) / 2)
    }

    // MARK: - Task Bars

    private var taskBars: some View {
        let cal = Calendar.current
        let range = dateRange

        return ForEach(Array(tasks.enumerated()), id: \.element.id) { idx, task in
            let y = headerHeight + CGFloat(idx) * rowHeight + rowHeight / 2

            // Label
            Text(task.title)
                .font(.caption)
                .lineLimit(1)
                .frame(width: labelWidth - 8, alignment: .trailing)
                .position(x: labelWidth / 2, y: y)

            // Bar
            let taskStart: Date = {
                if let s = task.startDate, let d = df.date(from: s) { return d }
                if let d = task.dueDate, let dt = df.date(from: d) { return dt }
                return Date()
            }()
            let taskEnd: Date = {
                if let d = task.dueDate, let dt = df.date(from: d) { return dt }
                return cal.date(byAdding: .day, value: 1, to: taskStart)!
            }()

            let startDays = CGFloat(cal.dateComponents([.day], from: range.min, to: taskStart).day ?? 0)
            let durDays = CGFloat(max(1, cal.dateComponents([.day], from: taskStart, to: taskEnd).day ?? 1))
            let barX = labelWidth + startDays * ptPerDay
            let barW = max(durDays * ptPerDay, 20)

            RoundedRectangle(cornerRadius: 4)
                .fill(barColor(task))
                .frame(width: barW, height: rowHeight - 8)
                .overlay(alignment: .leading) {
                    Text(task.title)
                        .font(.caption2.bold())
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .padding(.leading, 4)
                }
                .position(x: barX + barW / 2, y: y)
        }
    }

    private func barColor(_ task: CTRLTask) -> Color {
        if task.isDelegated == true { return .blue }
        switch task.priorityLevel {
        case "A": return .red
        case "B": return .orange
        case "C": return .blue.opacity(0.7)
        default: return .gray
        }
    }
}
