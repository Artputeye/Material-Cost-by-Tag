MATERIAL COST BY TAG/
├── data/
│   └── prices.json
├── icons/
│   └── material_cost_icon_32.png
├── src/
│   ├── core/
│   │   ├── calculator.rb
│   │   ├── csv_handler.rb
│   │   ├── model_collector.rb
│   │   ├── price_store.rb
│   │   └── tag_measurer.rb
│   └── main.rb
├── ui/
│   ├── app.js
│   ├── dialog_manager.rb
│   ├── index.html
│   └── styles.css
├── build.ps1
├── build.rb
├── context.md
├── MaterialCostByTag.rb
├── MaterialCostByTag.rbz
├── plan.md
├── README.md
├── Structure.md
└── Temp.txt

หมายเหตุ: `build.rb` เป็นไฟล์ว่างในปัจจุบัน ส่วน `MaterialCostByTag.rbz` เป็นไฟล์แพ็กเกจที่สร้างไว้แล้ว

รายละเอียดหน้าที่ของแต่ละไฟล์และ Module

1. Root Loader และ Entry Point
- `MaterialCostByTag.rb`: โหลด `sketchup.rb` และ `extensions.rb` จากนั้นสร้างและลงทะเบียน `SketchupExtension` โดยชี้ไปที่ `src/main.rb` พร้อมกำหนดชื่อ ผู้พัฒนา เวอร์ชัน และคำอธิบาย
- `src/main.rb`: โหลดไฟล์ Core และ `ui/dialog_manager.rb` ด้วย `require_relative` จากนั้นสร้างคำสั่งเมนู/Toolbar ชื่อ Material Cost และเชื่อมไปยัง `DialogManager.show_dialog`

2. Core Modules
- `MaterialCostByTag::Calculator` (`src/core/calculator.rb`): แปลงปริมาณจากหน่วยภายในของ SketchUp (นิ้ว) เป็น `m`, `m2`, `m3`, `ft`, `ft2`, `ft3` หรือ `yd3` และคำนวณต้นทุนด้วย Factor, Waste% และ Tax%
- `MaterialCostByTag::TagMeasurer` (`src/core/tag_measurer.rb`): วัดความยาวขอบที่ยาวที่สุด พื้นที่ Face ที่ใหญ่ที่สุด และปริมาตรของ Group/ComponentInstance ตาม Tag แล้วส่งค่ากลับเป็น `m`, `m2` และ `m3`
- `MaterialCostByTag::ModelCollector` (`src/core/model_collector.rb`): อ่านรายชื่อ Tag จาก Layers ของ Active Model และเลือก Group/ComponentInstance ที่ตรงกับ Tag เพื่อ Highlight ใน Selection
- `MaterialCostByTag::PriceStore` (`src/core/price_store.rb`): บันทึก/โหลดข้อมูลราคาใน Attribute Dictionary ของโมเดล (`MaterialCostByTag_Data`) และสำรองข้อมูลใน `data/prices.json` พร้อมทำความสะอาดข้อมูลก่อนบันทึก
- `MaterialCostByTag::CsvExporter` และ `MaterialCostByTag::CsvImporter` (`src/core/csv_handler.rb`): ส่งออกข้อมูลรายการเป็น CSV และนำเข้า CSV เพื่ออัปเดตรายการเดิมหรือเพิ่มรายการใหม่ โดยจับคู่ด้วย Tag และ Description

3. UI
- `MaterialCostByTag::DialogManager` (`ui/dialog_manager.rb`): สร้าง `UI::HtmlDialog`, เปิด `ui/index.html` และผูก callbacks `get_tags`, `get_all_saved_data`, `get_tag_measurements`, `save_tag_cost_data`, `export_csv_data` และ `import_csv_data`
- `ui/index.html`: โครงหน้าเว็บ ตารางรายการวัสดุ แถบสรุปราคารวม/น้ำหนักรวม และปุ่มนำเข้า/ส่งออก/บันทึก
- `ui/app.js`: จัดการตาราง คำนวณปริมาณ น้ำหนัก ต้นทุนรวม สรุปยอด บันทึก/นำเข้า/ส่งออกข้อมูล และสื่อสารกับ Ruby ผ่าน `window.sketchup`
- `ui/styles.css`: รูปแบบการแสดงผลของหน้าต่าง UI

4. Build และข้อมูลประกอบ
- `build.ps1`: บีบอัด `MaterialCostByTag.rb`, `data`, `icons`, `src` และ `ui` เป็น `MaterialCostByTag.rbz`
- `data/prices.json`: ไฟล์ข้อมูลราคาที่ใช้เป็นแหล่งสำรอง/เก็บข้อมูลราคา
- `icons/material_cost_icon_32.png`: ไอคอนของคำสั่งบน Toolbar