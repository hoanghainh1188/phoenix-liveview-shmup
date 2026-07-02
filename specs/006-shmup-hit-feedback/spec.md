# Feature Specification: Shmup — Hiệu ứng xác nhận trúng đạn

**Feature Branch**: `006-shmup-hit-feedback`
**Created**: 2026-07-02
**Status**: Draft
**Input**: User description: "Thêm hiệu ứng xác nhận trúng đạn rõ ràng: nổ/flash tại vị trí địch bị hạ thật sự (do server xác nhận), và số điểm nhấp nháy khi tăng, để người chơi phân biệt được trúng thật với cảm giác trúng do độ trễ mạng"

## User Scenarios & Testing *(mandatory)*

### User Story 1 — Hiệu ứng nổ tại vị trí hạ địch thật sự (Priority: P1) 🎯 MVP

Khi server xác nhận một địch bị hạ (hp về 0 do trúng đạn người chơi), một hiệu ứng hình ảnh rõ ràng (nổ/flash) xuất hiện đúng tại vị trí địch đó trong vài khung hình, rồi biến mất. Địch **rời khỏi màn hình do bay hết chiều cao** (không bị hạ) thì **không** có hiệu ứng này — chỉ biến mất lặng lẽ như hiện tại.

**Why this priority**: Đây là nguồn gốc trực tiếp của sự nhầm lẫn đã quan sát được (đạn trông như trúng địch do độ trễ mạng, nhưng không được tính điểm) — người chơi cần một tín hiệu server-xác-nhận rõ ràng, tách biệt khỏi việc chỉ "địch biến mất" (vốn xảy ra cả khi hạ được lẫn khi địch tự trôi ra khỏi màn hình).

**Independent Test**: Chơi một ván, hạ một địch — xác nhận thấy hiệu ứng nổ đúng tại vị trí đó; để một địch khác trôi hết ra khỏi màn hình mà không bắn trúng — xác nhận **không** có hiệu ứng nổ nào xuất hiện cho địch đó.

**Acceptance Scenarios**:

1. **Given** một địch đang còn hp, **When** đạn người chơi khiến hp về 0 (bị hạ), **Then** một hiệu ứng nổ/flash xuất hiện tại đúng vị trí (x, y) của địch vào thời điểm bị hạ.
2. **Given** hiệu ứng nổ vừa xuất hiện, **When** vài khung hình trôi qua, **Then** hiệu ứng tự biến mất (không tồn tại vĩnh viễn, không tích tụ theo thời gian).
3. **Given** một địch bay tới đáy màn hình mà chưa từng bị trúng đạn, **When** địch bị dọn dẹp do ra khỏi màn hình, **Then** không có hiệu ứng nổ nào xuất hiện.
4. **Given** nhiều địch bị hạ trong cùng một khung hình (ví dụ nhiều viên đạn trúng nhiều địch cùng lúc), **When** khung hình đó được xử lý, **Then** mỗi địch bị hạ đều có hiệu ứng nổ riêng tại đúng vị trí của nó (không chỉ một hiệu ứng duy nhất).

---

### User Story 2 — Số điểm nhấp nháy khi tăng (Priority: P2)

Mỗi khi điểm số tăng (do hạ được địch), dòng chữ "Điểm" hiển thị trong lúc chơi có một hiệu ứng nhấp nháy/nổi bật ngắn để thu hút sự chú ý, giúp người chơi nhận ra ngay điểm vừa được cộng — kể cả khi họ đang tập trung nhìn vào vùng chơi (canvas) chứ không phải dòng điểm phía trên.

**Why this priority**: Bổ sung thêm một tín hiệu xác nhận thứ hai, độc lập với hiệu ứng nổ trên canvas — hữu ích khi hành động dồn dập khiến người chơi có thể bỏ lỡ hiệu ứng nổ. Ưu tiên thấp hơn US1 vì US1 đã giải quyết phần lớn nguồn gốc nhầm lẫn.

**Independent Test**: Hạ một địch, quan sát dòng "Điểm" — xác nhận có hiệu ứng nhấp nháy/nổi bật ngắn ngay sau khi điểm tăng, rồi trở lại trạng thái bình thường.

**Acceptance Scenarios**:

1. **Given** điểm số vừa tăng (do hạ địch), **When** giao diện cập nhật, **Then** dòng "Điểm" có hiệu ứng nổi bật ngắn (ví dụ đổi màu/phóng to nhẹ trong thời gian ngắn) rồi trở lại bình thường.
2. **Given** điểm số không đổi trong một khung hình, **When** giao diện cập nhật, **Then** dòng "Điểm" không có hiệu ứng nhấp nháy nào (chỉ kích hoạt khi thực sự tăng).

---

### User Story 3 — Cường độ hiệu ứng phản ánh loại địch (Priority: P3)

Hiệu ứng nổ khi hạ được `:boss` (điểm thưởng lớn) rõ rệt hơn (to hơn/nổi bật hơn) so với khi hạ `:grunt`/`:tank` thường, tương xứng với việc boss cho điểm thưởng lớn hơn nhiều lần.

**Why this priority**: Tinh chỉnh trải nghiệm, không giải quyết vấn đề nhầm lẫn cốt lõi — chỉ làm rõ hơn "đây là một cú hạ lớn" cho người chơi. Có thể triển khai sau cùng khi US1/US2 đã hoạt động đúng.

**Independent Test**: Hạ một `:grunt` và một `:boss` trong cùng một ván (hoặc quan sát riêng biệt); xác nhận hiệu ứng nổ của boss rõ ràng to hơn/nổi bật hơn.

**Acceptance Scenarios**:

1. **Given** một `:boss` bị hạ, **When** hiệu ứng nổ xuất hiện, **Then** hiệu ứng đó lớn hơn/nổi bật hơn rõ rệt so với hiệu ứng khi hạ `:grunt` hoặc `:tank`.

---

### Edge Cases

- **Nhiều địch bị hạ cùng lúc**: Đã nêu ở US1 Acceptance Scenario 4 — mỗi vị trí hạ địch phải có hiệu ứng riêng, không được gộp thành một hoặc chỉ hiển thị hiệu ứng cuối cùng.
- **Trạng thái ván mới**: Bắt đầu ván mới sau game over không được để sót hiệu ứng nổ từ ván trước hiển thị lại hoặc gây lỗi — đúng nguyên tắc "không kế thừa trạng thái tạm thời giữa các ván" đã áp dụng cho power-up/máu/boss ở các feature trước.
- **Hiệu ứng không được ảnh hưởng luật chơi**: Đây thuần túy là phản hồi hình ảnh — không được thay đổi hitbox, điểm số, hay bất kỳ luật va chạm nào đã có.
- **Tải payload**: Số lượng sự kiện hạ địch trong một khung hình bị giới hạn tự nhiên bởi `max_enemies`/luật spawn hiện có — không cần thêm giới hạn riêng, nhưng payload gửi cho client phải chỉ chứa dữ liệu tối thiểu cần để vẽ (vị trí, loại), không gửi nguyên map địch nội bộ.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Trò MUST phát sinh một sự kiện "hạ địch" (kèm vị trí x, y và loại địch) đúng vào thời điểm một địch bị hp về 0 do trúng đạn người chơi.
- **FR-002**: Trò MUST KHÔNG phát sinh sự kiện "hạ địch" khi một địch bị loại bỏ do ra khỏi màn hình (`cull_offscreen`) mà chưa từng bị trúng đạn tới hp 0.
- **FR-003**: Sự kiện "hạ địch" MUST chỉ tồn tại đúng trong khung hình (tick) mà nó xảy ra — không tích lũy hoặc lặp lại ở các khung hình sau.
- **FR-004**: Giao diện MUST hiển thị một hiệu ứng hình ảnh (nổ/flash) tại vị trí mỗi sự kiện "hạ địch", tự biến mất sau một khoảng thời gian ngắn cố định.
- **FR-005**: Nếu nhiều địch bị hạ trong cùng một khung hình, giao diện MUST hiển thị hiệu ứng riêng biệt cho từng vị trí, không gộp lại.
- **FR-006**: Giao diện MUST hiển thị hiệu ứng nổi bật ngắn trên dòng hiển thị điểm số mỗi khi điểm số tăng so với khung hình trước đó.
- **FR-007**: Hiệu ứng nổ MUST có cường độ/kích thước khác nhau tùy theo loại địch bị hạ (`:boss` nổi bật hơn `:tank`/`:grunt`).
- **FR-008**: Khi bắt đầu ván mới (`new_playing/0`), trạng thái sự kiện "hạ địch" đang chờ hiển thị MUST được reset về rỗng — không kế thừa từ ván trước.
- **FR-009**: Toàn bộ logic phát sinh sự kiện "hạ địch" MUST là một phần của pipeline `Simulation.step/1` thuần túy, không thêm process/side-effect mới; hiệu ứng hình ảnh (nổ, nhấp nháy điểm) MUST xử lý hoàn toàn ở phía client, không ảnh hưởng tới trạng thái game phía server.

### Key Entities

- **Sự kiện hạ địch (kill event)**: Dữ liệu tạm thời phát sinh trong một tick khi địch bị hạ — gồm vị trí (x, y) và loại địch (`kind`) tại thời điểm hạ. Không phải trạng thái lâu dài của `%GameState{}`, chỉ tồn tại để truyền cho client trong khung hình đó.
- **Hiệu ứng nổ (client-side)**: Đối tượng hiển thị tạm thời trên canvas, có vị trí, kích thước/cường độ theo loại địch, và thời gian sống ngắn trước khi tự xóa — quản lý hoàn toàn trong `game_hook.js`, không phải trạng thái server.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Trong một ván chơi, mọi lần hạ địch thành công (điểm tăng) đều đi kèm hiệu ứng nổ quan sát được tại đúng vị trí, không có trường hợp điểm tăng mà không có hiệu ứng hoặc ngược lại.
- **SC-002**: Địch tự trôi ra khỏi màn hình không bao giờ kích hoạt hiệu ứng nổ.
- **SC-003**: Dòng điểm số có phản hồi hình ảnh quan sát được (nhấp nháy) đúng mỗi lần điểm tăng.
- **SC-004**: Hiệu ứng khi hạ boss quan sát được là lớn hơn/nổi bật hơn hiệu ứng khi hạ địch thường.
- **SC-005**: Bắt đầu ván mới không hiển thị lại bất kỳ hiệu ứng nổ nào còn sót từ ván trước.
- **SC-006**: Các luật cốt lõi đã có (điều khiển, điểm, độ khó, power-up, máu, boss, kỷ lục cục bộ) vẫn hoạt động không đổi khi tính năng hiệu ứng được bật — đây thuần túy là lớp phản hồi hình ảnh bổ sung.

## Assumptions

- Đây là cải thiện **cảm nhận** (perceived responsiveness) chứ không phải giảm độ trễ mạng thực tế — không thay đổi kiến trúc server-authoritative hiện có, không thêm client-side prediction/reconciliation trong phạm vi spec này.
- Thời gian sống, kích thước cụ thể, và cách vẽ hiệu ứng nổ/nhấp nháy điểm là chi tiết triển khai chốt ở bước `plan`/`research`, tương tự các bảng tham số trước đó.
- Hiệu ứng hoàn toàn ở phía client (canvas + CSS) dựa trên dữ liệu server gửi xuống — không yêu cầu asset hình ảnh/sprite phức tạp, dùng hình khối/màu sắc đơn giản nhất quán với phong cách hiện tại của game.
