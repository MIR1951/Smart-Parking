import SwiftUI
import FirebaseFirestore

struct PaymentMethodSelectionView: View {
    let spot: ParkingSpot
    let vehicle: Vehicle
    let slot: ParkingSlot
    let arrivalTime: Date
    let exitTime: Date
    
    @State private var selectedPaymentMethod: PaymentOption = .wallet
    @State private var showConfirmation = false
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.black)
                        .padding(8)
                        .background(Circle().fill(Color.white))
                        .shadow(color: Color.black.opacity(0.1), radius: 2)
                }
                
                Spacer()
                
                Text("To'lov usullari")
                    .font(.headline)
                    .foregroundColor(.black)
                
                Spacer()
                
                Circle()
                    .frame(width: 32, height: 32)
                    .foregroundColor(.clear)
            }
            .padding()
            .background(Color.white)
            
            ScrollView {
                VStack(spacing: 24) {
                    // Wallet section
                    SectionHeader(title: "Hamyon")
                    
                    PaymentOptionRow(
                        icon: "wallet.pass.fill",
                        iconColor: .purple,
                        title: "Hamyon",
                        isSelected: selectedPaymentMethod == .wallet,
                        showChevron: false,
                        action: { selectedPaymentMethod = .wallet }
                    )
                    
                    Divider()
                        .padding(.horizontal)
                    
                    // Credit & Debit Card section
                    SectionHeader(title: "Kredit & Debit Kartalar")
                    
                    PaymentOptionRow(
                        icon: "creditcard.fill",
                        iconColor: .purple,
                        title: "Karta qo'shish",
                        isSelected: selectedPaymentMethod == .creditCard,
                        showChevron: true,
                        action: { selectedPaymentMethod = .creditCard }
                    )
                    
                    Divider()
                        .padding(.horizontal)
                    
                    // More payment options
                    SectionHeader(title: "Boshqa to'lov usullari")
                    
                    PaymentOptionRow(
                        icon: "p.circle.fill",
                        iconColor: .blue,
                        title: "PayPal",
                        isSelected: selectedPaymentMethod == .paypal,
                        showChevron: false,
                        action: { selectedPaymentMethod = .paypal }
                    )
                    
                    PaymentOptionRow(
                        icon: "applelogo",
                        iconColor: .black,
                        title: "Apple Pay",
                        isSelected: selectedPaymentMethod == .applePay,
                        showChevron: false,
                        action: { selectedPaymentMethod = .applePay }
                    )
                    
                    PaymentOptionRow(
                        icon: "g.circle.fill",
                        iconColor: Color(red: 0.2, green: 0.5, blue: 0.9),
                        title: "Google Pay",
                        isSelected: selectedPaymentMethod == .googlePay,
                        showChevron: false,
                        action: { selectedPaymentMethod = .googlePay }
                    )
                }
                .padding(.top, 16)
            }
            
            Spacer()
            
            // Confirm Button
            Button(action: {
                showConfirmation = true
            }) {
                Text("To'lovni tasdiqlash")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.purple)
                    .cornerRadius(30)
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                    .shadow(color: Color.purple.opacity(0.3), radius: 5, x: 0, y: 3)
            }
            .padding()
        }
        .background(Color(UIColor.systemGroupedBackground))
        .edgesIgnoringSafeArea(.bottom)
        .fullScreenCover(isPresented: $showConfirmation) {
            PaymentReviewView(
                spot: spot,
                vehicle: vehicle,
                slot: slot,
                arrivalTime: arrivalTime,
                exitTime: exitTime,
                paymentOption: selectedPaymentMethod
            )
        }
    }
}

struct SectionHeader: View {
    let title: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.headline)
                .foregroundColor(.black)
                .padding(.horizontal)
                .padding(.top, 8)
            
            Spacer()
        }
    }
}

struct PaymentOptionRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let isSelected: Bool
    let showChevron: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(iconColor)
                    .frame(width: 40, height: 40)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                
                Text(title)
                    .foregroundColor(.black)
                    .font(.system(size: 16))
                    .padding(.leading, 4)
                
                Spacer()
                
                if showChevron {
                    Image(systemName: "chevron.right")
                        .foregroundColor(.purple)
                } else {
                    ZStack {
                        Circle()
                            .strokeBorder(Color.gray.opacity(0.5), lineWidth: 1.5)
                            .frame(width: 22, height: 22)
                            .background(
                                Circle()
                                    .fill(isSelected ? Color.purple : Color.white)
                                    .frame(width: 22, height: 22)
                            )
                        
                        if isSelected {
                            Circle()
                                .fill(Color.white)
                                .frame(width: 10, height: 10)
                        }
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color.white)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 4)
        .background(Color.white)
    }
}

enum PaymentOption: String, CaseIterable {
    case wallet = "Hamyon"
    case cash = "Naqt pul"
    case creditCard = "Kredit karta"
    case paypal = "PayPal"
    case applePay = "Apple Pay"
    case googlePay = "Google Pay"
}


