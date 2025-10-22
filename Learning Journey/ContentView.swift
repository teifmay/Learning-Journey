//
//  ContentView.swift
//  Learning Journey
//
//  Created by Teif May on 26/04/1447 AH.
//

import SwiftUI

struct FireGlassButton: View {

    @State private var isHovering = false
    @State private var isShining = true
    
    let customBrown = Color(red: 0.2, green: 0.08, blue: 0.08)

    var body: some View {
        Button(action: {

            print("Fire Button Tapped")
            withAnimation(.easeInOut(duration: 0.5)) {
                isShining = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isShining = false
            }
        }) {

            Image("Fire")
                .resizable()
                .scaledToFit()
                .frame(width: 30, height: 30)
                .padding(20)
        }
        .buttonStyle(PlainButtonStyle())
        .background(
            ZStack {
                Circle()
                    .fill(customBrown)
                
                //  Inner Shine/Edge (Glass/3D effect)
                Circle()
                    .strokeBorder(Color.white.opacity(0.4), lineWidth: 1)
                    .padding(1)
                    .shadow(color: .black.opacity(0.8), radius: 5, x: 0, y: 5)
                
                //  The Animated Shine Effect
                shineGradient
                    .mask(Circle())
                    .opacity(isShining ? 1 : 0)
                    .offset(x: isShining ? 100 : -100) // Animates from left to right
            }
        )
        .frame(width: 100, height: 100)
        .clipShape(Circle())
        .scaleEffect(isHovering ? 1.05 : 1.0)
        .animation(.spring(), value: isHovering)
        .onHover { hover in
            withAnimation(.easeInOut(duration: 0.3)) {
                isHovering = hover
                isShining = hover
            }
        }
        .onAppear {
            isShining = false // Reset position
            withAnimation(.easeInOut(duration: 0.5).delay(0.2)) {
                isShining = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation(.easeInOut(duration: 0.5)) {
                    isShining = false
                }
            }
        }
    }
    var shineGradient: some View {
        LinearGradient(
            gradient: Gradient(stops: [
                .init(color: .white.opacity(0.0), location: 0.0),
                .init(color: .white.opacity(0.8), location: 0.4),
                .init(color: .white.opacity(0.0), location: 0.8)
            ]),
            startPoint: .leading,
            endPoint: .trailing
        )
        .frame(width: 200, height: 200)
    }
}
struct ContentView: View {
    @State private var goal: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            
            ZStack {
                FireGlassButton()
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.top, 5)
            .padding(.bottom, 20)

            VStack(alignment: .leading, spacing: 5) {
                // Hello Learner
                Text("Hello Learner")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                 
                // النص الإرشادي الطويل
                Text("this app will help you learn everyday!")
                    .font(.callout)
                    .foregroundColor(.gray)
            }
            .padding(.bottom, 40)
            Text("I want to learn")
                .foregroundColor(.white)
                .font(.title2)
                .padding(.bottom, 8)

            TextField("", text: $goal,
                prompt: Text("Write Your Goal...")
                .font(.callout)
                .foregroundColor(.gray)
            )
            .font(.title)
            .foregroundColor(.white)
            .tint(.white)
            
            Rectangle()
                .frame(height: 1)
                .foregroundColor(.gray)
                .padding(.top, 4)
                .opacity(0.3)
            
            // . خيارات المدة وزر البدء
            VStack {
                Text("I want to learn it in a")
                    .font(.title2)
                    .foregroundColor(.white)
                    .padding(.top, 22)
                    .padding(.bottom, 10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                HStack {
                    Button("Week") { /* Action */ }
                        .buttonStyle(.borderedProminent)
                        .buttonBorderShape(.roundedRectangle(radius: 20))
                        .tint(Color(red: 0.1, green: 0.1, blue: 0.1)) // خلفية داكنة
                        .foregroundColor(.white)

                    Button("Month") { /* Action */ }
                        .buttonStyle(.borderedProminent)
                        .buttonBorderShape(.roundedRectangle(radius: 20))
                        .tint(Color(red: 0.1, green: 0.1, blue: 0.1))
                        .foregroundColor(.white)

                    Button("Day") { /* Action */ }
                        .buttonStyle(.borderedProminent)
                        .buttonBorderShape(.roundedRectangle(radius: 20))
                        .tint(Color(red: 0.1, green: 0.1, blue: 0.1))
                        .foregroundColor(.white)
                    
                    Spacer()
                }
                
                Button("Start Learning") { /* Action */ }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.orange)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 15))
                    .padding(.top, 200)
            }
            
            Spacer()
        }
        .padding(.horizontal, 20)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.ignoresSafeArea())
    }
}
#Preview {
    ContentView()
}
