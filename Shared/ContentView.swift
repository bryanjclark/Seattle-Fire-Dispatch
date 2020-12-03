//
//  ContentView.swift
//  Shared
//
//  Created by Bryan Clark on 11/25/20.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            ListView()
                .tabItem {
                    Image(systemName: "clock")
                    Text("Recent")
                }
            MapView()
                .tabItem {
                    Image(systemName: "map")
                    Text("Map")
                }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environment(\.colorScheme, .dark)
    }
}
