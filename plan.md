# Project Implementation Plan: Material Cost by Tag (SketchUp Extension)

แผนงานสำหรับการพัฒนา SketchUp Extension คำนวณปริมาณวัสดุและประเมินราคาก่อสร้าง (BOQ) ตาม Tag (Layer) 

---

## Phase 1: Structure & Extension Setup
- [ ] 1.1 สร้างโครงสร้างโฟลเดอร์โครงการตาม Architecture (Plugins/material_cost_by_tag/...)
- [ ] 1.2 เขียนไฟล์ `material_cost_by_tag.rb` สำหรับลงทะเบียน SketchupExtension กับ SketchUp API
- [ ] 1.3 เขียนไฟล์ `material_cost_by_tag/main.rb` เพื่อโหลดโมดูลย่อยและสร้าง เมนู/ไอคอน Toolbar
- [ ] 1.4 จัดสรรไฟล์จัดเก็บข้อมูลตั้งต้น `data/prices.json`

---

## Phase 2: Core Ruby Backend Development
- [ ] 2.1 พัฒนา `ModelCollector` (`core/model_collector.rb`)
  - วนลูปสแกน Entities ทั้งหมดใน active_model (รองรับ Face, Group, ComponentInstance)
  - ดึงค่าและจัดหมวดหมู่ตาม Tag/Layer (กำหนดวัตถุไร้ Tag เป็น UNTAGGED)
- [ ] 2.2 พัฒนา `Calculator` (`core/calculator.rb`)
  - ระบบแปลงหน่วยวัด SketchUp (Inches) ไปยังหน่วยเมตริกและอิมพีเรียล (m, m², m³, ft, ft², ft³, yd³, kg, tonne, ฯลฯ)
  - คำนวณสูตรราคารวม: Total Cost = Quantity x (Unit Cost x Factor) x (1 + Waste%/100) x (1 + Tax%/100)
- [ ] 2.3 พัฒนา `PriceStore` (`core/price_store.rb`)
  - ฟังก์ชัน อ่าน/เขียน ไฟล์ `data/prices.json`
  - ทำความสะอาดและตรวจทานความถูกต้องของข้อมูล (Data Sanitization & Validation)

---

## Phase 3: Frontend UI Development (Modern Theme)
- [ ] 3.1 สร้างโครงสร้าง HTML (`ui/index.html`)
  - ส่วน Header ("Material Cost")
  - ส่วน Top Toolbar (Tag Dropdown, Weight Input & Unit, Action Buttons)
  - ส่วน Data Table (Code, Description, Input, Factor, Unit, Unit Cost, Waste%, Tax%, Actions)
- [ ] 3.2 ปรับแต่งความสวยงามด้วย CSS (`ui/styles.css`)
  - ใช้ Modern Design (CSS Variables, Soft Shadows, Clean Input Controls)
- [ ] 3.3 พัฒนา JavaScript UI Logic
  - ระบบ Dynamic Row Generation (เพิ่ม/ลบ แถวตาราง)
  - ระบบ Auto-sync ค่าในช่อง Unit ตามการเลือกในช่อง Input Dropdown (ft, ft2, m, m2, ฯลฯ)

---

## Phase 4: Ruby & JS Bridge Integration
- [ ] 4.1 พัฒนา `DialogManager` (`ui/dialog_manager.rb`)
  - สร้างและตั้งค่า `UI::HtmlDialog`
- [ ] 4.2 ลงทะเบียน JS to Ruby Action Callbacks
  - `save_tag_cost_data`: รับข้อมูล JSON จากตาราง UI เพื่อบันทึกลงไฟล์
  - `refresh_summary`: ร้องขอการคำนวณจากโมเดลใหม่
  - `highlight_results`: ส่งคำสั่งไฮไลต์วัตถุใน 3D Viewport
- [ ] 4.3 เชื่อมต่อ Ruby to JS Execution
  - ใช้ `@dialog.execute_script()` ส่งข้อมูลการคำนวณปริมาณงานไปวาดบน UI

---

## Phase 5: Advanced Features & Export Module
- [ ] 5.1 พัฒนา `CsvExporter` (`core/csv_exporter.rb`)
  - จัดรูปแบบข้อมูลสรุปผล BOQ เป็นโครงสร้าง CSV
  - ระบบดาวน์โหลดไฟล์ CSV ผ่านทางหน้าต่าง Web UI
- [ ] 5.2 พัฒนาระบบ Selection Highlighting ใน 3D Viewport
  - เลือกวัตถุในโมเดลจริงทันทีเมื่อคลิกดูข้อมูล Tag บน UI

---

## Phase 6: Testing, Refinement & Deployment
- [ ] 6.1 ทดสอบคำนวณกับโมเดลซับซ้อน (Nested Groups/Components)
- [ ] 6.2 ตรวจสอบความถูกต้องของการแปลงหน่วยและการคิดคำนวณสูตรราคา
- [ ] 6.3 แพ็กเกจไฟล์ทั้งหมดเข้าโฟลเดอร์ และบีบอัดเป็นไฟล์ `.rbz` พร้อมติดตั้งใช้งานจริง