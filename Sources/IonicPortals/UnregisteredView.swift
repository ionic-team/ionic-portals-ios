import Foundation
import UIKit
import SwiftUI

struct Unregistered: View {
    @State private var shouldShowRegistrationError: Bool
    
    init(shouldShowRegistrationError: Bool) {
        self.shouldShowRegistrationError = shouldShowRegistrationError
    }
    
    var body: some View {
        VStack {
            VStack(spacing: 32) {
                LogoView()
                    .frame(width: 64, height: 64, alignment: .center)
                
                VStack(spacing: 18) {
                    Text("Register Product")
                        .font(.system(size: 24.0, weight: .bold, design: .default))
                    
                    Text("Please register in order to use Ionic Portals. You can do so at:")
                        .multilineTextAlignment(.center)
                        .font(.system(size: 18))
                    
                    Text("ionic.io/register-portals")
                }
                .frame(width: 279)
                .foregroundColor(.white)
            }
            .padding()
            .alert(isPresented: $shouldShowRegistrationError) {
                Alert(
                    title: Text("Registration Error"),
                    message: Text("Error validating your key for Ionic Portals. Check your key and try again."),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
    }
}

@available(*, deprecated, message: "I don't know why you would have ever used this to begin with 😉")
public class UnregisteredView: UIView {
}

struct Unregistered_Previews: PreviewProvider {
    static var previews: some View {
        HStack {
            Unregistered(shouldShowRegistrationError: true)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.portalBlue)
    }
}
