คำอธิบายการทำงานของโปรแกรม (Overview)

โปรแกรมนี้คือ SketchUp Extension สำหรับจัดทำรายการวัสดุและคำนวณต้นทุนตาม Tag ของโมเดล 3D โดยแบ่งเป็น Ruby Backend ที่เชื่อมต่อกับ SketchUp API และ HTML/CSS/JavaScript Frontend ที่ทำงานใน `UI::HtmlDialog`

1. การโหลด Extension และเปิดหน้าต่าง
- `MaterialCostByTag.rb` ลงทะเบียน Extension และชี้ไปยัง `src/main.rb`
- `src/main.rb` โหลด Core Modules และ `ui/dialog_manager.rb` จากนั้นสร้างคำสั่ง Material Cost ในเมนู Plugins และ Toolbar
- `DialogManager` เปิด `ui/index.html` และผูก Ruby callbacks กับ JavaScript bridge

2. การอ่าน Tag และวัดปริมาณ
- `ModelCollector.get_all_tags` อ่านรายชื่อจาก Layers ของ Active Model แล้วลบรายการซ้ำและเรียงตามตัวอักษร
- `TagMeasurer.get_tag_measurements` ตรวจ Group และ ComponentInstance ระดับบนสุดที่มี Tag ตรงกัน
- สำหรับแต่ละวัตถุ ระบบหาความยาวขอบที่มากที่สุด พื้นที่ Face ที่มากที่สุด และปริมาตร แล้วแปลงเป็น `m`, `m2` และ `m3`
- `ModelCollector.highlight_tag` มีความสามารถเลือก Group/ComponentInstance ตาม Tag ใน SketchUp Selection แต่ปัจจุบันยังไม่มี UI callback ที่เรียกฟังก์ชันนี้

3. การสื่อสารระหว่าง Ruby และ UI
- เมื่อ UI เรียก `get_tags`, `get_all_saved_data` หรือ `get_tag_measurements` Ruby จะส่งข้อมูลกลับด้วย `execute_script()` ในรูป JSON
- UI เรียก Ruby ผ่าน `window.sketchup` สำหรับ `save_tag_cost_data`, `export_csv_data` และ `import_csv_data`
- การคำนวณยอดรวม น้ำหนัก และต้นทุนต่อแถวทำใน `ui/app.js` และอัปเดตทันทีเมื่อค่าป้อนเปลี่ยน

4. การคำนวณต้นทุนและน้ำหนัก
- ผู้ใช้กำหนด Quantity, Factor, Weight/Unit, Unit Cost, Waste% และ Tax%
- สูตรต้นทุน:
  `Cost = Quantity x Factor x Unit Cost x (1 + Waste% / 100) x (1 + Tax% / 100)`
- น้ำหนักต่อแถวคำนวณจาก `Quantity x Factor x Weight/Unit` และรวมเป็น Total Weight (kg)
- หน่วยปริมาณที่ UI รองรับคือ `m`, `m2` และ `m3` โดยเลือกค่าจากผลการวัดของ Tag

5. การจัดเก็บและถ่ายโอนข้อมูล
- `PriceStore` ทำความสะอาดข้อมูลรายการก่อนบันทึก โดยเก็บ JSON ใน Attribute Dictionary `MaterialCostByTag_Data` ของโมเดล
- หากไม่พบข้อมูลในโมเดล ระบบจะอ่านจาก `data/prices.json`
- `CsvExporter` ส่งออกรายการเป็น CSV พร้อม UTF-8 BOM เพื่อให้เปิดใน Excel ได้สะดวก
- `CsvImporter` จับคู่รายการเดิมด้วย Tag และ Description ถ้าพบจะอัปเดต ถ้าไม่พบจะเพิ่มรายการใหม่