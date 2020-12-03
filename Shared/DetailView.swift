//
//  DetailView.swift
//  DispatchSwift
//
//  Created by Bryan Clark on 11/25/20.
//

import SwiftUI
import MapKit

class Geocoder: ObservableObject {
    static let shared = Geocoder()
    private static let sharedGeocoder = CLGeocoder()
    
    private var cachedLookups: [String: Location] = [:]
    
    func lookup(entry: Entry, completionHandler: @escaping ((Location?) -> Void)) {
        let addressString = entry.location
        print("Looking up \(addressString)")
        if let cached = cachedLookups[addressString] {
            print("Cache hit: \(addressString)")
            completionHandler(cached)
            return
        }
        
        let search = MKLocalSearch.Request()
        search.naturalLanguageQuery = addressString
        search.region = SeattleMegaRegion
        MKLocalSearch(request: search).start { (response, error) in
            if
                let result = response,
                let place = result.mapItems.first
           {
                let location = Location(
                    entry: entry,
                    mapItem: place
                )
                DispatchQueue.main.async {
                    print("Found: \(addressString)")
                    self.cachedLookups[addressString] = location
                    completionHandler(location)
                }
            }
        }
    }
}

class DetailDataModel: ObservableObject {
    @Published var region = SeattleRegion
    
    var locations: [Location] = []
    
    func lookup(entry: Entry) {
        Geocoder.shared.lookup(entry: entry) { (location) in
            guard let location = location else { return }
            
            DispatchQueue.main.async {
                self.locations = [location]
                self.region = MKCoordinateRegion(center: location.mapItem.placemark.coordinate, latitudinalMeters: 500, longitudinalMeters: 500)
            }
        }
    }
}

let SeattleCenter = CLLocationCoordinate2D(latitude: 47.609722, longitude: -122.333056)
let detailRegionSize = MKMapSize(width: 200, height: 200)
let SeattleRegion = MKCoordinateRegion(center: SeattleCenter, latitudinalMeters: 50000, longitudinalMeters: 50000)
let SeattleMegaRegion = MKCoordinateRegion(center: SeattleCenter, latitudinalMeters: 90000, longitudinalMeters: 90000)

struct Location: Identifiable, Equatable {
    static func == (lhs: Location, rhs: Location) -> Bool {
        return lhs.id == rhs.id
    }
    
    let entry: Entry
    let mapItem: MKMapItem
    
    var id: Int {
        return entry.id
    }
    
    var coordinate: CLLocationCoordinate2D {
        return mapItem.placemark.coordinate
    }
}


struct LocationMarker: View {
    let location: Location
    let navigable: Bool
    
    private struct Contents: View {
        let location: Location
        var body: some View {
            Group {
                if let icon = location.entry.mapIcon {
                    Image(systemName: icon).font(.subheadline)
                } else {
                    Text("\(location.entry.level)")
                        .font(.subheadline)
                        .bold()
                }
            }
                .foregroundColor(Color.white)
                .background(
                    Circle()
                        .fill(Color(location.entry.isActive ? .systemGreen : .systemGray))
                        .frame(width: 36, height: 36, alignment: .center)
                        .shadow(color: Color.black.opacity(0.3), radius: 2, x: 0, y: 2)
                        .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 2)
                )
        }
    }

    
    var body: some View {
        if self.navigable {
            NavigationLink(destination: DetailView(entry: location.entry)) {
                Contents(location: location)
            }
        } else {
            Contents(location: location)
        }
    }
}

struct DetailView: View {
    let entry: Entry
    @ObservedObject var dataModel = DetailDataModel()
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                Map(coordinateRegion: $dataModel.region, interactionModes: [.zoom, .pan], annotationItems: dataModel.locations) { location in
                    MapAnnotation(coordinate: location.coordinate) {
                        LocationMarker(location: location, navigable: false)
                    }
                }
                    .frame(height: 350)
                VStack(alignment: .leading) {
                    Text(entry.location).bold()
                    Text(entry.date, style: .time).foregroundColor(.gray)
                    Spacer(minLength: 12)
                    Text(entry.label)
                    Text("Level \(entry.level)")
                    Text("Units: \(entry.units.joined(separator: ", "))")
                    Spacer(minLength: 12)
                    Text("Incident ID: \(entry.incidentID)").font(.footnote).foregroundColor(.gray)
                    Spacer()
                    Text("(Note: map locations are approximate; dispatch doesn't offer the full address, so if the map is in the wrong spot, that's why!)").font(.footnote).foregroundColor(.gray).italic()
                }.padding()
                Spacer()
            }
        }
        .background(Color(UIColor.systemBackground))
        .navigationBarTitle(entry.label, displayMode: .inline)
        .onAppear(perform: {
            dataModel.lookup(entry: entry)
        })
    }
}

let dummyEntry = Entry(
    id: 1,
    isActive: false,
    date: Date(),
    incidentID: "ABC123",
    level: 1,
    units: ["A1", "B2", "C3"],
    location: "2853 NW Market St",
    label: "Free Burrito Alert"
)

struct DetailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView() {
            DetailView(entry: dummyEntry)
        }
//            .environment(\.colorScheme, .dark)
    }
}
