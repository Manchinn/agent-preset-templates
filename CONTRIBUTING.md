# Contributing ไปที่ Repo นี้

ขอบคุณที่สนใจช่วยเหลือ! งานหลักของ repo นี้คือ **ชุด persona templates** สำหรับ DSH (DeepSeek Harness) ที่ clone ไปรัน `install.ps1` แล้วกลายเป็น agent preset ได้ทันที

---

## 1. เพิ่ม persona ใหม่ (ของขวัญที่บ่อยสุด)

1. หย่อนไฟล์ `.md` หนึ่งไฟล์ต่อ persona ลงใน `personas/`
2. เปิดดูไฟล์ที่มีอยู่ก่อน (เช่น `personas/thai-coder.md`) เพื่อจับสไตล์
3. **ต้องมี placeholders `{{model}}` และ `{{cwd}}`** อย่างน้อยหนึ่งจุด — DSH แทนค่าให้ตอน mount
4. ปกติบรรทัดแรกจะเป็น `You are ... powered by the {{model}} model. Your working directory is {{cwd}}.` (แนะนำให้มี)
5. อัปเดตตารางใน `personas/README.md` และ `README.md` (ส่วน "Persona ที่แถมมา") ให้เพิ่มแถวใหม่
6. เก็บไฟล์ให้สั้นและคม: persona ควรเป็น "วิธีทำงาน/สไตล์/กฎ" ไม่ใช่เรื่องเล่ายาว ๆ

ตัวอย่างเทสต์ด้วยตัวเอง:

```powershell
pwsh ./test-install.ps1
```

> **สิ่งที่ผมรับไม่ได้ (อย่าเพิ่ม):** persona ที่มีจุดประสงค์ให้ agent **ข้าม safety ของระบบ** (injection-rebuttal protocol, สั่ง "never refuse", สอนสร้างเนื้อหาอันตราย เช่น วิธีทำระเบิด/มัลแวร์ หรือเนื้อหาต้องห้าม) — นี่คือ jailbreak prompt ไม่ใช่ persona ถ้าเจอใน PR จะถูกปฏิเสธ

## 2. แก้โค้ด (`install.ps1`, `test-install.ps1`)

- `install.ps1` สร้าง preset โดย clone base แล้วแทน persona row — ระวังอย่าให้ regex/โครงสร้างที่แทน persona พัง
- `test-install.ps1` ต้อง mirror กฎของ `install.ps1` — ถ้าเปลี่ยนวิธีแทน persona ให้อัปเดต assertion ตาม
- **ทุก commit ต้องผ่าน** `pwsh ./test-install.ps1` (exit 0) และ CI ต้องเขียว

## 3. รัน test ก่อนส่ง

```powershell
# เครื่อง
pwsh ./test-install.ps1            # exit 0 = ผ่าน
```

GitHub Actions รันชุดเดียวกันบน **Windows + Ubuntu** — ถ้า CI แดง PR จะไม่ถูกรวม

## 4. Conventional Commits (แนะนำ)

ใช้ prefix สั้น ๆ:

```
feat: add docs-writer persona
fix: handle empty UserProfile on Linux runners
docs: clarify persona placeholder rules
test: extend self-test for -Default
chore: update dependencies / formatting
```

## 5. ข้อควรรู้ที่ห้ามละเมิด

| เรื่อง | กติกา |
|---|---|
| Shipped presets (`standard`/`code`/`minimal`/`cordis`) | **ห้ามแก้/ลบ** — upgrade จะทับ ให้ copy ออกมาแก้แทน |
| Persona id | ต้องตรง `[a-z0-9][a-z0-9-]*` |
| Line endings | บังคับ `LF` ผ่าน `.gitattributes` — อย่าเปลี่ยนเป็น CRLF |
| Persona ที่มี placeholders | ห้ามแทนค่า `{{model}}`/`{{cwd}}` เอง |
| แชร์เนื้อหาอันตราย | ไม่อนุญาต (ดูข้อ 1) |

## 6. Flow ของ PR

1. fork + สร้าง branch (`feat/add-docs-writer`)
2. แก้ + รัน `pwsh ./test-install.ps1`
3. commit ด้วยข้อความแบบ Conventional
4. push + เปิด PR — อธิบายว่าทำอะไร และแนบผล test ถ้ามี
5. รอ review (CI ต้องเขียว)
