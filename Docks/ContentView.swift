//
//  ContentView.swift
//  Docks
//
//  Created by david on 11/16/22.
//

import SwiftUI

struct ContentView: View {
    @StateObject var DeviceManager = Device()
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundColor(.accentColor)
            Text("Hello, world!")
        }
        .padding()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
