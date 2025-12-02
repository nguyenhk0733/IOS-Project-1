import Foundation
import SwiftUI

public struct DiseaseDetail: Identifiable, Equatable {
    public let id = UUID()
    public let name: String
    public let symptoms: String
    public let careTips: String
}

public enum DiseaseDetailProvider {
    private static let details: [String: DiseaseDetail] = [
        "healthy": DiseaseDetail(
            name: "Lá khỏe mạnh",
            symptoms: "Không quan sát thấy đốm hoặc vùng đổi màu bất thường. Phiến lá sáng, cứng cáp và đồng đều.",
            careTips: "Duy trì tưới tiêu hợp lý, bón phân cân đối và loại bỏ lá già khô để phòng ngừa nấm khuẩn."
        ),
        "disease_leaf_spot": DiseaseDetail(
            name: "Đốm lá",
            symptoms: "Các đốm tròn nhỏ màu nâu, có quầng vàng xung quanh, lan dần và có thể hợp nhất thành mảng lớn.",
            careTips: "Tỉa bỏ lá bị nặng, giữ tán lá thoáng; cân nhắc phun đồng/mancozeb đúng nhãn và luân phiên hoạt chất."
        ),
        "disease_blight": DiseaseDetail(
            name: "Cháy lá",
            symptoms: "Lá héo rũ nhanh, xuất hiện vệt cháy đen hoặc nâu lan dọc gân lá; có thể kèm mùi hăng hoặc nấm mốc.",
            careTips: "Cắt bỏ phần lá/chồi bị cháy, khử trùng dụng cụ; cải thiện thoát nước và phun thuốc bảo vệ theo khuyến cáo địa phương."
        ),
        "disease_mildew": DiseaseDetail(
            name: "Phấn trắng/Phấn sương",
            symptoms: "Lớp phấn trắng hoặc xám trên bề mặt lá, đôi khi kèm biến dạng lá non và giảm lấp lánh màu xanh.",
            careTips: "Tăng thông thoáng, tránh tưới ướt lá; có thể phun lưu huỳnh hoặc bicarbonate, luân phiên nhóm DMI/QoI khi cần."
        ),
        "stress_nutrient": DiseaseDetail(
            name: "Thiếu/Thừa dinh dưỡng",
            symptoms: "Lá úa vàng từng mảng, mép cháy hoặc bạc màu; gân lá đôi khi xanh hơn phiến lá (thiếu N/K/Mg).",
            careTips: "Kiểm tra pH và dinh dưỡng; bón cân đối N-P-K, bổ sung vi lượng (Ca, Mg, Zn, B) và cải tạo đất bằng hữu cơ/vi sinh."
        ),
        "unknown": DiseaseDetail(
            name: "Không xác định",
            symptoms: "Mẫu không khớp tập huấn luyện hoặc ảnh mờ. Không đủ thông tin để suy ra triệu chứng đặc hiệu.",
            careTips: "Chụp lại ảnh rõ hơn, quan sát thêm mặt dưới lá/thân; nếu nghi bệnh, vệ sinh vườn và hỏi thêm chuyên gia địa phương."
        )
    ]

    public static func detail(for label: String) -> DiseaseDetail {
        details[label, default: details["unknown"]!]
    }
}

public struct DiseaseDetailView: View {
    private let result: InferenceResult
    private let detail: DiseaseDetail

    public init(result: InferenceResult, detail: DiseaseDetail? = nil) {
        self.result = result
        self.detail = detail ?? DiseaseDetailProvider.detail(for: result.summary)
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Detected Label")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(detail.name.isEmpty ? result.summary : detail.name)
                        .font(.title2.weight(.semibold))
                }

                confidenceView

                infoBlock(title: "Symptoms", text: detail.symptoms, icon: "bandage")
                infoBlock(title: "Care Tips", text: detail.careTips, icon: "leaf")
            }
            .padding()
        }
        .background(Color.appBackground.ignoresSafeArea())
        .navigationTitle("Disease details")
    }

    private var confidenceView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Model confidence")
                .font(.caption)
                .foregroundStyle(.secondary)
            ProgressView(value: result.confidence) {
                Text("\(Int(result.confidence * 100))% sure of this label")
                    .font(.subheadline)
            }
        }
    }

    private func infoBlock(title: String, text: String, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: icon)
                .font(.headline)
            Text(text)
                .appBodyStyle()
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.white.opacity(0.85))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.appPrimary.opacity(0.2))
        )
    }
}
