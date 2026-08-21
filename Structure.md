MATERIAL COST BY TAG/           
├── data/
│   └── prices.json
├── icons/
│   └── material_cost_icon_32.png
├── src/
│   ├── core/
│   │   ├── calculator.rb
│   │   ├── csv_exporter.rb
│   │   ├── model_collector.rb
│   │   └── price_store.rb
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
├── plan.md
├── README.md
├── Structure.md
└── Temp.txt

รายละเอียดหน้าที่ของแต่ละ Module

1. Root Loader & Entry Point
- material_cost_by_tag.rb: ไฟล์ระดับบนสุดที่วางไว้ในโฟลเดอร์ Plugins ทำหน้าที่เรียก SketchupExtension.new กำหนดรายละเอียดเวอร์ชัน ผู้พัฒนา และสั่งโหลดโฟลเดอร์หลัก
- material_cost_by_tag/main.rb: ใช้ require_relative ดึงไฟล์โมดูลย่อยทั้งหมดมารวมกัน และลงทะเบียนสร้างปุ่มเมนูบน Toolbar/Extensions Menu

1. Core Modules (การประมวลผลข้อมูล)
- MaterialCostByTag::ModelCollector (core/model_collector.rb):
  * สแกนหาวัตถุใน active_model รองรับทั้ง Face, Group, และ ComponentInstance
  * ดึงค่า Tag/Layer ของแต่ละวัตถุ (พร้อมจัดกลุ่มวัตถุที่ไม่มี Tag เป็น UNTAGGED)
  * มีฟังก์ชันสั่ง Highlighting วัตถุใน SketchUp Viewport ตาม Tag ที่เลือก

- MaterialCostByTag::Calculator (core/calculator.rb):
  * แปลงหน่วยจาก SketchUp Internal Unit (Inches) ไปเป็นหน่วยเมตริก (m, m², m³) หรืออิมพีเรียล (ft, yd³)
  * คำนวณสูตรราคารวม: Total Cost = Quantity x (Unit Cost x Factor) x (1 + Waste%) x (1 + Tax%)
  * สรุปผลสถิติภาพรวม (Total Cost, Average Rate, Total Area)

- MaterialCostByTag::PriceStore (core/price_store.rb):
  * จัดการไฟล์ data/prices.json (Read/Write)
  * ทำความสะอาดและกรองข้อมูลราคา (Sanitize & Validation) เช่น แปลงค่าว่างให้เป็น 0.0
  * กำหนดค่า Default Prices กรณีเพิ่งรันปลั๊กอินครั้งแรก

- MaterialCostByTag::CsvExporter (core/csv_exporter.rb):
  * จัดรูปแบบ String เป็นโครงสร้าง CSV (Escape Special Characters เช่น อักขระ , หรือ ")
  * ส่งข้อมูลไปยัง JavaScript เพื่อให้ผู้ใช้กดดาวน์โหลดไฟล์ออกทางหน้าจอ Web UI

3. UI Controller Module
- MaterialCostByTag::DialogManager (ui/dialog_manager.rb):
  * สร้างอินสแตนซ์ UI::HtmlDialog พร้อมตั้งค่าขนาดหน้าต่าง และพารามิเตอร์ Preferences
  * ผูกคำสั่ง Callbacks (add_action_callback) ได้แก่ save_tag_cost_data, refresh_summary, highlight_results
  * อ่านไฟล์ index.html และ styles.css เพื่อฉีดโค้ด (Inject HTML) ส่งให้ Dialog แสดงผล