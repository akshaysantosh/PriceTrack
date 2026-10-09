import SwiftUI
import Security

/// Smart Scan settings (a Claude API key), shown in a sheet from the gear button.
struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var apiKey: String = KeychainStore.load() ?? ""
    @State private var savedConfirmation = false
    @State private var saveErrorStatus: OSStatus?

    private var hasKey: Bool {
        !apiKey.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.l) {
                Text("Add a Claude API key and scanning reads item names, prices and quantities for you — you just confirm. Without a key, scanning still works using your phone's built-in text recognition.")
                    .font(AppFont.secondaryDetail())
                    .foregroundStyle(Color.textSecondary)

                CardView {
                    SecureField("Claude API key (sk-ant-...)", text: $apiKey)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .onChange(of: apiKey) {
                            savedConfirmation = false
                            saveErrorStatus = nil
                        }
                }

                HStack(spacing: AppSpacing.m) {
                    if hasKey {
                        Button(role: .destructive) {
                            apiKey = ""
                            KeychainStore.delete()
                            savedConfirmation = false
                        } label: {
                            Text("Remove")
                        }
                        .buttonStyle(.primary(.calloutWarnText))
                    }
                    Button {
                        let status = KeychainStore.save(apiKey.trimmingCharacters(in: .whitespacesAndNewlines))
                        if status == errSecSuccess {
                            savedConfirmation = true
                            saveErrorStatus = nil
                        } else {
                            savedConfirmation = false
                            saveErrorStatus = status
                        }
                    } label: {
                        Text("Save")
                    }
                    .buttonStyle(.solidAccent)
                    .disabled(!hasKey)
                }

                if savedConfirmation {
                    Text("Saved to this device's Keychain.")
                        .font(AppFont.caption())
                        .foregroundStyle(Color.accentSuccess)
                }
                if let saveErrorStatus {
                    Text("Couldn't save to Keychain (error \(saveErrorStatus)). Try again — if it keeps happening, that error code will help track down why.")
                        .font(AppFont.caption())
                        .foregroundStyle(Color.calloutWarnText)
                }

                Text("Your key stays in this iPhone's secure Keychain and is only sent to Anthropic when you scan a receipt. Get one at console.anthropic.com (separate from a Claude subscription) — each scan costs a small fraction of a cent.")
                    .font(AppFont.caption())
                    .foregroundStyle(Color.textMuted)
            }
            .padding(AppSpacing.l)
        }
        .background(PaperBackground())
        .navigationTitle("Smart Scan")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") { dismiss() }
            }
        }
    }
}
