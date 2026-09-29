-- ============================================================
-- BASANTA DRY CLEANLINESS — ERROR FIX
-- Run this file in Supabase SQL Editor.
-- It is designed to repair an existing database safely.
-- ============================================================

-- 1) ORDERS: fields used by the website/admin panel
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS cloth_description TEXT;
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS cloth_details TEXT;
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS cloth_image TEXT;
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS cloth_images JSONB DEFAULT '[]'::jsonb;
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT NOW();

-- 2) NOTIFICATIONS LOG
-- Fixes: relation does not exist / column "type" does not exist.
CREATE TABLE IF NOT EXISTS public.notifications_log (
  id BIGSERIAL PRIMARY KEY
);

ALTER TABLE public.notifications_log ADD COLUMN IF NOT EXISTS order_id BIGINT;
ALTER TABLE public.notifications_log ADD COLUMN IF NOT EXISTS type TEXT;
ALTER TABLE public.notifications_log ADD COLUMN IF NOT EXISTS recipient TEXT;
ALTER TABLE public.notifications_log ADD COLUMN IF NOT EXISTS message TEXT;
ALTER TABLE public.notifications_log ADD COLUMN IF NOT EXISTS status TEXT DEFAULT 'pending';
ALTER TABLE public.notifications_log ADD COLUMN IF NOT EXISTS error_message TEXT;
ALTER TABLE public.notifications_log ADD COLUMN IF NOT EXISTS sent_at TIMESTAMPTZ;
ALTER TABLE public.notifications_log ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ DEFAULT NOW();

ALTER TABLE public.notifications_log ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Public all notifications" ON public.notifications_log;

CREATE POLICY "Public all notifications"
ON public.notifications_log
FOR ALL
TO anon, authenticated
USING (true)
WITH CHECK (true);

CREATE INDEX IF NOT EXISTS idx_notifications_log_order_id
ON public.notifications_log(order_id);

-- 3) REPAIR THE ORDER NOTIFICATION TRIGGER.
-- We deliberately do not write order_id here because an older
-- notifications_log table may have a different order_id type.
CREATE OR REPLACE FUNCTION public.log_order_notification()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  INSERT INTO public.notifications_log
    (type, recipient, message, status, created_at)
  VALUES
    (
      'whatsapp',
      NEW.phone,
      'Order ' || COALESCE(NEW.order_number::text, NEW.id::text) || ' created',
      'pending',
      NOW()
    );

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS after_order_insert ON public.orders;

CREATE TRIGGER after_order_insert
AFTER INSERT ON public.orders
FOR EACH ROW
EXECUTE FUNCTION public.log_order_notification();

-- 4) CLOTH IMAGE STORAGE
INSERT INTO storage.buckets (id, name, public)
VALUES ('cloth-images', 'cloth-images', true)
ON CONFLICT (id)
DO UPDATE SET public = true;

DROP POLICY IF EXISTS "Public view cloth images" ON storage.objects;
DROP POLICY IF EXISTS "Public upload cloth images" ON storage.objects;
DROP POLICY IF EXISTS "Public update cloth images" ON storage.objects;
DROP POLICY IF EXISTS "Public delete cloth images" ON storage.objects;

CREATE POLICY "Public view cloth images"
ON storage.objects
FOR SELECT TO anon, authenticated
USING (bucket_id = 'cloth-images');

CREATE POLICY "Public upload cloth images"
ON storage.objects
FOR INSERT TO anon, authenticated
WITH CHECK (bucket_id = 'cloth-images');

CREATE POLICY "Public update cloth images"
ON storage.objects
FOR UPDATE TO anon, authenticated
USING (bucket_id = 'cloth-images')
WITH CHECK (bucket_id = 'cloth-images');

CREATE POLICY "Public delete cloth images"
ON storage.objects
FOR DELETE TO anon, authenticated
USING (bucket_id = 'cloth-images');

-- 5) ADMIN/CONTENT IMAGE STORAGE
INSERT INTO storage.buckets (id, name, public)
VALUES ('website-image', 'website-image', true)
ON CONFLICT (id)
DO UPDATE SET public = true;

DROP POLICY IF EXISTS "Public view website images" ON storage.objects;
DROP POLICY IF EXISTS "Public upload website images" ON storage.objects;
DROP POLICY IF EXISTS "Public update website images" ON storage.objects;
DROP POLICY IF EXISTS "Public delete website images" ON storage.objects;

CREATE POLICY "Public view website images"
ON storage.objects
FOR SELECT TO anon, authenticated
USING (bucket_id = 'website-image');

CREATE POLICY "Public upload website images"
ON storage.objects
FOR INSERT TO anon, authenticated
WITH CHECK (bucket_id = 'website-image');

CREATE POLICY "Public update website images"
ON storage.objects
FOR UPDATE TO anon, authenticated
USING (bucket_id = 'website-image')
WITH CHECK (bucket_id = 'website-image');

CREATE POLICY "Public delete website images"
ON storage.objects
FOR DELETE TO anon, authenticated
USING (bucket_id = 'website-image');

-- 6) REQUIRED CONTENT TABLES/COLUMNS
CREATE TABLE IF NOT EXISTS public.services (
  id BIGSERIAL PRIMARY KEY,
  name TEXT NOT NULL DEFAULT 'Service',
  description TEXT,
  price NUMERIC(10,2) DEFAULT 0,
  icon TEXT DEFAULT '🧺',
  image_url TEXT,
  active BOOLEAN DEFAULT true,
  sort_order INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.pricing (
  id BIGSERIAL PRIMARY KEY,
  name TEXT NOT NULL DEFAULT 'Item',
  description TEXT,
  price NUMERIC(10,2) DEFAULT 0,
  category TEXT,
  image_url TEXT,
  active BOOLEAN DEFAULT true,
  sort_order INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.steps (
  id BIGSERIAL PRIMARY KEY,
  step_number INTEGER DEFAULT 1,
  title TEXT NOT NULL DEFAULT 'Step',
  description TEXT,
  icon TEXT,
  active BOOLEAN DEFAULT true,
  sort_order INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.services ADD COLUMN IF NOT EXISTS description TEXT;
ALTER TABLE public.services ADD COLUMN IF NOT EXISTS price NUMERIC(10,2) DEFAULT 0;
ALTER TABLE public.services ADD COLUMN IF NOT EXISTS image_url TEXT;
ALTER TABLE public.services ADD COLUMN IF NOT EXISTS active BOOLEAN DEFAULT true;
ALTER TABLE public.services ADD COLUMN IF NOT EXISTS sort_order INTEGER DEFAULT 0;

ALTER TABLE public.pricing ADD COLUMN IF NOT EXISTS description TEXT;
ALTER TABLE public.pricing ADD COLUMN IF NOT EXISTS active BOOLEAN DEFAULT true;
ALTER TABLE public.pricing ADD COLUMN IF NOT EXISTS sort_order INTEGER DEFAULT 0;

ALTER TABLE public.steps ADD COLUMN IF NOT EXISTS description TEXT;
ALTER TABLE public.steps ADD COLUMN IF NOT EXISTS active BOOLEAN DEFAULT true;
ALTER TABLE public.steps ADD COLUMN IF NOT EXISTS sort_order INTEGER DEFAULT 0;



ALTER TABLE public.services ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.pricing ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.steps ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "services_public_all" ON public.services;
CREATE POLICY "services_public_all" ON public.services
FOR ALL TO anon, authenticated USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "pricing_public_all" ON public.pricing;
CREATE POLICY "pricing_public_all" ON public.pricing
FOR ALL TO anon, authenticated USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "steps_public_all" ON public.steps;
CREATE POLICY "steps_public_all" ON public.steps
FOR ALL TO anon, authenticated USING (true) WITH CHECK (true);

-- 7) SIMPLE VERIFICATION
SELECT 'notifications_log' AS table_name, COUNT(*) AS rows
FROM public.notifications_log;

SELECT column_name, data_type
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name = 'notifications_log'
ORDER BY ordinal_position;
