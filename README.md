# Agent Preset Templates for DeepSeek Harness (DSH)

ชุด **persona templates** ที่ clone ลงเครื่องแล้วรันติดตั้งเป็น agent preset ได้ทันที ทำงานบนระบบเดียวกับ Web GUI ของ DSH (`dsh-agent-presets`): ตอนสร้าง session ใหม่ DSH จะ mount preset ที่เลือกให้ session นั้น

> แต่ละ preset เป็น **สูตรประกอบ agent** ในไดเรกทอรีเดียว (`agent.cordis.yml` + `preset.yml`) — ชุดนี้แชร์เฉพาะส่วนที่เป็นของคุณ คือ **persona text** ส่วนเครื่องมือ/plan/compaction เป็นของ base preset (`standard` / `code` / `minimal` / `cordis`) ที่ DSH สร้างให้เอง

---

## สถานะ CI

[![test](https://github.com/Manchinn/agent-preset-templates/actions/workflows/test.yml/badge.svg)](https://github.com/Manchinn/agent-preset-templates/actions/workflows/test.yml)

แก้โค้ดแล้วไม่แน่ใจว่ายังรันได้? รัน self-test ที่เครื่อง:

```powershell
pwsh ./test-install.ps1     # exit 0 = OK
```

สคริปต์นี้ทดสอบ `install.ps1` จริงบน base preset สังเคราะห์ (ไม่ต้องมี DSH ติดตั้ง) — เช็คว่า persona ถูกแทนค่า, `{{model}}`/`{{cwd}}` คงอยู่, row ข้างเคียงไม่หลุด, `preset.yml` ถูกเขียน และ `-Default` อัปเดต `settings.yaml` GitHub Actions รันให้อัตโนมัติทั้ง Windows และ Ubuntu ทุก push / PR

---

## วิธีติดตั้ง (clone → รันสคริปต์เดียว)

```powershell
# 1. clone ลงเครื่อง
git clone <repo-url> agent-preset-templates
cd agent-preset-templates

# 2. สร้าง preset จาก persona template
./install.ps1 -Id thai-coder -PersonaFile personas\thai-coder.md `
    -Name "Thai Coder" -Description "Coding agent ตอบไทย"

# (optional) ตั้งเป็น default สำหรับ session ใหม่
./install.ps1 -Id thai-coder -Default
```

เสร็จแล้วไฟล์ไปอยู่ที่ `$HOME\.dsh\.agent-presets\<id>\` และโผล่ในการ์ด roster ของ Web GUI (**Settings → Agent Presets**) ให้เลือกตอนสร้าง session ใหม่

## ตัวเลือกของ `install.ps1`

| พารามิเตอร์ | ค่าเริ่มต้น | หมายเหตุ |
|---|---|---|
| `-Id` | **บังคับ** | ชื่อ preset ต้องตรง `[a-z0-9][a-z0-9-]*` |
| `-From` | `standard` | base preset ที่จะ clone: `standard` / `code` / `minimal` / `cordis` |
| `-PersonaFile` | `personas\thai-coder.md` | ไฟล์ `.md` persona |
| `-Name` / `-Description` | — | metadata บนการ์ด |
| `-Default` | off | ตั้งเป็น default ของ session ใหม่ (backup `settings.yaml` ให้) |
| `-HomeOverride` | `$DSH_HOME` หรือ `~\.dsh` | ใช้สำหรับทดสอบ |

> **ไม่มี Web?** ตัวเลือก `-From minimal` ได้ preset เงียบสุด (shell ถาวร + `str_replace_editor` เท่านั้น)

## Persona ที่แถมมา

| ไฟล์ | สไตล์ |
|---|---|
| `personas/thai-coder.md` | Coding agent ตอบไทย กระชับ เน้นหลักฐานจริง |
| `personas/terse-staff-eng.md` | Staff engineer ตอบสั้น เปลืองน้อย diff-first |
| `personas/research-analyst.md` | Research analyst แยก FACTS / INFERENCE / UNKNOWN + citation |
| `personas/cronus-full.md` | Titan voice — direct delivery, ซื่อสัตย์ว่าเป็น AI |

### เพิ่ม persona เอง

วางไฟล์ `.md` ลงใน `personas/` แล้วรัน:

```powershell
./install.ps1 -Id my-agent -PersonaFile personas\<file>.md -Name "My Agent"
```

**หมายเหตุเรื่อง placeholder:** persona สามารถใช้ `{{model}}` และ `{{cwd}}` — DSH แทนค่าจาก route และ workspace ของ agent เองตอน mount ให้เขียนทิ้งไว้ตามนั้น อย่าแทนค่าเอง

---

## ข้อควรรู้ก่อนแชร์

- **Preset คือ composition — ไว้วางใจระดับ shell access** persona text มีผลต่อพฤติกรรม model โดยตรง ก่อนอัปโหลด ให้อ่าน `agent.cordis.yml` และ persona `.md` ทุกบรรทัด
- **อย่าแก้/ลบ shipped presets** (`standard`/`code`/`minimal`/`cordis`) ที่มากับตัว install — upgrade จะทับ ให้ clone (copy) ออกมาแก้แทน
- **เวอร์ชัน DSH ที่ต่างกัน** อาจ rename package ใน `agent.cordis.yml` — ถ้าใครเจอ BROKEN ให้ลอง `dsh` ล่าสุด หรือเปลี่ยน `-From` เป็น base preset อื่น
- การแก้อะไรใน preset มีผลกับ session ที่สร้าง **หลัง** แก้เท่านั้น — session ที่เริ่มแล้วติด preset เดิม (switch ไม่ได้ แต่ปิด/สร้างใหม่ได้)

---

## โครงสร้าง

```
agent-preset-templates/
├── README.md            ← นี้
├── install.ps1          ← clone แล้วรัน (สร้าง preset จาก persona)
├── LICENSE              ← MIT
├── personas/            ★ persona templates
│   ├── thai-coder.md
│   ├── terse-staff-eng.md
│   ├── research-analyst.md
│   ├── cronus-full.md
│   └── README.md
└── .gitignore
```
