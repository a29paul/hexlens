import SwiftUI

struct ChampSelectView: View {
    @ObservedObject var gameStateManager: GameStateManager

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack(spacing: 12) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.lolChampSelectBg)
                    .frame(width: 48, height: 48)
                    .overlay(
                        Text("⚔")
                            .font(.system(size: 20))
                    )

                VStack(alignment: .leading) {
                    Text(championName)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white)
                    Text(roleText)
                        .font(.system(size: 12))
                        .foregroundStyle(Color.lolGold)
                }
            }
            .padding(.bottom, 4)

            Divider()
                .background(Color.white.opacity(0.1))

            // Rune Import Button
            Button(action: importRunes) {
                HStack {
                    Image(systemName: "arrow.down.circle.fill")
                    Text("Import Runes")
                }
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.lolGold)
                )
            }
            .buttonStyle(.plain)

            // Build Path
            VStack(alignment: .leading, spacing: 8) {
                SectionHeader(title: "CORE BUILD PATH")
                HStack(spacing: 6) {
                    ForEach(0..<6, id: \.self) { _ in
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.lolChampSelectBg)
                            .frame(width: 32, height: 32)
                            .overlay(
                                RoundedRectangle(cornerRadius: 4)
                                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
                            )
                    }
                }
                Text("Build data loading...")
                    .font(.system(size: 11))
                    .foregroundStyle(Color.lolTextSecondary)
                    .italic()
            }

            // Matchup
            VStack(alignment: .leading, spacing: 8) {
                SectionHeader(title: "MATCHUP")
                Text("Matchup data loading...")
                    .font(.system(size: 11))
                    .foregroundStyle(Color.lolTextSecondary)
                    .italic()
            }
        }
        .padding(20)
        .frame(width: 360)
        .background(Color.lolChampSelectBg)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.15), lineWidth: 1)
        )
        .onAppear { resolveChampionName() }
        .onChange(of: gameStateManager.champSelectSession?.localPlayerCellId) { resolveChampionName() }
    }

    @State private var resolvedChampName: String = "Selecting..."

    private var championName: String { resolvedChampName }

    private var roleText: String {
        guard let session = gameStateManager.champSelectSession,
              let localCell = session.localPlayerCellId,
              let me = session.myTeam?.first(where: { $0.cellId == localCell }),
              let position = me.assignedPosition, !position.isEmpty else {
            return "Role TBD"
        }
        return position.capitalized
    }

    private func resolveChampionName() {
        guard let session = gameStateManager.champSelectSession,
              let localCell = session.localPlayerCellId,
              let me = session.myTeam?.first(where: { $0.cellId == localCell }),
              me.championId > 0 else {
            resolvedChampName = "Selecting..."
            return
        }
        let champId = me.championId
        Task {
            let name = await DataDragon.shared.championName(for: champId)
            await MainActor.run { resolvedChampName = name }
        }
    }

    private func importRunes() {
        guard let session = gameStateManager.champSelectSession,
              let localCell = session.localPlayerCellId,
              let me = session.myTeam?.first(where: { $0.cellId == localCell }),
              me.championId > 0 else { return }

        let champId = me.championId
        let assignedPos = me.assignedPosition ?? ""
        Task {
            let champName = await DataDragon.shared.championName(for: champId)
            let role = PlayerRole(rawValue: assignedPos.lowercased()) ?? .unknown
            let buildData = await PatchDataService.shared.getBuildData(for: champName, role: role)
            if let runes = buildData?.recommendedRunes {
                await MainActor.run { gameStateManager.importRunes(runes) }
            }
        }
    }
}
