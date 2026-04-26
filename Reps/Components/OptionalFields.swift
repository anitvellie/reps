import SwiftUI

struct IntOptionalField: View {
    let placeholder: String
    @Binding var value: Int?

    @State private var text: String

    init(placeholder: String, value: Binding<Int?>) {
        self.placeholder = placeholder
        _value = value
        _text = State(initialValue: value.wrappedValue.map { String($0) } ?? "")
    }

    var body: some View {
        TextField(placeholder, text: $text)
            .keyboardType(.numberPad)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .onChange(of: text) { _, newValue in
                value = Int(newValue)
            }
    }
}

struct DoubleOptionalField: View {
    let placeholder: String
    @Binding var value: Double?

    @State private var text: String

    init(placeholder: String, value: Binding<Double?>) {
        self.placeholder = placeholder
        _value = value
        _text = State(initialValue: value.wrappedValue.map { Self.format($0) } ?? "")
    }

    var body: some View {
        TextField(placeholder, text: $text)
            .keyboardType(.decimalPad)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .onChange(of: text) { _, newValue in
                value = Double(newValue)
            }
    }

    private static func format(_ v: Double) -> String {
        v.truncatingRemainder(dividingBy: 1) == 0 ? String(Int(v)) : String(v)
    }
}
