BASANTA DRY CLEANLINESS — FIXED BUILD
=======================================

Files included:
- index.html / app.js / style.css
- Admin.html / admin.js / admin.css
- content-admin.html / content-admin.js / content-admin.css
- track.html / track.js / track.css
- success.html / success.js / success.css
- article.html
- legal/static pages
- config.js
- supabase-error-fix.sql

FIXES MADE
----------
1. Shared Supabase configuration is now in config.js.
2. The existing Supabase URL/anon key from article.html is reused.
3. Fixed GitHub case-sensitive link: admin.html -> Admin.html.
4. Fixed Admin status option values to match JS/database statuses.
5. Order booking now shows the real Supabase insert error instead of silently creating a fake success page.
6. Cloth image upload now reports the actual Storage error.
7. Added a safe SQL repair file for notifications_log, including the missing type column.
8. Repaired the order-created notification trigger so it no longer depends on an old order_id column type.
9. Added/ensured cloth_description, cloth_details, cloth_image and cloth_images columns.
10. Ensured cloth-images and website-image Storage buckets/policies exist.
11. Ensured services/pricing/steps required columns exist.

SUPABASE
--------
Run ONLY:
  supabase-error-fix.sql

Run it in:
Supabase Dashboard -> SQL Editor -> New query -> paste/run.

IMPORTANT
---------
The anon key is intended for browser use, but the current SQL policies are permissive.
Before a public launch, add proper admin authentication and restrict INSERT/UPDATE/DELETE
permissions to authenticated admins.

CONFIG
------
If you rotate/change the Supabase project, edit config.js:
  SUPABASE_URL
  SUPABASE_ANON_KEY

WHATSAPP
--------
Change WHATSAPP_NUMBER in config.js to your business WhatsApp number without + or spaces.

TEST CHECKLIST
--------------
1. Open index.html.
2. Submit a test pickup order.
3. Confirm order appears in Admin.html.
4. Open Manage Order and verify Cloth Details / Description.
5. Upload a cloth image and confirm it opens.
6. Change order status and refresh.
7. Test track.html?order=BC-0001.
8. Test success.html?order=BC-0001.
9. Test content-admin.html image upload.
