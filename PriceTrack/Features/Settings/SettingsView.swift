import SwiftUI
import Security

struct SettingsView: View {
    @State private var apiKey: String = KeychainStore.load() ?? ""
    @State private var savedConfirmation = false
    @State private var saveErrorStatus: OSStatus?

    private var hasKey: Bool {
        !apiKey.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppMetrics.cardSpacing) {
                PageHeader(title: "Settings")

                CardView {
                    SectionLabel(text: "Smart scan")
                    Text("Add a Claude API key to have Scan read item names, prices, and quantities directly — you just confirm instead of typing everything in. Without a key, Scan still works using your phone's built-in text recognition.")
                        .font(AppFont.secondaryDetail())
                        .foregroundStyle(Color.textSecondary)
                        .padding(.top, 4)

                    SecureField("Claude API key (sk-ant-...)", text: $apiKey)
                        .textFieldStyle(.roundedBorder)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .padding(.top, 12)
                        .onChange(of: apiKey) {
                            savedConfirmation = false
                            saveErrorStatus = nil
                        }

                    HStack(spacing: 12) {
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
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.primary)
                        .disabled(!hasKey)

                        if hasKey {
                            Button(role: .destructive) {
                                apiKey = ""
                                KeychainStore.delete()
                                savedConfirmation = false
                            } label: {
                                Text("Remove")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.primary(.calloutWarnText))
                        }
                    }
                    .padding(.top, 12)

                    if savedConfirmation {
                        Text("Saved to this device's Keychain.")
                            .font(AppFont.caption())
                            .foregroundStyle(Color.accentSuccess)
                            .padding(.top, 4)
                    }
                    if let saveErrorStatus {
                        Text("Couldn't save to Keychain (error \(saveErrorStatus)). Try again — if it keeps happening, that error code will help track down why.")
                            .font(AppFont.caption())
                            .foregroundStyle(Color.calloutWarnText)
                            .padding(.top, 4)
                    }
                }

                CalloutBanner(text: "Your key is stored only in this iPhone's secure Keychain — it's never sent anywhere except directly to Anthropic when you scan a receipt.")

                CalloutBanner(
                    text: "Get a key at console.anthropic.com (separate from your regular Claude subscription). Each scan costs a small fraction of a cent.",
                    style: .warn
                )
            }
            .padding(16)
        }
        .background(Color.bgPage)
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
    }
}
