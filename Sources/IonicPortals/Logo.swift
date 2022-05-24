//
//  Logo.swift
//  
//
//  Created by Steven Sherry on 5/24/22.
//

import SwiftUI

struct LogoView: View {
    var body: some View {
        ZStack {
            Background()
                .fill(.white.opacity(0.3))
            
            RightPost()
                .fill(
                    LinearGradient(
                        stops: .postGradients,
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            
            LeftPost()
                .fill(
                    LinearGradient(
                        stops: .postGradients,
                        startPoint: .bottom,
                        endPoint: .top
                    )
                )
            
            TopOval()
                .fill(.white, style: FillStyle(eoFill: true))
            
            BottomOval()
                .fill(.white, style: FillStyle(eoFill: true))
        }
    }
}

private struct Background: Shape {
    func path(in rect: CGRect) -> Path {
        let width = rect.size.width
        let height = rect.size.height
        
        return Path { path in
            path.move(to: CGPoint(x: 0, y: 0.23077*height))
            path.addCurve(to: CGPoint(x: 0.5*width, y: 0.03846*height), control1: CGPoint(x: 0, y: 0.23077*height), control2: CGPoint(x: 0.15385*width, y: 0.03846*height))
            path.addCurve(to: CGPoint(x: width, y: 0.23077*height), control1: CGPoint(x: 0.84615*width, y: 0.03846*height), control2: CGPoint(x: width, y: 0.23077*height))
            path.addLine(to: CGPoint(x: width, y: 0.76923*height))
            path.addCurve(to: CGPoint(x: 0.5*width, y: 0.96154*height), control1: CGPoint(x: width, y: 0.76923*height), control2: CGPoint(x: 0.84615*width, y: 0.96154*height))
            path.addCurve(to: CGPoint(x: 0, y: 0.76923*height), control1: CGPoint(x: 0.15385*width, y: 0.96154*height), control2: CGPoint(x: 0, y: 0.76923*height))
            path.addLine(to: CGPoint(x: 0, y: 0.23077*height))
        }
    }
}

private struct RightPost: Shape {
    func path(in rect: CGRect) -> Path {
        let width = rect.size.width
        let height = rect.size.height
        
        return Path { path in
            path.move(to: CGPoint(x: 0.96154*width, y: 0.80769*height))
            path.addCurve(to: CGPoint(x: 0.92308*width, y: 0.76923*height), control1: CGPoint(x: 0.9403*width, y: 0.80769*height), control2: CGPoint(x: 0.92308*width, y: 0.79047*height))
            path.addLine(to: CGPoint(x: 0.92308*width, y: 0.23077*height))
            path.addCurve(to: CGPoint(x: 0.96154*width, y: 0.19231*height), control1: CGPoint(x: 0.92308*width, y: 0.20953*height), control2: CGPoint(x: 0.9403*width, y: 0.19231*height))
            path.addCurve(to: CGPoint(x: width, y: 0.23077*height), control1: CGPoint(x: 0.98278*width, y: 0.19231*height), control2: CGPoint(x: width, y: 0.20953*height))
            path.addLine(to: CGPoint(x: width, y: 0.76923*height))
            path.addCurve(to: CGPoint(x: 0.96154*width, y: 0.80769*height), control1: CGPoint(x: width, y: 0.79047*height), control2: CGPoint(x: 0.98278*width, y: 0.80769*height))
        }
    }
}

private struct LeftPost: Shape {
    func path(in rect: CGRect) -> Path {
        let width = rect.size.width
        let height = rect.size.height
        
        return Path { path in
            path.move(to: CGPoint(x: 0.03846*width, y: 0.19232*height))
            path.addCurve(to: CGPoint(x: 0, y: 0.23078*height), control1: CGPoint(x: 0.01722*width, y: 0.19232*height), control2: CGPoint(x: 0, y: 0.20954*height))
            path.addLine(to: CGPoint(x: 0, y: 0.76924*height))
            path.addCurve(to: CGPoint(x: 0.03846*width, y: 0.8077*height), control1: CGPoint(x: 0, y: 0.79048*height), control2: CGPoint(x: 0.01722*width, y: 0.8077*height))
            path.addCurve(to: CGPoint(x: 0.07692*width, y: 0.76924*height), control1: CGPoint(x: 0.0597*width, y: 0.8077*height), control2: CGPoint(x: 0.07692*width, y: 0.79048*height))
            path.addLine(to: CGPoint(x: 0.07692*width, y: 0.23078*height))
            path.addCurve(to: CGPoint(x: 0.03846*width, y: 0.19232*height), control1: CGPoint(x: 0.07692*width, y: 0.20954*height), control2: CGPoint(x: 0.0597*width, y: 0.19232*height))
        }
    }
}

private struct TopOval: Shape {
    func path(in rect: CGRect) -> Path {
        let width = rect.size.width
        let height = rect.size.height
        
        return Path { path in
            path.move(to: CGPoint(x: 0.10174*width, y: 0.18331*height))
            path.addCurve(to: CGPoint(x: 0.07694*width, y: 0.23077*height), control1: CGPoint(x: 0.08317*width, y: 0.2016*height), control2: CGPoint(x: 0.07694*width, y: 0.21762*height))
            path.addCurve(to: CGPoint(x: 0.10174*width, y: 0.27822*height), control1: CGPoint(x: 0.07694*width, y: 0.24392*height), control2: CGPoint(x: 0.08317*width, y: 0.25994*height))
            path.addCurve(to: CGPoint(x: 0.18845*width, y: 0.33125*height), control1: CGPoint(x: 0.12044*width, y: 0.29665*height), control2: CGPoint(x: 0.14947*width, y: 0.31501*height))
            path.addCurve(to: CGPoint(x: 0.50001*width, y: 0.38462*height), control1: CGPoint(x: 0.26624*width, y: 0.36366*height), control2: CGPoint(x: 0.37637*width, y: 0.38462*height))
            path.addCurve(to: CGPoint(x: 0.81158*width, y: 0.33125*height), control1: CGPoint(x: 0.62365*width, y: 0.38462*height), control2: CGPoint(x: 0.73379*width, y: 0.36366*height))
            path.addCurve(to: CGPoint(x: 0.89829*width, y: 0.27822*height), control1: CGPoint(x: 0.85056*width, y: 0.31501*height), control2: CGPoint(x: 0.87959*width, y: 0.29665*height))
            path.addCurve(to: CGPoint(x: 0.92309*width, y: 0.23077*height), control1: CGPoint(x: 0.91685*width, y: 0.25994*height), control2: CGPoint(x: 0.92309*width, y: 0.24392*height))
            path.addCurve(to: CGPoint(x: 0.89829*width, y: 0.18331*height), control1: CGPoint(x: 0.92309*width, y: 0.21762*height), control2: CGPoint(x: 0.91685*width, y: 0.2016*height))
            path.addCurve(to: CGPoint(x: 0.81158*width, y: 0.13029*height), control1: CGPoint(x: 0.87959*width, y: 0.16489*height), control2: CGPoint(x: 0.85056*width, y: 0.14653*height))
            path.addCurve(to: CGPoint(x: 0.50001*width, y: 0.07692*height), control1: CGPoint(x: 0.73379*width, y: 0.09788*height), control2: CGPoint(x: 0.62365*width, y: 0.07692*height))
            path.addCurve(to: CGPoint(x: 0.18845*width, y: 0.13029*height), control1: CGPoint(x: 0.37637*width, y: 0.07692*height), control2: CGPoint(x: 0.26624*width, y: 0.09788*height))
            path.addCurve(to: CGPoint(x: 0.10174*width, y: 0.18331*height), control1: CGPoint(x: 0.14947*width, y: 0.14653*height), control2: CGPoint(x: 0.12044*width, y: 0.16489*height))
            path.closeSubpath()
            path.move(to: CGPoint(x: 0.15886*width, y: 0.05928*height))
            path.addCurve(to: CGPoint(x: 0.50001*width, y: 0), control1: CGPoint(x: 0.24812*width, y: 0.0221*height), control2: CGPoint(x: 0.36875*width, y: 0))
            path.addCurve(to: CGPoint(x: 0.84116*width, y: 0.05928*height), control1: CGPoint(x: 0.63127*width, y: 0), control2: CGPoint(x: 0.75191*width, y: 0.0221*height))
            path.addCurve(to: CGPoint(x: 0.95227*width, y: 0.12851*height), control1: CGPoint(x: 0.8857*width, y: 0.07784*height), control2: CGPoint(x: 0.92426*width, y: 0.10092*height))
            path.addCurve(to: CGPoint(x: 1.00001*width, y: 0.23077*height), control1: CGPoint(x: 0.98042*width, y: 0.15624*height), control2: CGPoint(x: 1.00001*width, y: 0.19082*height))
            path.addCurve(to: CGPoint(x: 0.95227*width, y: 0.33302*height), control1: CGPoint(x: 1.00001*width, y: 0.27072*height), control2: CGPoint(x: 0.98042*width, y: 0.3053*height))
            path.addCurve(to: CGPoint(x: 0.84116*width, y: 0.40225*height), control1: CGPoint(x: 0.92426*width, y: 0.36062*height), control2: CGPoint(x: 0.8857*width, y: 0.38369*height))
            path.addCurve(to: CGPoint(x: 0.50001*width, y: 0.46154*height), control1: CGPoint(x: 0.75191*width, y: 0.43944*height), control2: CGPoint(x: 0.63127*width, y: 0.46154*height))
            path.addCurve(to: CGPoint(x: 0.15886*width, y: 0.40225*height), control1: CGPoint(x: 0.36875*width, y: 0.46154*height), control2: CGPoint(x: 0.24812*width, y: 0.43944*height))
            path.addCurve(to: CGPoint(x: 0.04775*width, y: 0.33302*height), control1: CGPoint(x: 0.11432*width, y: 0.38369*height), control2: CGPoint(x: 0.07576*width, y: 0.36062*height))
            path.addCurve(to: CGPoint(x: 0.00001*width, y: 0.23077*height), control1: CGPoint(x: 0.01961*width, y: 0.3053*height), control2: CGPoint(x: 0.00001*width, y: 0.27072*height))
            path.addCurve(to: CGPoint(x: 0.04775*width, y: 0.12851*height), control1: CGPoint(x: 0.00001*width, y: 0.19082*height), control2: CGPoint(x: 0.01961*width, y: 0.15624*height))
            path.addCurve(to: CGPoint(x: 0.15886*width, y: 0.05928*height), control1: CGPoint(x: 0.07576*width, y: 0.10092*height), control2: CGPoint(x: 0.11432*width, y: 0.07784*height))
        }
    }
}

private struct BottomOval: Shape {
    func path(in rect: CGRect) -> Path {
        let width = rect.size.width
        let height = rect.size.height
        
        return Path { path in
            path.move(to: CGPoint(x: 0.10172*width, y: 0.72177*height))
            path.addCurve(to: CGPoint(x: 0.07692*width, y: 0.76923*height), control1: CGPoint(x: 0.08316*width, y: 0.74006*height), control2: CGPoint(x: 0.07692*width, y: 0.75607*height))
            path.addCurve(to: CGPoint(x: 0.10172*width, y: 0.81668*height), control1: CGPoint(x: 0.07692*width, y: 0.78238*height), control2: CGPoint(x: 0.08316*width, y: 0.79839*height))
            path.addCurve(to: CGPoint(x: 0.18844*width, y: 0.8697*height), control1: CGPoint(x: 0.12042*width, y: 0.8351*height), control2: CGPoint(x: 0.14946*width, y: 0.85346*height))
            path.addCurve(to: CGPoint(x: 0.5*width, y: 0.92307*height), control1: CGPoint(x: 0.26623*width, y: 0.90212*height), control2: CGPoint(x: 0.37636*width, y: 0.92307*height))
            path.addCurve(to: CGPoint(x: 0.81156*width, y: 0.8697*height), control1: CGPoint(x: 0.62364*width, y: 0.92307*height), control2: CGPoint(x: 0.73377*width, y: 0.90212*height))
            path.addCurve(to: CGPoint(x: 0.89828*width, y: 0.81668*height), control1: CGPoint(x: 0.85054*width, y: 0.85346*height), control2: CGPoint(x: 0.87957*width, y: 0.8351*height))
            path.addCurve(to: CGPoint(x: 0.92308*width, y: 0.76923*height), control1: CGPoint(x: 0.91684*width, y: 0.79839*height), control2: CGPoint(x: 0.92308*width, y: 0.78238*height))
            path.addCurve(to: CGPoint(x: 0.89828*width, y: 0.72177*height), control1: CGPoint(x: 0.92308*width, y: 0.75607*height), control2: CGPoint(x: 0.91684*width, y: 0.74006*height))
            path.addCurve(to: CGPoint(x: 0.81156*width, y: 0.66875*height), control1: CGPoint(x: 0.87957*width, y: 0.70335*height), control2: CGPoint(x: 0.85054*width, y: 0.68499*height))
            path.addCurve(to: CGPoint(x: 0.5*width, y: 0.61538*height), control1: CGPoint(x: 0.73377*width, y: 0.63633*height), control2: CGPoint(x: 0.62364*width, y: 0.61538*height))
            path.addCurve(to: CGPoint(x: 0.18844*width, y: 0.66875*height), control1: CGPoint(x: 0.37636*width, y: 0.61538*height), control2: CGPoint(x: 0.26623*width, y: 0.63633*height))
            path.addCurve(to: CGPoint(x: 0.10172*width, y: 0.72177*height), control1: CGPoint(x: 0.14946*width, y: 0.68499*height), control2: CGPoint(x: 0.12042*width, y: 0.70335*height))
            path.closeSubpath()
            path.move(to: CGPoint(x: 0.15885*width, y: 0.59774*height))
            path.addCurve(to: CGPoint(x: 0.5*width, y: 0.53846*height), control1: CGPoint(x: 0.2481*width, y: 0.56055*height), control2: CGPoint(x: 0.36874*width, y: 0.53846*height))
            path.addCurve(to: CGPoint(x: 0.84115*width, y: 0.59774*height), control1: CGPoint(x: 0.63126*width, y: 0.53846*height), control2: CGPoint(x: 0.7519*width, y: 0.56055*height))
            path.addCurve(to: CGPoint(x: 0.95226*width, y: 0.66697*height), control1: CGPoint(x: 0.88569*width, y: 0.6163*height), control2: CGPoint(x: 0.92425*width, y: 0.63938*height))
            path.addCurve(to: CGPoint(x: width, y: 0.76923*height), control1: CGPoint(x: 0.9804*width, y: 0.6947*height), control2: CGPoint(x: width, y: 0.72928*height))
            path.addCurve(to: CGPoint(x: 0.95226*width, y: 0.87148*height), control1: CGPoint(x: width, y: 0.80917*height), control2: CGPoint(x: 0.9804*width, y: 0.84375*height))
            path.addCurve(to: CGPoint(x: 0.84115*width, y: 0.94071*height), control1: CGPoint(x: 0.92425*width, y: 0.89907*height), control2: CGPoint(x: 0.88569*width, y: 0.92215*height))
            path.addCurve(to: CGPoint(x: 0.5*width, y: 0.99999*height), control1: CGPoint(x: 0.7519*width, y: 0.9779*height), control2: CGPoint(x: 0.63126*width, y: 0.99999*height))
            path.addCurve(to: CGPoint(x: 0.15885*width, y: 0.94071*height), control1: CGPoint(x: 0.36874*width, y: 0.99999*height), control2: CGPoint(x: 0.2481*width, y: 0.9779*height))
            path.addCurve(to: CGPoint(x: 0.04774*width, y: 0.87148*height), control1: CGPoint(x: 0.11431*width, y: 0.92215*height), control2: CGPoint(x: 0.07575*width, y: 0.89907*height))
            path.addCurve(to: CGPoint(x: 0, y: 0.76923*height), control1: CGPoint(x: 0.01959*width, y: 0.84375*height), control2: CGPoint(x: 0, y: 0.80917*height))
            path.addCurve(to: CGPoint(x: 0.04774*width, y: 0.66697*height), control1: CGPoint(x: 0, y: 0.72928*height), control2: CGPoint(x: 0.01959*width, y: 0.6947*height))
            path.addCurve(to: CGPoint(x: 0.15885*width, y: 0.59774*height), control1: CGPoint(x: 0.07575*width, y: 0.63938*height), control2: CGPoint(x: 0.11431*width, y: 0.6163*height))
        }
    }
}

private extension Array where Element == Gradient.Stop {
    static let postGradients: [Gradient.Stop] = [
        .init(color: .white.opacity(0.7), location: 0.231),
        .init(color: .white.opacity(0.0), location: 0.769)
    ]
}

struct LogoView_Previews: PreviewProvider {
    static var previews: some View {
        GeometryReader { proxy in
            HStack {
                LogoView()
                    .frame(width: 64, height: 64)
            }
            .edgesIgnoringSafeArea(.all)
            .frame(width: proxy.size.width, height: proxy.size.height, alignment: .center)
        }
        .background(Color.portalBlue)
    }
}
