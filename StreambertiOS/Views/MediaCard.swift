import SwiftUI

struct MediaCard: View {
    let item: MediaItem
    var caption: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            AsyncImage(url: item.posterURL) { img in
                img.resizable().scaledToFill()
            } placeholder: {
                Color.gray.opacity(0.3)
            }
            .frame(width: 130, height: 195)
            .clipped()
            .clipShape(RoundedRectangle(cornerRadius: 10))

            Text(item.displayTitle)
                .font(.caption.bold())
                .foregroundColor(.white)
                .lineLimit(2)
                .frame(width: 130, alignment: .leading)

            Text(item.displayDate.prefix(4))
                .font(.caption2)
                .foregroundColor(.gray)

            if let caption {
                Text(caption)
                    .font(.caption2.bold())
                    .foregroundColor(.purple)
                    .lineLimit(1)
                    .frame(width: 130, alignment: .leading)
            }
        }
        .frame(width: 130)
    }
}
