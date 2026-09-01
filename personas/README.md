# Persona templates

หย่อนไฟล์ `.md` ตัวหนึ่งต่อ persona ลงในโฟลเดอร์นี้ แล้ว install ด้วย:

```powershell
./install.ps1 -Id <id> -PersonaFile personas\<filename>.md -Name "<ชื่อการ์ด>"
```

## กติกาของไฟล์ persona

- **บรรทัดแรก** มักเป็น "You are ... powered by the {{model}} model. Your working directory is {{cwd}}." — คือตัวตนเบื้องต้นที่ DSH ใช้สร้าง base
- ใช้ placeholder `{{model}}` และ `{{cwd}}` ได้ (DSH แทนค่าให้ตอน mount) อย่าแทนค่าเอง
- ส่วนที่เหลือคือ **วิธีทำงาน / สไตล์ / กฎ** ของ agent
- คนที่จะ clone ต้องอ่านไฟล์นี้ก่อน เพราะมันกำหนดพฤติกรรม model โดยตรง
