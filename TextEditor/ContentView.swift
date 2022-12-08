//
//  ContentView.swift
//  TextEditor
//
//  Created by Linda Lu on 12/7/22.
//

import SwiftUI
import CodeEditor

struct TextEditingView: View {
    @State private var fullText: String = "This is some editable text..."

    var body: some View {
        TextEditor(text: $fullText)
    }
}

struct ContentView: View {

    @State private var source = ""
    
    var body: some View {
        CodeEditor(source: $source, language: .java, theme: .ocean)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
