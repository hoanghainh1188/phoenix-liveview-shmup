# Feature Specification: Shmup — Đa dạng địch và Boss

**Feature Branch**: `005-shmup-enemy-variety`
**Created**: 2026-07-02
**Status**: Draft
**Input**: User description: "Thêm đa dạng loại địch (ví dụ địch máu dày di chuyển chậm) và một boss xuất hiện định kỳ sau mỗi vài tier độ khó, có máu lớn và thưởng điểm cao khi hạ được"

## User Scenarios & Testing *(mandatory)*

### User Story 1 — Ít nhất hai loại địch thường khác nhau (Priority: P1) 🎯 MVP

Ngoài loại địch cơ bản hiện có, trò xuất hiện thêm ít nhất **một loại địch khác** với đặc điểm khác biệt rõ rệt (ví dụ: máu dày hơn, di chuyển chậm hơn, kích thước lớn hơn). Loại địch mới xuất hiện xen kẽ với loại cơ bản theo tiến trình độ khó, không thay thế hoàn toàn loại cũ.

**Why this priority**: Đây là nền tảng bắt buộc trước khi có ý nghĩa để nói tới "boss" — không có khái niệm phân loại địch thì không thể mô tả boss như một loại đặc biệt.

**Independent Test**: Chơi một ván đủ lâu, quan sát địch xuất hiện; xác nhận có ít nhất hai hình dạng/kích thước khác nhau, và loại "máu dày, chậm" cần nhiều phát trúng hơn để hạ so với loại cơ bản.

**Acceptance Scenarios**:

1. **Given** ván đang diễn ra ở độ khó đủ cao để loại địch mới xuất hiện, **When** địch được sinh ra, **Then** có thể quan sát được ít nhất hai loại địch khác nhau về kích thước hoặc tốc độ.
2. **Given** một địch thuộc loại "máu dày", **When** đạn người chơi trúng, **Then** số lần trúng cần thiết để hạ nhiều hơn địch loại cơ bản ở cùng bậc độ khó.
3. **Given** một địch thuộc loại "máu dày", **When** quan sát chuyển động, **Then** tốc độ di chuyển xuống chậm hơn rõ rệt so với địch cơ bản.

---

### User Story 2 — Boss xuất hiện định kỳ theo tier (Priority: P2)

Sau mỗi vài bậc độ khó (ví dụ mỗi 5 tier), một **boss** xuất hiện: kích thước lớn hơn hẳn, máu nhiều hơn hẳn so với địch thường cùng thời điểm, và khi bị hạ **thưởng điểm cao** hơn nhiều so với địch thường. Mỗi mốc tier chỉ sinh **đúng một boss**, không lặp lại liên tục.

**Why this priority**: Đây là điểm nhấn chính người dùng yêu cầu, nhưng phụ thuộc vào cơ chế phân loại địch đã có ở US1 để triển khai nhất quán.

**Independent Test**: Chơi đủ lâu để vượt qua mốc tier sinh boss đầu tiên; xác nhận đúng một boss xuất hiện (không phải nhiều), có kích thước/máu vượt trội, và hạ được thì điểm tăng vọt so với hạ địch thường.

**Acceptance Scenarios**:

1. **Given** độ khó vừa đạt một mốc tier sinh boss (ví dụ tier là bội số của 5), **When** vòng lặp mô phỏng xử lý mốc đó, **Then** đúng một boss được sinh ra, không sinh thêm boss khác cho tới mốc tier kế tiếp.
2. **Given** boss đang tồn tại trên màn hình, **When** so sánh với địch thường cùng thời điểm, **Then** boss có máu nhiều hơn hẳn (cần nhiều phát trúng hơn đáng kể) và thường có kích thước lớn hơn.
3. **Given** boss bị hạ (máu về 0), **When** tính điểm, **Then** điểm thưởng lớn hơn nhiều lần so với điểm hạ một địch thường.
4. **Given** boss đã bị hạ hoặc đã ra khỏi màn hình, **When** độ khó chưa đạt mốc tier sinh boss tiếp theo, **Then** không có boss nào khác xuất hiện cho tới mốc kế tiếp.

---

### User Story 3 — Phân biệt trực quan các loại địch (Priority: P3)

Trên giao diện, mỗi loại địch (cơ bản, máu dày, boss) có **màu sắc hoặc kích thước khác nhau** để người chơi nhận biết ngay từ xa loại địch nào đang tới, đặc biệt là boss.

**Why this priority**: Cải thiện trải nghiệm và khả năng đọc trận đấu, nhưng không ảnh hưởng luật chơi cốt lõi — có thể triển khai sau cùng khi US1/US2 đã hoạt động đúng.

**Independent Test**: Quan sát màn hình khi có đủ các loại địch; xác nhận phân biệt được bằng mắt loại cơ bản, loại máu dày, và boss mà không cần đọc số liệu debug.

**Acceptance Scenarios**:

1. **Given** nhiều loại địch cùng xuất hiện trên màn hình, **When** người chơi quan sát, **Then** mỗi loại có màu sắc hoặc kích thước phân biệt được rõ ràng.
2. **Given** boss xuất hiện, **When** người chơi quan sát, **Then** boss nổi bật rõ rệt so với mọi địch thường khác trên màn hình.

---

### Edge Cases

- **Bỏ lỡ mốc tier do tăng nhanh**: Nếu độ khó tăng vượt quá một mốc sinh boss trong cùng một bước mô phỏng (về lý thuyết tier chỉ tăng dần 1 mỗi lần nên khó xảy ra, nhưng phải đảm bảo không sinh boss trùng lặp hoặc bỏ sót nếu logic tier thay đổi sau này).
- **Boss còn sống khi ván kết thúc**: Không cần xử lý đặc biệt — ván mới (`new_playing/0`) phải reset lại trạng thái theo dõi boss, không được để "đã sinh boss ở mốc X" rò rỉ sang ván sau khiến boss không bao giờ xuất hiện lại.
- **Boss ra khỏi màn hình mà chưa bị hạ**: Xử lý như địch thường khi ra khỏi màn hình (dọn dẹp, không cộng điểm) — không có xử lý đặc biệt "boss chạy trốn".
- **Giới hạn số địch đồng thời (`max_enemies` theo tier, từ 002)**: Boss vẫn tính là một địch trong tổng số, không được phá vỡ giới hạn/hiệu năng đã thiết lập ở 002.
- **Tương tác với power-up (003)**: Việc địch (kể cả boss) rơi power-up vẫn theo đúng tỉ lệ xác suất đã có ở 003 — không bắt buộc boss phải rơi power-up 100%, tránh phức tạp hoá phạm vi.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Trò MUST hỗ trợ tối thiểu hai loại địch thường ("cơ bản" và "máu dày") có thể phân biệt được qua máu và/hoặc tốc độ di chuyển.
- **FR-002**: Loại địch "máu dày" MUST có máu cao hơn và tốc độ di chuyển xuống chậm hơn so với địch "cơ bản" cùng bậc độ khó.
- **FR-003**: Việc chọn loại địch thường khi sinh ra MUST tất định (không dùng số ngẫu nhiên không kiểm soát được), để có thể viết test xác định được loại địch sinh ra.
- **FR-004**: Trò MUST sinh đúng một boss mỗi khi độ khó đạt một mốc tier cố định (ví dụ mỗi 5 tier), không sinh nhiều boss cho cùng một mốc.
- **FR-005**: Boss MUST có máu vượt trội (nhiều hơn đáng kể) so với địch thường cùng bậc độ khó tại thời điểm boss xuất hiện.
- **FR-006**: Hạ được boss MUST cộng điểm thưởng lớn hơn nhiều lần so với điểm hạ một địch thường.
- **FR-007**: Trò MUST theo dõi mốc tier sinh boss tiếp theo trong `%GameState{}`, cập nhật sau mỗi lần sinh boss để không sinh trùng cho cùng một mốc.
- **FR-008**: Khi bắt đầu ván mới (`new_playing/0`), trạng thái theo dõi mốc boss MUST reset về mặc định — không kế thừa từ ván trước.
- **FR-009**: Giao diện MUST hiển thị được sự khác biệt trực quan (màu sắc và/hoặc kích thước) giữa địch cơ bản, địch máu dày, và boss.
- **FR-010**: Toàn bộ logic phân loại địch và sinh boss MUST là một phần của pipeline `Simulation.step/1` thuần túy, không thêm process/side-effect mới.
- **FR-011**: Số lượng địch đồng thời (bao gồm boss) MUST tiếp tục tuân theo giới hạn `max_enemies` theo tier đã có ở 002.

### Key Entities

- **Loại địch (enemy kind)**: Thuộc tính mới trên địch — `:grunt` (cơ bản, hành vi hiện có), `:tank` (máu dày, chậm hơn), `:boss` (mốc tier định kỳ, máu rất cao, thưởng điểm lớn).
- **Mốc boss tiếp theo (next boss tier)**: Trạng thái trên `%GameState{}` theo dõi mốc tier kế tiếp sẽ sinh boss, tăng lên sau mỗi lần sinh để tránh trùng lặp.
- **Địch (enemy)**: Mở rộng thêm trường `kind`; máu, kích thước, và điểm thưởng khi hạ đều phụ thuộc `kind` thay vì chỉ phụ thuộc tier như trước.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Trong một ván đủ dài, người chơi quan sát được ít nhất hai loại địch thường khác nhau về kích thước/tốc độ.
- **SC-002**: Địch loại "máu dày" luôn cần nhiều phát trúng hơn địch "cơ bản" cùng bậc độ khó để hạ, đo được qua so sánh trực tiếp.
- **SC-003**: Sau khi vượt mốc tier sinh boss đầu tiên (ví dụ tier 5), đúng một boss xuất hiện — không phải 0, không phải nhiều hơn 1.
- **SC-004**: Hạ boss cho điểm thưởng cao hơn rõ rệt (đo được, ví dụ gấp nhiều lần) so với hạ địch thường ngay trước đó trong cùng ván.
- **SC-005**: Bắt đầu ván mới sau game over luôn cho phép boss xuất hiện lại đúng từ mốc tier đầu tiên, không bị "dùng hết" từ ván trước.
- **SC-006**: Các luật cốt lõi đã có (điều khiển, điểm, độ khó tăng dần theo 002, power-up theo 003, máu người chơi theo 004, kỷ lục cục bộ) vẫn hoạt động không đổi khi tính năng đa dạng địch/boss được bật.

## Assumptions

- Mốc tier sinh boss là **hằng số cố định** (ví dụ mỗi 5 tier); giá trị cụ thể và bảng tham số máu/điểm thưởng boss chốt ở bước `plan`/`research`, tương tự các bảng tham số trước đó (002/003/004).
- Boss dùng lại các chế độ chuyển động đã có (`Physics.step_enemy/2`) thay vì cần engine hành vi mới — chỉ khác biệt về máu, kích thước, và điểm thưởng, không yêu cầu "đòn tấn công đặc biệt" trong phạm vi spec này.
- Boss không bắt buộc rơi power-up 100% khi bị hạ — vẫn theo đúng tỉ lệ xác suất chung đã có ở 003.
- Không giới hạn tối đa số boss xuất hiện trong một ván dài (mỗi mốc tier một boss, không có "trần" số boss) — để lại cân nhắc lại nếu cần trong spec sau.
