//
//  Log a day.swift
//  Learning Journey
//
//  Created by Teif May on 29/04/1447 AH.
//

import SwiftUI

struct LogADay: View {
    var body: some View {
        NavigationStack {
            // Your screen content goes here
            VStack(alignment: .leading, spacing: 10) {
                HStack{
                    Button("Calendar") { /* Action */ }
                        .buttonStyle(.borderedProminent)
                        .buttonBorderShape(.roundedRectangle(radius: 20))
                        .tint(Color(red: 0.1, green: 0.1, blue: 0.1))
                    
                }
                // Placeholder content

            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.black.ignoresSafeArea())
            .navigationTitle("Activity")
            .toolbarTitleDisplayMode(.large) // Large title style
            .toolbarBackground(.black, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar) // Ensures appropriate contrast
            .foregroundStyle(.white) // Applies to nav title in many cases
        }
    }
}

#Preview{
    LogADay()
}
