# Feature Specification: Shmup — Máu/mạng người chơi

**Feature Branch**: `004-shmup-player-health`
**Created**: 2026-07-02
**Status**: Draft
**Input**: User description: "Thêm hệ thống máu/mạng cho người chơi: thanh máu hoặc số mạng thay vì chết ngay khi trúng 1 viên đạn địch, có khoảng bất tử ngắn sau khi trúng đạn"

## User Scenarios & Testing *(mandatory)*

### User Story 1 — Nhiều mạng thay vì chết ngay (Priority: P1) 🎯 MVP

Người chơi bắt đầu ván với **nhiều điểm máu/mạng** (không chỉ 1 như hiện tại). Khi trúng một viên đạn địch (và không có khiên, không đang bất tử), người chơi **mất một điểm máu** thay vì kết thúc ván ngay lập tức. Ván chỉ kết thúc (game over) khi máu về **0**. Số máu hiện tại hiển thị được cho người chơi trong lúc chơi.

**Why this priority**: Đây là thay đổi luật cốt lõi bắt buộc phải có trước — không có nó thì "khoảng bất tử" (US2) và cách khiên tương tác (US3) không có ý nghĩa để định nghĩa.

**Independent Test**: Chơi một ván, cố ý để trúng đạn địch nhiều lần liên tiếp (cách nhau đủ lâu); xác nhận mỗi lần trúng chỉ trừ một điểm máu và ván tiếp tục cho tới khi máu về 0 mới kết thúc.

**Acceptance Scenarios**:

1. **Given** người chơi vừa bắt đầu ván, **When** ván khởi tạo, **Then** người chơi có máu ở mức tối đa mặc định (nhiều hơn 1).
2. **Given** người chơi còn máu > 1 và không có khiên/bất tử, **When** trúng một viên đạn địch, **Then** máu giảm đúng 1 và ván **không** kết thúc.
3. **Given** người chơi chỉ còn 1 máu và không có khiên/bất tử, **When** trúng một viên đạn địch, **Then** máu về 0 và ván kết thúc (game over) như luật hiện có.
4. **Given** ván đang diễn ra, **When** người chơi đang chơi, **Then** số máu hiện tại được hiển thị (ví dụ dạng số hoặc thanh máu) trên giao diện.

---

### User Story 2 — Khoảng bất tử ngắn sau khi trúng đạn (Priority: P2)

Ngay sau khi mất một điểm máu, người chơi có một **khoảng thời gian ngắn bất tử** (miễn nhiễm với mọi va chạm đạn địch tiếp theo) trước khi có thể bị trừ máu lần nữa. Trong khoảng này, người chơi nên có **phản hồi hình ảnh** (ví dụ nhấp nháy) để biết mình đang bất tử.

**Why this priority**: Không có khoảng bất tử, nhiều viên đạn trúng gần như cùng lúc (hoặc đứng giữa luồng đạn dày ở tier cao) sẽ trừ hết máu ngay lập tức, làm mất ý nghĩa của US1. Đây là điều kiện cần để hệ thống máu thực sự hữu ích.

**Independent Test**: Cố ý để trúng đạn, sau đó ngay lập tức lái tàu vào luồng đạn khác trong khoảng bất tử; xác nhận không bị trừ thêm máu cho tới khi khoảng bất tử kết thúc.

**Acceptance Scenarios**:

1. **Given** người chơi vừa mất một điểm máu, **When** một viên đạn địch khác chạm vào người chơi trong khoảng bất tử, **Then** máu **không** giảm thêm và ván tiếp tục bình thường.
2. **Given** khoảng bất tử đang diễn ra, **When** khoảng thời gian đó kết thúc, **Then** viên đạn địch tiếp theo chạm vào người chơi trừ máu bình thường trở lại.
3. **Given** người chơi đang bất tử, **When** quan sát giao diện, **Then** có tín hiệu hình ảnh phân biệt được với trạng thái bình thường (ví dụ nhấp nháy tàu).

---

### User Story 3 — Khiên (003) vẫn hoạt động độc lập với máu (Priority: P3)

Khiên tạm thời (đã có ở feature 003) tiếp tục **hấp thụ hoàn toàn** một lần trúng đạn — khi có khiên, trúng đạn địch **không trừ máu và không kích hoạt khoảng bất tử** (khác với một lần trúng thường, vốn trừ máu và kích hoạt bất tử). Khiên và khoảng bất tử là hai cơ chế phòng thủ độc lập, có thể tồn tại cùng lúc.

**Why this priority**: Đảm bảo tính năng máu mới không âm thầm phá vỡ hành vi khiên đã có; giá trị chủ yếu là tương thích ngược, ưu tiên thấp hơn hai user story thay đổi luật cốt lõi ở trên.

**Independent Test**: Nhặt khiên, để trúng đạn — xác nhận máu không đổi và khiên tiêu hao; sau đó để trúng đạn tiếp theo (không còn khiên, không bất tử) — xác nhận máu giảm đúng 1 như luật US1.

**Acceptance Scenarios**:

1. **Given** người chơi đang có khiên hoạt động, **When** trúng một viên đạn địch, **Then** máu không đổi, khiên bị tiêu hao, và người chơi **không** vào trạng thái bất tử từ sự kiện này.
2. **Given** người chơi vừa hết khiên do vừa tiêu hao (không phải do trúng đạn), **When** trúng viên đạn tiếp theo, **Then** máu giảm 1 và khoảng bất tử được kích hoạt như bình thường (US1/US2).

---

### Edge Cases

- **Nhiều viên đạn trúng cùng một tick**: Nếu nhiều viên đạn địch chạm người chơi trong cùng một bước mô phỏng, chỉ trừ **đúng 1** điểm máu cho tick đó (không trừ theo số viên đạn trúng), tương tự cách khiên hiện tại chỉ xử lý một va chạm mỗi tick.
- **Game over khi máu về 0 trong lúc đang bất tử từ trước**: Không xảy ra theo thiết kế — bất tử nghĩa là không thể bị trừ máu, nên máu chỉ có thể về 0 tại đúng thời điểm không bất tử.
- **Ván mới sau game over**: `new_playing/0` luôn khởi tạo lại máu ở mức tối đa và không bất tử — không kế thừa trạng thái máu/bất tử từ ván trước (giống nguyên tắc đã áp dụng cho power-up ở 003).
- **Tương tác với độ khó tăng dần (002)**: Số máu tối đa và thời lượng bất tử là hằng số cố định trong phạm vi spec này (không tăng/giảm theo tier) — hệ thống máu không được làm giảm ý nghĩa của độ khó tăng dần (ví dụ bất tử không được kéo dài tới mức xoá thử thách đạn địch dày ở tier cao).
- **Hiển thị máu**: Nếu máu tối đa là một số cụ thể (không phải "vô hạn" hay thanh phần trăm), giao diện cần thể hiện rõ cả máu hiện tại lẫn máu tối đa (ví dụ "Máu: 2/3") để người chơi hiểu được mức độ nguy hiểm.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Trò MUST khởi tạo người chơi với máu ở một mức tối đa cố định lớn hơn 1 khi bắt đầu ván (`new_playing/0`).
- **FR-002**: Khi người chơi trúng đạn địch mà không có khiên và không đang bất tử, trò MUST trừ đúng 1 điểm máu và kích hoạt khoảng bất tử, thay vì kết thúc ván ngay như hành vi cũ.
- **FR-003**: Trò MUST kết thúc ván (game over) khi và chỉ khi máu người chơi giảm xuống 0.
- **FR-004**: Trong khoảng bất tử, trò MUST không trừ thêm máu dù có bao nhiêu viên đạn địch chạm vào người chơi.
- **FR-005**: Khoảng bất tử MUST có thời lượng cố định tính theo thời gian chơi (play_tick) và tự động kết thúc, sau đó việc trúng đạn trừ máu bình thường trở lại.
- **FR-006**: Giao diện MUST hiển thị số máu hiện tại (và máu tối đa) cho người chơi trong lúc `:playing`.
- **FR-007**: Trò MUST cung cấp tín hiệu hình ảnh phân biệt được khi người chơi đang bất tử (khác trạng thái bình thường).
- **FR-008**: Khi người chơi có khiên (feature 003) và trúng đạn, trò MUST giữ nguyên hành vi khiên hiện có (không trừ máu, không kết thúc ván) và KHÔNG kích hoạt khoảng bất tử từ sự kiện đó.
- **FR-009**: Nhiều viên đạn địch trúng người chơi trong cùng một bước mô phỏng MUST chỉ gây trừ tối đa 1 điểm máu cho bước đó.
- **FR-010**: Khi bắt đầu ván mới (`new_playing/0`), máu và trạng thái bất tử MUST luôn về mặc định — không kế thừa từ ván trước.
- **FR-011**: Toàn bộ trạng thái máu/bất tử MUST là một phần của `%GameState{}`/player map và được cập nhật thuần túy trong pipeline `Simulation.step/1`, không thêm process/side-effect mới.

### Key Entities

- **Máu người chơi (hp/max_hp)**: Số nguyên trên player, giảm khi trúng đạn (ngoài khiên/bất tử), quyết định thời điểm game over khi về 0.
- **Bất tử (invulnerable)**: Trạng thái tạm thời trên player sau khi mất máu, có thời hạn tính bằng play_tick, chặn mọi trừ máu tiếp theo cho tới khi hết hạn.
- **Người chơi (player)**: Mở rộng thêm `hp`, `max_hp`, `invulnerable_until` bên cạnh các trường hiện có (bao gồm khiên/hiệu lực từ 003).

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Người chơi có thể trúng đạn địch tối thiểu 2 lần (cách nhau đủ lâu để hết bất tử) trước khi ván kết thúc, với máu tối đa mặc định.
- **SC-002**: Trúng nhiều đạn địch trong cùng một khoảnh khắc/khoảng bất tử chỉ gây đúng 1 lần trừ máu quan sát được, không phải nhiều lần.
- **SC-003**: Giao diện luôn phản ánh đúng số máu hiện tại trong lúc chơi, khớp với số lần trúng đạn đã xảy ra (trừ khiên).
- **SC-004**: Có khiên khi trúng đạn thì máu không đổi, xác nhận được qua so sánh trước/sau lần trúng đó.
- **SC-005**: Bắt đầu ván mới sau game over luôn cho máu ở mức tối đa và không bất tử, không kế thừa từ ván trước.
- **SC-006**: Các luật cốt lõi đã có (điều khiển, điểm, độ khó tăng dần theo 002, power-up theo 003, kỷ lục cục bộ) vẫn hoạt động không đổi khi hệ thống máu được bật.

## Assumptions

- Máu tối đa là **hằng số cố định** trong phạm vi spec này (ví dụ 3); không có power-up hồi máu hoặc tăng máu tối đa — để lại cho spec sau nếu cần.
- Thời lượng bất tử là **hằng số cố định** tính theo play_tick, giá trị cụ thể chốt ở bước `plan`/`research`, tương tự cách 002/003 đã làm với các bảng tham số khác.
- Hiển thị máu ở mức tối thiểu (text hoặc icon đơn giản) là đủ cho phạm vi spec này — không yêu cầu thiết kế UI thanh máu phức tạp.
- Bất tử chỉ được kích hoạt bởi việc **mất máu** (không phải bởi việc nhặt power-up hay bất kỳ hành động nào khác ngoài phạm vi FR-002).
