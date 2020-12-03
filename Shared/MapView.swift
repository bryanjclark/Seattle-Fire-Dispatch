//
//  MapView.swift
//  DispatchSwift
//
//  Created by Bryan Clark on 11/26/20.
//

import SwiftUI
import MapKit

// STOPSHIP: The map annotations often double-up because they're endlessly added to the map. Is there a way to prevent that from happening?
// TODO: Make the active pins go in front of the inactive ones
// TODO: Throttle the pins' entry onto the screen
// TODO: Debounce the location-lookups to determine whether to show a spinner
// TODO: Cluster the map pins; if a single one is active then the cluster is green.

class MapDataModel: ObservableObject {
    private let dataFetcher = DataFetcher.shared
    
    @Published var region = SeattleRegion
    @Published private var locationsDict: [Int: Location] = [:] {
        didSet {
            self.locations = Array(locationsDict.values)
            print("locations count: \(self.locations.count)")
        }
    }
    @Published var locations: [Location] = []
    
    init() {}
    
    var hasDoneInitialFetch = false
    func performInitialFetch() {
        guard !hasDoneInitialFetch else { return }
        self.hasDoneInitialFetch = true
        self.fetch()
    }
    
    func fetch() {
        print("\(dataFetcher.entries.count) entries")
        dataFetcher.entries.forEach { entry in
            Geocoder.shared.lookup(entry: entry) { (location) in
                guard let location = location else { return }
                self.locationsDict[entry.id]  = location
            }
        }
    }
}

struct MapView: View {
    @ObservedObject private var dataModel = MapDataModel()
    
    var body: some View {
        NavigationView {
            ZStack {
                Map(coordinateRegion: $dataModel.region, annotationItems: dataModel.locations) { location in
                    MapAnnotation(coordinate: location.coordinate) {
                        LocationMarker(location: location, navigable: true)
                    }
                }
            }
            .navigationBarTitle("Map", displayMode: .large)
            .onAppear(perform: {
                dataModel.performInitialFetch()
            })
        }
    }
}

struct MapView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            MapView()
        }
    }
}
