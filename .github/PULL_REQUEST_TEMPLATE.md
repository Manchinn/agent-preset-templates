## สรุปการเปลี่ยนแปลง

<!-- หนึ่งหรือสองประโยค: PR นี้ทำอะไร และเพราะอะไร -->

## ประเภท

- [ ] feat (เพิ่ม persona / feature ใหม่)
- [ ] fix (แก้ bug)
- [ ] docs (เอกสาร)
- [ ] test (เพิ่ม/แก้ test)
- [ ] chore (อื่น ๆ)

## รายละเอียด

- **ไฟล์ที่แก้:**
- **Persona/feature ที่เพิ่ม** (ถ้ามี): อธิบายสไตล์สั้น ๆ

## การทดสอบ

- [ ] รัน `pwsh ./test-install.ps1` แล้วผ่าน (exit 0)
- [ ] CI เขียวบน Windows + Ubuntu

## ตรวจก่อนส่ง

- [ ] ไม่ได้แก้/ลบ shipped preset
- [ ] persona ใหม่มี `{{model}}`/`{{cwd}}` และไม่มีเนื้อหาข้าม safety ระบบ
- [ ] อัปเดต `personas/README.md` + `README.md` ให้ตรง หากเพิ่ม persona

> หมายเหตุสำหรับ reviewer: ถ้าตรวจพบ persona ที่เป็น jailbreak prompt (สั่งให้ข้าม safety, สร้างเนื้อหาอันตราย) ให้ปิด PR นี้ทันที
