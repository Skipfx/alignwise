-- Create storage bucket for user files (meal photos, etc.)
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'user-files',
    'user-files', 
    false,
    10485760, -- 10MB limit
    ARRAY['image/jpeg', 'image/png', 'image/webp', 'image/jpg']
);

-- RLS Policy: Users can view their own files
CREATE POLICY "users_view_own_files"
ON storage.objects
FOR SELECT
TO authenticated
USING (bucket_id = 'user-files' AND owner = auth.uid());

-- RLS Policy: Users can upload files to their folder
CREATE POLICY "users_upload_own_files" 
ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (
    bucket_id = 'user-files' 
    AND owner = auth.uid()
    AND (storage.foldername(name))[1] = auth.uid()::text
);

-- RLS Policy: Users can update their own files
CREATE POLICY "users_update_own_files"
ON storage.objects
FOR UPDATE
TO authenticated
USING (bucket_id = 'user-files' AND owner = auth.uid())
WITH CHECK (bucket_id = 'user-files' AND owner = auth.uid());

-- RLS Policy: Users can delete their own files  
CREATE POLICY "users_delete_own_files"
ON storage.objects
FOR DELETE
TO authenticated
USING (bucket_id = 'user-files' AND owner = auth.uid());