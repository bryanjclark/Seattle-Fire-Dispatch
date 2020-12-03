//
//  ListView.swift
//  DispatchSwift
//
//  Created by Bryan Clark on 11/26/20.
//

import SwiftUI
import Fuzi

// NOTE: List of common codes:
// http://web.archive.org/web/20080513221504/http://www.seattle.gov/fire/mr/TypeCode.htm

struct Entry: Identifiable {
    let id: Int
    let isActive: Bool
    let date: Date
    let incidentID: String
    let level: Int
    let units: [String]
    let location: String
    let label: String
    
    var mapIcon: String? {
        func has(_ substrings: [String]) -> Bool {
            let lowercaseLabel = self.label.lowercased()
            return substrings.reduce(false) { (result, string) -> Bool in
                return result || lowercaseLabel.contains(string.lowercased())
            }
        }
        
        if has(["aid response", "medic response"]) {
            return "cross"
        } else if has(["fire"]) {
            return "flame"
        } else if has(["motor vehicle"]) {
            return "car"
        } else if has(["violence"]) {
            return "exclamationmark.shield"
        } else if has(["water"]) {
            return "drop"
        } else if has(["investigate"]) {
            return "magnifyingglass"
        } else if has(["low acuity"]) {
            return "person"
        } else if has(["wires down", "electric"]) {
            return "bolt"
        }
        return nil
    }
}

class SeattleFireDispatchHTMLParser {
    static func parse(data: Data, count: Int) throws -> [Entry] {
        let document = try HTMLDocument(data: data)
        var results = Array<Entry>()
        for row in 0..<count {
            if
                let data = document.body?.firstChild(css: "#row_\(row+1)")?.children,
                let level = data[2].numberValue?.intValue
            {
                let isActive = data[0].rawXML.contains("class=\"active\"")
                let dateString = data[0].stringValue
                // https://www.datetimeformatter.com/how-to-format-date-time-in-swift/
                // "11/25/2020 8:21:21 PM"
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "MM/dd/yyyy h:mm:ss a"
                let date = dateFormatter.date(from: dateString)!

                let incidentID = data[1].stringValue
                let units = Array(data[3].stringValue
                                    .split(separator: " ")
                                    .map { String($0) }
                )
                let location = data[4].stringValue
                let label = data[5].stringValue
                results.append(
                    Entry(
                        id: row,
                        isActive: isActive,
                        date: date,
                        incidentID: incidentID,
                        level: level,
                        units: units,
                        location: location,
                        label: label
                    )
                )
            }
        }
        return results
    }
}

class DataFetcher: ObservableObject {
    static let shared = DataFetcher()
    
    @Published var entries = [Entry]()
    
    func fetch() {
        let url = URL(string: "http://www2.seattle.gov/fire/realtime911/getRecsForDatePub.asp?action=Today&incDate=&rad1=des")!
        URLSession.shared.dataTask(with: url) {(data, response, error) in
            do {
                if let results = data {
                    let results = try SeattleFireDispatchHTMLParser.parse(data: results, count: 200)
                    DispatchQueue.main.async {
                        self.entries = results
                    }
                }
            } catch {
                print(error)
            }
        }.resume()
    }
    
    private init() {
        self.fetch()
    }
}

struct RefreshButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            self.action()
        }) {
            Image(systemName: "arrow.clockwise")
        }
    }
}

fileprivate let activeColor = UIColor.systemGreen

struct ListView: View {
    @ObservedObject var dataFetcher = DataFetcher.shared
    
    var body: some View {
        NavigationView {
            List(dataFetcher.entries) { entry in
                NavigationLink(destination: DetailView(entry: entry)) {
                    VStack(alignment: .leading) {
                        HStack {
                            Text(entry.label)
                                .foregroundColor(entry.isActive ? Color(activeColor) : Color.primary)
                                .bold()
                            Spacer()
                            if let image = entry.mapIcon {
                                Image(systemName: image)
                                    .foregroundColor(entry.isActive ? Color(activeColor) : Color.secondary)
                            }
                            Text(entry.date, style: entry.isActive ? .relative : .time)
                                .foregroundColor(entry.isActive ? Color(activeColor) : Color.secondary)
                                .font(.footnote)
                        }
                        Text(entry.location)
                            .foregroundColor(.gray)
                        HStack {
                            if entry.isActive {
                                Text("Active").foregroundColor(Color(activeColor))
                                Text("•")
                            }
                            Text("Level \(entry.level)")
                            Text("•")
                            Text(entry.units.count == 1 ? "1 unit" : "\(entry.units.count) units")
                        }.foregroundColor(.gray)
                    }
                }
            }
            .listStyle(PlainListStyle())
            .navigationBarItems(trailing: RefreshButton(action: self.dataFetcher.fetch))
            .navigationTitle("Seattle Fire Dispatch")
        }
    }
}

struct ListView_Previews: PreviewProvider {
    static var previews: some View {
        ListView()
            .previewDevice(PreviewDevice(rawValue: "iPhone SE"))
            .environment(\.colorScheme, .dark)
    }
}
