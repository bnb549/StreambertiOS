import SwiftUI

struct MediaCard: View {
    let item: MediaItem

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            AsyncImage(url: item.posterURL) { img in
                img.resizable().scaledToFill()
            } placeholder: {
                Color.gray.opacity(0.3)
            }
            .frame(width: 130, height: 195)
            .cornerRadius(10)
            .clipped()

            Text(item.displayTitle)
                .font(.caption.bold())
                .foregroundColor(.white)
                .lineLimit(2)
                .frame(width: 130, alignment: .leading)

            Text(item.displayDate.prefix(4))
                .font(.caption2)
                .foregroundColor(.gray)
        }
        .frame(width: 130)
    }
}
