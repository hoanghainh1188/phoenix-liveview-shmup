# Feature Specification: Shmup — Power-up và vũ khí nâng cấp

**Feature Branch**: `003-shmup-powerups`
**Created**: 2026-07-02
**Status**: Draft
**Input**: User description: "Thêm hệ thống power-up / vũ khí nâng cấp: vật phẩm rơi ra khi hạ địch, người chơi nhặt để tăng tốc độ bắn, bắn nhiều tia, hoặc nhận khiên tạm thời"

## User Scenarios & Testing *(mandatory)*

### User Story 1 — Địch rơi vật phẩm khi bị hạ (Priority: P1) 🎯 MVP

Khi người chơi hạ một địch, có **cơ hội** (không phải luôn luôn) vật phẩm power-up rơi ra từ vị trí địch và rơi xuống theo trọng lực giống đạn/địch khác. Người chơi phải **di chuyển tàu để chạm vào vật phẩm** trước khi nó rơi ra khỏi màn hình để nhặt được; nếu không kịp, vật phẩm biến mất không có hiệu lực.

**Why this priority**: Không có cơ chế rơi/nhặt vật phẩm thì không thể có power-up nào khác — đây là nền tảng bắt buộc cho toàn bộ tính năng.

**Independent Test**: Chơi một ván, hạ nhiều địch liên tiếp; xác nhận thỉnh thoảng có vật phẩm rơi ra, và việc điều khiển tàu chạm vào vật phẩm khiến nó biến mất khỏi màn hình (được nhặt).

**Acceptance Scenarios**:

1. **Given** một địch đang bị nhắm bắn, **When** địch bị hạ (hp về 0), **Then** hệ thống MAY (theo tỉ lệ xác suất) sinh ra một vật phẩm rơi tại vị trí địch vừa bị hạ.
2. **Given** vật phẩm đang rơi trên màn hình, **When** tàu người chơi chạm vào vật phẩm (va chạm hộp bao như luật va chạm hiện có), **Then** vật phẩm biến mất và hiệu lực tương ứng được kích hoạt cho người chơi.
3. **Given** vật phẩm đang rơi, **When** vật phẩm ra khỏi đáy màn hình mà không được nhặt, **Then** vật phẩm biến mất không có hiệu lực gì (giống luật loại bỏ đạn/địch ngoài màn hình hiện có).

---

### User Story 2 — Tăng tốc độ bắn và bắn nhiều tia (Priority: P2)

Có ít nhất hai loại vật phẩm vũ khí: **tăng tốc độ bắn** (giảm thời gian hồi chiêu giữa các phát bắn) và **bắn nhiều tia** (mỗi lần bắn ra nhiều viên đạn theo các hướng khác nhau thay vì một viên thẳng). Hiệu lực có **thời hạn** (đếm ngược theo thời gian chơi) và tự động hết khi hết hạn, quay về trạng thái vũ khí cơ bản.

**Why this priority**: Đây là hai hình thức power-up trực tiếp thay đổi cách người chơi tấn công, là giá trị cốt lõi thứ hai của tính năng sau khi có cơ chế rơi/nhặt.

**Independent Test**: Nhặt vật phẩm tăng tốc độ bắn, xác nhận khoảng cách giữa các viên đạn bắn ra ngắn lại so với mặc định; nhặt vật phẩm bắn nhiều tia, xác nhận mỗi lần bắn ra nhiều hơn một viên đạn; đợi hết thời hạn, xác nhận vũ khí quay lại trạng thái cơ bản.

**Acceptance Scenarios**:

1. **Given** người chơi đang ở vũ khí cơ bản, **When** nhặt vật phẩm tăng tốc độ bắn, **Then** thời gian hồi giữa hai lần bắn liên tiếp giảm so với mặc định trong suốt thời hạn hiệu lực.
2. **Given** người chơi đang ở vũ khí cơ bản, **When** nhặt vật phẩm bắn nhiều tia, **Then** mỗi lần bắn tạo ra nhiều viên đạn theo các hướng khác nhau trong suốt thời hạn hiệu lực.
3. **Given** một hiệu lực vũ khí đang chạy, **When** thời hạn kết thúc, **Then** người chơi quay về hành vi bắn cơ bản (một viên đạn thẳng, tốc độ bắn mặc định).
4. **Given** người chơi đã có hiệu lực tăng tốc độ bắn đang chạy, **When** nhặt thêm một vật phẩm tăng tốc độ bắn khác, **Then** thời hạn hiệu lực được làm mới (gia hạn) thay vì cộng dồn hai hiệu lực chồng nhau không xác định.

---

### User Story 3 — Khiên tạm thời (Priority: P3)

Vật phẩm khiên giúp người chơi **chịu được một lần trúng đạn địch** mà không kết thúc ván (khác với hiện tại: trúng đạn địch là chết ngay). Khiên tiêu hao khi đỡ được một lần trúng, hoặc hết hiệu lực sau một khoảng thời gian nếu không bị dùng tới.

**Why this priority**: Đây là power-up phòng thủ, có giá trị nhưng thay đổi luật thua hiện có (một-hit-chết) nên ưu tiên thấp hơn hai power-up tấn công đơn giản hơn ở P1/P2.

**Independent Test**: Nhặt vật phẩm khiên, cố tình để trúng một viên đạn địch, xác nhận ván không kết thúc và khiên biến mất (hoặc hiển thị đã dùng); trúng viên đạn thứ hai sau khi khiên đã tiêu hao, xác nhận ván kết thúc như luật hiện có.

**Acceptance Scenarios**:

1. **Given** người chơi chưa có khiên, **When** nhặt vật phẩm khiên, **Then** người chơi ở trạng thái được bảo vệ (khiên đang hoạt động).
2. **Given** người chơi đang có khiên hoạt động, **When** trúng một viên đạn địch, **Then** ván KHÔNG kết thúc, khiên bị tiêu hao (mất trạng thái bảo vệ), và viên đạn đó bị loại bỏ.
3. **Given** người chơi không có khiên (chưa nhặt hoặc đã tiêu hao), **When** trúng một viên đạn địch, **Then** ván kết thúc theo đúng luật hiện có (game over).
4. **Given** khiên đang hoạt động nhưng chưa bị dùng, **When** hết thời hạn hiệu lực, **Then** khiên tự động mất tác dụng như các power-up có thời hạn khác.

---

### Edge Cases

- **Nhiều vật phẩm cùng lúc**: Nếu nhiều vật phẩm khác loại đang rơi và người chơi nhặt gần như đồng thời, mỗi lần nhặt xử lý độc lập theo thứ tự va chạm được phát hiện; không được để một lần nhặt vô tình bỏ qua vật phẩm khác.
- **Nhặt trùng loại đang hoạt động**: Với vật phẩm có thời hạn (bắn nhanh, nhiều tia, khiên), nhặt thêm cùng loại khi đang hoạt động phải có quy tắc rõ ràng (gia hạn thời gian) thay vì hành vi không xác định.
- **Hai power-up tấn công cùng lúc**: Nếu tăng tốc độ bắn và bắn nhiều tia cùng hoạt động (nhặt cả hai gần nhau), hai hiệu lực MUST kết hợp được (bắn nhiều tia với tốc độ nhanh hơn) thay vì loại trừ lẫn nhau, trừ khi được ghi rõ là không tương thích.
- **Game over khi đang có power-up**: Khi ván kết thúc (game_over), mọi power-up đang hoạt động phải được coi là hết hiệu lực ở lượt chơi tiếp theo (`new_playing/0` luôn khởi tạo trạng thái vũ khí cơ bản, không kế thừa từ ván trước).
- **Tỉ lệ rơi bằng 0 hoặc quá cao**: Tỉ lệ rơi vật phẩm phải đủ thấp để không làm mất ý nghĩa "phần thưởng", nhưng đủ cao để người chơi trải nghiệm được tính năng trong một ván chơi thông thường — cần một giá trị cụ thể được ghi trong plan/kiểm thử.
- **Tương tác với độ khó tăng dần (spec 002)**: Power-up không được vô hiệu hóa hoàn toàn thử thách của độ khó tăng dần (ví dụ khiên không nên miễn nhiễm vĩnh viễn) — mỗi hiệu lực đều có thời hạn hoặc số lần dùng giới hạn.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Trò MUST cho phép vật phẩm power-up rơi ra từ vị trí một địch vừa bị hạ, theo một tỉ lệ xác suất cấu hình được (không phải mọi lần hạ địch đều rơi vật phẩm).
- **FR-002**: Vật phẩm rơi MUST di chuyển xuống màn hình và bị loại bỏ khi ra khỏi đáy màn hình mà không được nhặt, theo cùng nguyên tắc dọn dẹp (cull offscreen) đang áp dụng cho đạn/địch.
- **FR-003**: Trò MUST phát hiện va chạm giữa tàu người chơi và vật phẩm rơi (dùng lại luật va chạm hộp bao hiện có) và kích hoạt hiệu lực tương ứng khi nhặt được, đồng thời loại bỏ vật phẩm khỏi màn hình.
- **FR-004**: Trò MUST hỗ trợ tối thiểu ba loại power-up: (a) tăng tốc độ bắn, (b) bắn nhiều tia, (c) khiên tạm thời.
- **FR-005**: Các hiệu lực (a) và (b) MUST có thời hạn tính theo thời gian chơi (play_tick) và tự động hết hiệu lực, quay về hành vi bắn cơ bản, khi hết thời hạn.
- **FR-006**: Nhặt thêm một power-up cùng loại khi hiệu lực loại đó đang hoạt động MUST gia hạn (làm mới) thời hạn, không cộng dồn nhiều tầng hiệu lực không xác định.
- **FR-007**: Hiệu lực tăng tốc độ bắn và bắn nhiều tia MUST có thể hoạt động đồng thời và kết hợp tác dụng (bắn nhiều tia với tốc độ hồi chiêu đã giảm).
- **FR-008**: Khiên (c) MUST hấp thụ đúng một lần trúng đạn địch tiếp theo (ngăn kết thúc ván ở lần trúng đó), tiêu hao ngay sau khi hấp thụ, và cũng MUST tự hết hiệu lực sau một thời hạn nếu không được dùng tới.
- **FR-009**: Khi bắt đầu ván mới (`new_playing/0`), trạng thái vũ khí và khiên MUST luôn ở mặc định cơ bản — không kế thừa power-up từ ván trước.
- **FR-010**: Toàn bộ trạng thái power-up (vật phẩm đang rơi, hiệu lực đang hoạt động, thời hạn còn lại) MUST là một phần của `%GameState{}` và được cập nhật thuần túy trong pipeline `Simulation.step/1`, không thêm process/side-effect mới.
- **FR-011**: Snapshot gửi cho client (`push_event("frame", ...)`) MUST bao gồm đủ thông tin để hiển thị vật phẩm đang rơi và trạng thái hiệu lực hiện tại của người chơi (ví dụ để vẽ icon/HUD), tuân theo quy tắc chỉ gửi các trường JSON-safe (xem ghi chú `snapshot/1` trong `CLAUDE.md`).

### Key Entities

- **Vật phẩm power-up (powerup)**: Thực thể rơi trên màn hình, có vị trí, kích thước, loại (`:rapid_fire`, `:multi_shot`, `:shield`), và vận tốc rơi; bị loại bỏ khi ra khỏi màn hình hoặc khi được nhặt.
- **Hiệu lực đang hoạt động (active effect)**: Trạng thái gắn với người chơi, gồm loại hiệu lực và thời hạn còn lại (tính bằng play_tick); có thể có nhiều hiệu lực tấn công hoạt động song song, riêng khiên là trạng thái nhị phân (đang có / không có) cộng thời hạn.
- **Người chơi (player)**: Mở rộng thêm các hiệu lực đang hoạt động hiện có (không thay đổi vị trí/kích thước hộp va chạm).

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Trong một ván chơi đủ dài (hạ khoảng 20+ địch), người chơi quan sát được ít nhất một vật phẩm rơi ra và có thể nhặt được nó.
- **SC-002**: Sau khi nhặt vật phẩm tăng tốc độ bắn, khoảng thời gian giữa hai lần bắn liên tiếp đo được ngắn hơn rõ rệt so với mặc định, và tự trở lại mặc định sau khi hết thời hạn quan sát được.
- **SC-003**: Sau khi nhặt vật phẩm bắn nhiều tia, mỗi lần bắn tạo ra nhiều hơn một viên đạn quan sát được trên màn hình.
- **SC-004**: Khi có khiên và trúng đúng một viên đạn địch, ván tiếp tục (không game over) và khiên biến mất sau lần trúng đó; trúng đạn lần kế tiếp không có khiên khiến ván kết thúc như luật hiện có.
- **SC-005**: Bắt đầu ván mới sau khi game over luôn cho trạng thái vũ khí/khiên cơ bản, không power-up nào tồn tại từ ván trước.
- **SC-006**: Các luật cốt lõi đã có (điều khiển, điểm, độ khó tăng dần theo spec 002, kỷ lục cục bộ) vẫn hoạt động không đổi khi tính năng power-up được bật.

## Assumptions

- Tính năng **mở rộng** trên nền simulation thuần túy hiện có (`Shmup.Game.*`); không cần Ecto hay lưu trữ server-side ngoài process LiveView.
- Tỉ lệ rơi vật phẩm, thời hạn hiệu lực cụ thể (số giây/play_tick), và số lượng tia khi bắn nhiều tia là **tham số cụ thể sẽ chốt ở bước plan/research**, tương tự cách spec 002 để bảng tham số độ khó cho `plan.md`/`research.md`.
- Vật phẩm chỉ rơi từ địch bị hạ bằng đạn người chơi (không rơi từ địch biến mất do ra khỏi màn hình), giữ đúng ý nghĩa "phần thưởng cho việc tiêu diệt địch".
- Không yêu cầu chọn loại power-up cụ thể trước khi rơi (loại được chọn ngẫu nhiên trong ba loại ở FR-004) trừ khi làm rõ thêm ở clarify.
- Giao diện hiển thị trạng thái power-up (icon, thời gian còn lại) có thể ở mức tối thiểu (ví dụ text debug như `difficulty_tier` hiện tại) — không yêu cầu thiết kế UI phức tạp trong phạm vi spec này.
