# Changelog

การเปลี่ยนแปลงที่สำคัญทั้งหมดของโปรเจกต์นี้จะถูกบันทึกในไฟล์นี้
ใช้รูปแบบตาม [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) และยึดตาม [Semantic Versioning](https://semver.org/)

ยังไม่มี release tag — ตัด tag แรก (แนะนำ `0.1.0`) เมื่อชุด persona คงที่พอจะเป็น v1 ได้

## [Unreleased]

### Added
- `install.ps1`: ตัวติดตั้ง clone-and-go ที่แปลง persona template เป็น DSH agent preset
- Persona templates 4 ตัว: `thai-coder`, `terse-staff-eng`, `research-analyst`, `cronus-full`
- `test-install.ps1`: self-test ที่รัน `install.ps1` บน base สังเคราะห์แล้ว assert ผลลัพธ์
- GitHub Actions CI (`.github/workflows/test.yml`) รัน self-test บน Windows + Ubuntu
- `LICENSE` (MIT), `.gitattributes` (บังคับ LF), `.gitignore`

### Fixed
- จัดการ path ข้ามแพลตฟอร์มใน `install.ps1` / `test-install.ps1` (`Join-Path` แบบหลาย segment, โฟล์วาร์ดสแลชในค่า default, `[IO.Path]::GetTempPath()`)
- `Find-ShippedRoot` ถูกข้ามเมื่อใช้ `-BaseDir`; กัน env เป็น null ใน fallback ของ nvm
- `Resolve-DshHome` ใช้ `$env:HOME` แทนเมื่อ `UserProfile` ว่าง (บน Linux runner)

### Notes
- repo สาธารณะ: https://github.com/Manchinn/agent-preset-templates
